const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

const USE_S3 =
  process.env.AWS_ACCESS_KEY_ID &&
  process.env.AWS_SECRET_ACCESS_KEY &&
  process.env.AWS_S3_BUCKET;

let s3Client, S3_BUCKET, S3_REGION;

if (USE_S3) {
  try {
    const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
    S3_BUCKET = process.env.AWS_S3_BUCKET;
    S3_REGION = process.env.AWS_REGION || 'us-east-1';
    s3Client = new S3Client({
      region: S3_REGION,
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
      },
    });
    console.log('Storage: S3 enabled');
  } catch (e) {
    console.warn('S3 SDK not available, falling back to local storage:', e.message);
  }
}

const LOCAL_UPLOADS_DIR = path.resolve(process.cwd(), 'uploads');

function ensureUploadsDir() {
  if (!fs.existsSync(LOCAL_UPLOADS_DIR)) {
    fs.mkdirSync(LOCAL_UPLOADS_DIR, { recursive: true });
  }
}

/**
 * Store a file buffer. Returns the public URL.
 * @param {Buffer} buffer
 * @param {string} originalName
 * @param {string} mimeType
 * @param {string} folder - e.g. 'sightings' or 'avatars'
 * @returns {Promise<string>} public URL
 */
async function storeFile(buffer, originalName, mimeType, folder = 'sightings') {
  const ext = path.extname(originalName) || '.jpg';
  const hash = crypto.randomBytes(16).toString('hex');
  const filename = `${folder}/${hash}${ext}`;

  if (USE_S3 && s3Client) {
    const { PutObjectCommand } = require('@aws-sdk/client-s3');
    await s3Client.send(
      new PutObjectCommand({
        Bucket: S3_BUCKET,
        Key: filename,
        Body: buffer,
        ContentType: mimeType,
        ACL: 'public-read',
      })
    );
    return `https://${S3_BUCKET}.s3.${S3_REGION}.amazonaws.com/${filename}`;
  }

  // Local storage fallback
  ensureUploadsDir();
  const folderPath = path.join(LOCAL_UPLOADS_DIR, folder);
  if (!fs.existsSync(folderPath)) {
    fs.mkdirSync(folderPath, { recursive: true });
  }
  const filePath = path.join(LOCAL_UPLOADS_DIR, filename);
  fs.writeFileSync(filePath, buffer);

  const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
  return `${baseUrl}/uploads/${filename}`;
}

/**
 * Delete a file by URL (local only; S3 deletion omitted for MVP).
 */
async function deleteFile(url) {
  if (USE_S3) return; // S3 lifecycle policies handle cleanup
  try {
    const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
    const relativePath = url.replace(`${baseUrl}/uploads/`, '');
    const filePath = path.join(LOCAL_UPLOADS_DIR, relativePath);
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
  } catch (err) {
    console.error('File deletion error:', err.message);
  }
}

module.exports = { storeFile, deleteFile };
