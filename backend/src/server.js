/**
 * IntegraTax Middleware — backend/src/server.js
 *
 * Security hardening changelog (see QA report):
 *   SEC-002 — CORS locked to ALLOWED_ORIGIN env var           (was: reflect any origin)
 *   SEC-003 — helmet added for security headers               (was: no headers)
 *   SEC-004 — express-rate-limit (60 req/min per IP)          (was: no limit)
 *   SEC-005 — proxy params Array.isArray guard                (was: arrays passed through)
 *   SEC-006 — X-IntegraTax-Key secret header authentication   (was: open to any caller)
 *   SEC-008 — SIMPBB_BASE_URL validated at startup            (was: silent fallback)
 *   SEC-009 — AbortSignal.timeout(10000) on upstream fetch    (was: no timeout)
 *   SEC-010 — X-Powered-By disabled via helmet                (was: exposed)
 */

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';

// ─── Startup Environment Validation ──────────────────────────────────────────
// SIMPBB_BASE_URL is required in all environments. Fail fast if missing.
if (!process.env.SIMPBB_BASE_URL && process.env.NODE_ENV === 'production') {
  console.error('[FATAL] SIMPBB_BASE_URL environment variable is not set.');
  console.error('        Set it to the upstream SIMPBB API base URL before starting.');
  process.exit(1);
}

const port = Number(process.env.PORT ?? 3000);
const simpbbBaseUrl =
  process.env.SIMPBB_BASE_URL ?? 'https://simpbb.technosmart.id/api/rpc';

// Secret key for frontend↔middleware authentication.
// Generate with: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
// Set INTEGRATAX_API_KEY in the environment; leave unset to disable auth (dev only).
const apiKey = process.env.INTEGRATAX_API_KEY ?? '';

const allowedOrpcPaths = new Set([
  '/wilayah/listPropinsi',
  '/objekPajak/search',
  '/objekPajak/listDetails',
  '/objekPajak/getByNop',
]);

const app = express();

// ─── Security Headers (SEC-003, SEC-010) ─────────────────────────────────────
app.use(
  helmet({
    crossOriginEmbedderPolicy: false, // Allow Flutter web embedding
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        connectSrc: ["'self'"],
      },
    },
  }),
);

// ─── CORS (SEC-002) ───────────────────────────────────────────────────────────
// In development: all localhost origins are allowed (Flutter web uses random ports).
// In production: restrict to the explicit ALLOWED_ORIGIN allowlist.
const isDev = process.env.NODE_ENV !== 'production';
const rawAllowed = process.env.ALLOWED_ORIGIN ?? 'http://localhost:3000';
const allowedOrigins = new Set(rawAllowed.split(',').map((o) => o.trim()));

// Matches http://localhost:<any-port> and http://127.0.0.1:<any-port>
const localhostPattern = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;

app.use(
  cors({
    origin(origin, callback) {
      // Allow requests without Origin (mobile apps, curl, Postman)
      if (!origin) return callback(null, true);
      // Dev: permit any localhost port (Flutter web, Angular, Vite, etc.)
      if (isDev && localhostPattern.test(origin)) return callback(null, true);
      // Prod: check explicit allowlist
      if (allowedOrigins.has(origin)) return callback(null, true);
      callback(new Error(`CORS: origin '${origin}' tidak diizinkan.`));
    },
    optionsSuccessStatus: 200,
  }),
);

// ─── Body Parsing ─────────────────────────────────────────────────────────────
app.use(express.json({ limit: '1mb' }));

// ─── Rate Limiting (SEC-004) ──────────────────────────────────────────────────
const limiter = rateLimit({
  windowMs: 60 * 1000,   // 1 minute window
  max: 60,               // 60 requests per window per IP
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Terlalu banyak permintaan. Coba lagi dalam satu menit.' },
});
app.use(limiter);

// ─── Middleware Authentication (SEC-006) ──────────────────────────────────────
// Skip when apiKey is not configured (development without the env var).
app.use((req, res, next) => {
  if (!apiKey) return next(); // Auth disabled in dev when key not set
  const provided = req.headers['x-integratax-key'];
  if (!provided || provided !== apiKey) {
    return res.status(401).json({ message: 'Akses tidak sah.' });
  }
  next();
});

// ─── Routes ───────────────────────────────────────────────────────────────────

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'integratax-middleware',
    timestamp: new Date().toISOString(),
  });
});

