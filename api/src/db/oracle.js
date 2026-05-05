import oracledb from 'oracledb';

oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
oracledb.autoCommit = false;

let pool;

export async function initOraclePool() {
  if (pool) return pool;

  const requiredEnv = ['ORACLE_USER', 'ORACLE_PASSWORD', 'ORACLE_CONNECT_STRING'];
  const missing = requiredEnv.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(`Faltan variables Oracle: ${missing.join(', ')}`);
  }

  pool = await oracledb.createPool({
    user: process.env.ORACLE_USER,
    password: process.env.ORACLE_PASSWORD,
    connectString: process.env.ORACLE_CONNECT_STRING,
    poolMin: 1,
    poolMax: 8,
    poolIncrement: 1,
  });

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
