import { execFileSync } from 'node:child_process';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { mkdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const walletArchive = process.env.ORACLE_WALLET_TGZ_BASE64;

if (!walletArchive) {
  process.exit(0);
}

const walletDir = resolve(process.env.TNS_ADMIN || 'wallet');
const tempDir = mkdtempSync(join(tmpdir(), 'book-manager-wallet-'));
const archivePath = join(tempDir, 'wallet.tgz');

try {
  await mkdir(walletDir, { recursive: true });
  writeFileSync(archivePath, Buffer.from(walletArchive, 'base64'));
  execFileSync('tar', ['-xzf', archivePath, '-C', walletDir], {
    stdio: 'inherit',
  });
  console.log(`Oracle wallet preparado en ${walletDir}.`);
} finally {
  rmSync(tempDir, { force: true, recursive: true });
}
