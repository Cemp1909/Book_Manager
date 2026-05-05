import cors from 'cors';
import express from 'express';
import morgan from 'morgan';
import { buildHealthRoutes } from './routes/healthRoutes.js';
import { buildResourceRoutes } from './routes/resourceRoutes.js';

export function buildApp() {
  const app = express();

  app.use(cors());
  app.use(express.json({ limit: '10mb' }));
  app.use(morgan('dev'));

  app.use('/health', buildHealthRoutes());
  app.use('/api/v1', buildResourceRoutes());

  app.use((req, res) => {
    res.status(404).json({
      ok: false,
      message: 'Ruta no encontrada.',
    });
  });

  app.use((error, req, res, next) => {
    const status = error.status || 500;
    const isProduction = process.env.NODE_ENV === 'production';

    res.status(status).json({
      ok: false,
      message: status === 500 && isProduction
        ? 'Error interno del servidor.'
        : error.message,
    });
  });

  return app;
}
