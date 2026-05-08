import { Router } from 'express';
import { isMailConfigured } from '../config/mailConfig.js';
import { sendVerificationCodeEmail } from '../services/mailService.js';
import { asyncHandler, HttpError } from '../utils/http.js';

export function buildAuthRoutes() {
  const router = Router();

  router.post(
    '/send-verification-code',
    asyncHandler(async (req, res) => {
      const email = req.body?.email?.trim();
      const code = req.body?.code?.trim();

      if (!isValidEmail(email)) {
        throw new HttpError(400, 'Correo invalido.');
      }

      if (!/^[0-9]{6}$/.test(code ?? '')) {
        throw new HttpError(400, 'Codigo invalido.');
      }

      if (!isMailConfigured()) {
        throw new HttpError(
          503,
          'Correo no configurado. Revisa SMTP_HOST, SMTP_PORT, SMTP_USER y SMTP_PASSWORD.',
        );
      }

      await sendVerificationCodeEmail({ to: email, code });

      res.json({ ok: true });
    }),
  );

  return router;
}

function isValidEmail(value) {
  return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(value ?? '');
}
