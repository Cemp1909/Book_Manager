import nodemailer from 'nodemailer';
import { getMailConfig } from '../config/mailConfig.js';

let transporter;

export async function sendVerificationCodeEmail({ to, code }) {
  const config = getMailConfig();
  const activeTransporter = getTransporter(config);

  await activeTransporter.sendMail({
    from: config.from,
    to,
    subject: 'Codigo de verificacion - Book Manager',
    text: buildTextMessage(code),
    html: buildHtmlMessage(code),
  });
}

function getTransporter(config) {
  if (transporter) return transporter;

  transporter = nodemailer.createTransport({
    host: config.host,
    port: config.port,
    secure: config.secure,
    auth: config.auth,
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 15000,
  });

  return transporter;
}

function buildTextMessage(code) {
  return [
    'Tu codigo de verificacion para Book Manager es:',
    '',
    code,
    '',
    'Si no solicitaste este codigo, puedes ignorar este correo.',
  ].join('\n');
}

function buildHtmlMessage(code) {
  return `
    <div style="font-family: Arial, sans-serif; color: #17202a; line-height: 1.5;">
      <h2>Codigo de verificacion</h2>
      <p>Tu codigo para Book Manager es:</p>
      <p style="font-size: 28px; font-weight: 800; letter-spacing: 4px;">${code}</p>
      <p>Si no solicitaste este codigo, puedes ignorar este correo.</p>
    </div>
  `;
}
