import { Router } from 'express';
import { isOracleConfigured } from '../config/oracleConfig.js';
import { testOracleConnection } from '../db/oracle.js';
import { asyncHandler, HttpError } from '../utils/http.js';

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
      if (!isOracleConfigured()) {
        throw new HttpError(
          503,
          'Oracle no esta configurado. Revisa ORACLE_USER, ORACLE_PASSWORD y ORACLE_CONNECT_STRING.',
        );
      }

      const database = await testOracleConnection();

      res.json({
        ok: true,
        database,
      });
    }),
  );

  return router;
}
