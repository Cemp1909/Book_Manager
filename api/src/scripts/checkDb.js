import 'dotenv/config';
import { closeOraclePool, testOracleConnection } from '../db/oracle.js';

async function main() {
  const database = await testOracleConnection();
  console.log('Conexion Oracle OK:', database);
}

main()
  .catch((error) => {
    console.error('Conexion Oracle fallida:', error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await closeOraclePool();
  });
