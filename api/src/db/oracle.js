import oracledb from 'oracledb';
import { getOracleConfig } from '../config/oracleConfig.js';

oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
oracledb.autoCommit = false;
oracledb.fetchAsString = [oracledb.CLOB];

let pool;

export async function initOraclePool() {
  if (pool) return pool;

  pool = await oracledb.createPool(getOracleConfig());

  return pool;
}

export async function withConnection(action) {
  const activePool = await initOraclePool();
  const connection = await activePool.getConnection();

  try {
    return await action(connection);
  } finally {
    await connection.close();
  }
}

export async function closeOraclePool() {
  if (!pool) return;
  await pool.close(10);
  pool = undefined;
}

export async function testOracleConnection() {
  return withConnection(async (connection) => {
    const result = await connection.execute(`
      SELECT
        1 AS ok,
        SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS schema,
        SYS_CONTEXT('USERENV', 'SERVICE_NAME') AS service_name
      FROM dual
    `);

    return result.rows[0];
  });
}