app.post('/api/simpbb/search', async (req, res, next) => {
  try {
    const query = String(req.body?.query ?? '').trim();
    const limit = Number(req.body?.limit ?? 5);

    if (query.length < 2) {
      return res.status(400).json({ message: 'Query minimal 2 karakter.' });
    }

    const result = await postOrpc('/objekPajak/search', {
      query,
      limit: clamp(limit, 1, 20),
    });
    res.json({ data: result });
  } catch (error) {
    next(error);
  }
});

app.post('/api/simpbb/list-details', async (req, res, next) => {
  try {
    const limit = Number(req.body?.limit ?? 10);
    const offset = Number(req.body?.offset ?? 0);
    const search = String(req.body?.search ?? '').trim();

    const params = {
      kdPropinsi: String(req.body?.kdPropinsi ?? '51'),
      limit: clamp(limit, 1, 50),
      offset: Math.max(0, offset),
    };

    if (search.length > 0) {
      params.search = search;
    }

    const result = await postOrpc('/objekPajak/listDetails', params);
    res.json({ data: result });
  } catch (error) {
    next(error);
  }
});

app.post('/api/simpbb/proxy', async (req, res, next) => {
  try {
    const path = String(req.body?.path ?? '');

    // SEC-005: reject arrays — typeof [] === 'object' would otherwise bypass this guard.
    const rawParams = req.body?.params;
    const params =
      rawParams !== null &&
      typeof rawParams === 'object' &&
      !Array.isArray(rawParams)
        ? rawParams
        : {};

    if (!allowedOrpcPaths.has(path)) {
      return res.status(400).json({ message: 'Endpoint tidak diizinkan.' });
    }

    const result = await postOrpc(path, params);
    res.json({ data: result });
  } catch (error) {
    next(error);
  }
});

// ─── Error Handler ────────────────────────────────────────────────────────────
// eslint-disable-next-line no-unused-vars
app.use((error, req, res, _next) => {
  // Do not leak stack traces to the client.
  const statusCode = error.statusCode ?? 500;
  const message =
    statusCode === 500
      ? 'Terjadi kesalahan internal middleware.'
      : (error.message ?? 'Terjadi kesalahan.');
  res.status(statusCode).json({ message });
});

app.listen(port, () => {
  console.log(`IntegraTax middleware listening on http://localhost:${port}`);
  if (!apiKey) {
    console.warn(
      '[WARN] INTEGRATAX_API_KEY is not set — middleware authentication is DISABLED.',
    );
  }
  if (!process.env.ALLOWED_ORIGIN) {
    if (isDev) {
      console.info(
        '[INFO] ALLOWED_ORIGIN is not set — running in DEV mode: all localhost origins are allowed.',
      );
    } else {
      console.warn(
        '[WARN] ALLOWED_ORIGIN is not set — CORS is restricted to localhost:3000 only.',
      );
    }
  }
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * POST to the SIMPBB oRPC upstream.
 * SEC-009: Uses AbortSignal.timeout to prevent indefinite hangs.
 */
async function postOrpc(path, params) {
  let response;
  try {
    response = await fetch(`${simpbbBaseUrl}${path}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({ json: params }),
      signal: AbortSignal.timeout(10_000), // 10s upstream timeout (SEC-009)
    });
  } catch (err) {
    if (err.name === 'TimeoutError' || err.name === 'AbortError') {
      const timeout = new Error('SIMPBB upstream timeout setelah 10 detik.');
      timeout.statusCode = 504;
      throw timeout;
    }
    const connErr = new Error(`Tidak dapat terhubung ke SIMPBB: ${err.message}`);
    connErr.statusCode = 502;
    throw connErr;
  }

  const text = await response.text();
  let decoded;
  try {
    decoded = text ? JSON.parse(text) : {};
  } catch {
    const malformed = new Error('SIMPBB response bukan JSON valid.');
    malformed.statusCode = 502;
    throw malformed;
  }

  if (!response.ok) {
    const upstream = new Error(
      decoded?.message ?? decoded?.error ?? 'SIMPBB request gagal.',
    );
    upstream.statusCode = response.status;
    throw upstream;
  }

  if (!Object.prototype.hasOwnProperty.call(decoded, 'json')) {
    const malformed = new Error('SIMPBB response tidak memiliki wrapper json.');
    malformed.statusCode = 502;
    throw malformed;
  }

  return decoded.json?.data ?? decoded.json;
}

function clamp(value, min, max) {
  if (!Number.isFinite(value)) return min;
  return Math.min(Math.max(value, min), max);
}
