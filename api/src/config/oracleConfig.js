const defaultPoolMin = 1;
const defaultPoolMax = 8;
const defaultPoolIncrement = 1;
const defaultQueueTimeout = 120000;

export function isOracleConfigured(env = process.env) {
  return requiredOracleEnvKeys.every((key) => Boolean(env[key]));
}

export function getOracleConfig(env = process.env) {
  const missing = requiredOracleEnvKeys.filter((key) => !env[key]);
  if (missing.length > 0) {
    throw new Error(`Faltan variables Oracle: ${missing.join(', ')}`);
  }

  const config = {
    user: env.ORACLE_USER,
    password: env.ORACLE_PASSWORD,
    connectString: env.ORACLE_CONNECT_STRING,
    poolMin: parsePoolNumber(env.ORACLE_POOL_MIN, defaultPoolMin),
    poolMax: parsePoolNumber(env.ORACLE_POOL_MAX, defaultPoolMax),
    poolIncrement: parsePoolNumber(
      env.ORACLE_POOL_INCREMENT,
      defaultPoolIncrement,
    ),
    queueTimeout: parsePoolNumber(env.ORACLE_QUEUE_TIMEOUT, defaultQueueTimeout),
  };

  if (env.TNS_ADMIN) {
    config.configDir = env.TNS_ADMIN;
    config.walletLocation = env.TNS_ADMIN;
  }

  if (env.ORACLE_WALLET_PASSWORD) {
    config.walletPassword = env.ORACLE_WALLET_PASSWORD;
  }

  return config;
}

export const requiredOracleEnvKeys = [
  'ORACLE_USER',
  'ORACLE_PASSWORD',
  'ORACLE_CONNECT_STRING',
];

function parsePoolNumber(value, fallback) {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 0) return fallback;
  return parsed;
}
