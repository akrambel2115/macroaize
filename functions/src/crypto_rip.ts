import crypto from 'crypto';

export function maskRip(rip: string): string {
  const clean = rip.replace(/\s+/g, '');
  if (clean.length <= 4) return `****${clean}`;
  return clean.slice(0, -4).replace(/./g, '•') + clean.slice(-4);
}

export function encryptRip(plainRip: string, keyB64: string): EncryptedRip {
  if (!plainRip || !keyB64) {
    throw new Error('Missing required parameters for RIP encryption');
  }

  try {
    const key = Buffer.from(keyB64, 'base64');
    if (key.length !== 32) {
      throw new Error('Invalid key length. Expected 32 bytes for AES-256');
    }

    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
    const ciphertext = Buffer.concat([
      cipher.update(plainRip, 'utf8'),
      cipher.final()
    ]);
    const tag = cipher.getAuthTag();

    return {
      version: 1,
      algorithm: 'AES-256-GCM',
      iv: iv.toString('base64'),
      tag: tag.toString('base64'),
      ciphertext: ciphertext.toString('base64'),
      encryptedAt: new Date().toISOString()
    };
  } catch (error) {
    throw new Error(`RIP encryption failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}

export function decryptRip(encryptedData: EncryptedRip, keyB64: string): string {
  if (!encryptedData || !keyB64) {
    throw new Error('Missing required parameters for RIP decryption');
  }

  if (encryptedData.version !== 1 || encryptedData.algorithm !== 'AES-256-GCM') {
    throw new Error(`Unsupported encryption version or algorithm: ${encryptedData.version}/${encryptedData.algorithm}`);
  }

  try {
    const key = Buffer.from(keyB64, 'base64');
    if (key.length !== 32) {
      throw new Error('Invalid key length. Expected 32 bytes for AES-256');
    }

    const iv = Buffer.from(encryptedData.iv, 'base64');
    const tag = Buffer.from(encryptedData.tag, 'base64');
    const ciphertext = Buffer.from(encryptedData.ciphertext, 'base64');

    const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
    decipher.setAuthTag(tag);

    const plaintext = Buffer.concat([
      decipher.update(ciphertext),
      decipher.final()
    ]);

    return plaintext.toString('utf8');
  } catch (error) {
    throw new Error(`RIP decryption failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}

export function isValidRip(rip: string): boolean {
  if (!rip) return false;
  const clean = rip.replace(/\s+/g, '');
  if (!/^\d{20}$/.test(clean)) return false;
  return true;
}

export function generateEncryptionKey(): string {
  return crypto.randomBytes(32).toString('base64');
}

export interface EncryptedRip {
  version: number;
  algorithm: string;
  iv: string;
  tag: string;
  ciphertext: string;
  encryptedAt: string;
}
