function errorHandler(err, req, res, next) {
  console.error('Unhandled error:', err);

  // Multer file size / type errors
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ success: false, error: 'File too large. Maximum size is 10 MB.' });
  }
  if (err.code === 'LIMIT_UNEXPECTED_FILE') {
    return res.status(400).json({ success: false, error: 'Unexpected file field.' });
  }

  // PostgreSQL unique violation
  if (err.code === '23505') {
    const detail = err.detail || '';
    if (detail.includes('username')) {
      return res.status(409).json({ success: false, error: 'Username is already taken.' });
    }
    if (detail.includes('email')) {
      return res.status(409).json({ success: false, error: 'Email is already registered.' });
    }
    return res.status(409).json({ success: false, error: 'Duplicate entry.' });
  }

  // PostgreSQL foreign key violation
  if (err.code === '23503') {
    return res.status(400).json({ success: false, error: 'Referenced resource does not exist.' });
  }

  const status = err.status || err.statusCode || 500;
  const message = (status < 500 ? err.message : null) || 'Internal server error';
  return res.status(status).json({ success: false, error: message });
}

module.exports = { errorHandler };
