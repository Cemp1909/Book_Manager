export function isMailConfigured(env = process.env) {
  return requiredMailEnvKeys.every((key) => isRealValue(key, env[key]));
}

export function getMailConfig(env = process.env) {
  const missing = requiredMailEnvKeys.filter((key) => !isRealValue(key, env[key]));
  if (missing.length > 0) {
    throw new Error(`Faltan variables SMTP: ${missing.join(', ')}`);
  }

  return {
    host: env.SMTP_HOST,
    port: parsePort(env.SMTP_PORT),
    secure: parseSecure(env.SMTP_SECURE, env.SMTP_PORT),
    auth: {
      user: env.SMTP_USER,
      pass: env.SMTP_PASSWORD,
    },
    from: env.SMTP_FROM || env.SMTP_USER,
  };
}

export const requiredMailEnvKeys = [
  'SMTP_HOST',
  'SMTP_PORT',
  'SMTP_USER',
  'SMTP_PASSWORD',
];

function parsePort(value) {
  const port = Number(value);
  if (!Number.isInteger(port) || port <= 0) return 587;
  return port;
}

function parseSecure(value, port) {
  if (value === 'true') return true;
  if (value === 'false') return false;
  return Number(port) === 465;
}

function isRealValue(key, value) {
  if (!value) return false;
  const placeholderValues = new Set([
    'smtp.example.com',
    'correo@example.com',
    'change_me',
  ]);
  return !placeholderValues.has(value) && !(key === 'SMTP_PASSWORD' && value.length < 4);
}
