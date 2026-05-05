import 'dotenv/config';
import { buildApp } from './app.js';
import { closeOraclePool, initOraclePool } from './db/oracle.js';

const port = Number(process.env.PORT) || 3000;
const app = buildApp();

async function start() {
  if (process.env.ORACLE_CONNECT_STRING) {
    await initOraclePool();
    console.log('Oracle pool inicializado.');
  } else {
    console.warn('Oracle no configurado. Copia .env.example a .env cuando tengas la base.');
  }

  app.listen(port, () => {
    console.log(`Book Manager API escuchando en http://localhost:${port}`);
  });
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

async function shutdown() {
  await closeOraclePool();
  process.exit(0);
}

start().catch((error) => {
  console.error('No se pudo iniciar la API:', error);
  process.exit(1);
});
