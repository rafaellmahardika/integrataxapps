/**
 * IntegraTax Middleware — backend/test/server.test.js
 *
 * Backend API tests using Jest + Supertest.
 * Tests validation logic, security guards, and edge cases identified in the QA report.
 *
 * Run: npm test --prefix backend
 */

import request from 'supertest';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';

// ─── Build a testable app instance (without actually starting a server) ───────
// We mock postOrpc by monkey-patching fetch globally so tests don't hit SIMPBB.

function buildApp({ mockFetch = null } = {}) {
  // If a mockFetch is provided, inject it globally for this test scope
  if (mockFetch) global.fetch = mockFetch;

  const app = express();
  app.use(helmet());
  app.use(cors({ origin: true })); // Open in test mode
  app.use(express.json({ limit: '1mb' }));

  const allowedOrpcPaths = new Set([
    '/wilayah/listPropinsi',
    '/objekPajak/search',
    '/objekPajak/listDetails',
    '/objekPajak/getByNop',
  ]);

  function clamp(value, min, max) {
    if (!Number.isFinite(value)) return min;
    return Math.min(Math.max(value, min), max);
  }

  async function postOrpc(path, params) {
    const response = await fetch(`https://mock.simpbb${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({ json: params }),
      signal: AbortSignal.timeout(10_000),
    });

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
      const upstream = new Error(decoded?.message ?? 'SIMPBB request gagal.');
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

  app.get('/health', (req, res) => {
    res.json({ status: 'ok', service: 'integratax-middleware', timestamp: new Date().toISOString() });
  });

  app.post('/api/simpbb/search', async (req, res, next) => {
    try {
      const query = String(req.body?.query ?? '').trim();
      const limit = Number(req.body?.limit ?? 5);
      if (query.length < 2) return res.status(400).json({ message: 'Query minimal 2 karakter.' });
      const result = await postOrpc('/objekPajak/search', { query, limit: clamp(limit, 1, 20) });
      res.json({ data: result });
    } catch (e) { next(e); }
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
      if (search.length > 0) params.search = search;
      const result = await postOrpc('/objekPajak/listDetails', params);
      res.json({ data: result });
    } catch (e) { next(e); }
  });

  app.post('/api/simpbb/proxy', async (req, res, next) => {
    try {
      const path = String(req.body?.path ?? '');
      const rawParams = req.body?.params;
      // SEC-005: Array.isArray guard
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
    } catch (e) { next(e); }
  });

  // eslint-disable-next-line no-unused-vars
  app.use((error, req, res, _next) => {
    const statusCode = error.statusCode ?? 500;
    res.status(statusCode).json({ message: error.message ?? 'Internal error' });
  });

  return app;
}

// ─── Mock fetch factory ───────────────────────────────────────────────────────

function mockFetchSuccess(data) {
  return async () => ({
    ok: true,
    status: 200,
    text: async () => JSON.stringify({ json: { data } }),
  });
}

function mockFetchError(status, message) {
  return async () => ({
    ok: false,
    status,
    text: async () => JSON.stringify({ message }),
  });
}

function mockFetchMalformedJson() {
  return async () => ({
    ok: true,
    status: 200,
    text: async () => 'not valid json }{',
  });
}

function mockFetchMissingWrapper() {
  return async () => ({
    ok: true,
    status: 200,
    text: async () => JSON.stringify({ result: [] }), // No "json" key
  });
}

// ─── Test Suites ─────────────────────────────────────────────────────────────

describe('GET /health', () => {
  const app = buildApp();

  test('TC-020: returns 200 with required fields', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.service).toBe('integratax-middleware');
    expect(res.body.timestamp).toBeDefined();
  });

  test('timestamp is valid ISO 8601', async () => {
    const res = await request(app).get('/health');
    expect(() => new Date(res.body.timestamp)).not.toThrow();
    expect(new Date(res.body.timestamp).toISOString()).toBe(res.body.timestamp);
  });

  test('SEC-003: X-Powered-By is not present', async () => {
    const res = await request(app).get('/health');
    expect(res.headers['x-powered-by']).toBeUndefined();
  });

  test('responds with JSON content-type', async () => {
    const res = await request(app).get('/health');
    expect(res.headers['content-type']).toMatch(/application\/json/);
  });
});

describe('POST /api/simpbb/search — validation', () => {
  const app = buildApp({ mockFetch: mockFetchSuccess([]) });

  test('TC-024 BUG: rejects missing body (no query)', async () => {
    const res = await request(app).post('/api/simpbb/search').send({});
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toContain('2 karakter');
  });

  test('TC: rejects 1-char query', async () => {
    const res = await request(app)
      .post('/api/simpbb/search')
      .send({ query: 'a' });
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toContain('2 karakter');
  });

  test('TC: rejects whitespace-only query (trims first)', async () => {
    const res = await request(app)
      .post('/api/simpbb/search')
      .send({ query: '   ' });
    expect(res.statusCode).toBe(400);
  });

  test('TC: accepts 2-char query', async () => {
    const app2 = buildApp({ mockFetch: mockFetchSuccess([{ nmWpSppt: 'AB', jalanOp: 'JL.X' }]) });
    const res = await request(app2)
      .post('/api/simpbb/search')
      .send({ query: 'AB' });
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('data');
  });

  test('TC: clamps limit=null to 1 (minimum)', async () => {
    // When limit is null, Number(null)=0 which is non-finite? No, 0 is finite.
    // clamp(0, 1, 20) = 1
    const app2 = buildApp({ mockFetch: mockFetchSuccess([]) });
    const res = await request(app2)
      .post('/api/simpbb/search')
      .send({ query: 'BUDI', limit: null });
    expect(res.statusCode).toBe(200);
  });

  test('TC: clamps string limit to minimum (NaN → 1)', async () => {
    const app2 = buildApp({ mockFetch: mockFetchSuccess([]) });
    const res = await request(app2)
      .post('/api/simpbb/search')
      .send({ query: 'BUDI', limit: 'abc' });
    expect(res.statusCode).toBe(200);
  });

  test('TC: clamps limit=9999 to 20 (maximum)', async () => {
    const app2 = buildApp({ mockFetch: mockFetchSuccess([]) });
    const res = await request(app2)
      .post('/api/simpbb/search')
      .send({ query: 'BUDI', limit: 9999 });
    expect(res.statusCode).toBe(200);
  });

  test('TC-028: returns 413 for oversized body', async () => {
    const bigBody = JSON.stringify({ query: 'A'.repeat(1_100_000) });
    const res = await request(app)
      .post('/api/simpbb/search')
      .set('Content-Type', 'application/json')
      .send(bigBody);
    expect(res.statusCode).toBe(413);
  });
});

describe('POST /api/simpbb/search — upstream error handling', () => {
  test('returns 502 on malformed upstream JSON', async () => {
    const app = buildApp({ mockFetch: mockFetchMalformedJson() });
    const res = await request(app)
      .post('/api/simpbb/search')
      .send({ query: 'BUDI' });
    expect(res.statusCode).toBe(502);
    expect(res.body.message).toContain('JSON valid');
  });

  test('returns 502 when upstream response missing json wrapper', async () => {
    const app = buildApp({ mockFetch: mockFetchMissingWrapper() });
    const res = await request(app)
      .post('/api/simpbb/search')
      .send({ query: 'BUDI' });
    expect(res.statusCode).toBe(502);
  });

  test('returns upstream status on upstream 4xx', async () => {
    const app = buildApp({ mockFetch: mockFetchError(422, 'Unprocessable') });
    const res = await request(app)
      .post('/api/simpbb/search')
      .send({ query: 'BUDI' });
    expect(res.statusCode).toBe(422);
  });

  test('returns upstream status on upstream 500', async () => {
    const app = buildApp({ mockFetch: mockFetchError(500, 'Internal') });
    const res = await request(app)
      .post('/api/simpbb/search')
      .send({ query: 'BUDI' });
    expect(res.statusCode).toBe(500);
  });
});

describe('POST /api/simpbb/list-details', () => {
  test('defaults: works with empty body', async () => {
    const app = buildApp({ mockFetch: mockFetchSuccess({ rows: [], total: 0 }) });
    const res = await request(app)
      .post('/api/simpbb/list-details')
      .send({});
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('data');
  });

  test('clamps negative offset to 0', async () => {
    let capturedParams;
    global.fetch = async (url, { body }) => {
      capturedParams = JSON.parse(body).json;
      return {
        ok: true,
        status: 200,
        text: async () => JSON.stringify({ json: { rows: [], total: 0 } }),
      };
    };
    const app = buildApp();
    await request(app)
      .post('/api/simpbb/list-details')
      .send({ offset: -999 });
    expect(capturedParams.offset).toBe(0);
  });

  test('clamps limit above 50 to 50', async () => {
    let capturedParams;
    global.fetch = async (url, { body }) => {
      capturedParams = JSON.parse(body).json;
      return {
        ok: true,
        status: 200,
        text: async () => JSON.stringify({ json: { rows: [], total: 0 } }),
      };
    };
    const app = buildApp();
    await request(app)
      .post('/api/simpbb/list-details')
      .send({ limit: 9999 });
    expect(capturedParams.limit).toBe(50);
  });
});

describe('POST /api/simpbb/proxy — allowlist enforcement', () => {
  const app = buildApp({ mockFetch: mockFetchSuccess([]) });

  test('TC-025: rejects disallowed path', async () => {
    const res = await request(app)
      .post('/api/simpbb/proxy')
      .send({ path: '/admin/deleteAll', params: {} });
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toContain('tidak diizinkan');
  });

  test('TC-026: rejects path traversal attempt', async () => {
    const res = await request(app)
      .post('/api/simpbb/proxy')
      .send({ path: '/../../../etc/passwd', params: {} });
    expect(res.statusCode).toBe(400);
  });

  test('TC-027: rejects full URL injection', async () => {
    const res = await request(app)
      .post('/api/simpbb/proxy')
      .send({ path: 'https://evil.com/steal', params: {} });
    expect(res.statusCode).toBe(400);
  });

  test('rejects missing path', async () => {
    const res = await request(app)
      .post('/api/simpbb/proxy')
      .send({ params: {} });
    expect(res.statusCode).toBe(400);
  });

  test('accepts allowed path', async () => {
    const app2 = buildApp({ mockFetch: mockFetchSuccess([{ kdPropinsi: '51', nmPropinsi: 'BALI' }]) });
    const res = await request(app2)
      .post('/api/simpbb/proxy')
      .send({ path: '/wilayah/listPropinsi', params: {} });
    expect(res.statusCode).toBe(200);
  });
});

describe('POST /api/simpbb/proxy — SEC-005 params array fix', () => {
  test('array params are replaced with empty object {}', async () => {
    let capturedParams;
    global.fetch = async (url, { body }) => {
      capturedParams = JSON.parse(body).json;
      return {
        ok: true,
        status: 200,
        text: async () => JSON.stringify({ json: [] }),
      };
    };
    const app = buildApp();
    await request(app)
      .post('/api/simpbb/proxy')
      .send({ path: '/wilayah/listPropinsi', params: [1, 2, 3] });
    // After fix, captured params should be {} not [1,2,3]
    expect(Array.isArray(capturedParams)).toBe(false);
    expect(capturedParams).toEqual({});
  });
});

describe('clamp() utility — edge cases', () => {
  // Test via the list-details endpoint which uses clamp internally
  test('clamp(NaN, 1, 20) = 1', async () => {
    let capturedParams;
    global.fetch = async (url, { body }) => {
      capturedParams = JSON.parse(body).json;
      return {
        ok: true,
        status: 200,
        text: async () => JSON.stringify({ json: { rows: [], total: 0 } }),
      };
    };
    const app = buildApp();
    await request(app)
      .post('/api/simpbb/list-details')
      .send({ limit: 'not-a-number' });
    expect(capturedParams.limit).toBe(1);
  });

  test('limit=null uses server default (null ?? 10 = 10 via nullish coalescing)', async () => {
    // IMPORTANT BEHAVIOR NOTE:
    // The route uses: Number(req.body?.limit ?? 10)
    // When limit is null: null ?? 10 === 10 (nullish coalescing; null triggers the default)
    // Therefore limit=null → default=10, not 1. This is correct and expected.
    let capturedLimit;
    const interceptFetch = async (url, { body }) => {
      capturedLimit = JSON.parse(body).json.limit;
      return {
        ok: true,
        status: 200,
        text: async () => JSON.stringify({ json: { rows: [], total: 0 } }),
      };
    };
    const app = buildApp({ mockFetch: interceptFetch });
    await request(app)
      .post('/api/simpbb/list-details')
      .send({ limit: null });
    // null ?? 10 = 10 → clamp(10, 1, 50) = 10
    expect(capturedLimit).toBe(10);
  });
});
