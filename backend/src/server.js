import express from 'express';
import cors from 'cors';

const app = express();

const port = Number(process.env.PORT ?? 3000);
const simpbbBaseUrl = process.env.SIMPBB_BASE_URL ?? 'https://simpbb.technosmart.id/api/rpc';

const allowedOrpcPaths = new Set([
  '/wilayah/listPropinsi',
  '/objekPajak/search',
  '/objekPajak/listDetails',
  '/objekPajak/getByNop',
]);

app.use(cors({ origin: true }));
app.use(express.json({ limit: '1mb' }));

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
    const params = req.body?.params && typeof req.body.params === 'object' ? req.body.params : {};

    if (!allowedOrpcPaths.has(path)) {
      return res.status(400).json({ message: 'Endpoint tidak diizinkan.' });
    }

    const result = await postOrpc(path, params);
    res.json({ data: result });
  } catch (error) {
    next(error);
  }
});

app.use((error, req, res, next) => {
  const statusCode = error.statusCode ?? 500;
  res.status(statusCode).json({
    message: error.message ?? 'Internal middleware error',
  });
});

app.listen(port, () => {
  console.log(`IntegraTax middleware listening on http://localhost:${port}`);
});

async function postOrpc(path, params) {
  const response = await fetch(`${simpbbBaseUrl}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify({ json: params }),
  });

  const text = await response.text();
  let decoded;
  try {
    decoded = text ? JSON.parse(text) : {};
  } catch (error) {
    const malformed = new Error('SIMPBB response bukan JSON valid.');
    malformed.statusCode = 502;
    throw malformed;
  }

  if (!response.ok) {
    const upstream = new Error(decoded?.message ?? decoded?.error ?? 'SIMPBB request gagal.');
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
