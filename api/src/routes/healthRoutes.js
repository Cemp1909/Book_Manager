import { Router } from 'express';
import { withConnection } from '../db/oracle.js';
import { asyncHandler } from '../utils/http.js';

export function buildHealthRoutes() {
  const router = Router();

  router.get('/', (req, res) => {
    res.json({
      ok: true,
      service: 'book-manager-api',
      status: 'running',
    });
  });

  router.get(
    '/db',
    asyncHandler(async (req, res) => {
      const result = await withConnection(async (connection) => {
        return connection.execute('SELECT 1 AS ok FROM dual');
      });

      res.json({
        ok: true,
        database: result.rows[0],
      });
    }),
  );

  return router;
}
