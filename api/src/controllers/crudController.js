import oracledb from 'oracledb';
import { withConnection } from '../db/oracle.js';
import { HttpError, sendCreated } from '../utils/http.js';

const maxLimit = 200;

export function createCrudController(schema) {
  return {
    list: async (req, res) => {
      const limit = Math.min(Number(req.query.limit) || 50, maxLimit);
      const offset = Number(req.query.offset) || 0;

      const rows = await withConnection(async (connection) => {
        const result = await connection.execute(
          `
          SELECT *
          FROM ${schema.table}
          ORDER BY ${schema.id} DESC
          OFFSET :offset ROWS FETCH NEXT :limit ROWS ONLY
          `,
          { offset, limit },
        );
        return result.rows;
      });

      res.json({ ok: true, data: rows });
    },

    getById: async (req, res) => {
      const id = Number(req.params.id);
      if (!Number.isInteger(id)) throw new HttpError(400, 'Id invalido.');

      const row = await withConnection(async (connection) => {
        const result = await connection.execute(
          `SELECT * FROM ${schema.table} WHERE ${schema.id} = :id`,
          { id },
        );
        return result.rows[0];
      });

      if (!row) throw new HttpError(404, 'Registro no encontrado.');
      res.json({ ok: true, data: row });
    },

    create: async (req, res) => {
      const data = pickAllowedColumns(req.body, schema.columns);
      if (Object.keys(data).length === 0) {
        throw new HttpError(400, 'No hay campos validos para guardar.');
      }

      const columns = Object.keys(data);
      const bindNames = columns.map((column) => `:${column}`);
      const returningBind = 'new_id';

      const id = await withConnection(async (connection) => {
        const result = await connection.execute(
          `
          INSERT INTO ${schema.table} (${columns.join(', ')})
          VALUES (${bindNames.join(', ')})
          RETURNING ${schema.id} INTO :${returningBind}
          `,
          {
            ...data,
            [returningBind]: {
              dir: oracledb.BIND_OUT,
              type: oracledb.NUMBER,
            },
          },
        );
        await connection.commit();
        return result.outBinds[returningBind][0];
      });

      sendCreated(res, id, data);
    },

    update: async (req, res) => {
      const id = Number(req.params.id);
      if (!Number.isInteger(id)) throw new HttpError(400, 'Id invalido.');

      const data = pickAllowedColumns(req.body, schema.columns);
      if (Object.keys(data).length === 0) {
        throw new HttpError(400, 'No hay campos validos para actualizar.');
      }

      const assignments = Object.keys(data).map((column) => `${column} = :${column}`);

      const rowsAffected = await withConnection(async (connection) => {
        const result = await connection.execute(
          `
          UPDATE ${schema.table}
          SET ${assignments.join(', ')}
          WHERE ${schema.id} = :id
          `,
          { ...data, id },
        );
        await connection.commit();
        return result.rowsAffected ?? 0;
      });

      if (rowsAffected === 0) throw new HttpError(404, 'Registro no encontrado.');
      res.json({ ok: true, id, data });
    },

    remove: async (req, res) => {
      const id = Number(req.params.id);
      if (!Number.isInteger(id)) throw new HttpError(400, 'Id invalido.');

      const rowsAffected = await withConnection(async (connection) => {
        const result = await connection.execute(
          `DELETE FROM ${schema.table} WHERE ${schema.id} = :id`,
          { id },
        );
        await connection.commit();
        return result.rowsAffected ?? 0;
      });

      if (rowsAffected === 0) throw new HttpError(404, 'Registro no encontrado.');
      res.json({ ok: true, id });
    },
  };
}

function pickAllowedColumns(source, allowedColumns) {
  const data = {};
  for (const column of allowedColumns) {
    if (Object.hasOwn(source, column)) {
      data[column] = normalizeValue(source[column]);
    }
  }
  return data;
}

function normalizeValue(value) {
  if (value === '') return null;
  return value;
}
