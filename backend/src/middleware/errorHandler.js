class AppError extends Error {
  constructor(message, statusCode = 400) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
  }
}

function notFoundHandler(req, res, next) {
  next(new AppError(`Route not found: ${req.method} ${req.originalUrl}`, 404));
}

function errorHandler(err, req, res, next) { // eslint-disable-line no-unused-vars
  const statusCode = err.statusCode || 500;
  const payload = {
    success: false,
    message: err.isOperational ? err.message : 'Internal server error',
  };
  if (process.env.NODE_ENV !== 'production' && !err.isOperational) {
    payload.stack = err.stack;
  }
  if (statusCode >= 500) {
    console.error(err);
  }
  res.status(statusCode).json(payload);
}

module.exports = { AppError, notFoundHandler, errorHandler };
