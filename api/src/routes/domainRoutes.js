import oracledb from 'oracledb';
import { Router } from 'express';
import { withConnection } from '../db/oracle.js';
import { asyncHandler, HttpError } from '../utils/http.js';

export function buildDomainRoutes() {
  const router = Router();

  router.post(
    '/orders',
    asyncHandler(async (req, res) => {
      const order = req.body ?? {};
      const items = Array.isArray(order.items) ? order.items : [];
      if (items.length === 0) throw new HttpError(400, 'El pedido no tiene detalle.');

      const id = await withConnection((connection) =>
        executeWrite(connection, async () => {
          const orderId = await insertReturningId(
            connection,
            `
            INSERT INTO pedidos (fecha, id_colegio, id_usuario, total, estado)
            VALUES (CURRENT_TIMESTAMP, :schoolId, :userId, :total, :status)
            RETURNING id_pedido INTO :newId
            `,
            {
              schoolId: integerOrNull(order.schoolId),
              userId: integerOrNull(order.userId),
              total: integerOrZero(order.total),
              status: textOrDefault(order.status, 'Pendiente'),
            },
          );

          for (const item of items) {
            await connection.execute(
              `
              INSERT INTO pedido_detalle (
                id_pedido,
                tipo_producto,
                id_libro,
                id_combo,
                cantidad,
                precio_unitario,
                subtotal
              )
              VALUES (
                :orderId,
                :productType,
                :bookId,
                :comboId,
                :quantity,
                :unitPrice,
                :subtotal
              )
              `,
              {
                orderId,
                productType: textOrDefault(item.productType, 'libro'),
                bookId: integerOrNull(item.bookId),
                comboId: integerOrNull(item.comboId),
                quantity: integerOrZero(item.quantity),
                unitPrice: integerOrZero(item.unitPrice),
                subtotal: integerOrZero(item.subtotal),
              },
            );
          }

          return orderId;
        }),
      );

      res.status(201).json({ ok: true, id });
    }),
  );

  router.post(
    '/book-prices',
    asyncHandler(async (req, res) => {
      const price = req.body ?? {};
      await withConnection((connection) =>
        executeWrite(connection, async () => {
          await connection.execute(
            `
            MERGE INTO precio_libro_colegio_anio target
            USING (
              SELECT
                :bookId AS id_libro,
                :schoolId AS id_colegio,
                :year AS anio,
                :price AS precio
              FROM dual
            ) source
            ON (
              target.id_libro = source.id_libro
              AND target.id_colegio = source.id_colegio
              AND target.anio = source.anio
            )
            WHEN MATCHED THEN UPDATE SET target.precio = source.precio
            WHEN NOT MATCHED THEN INSERT (id_libro, id_colegio, anio, precio)
              VALUES (source.id_libro, source.id_colegio, source.anio, source.precio)
            `,
            {
              bookId: integerOrNull(price.id_libro ?? price.bookId),
              schoolId: integerOrNull(price.id_colegio ?? price.schoolId),
              year: integerOrZero(price.anio ?? price.year),
              price: integerOrZero(price.precio ?? price.price),
            },
          );
        }),
      );

      res.status(201).json({ ok: true });
    }),
  );

  router.put(
    '/orders/:id/status',
    asyncHandler(async (req, res) => {
      const orderId = integerOrNull(req.params.id);
      if (orderId == null) throw new HttpError(400, 'Id de pedido invalido.');

      await withConnection((connection) =>
        executeWrite(connection, async () => {
          const result = await connection.execute(
            `
            UPDATE pedidos
            SET estado = :status
            WHERE id_pedido = :orderId
            `,
            {
              orderId,
              status: textOrDefault(req.body?.status, 'Pendiente'),
            },
          );
          if ((result.rowsAffected ?? 0) === 0) {
            throw new HttpError(404, 'Pedido no encontrado.');
          }
        }),
      );

      res.json({ ok: true, id: orderId });
    }),
  );

  router.post(
    '/dispatches',
    asyncHandler(async (req, res) => {
      const dispatch = req.body ?? {};
      const orderId = integerOrNull(dispatch.orderId);
      const details = Array.isArray(dispatch.details) ? dispatch.details : [];
      if (orderId == null) throw new HttpError(400, 'Id de pedido invalido.');
      if (details.length === 0) {
        throw new HttpError(400, 'El despacho no tiene detalle.');
      }

      const id = await withConnection((connection) =>
        executeWrite(connection, async () => {
          let dispatchId = await dispatchIdForOrder(connection, orderId);
          if (dispatchId == null) {
            dispatchId = await insertDispatch(connection, {
              orderId,
              userId: integerOrNull(dispatch.userId),
              status: textOrDefault(dispatch.status, 'Despachado'),
              remissionNumber: textOrNull(dispatch.remissionNumber),
              observation: textOrNull(dispatch.observation),
            });
          } else {
            await connection.execute(
              `
              UPDATE despachos
              SET fecha = CURRENT_TIMESTAMP,
                  id_usuario = :userId,
                  estado = :status,
                  numero_remision = COALESCE(:remissionNumber, numero_remision),
                  observacion = :observation
              WHERE id_despacho = :dispatchId
              `,
              {
                dispatchId,
                userId: integerOrNull(dispatch.userId),
                status: textOrDefault(dispatch.status, 'Despachado'),
                remissionNumber: textOrNull(dispatch.remissionNumber),
                observation: textOrNull(dispatch.observation),
              },
            );
            await connection.execute(
              `DELETE FROM despacho_detalle WHERE id_despacho = :dispatchId`,
              { dispatchId },
            );
          }

          for (const detail of details) {
            const bookId = integerOrNull(detail.bookId);
            const quantity = integerOrZero(detail.quantity);
            await connection.execute(
              `
              INSERT INTO despacho_detalle (id_despacho, id_libro, cantidad)
              VALUES (:dispatchId, :bookId, :quantity)
              `,
              {
                dispatchId,
                bookId,
                quantity,
              },
            );

            const stockResult = await connection.execute(
              `
              UPDATE libros
              SET stock = stock - :quantity
              WHERE id_libro = :bookId
                AND stock >= :quantity
              `,
              { bookId, quantity },
            );
            if ((stockResult.rowsAffected ?? 0) === 0) {
              throw new HttpError(
                400,
                `Stock insuficiente para el libro ${bookId}.`,
              );
            }
          }

          const movement = dispatch.movement;
          if (movement) {
            await insertInventoryMovement(connection, movement);
          }

          await connection.execute(
            `
            UPDATE pedidos
            SET estado = :status
            WHERE id_pedido = :orderId
            `,
            { orderId, status: 'Despachado' },
          );

          return dispatchId;
        }),
      );

      res.status(201).json({ ok: true, id });
    }),
  );

  router.post(
    '/remissions',
    asyncHandler(async (req, res) => {
      const remission = req.body ?? {};
      const id = await withConnection((connection) =>
        executeWrite(connection, async () => {
          const orderId = integerOrNull(remission.orderId);
          let dispatchId = integerOrNull(remission.dispatchId);
          if (dispatchId == null && orderId != null) {
            dispatchId = await dispatchIdForOrder(connection, orderId);
            if (dispatchId == null) {
              dispatchId = await insertDispatch(connection, {
                orderId,
                userId: integerOrNull(remission.userId),
                status: 'Remision generada',
                remissionNumber: textOrDefault(
                  remission.number,
                  `REM-${orderId}`,
                ),
                observation: 'Remision generada antes del despacho',
              });
            }
          }

          if (dispatchId == null) {
            throw new HttpError(400, 'La remision requiere pedido o despacho.');
          }

          const existingRemissionId = await remissionIdForDispatch(
            connection,
            dispatchId,
          );
          if (existingRemissionId != null) {
            await connection.execute(
              `
              UPDATE remisiones
              SET numero = :remissionNumber,
                  fecha_generacion = CURRENT_TIMESTAMP,
                  id_usuario = :userId,
                  archivo_pdf = COALESCE(:pdfFile, archivo_pdf),
                  estado = :remissionStatus
              WHERE id_remision = :remissionId
              `,
              {
                remissionId: existingRemissionId,
                remissionNumber: textOrDefault(
                  remission.number,
                  `REM-${Date.now()}`,
                ),
                userId: integerOrNull(remission.userId),
                pdfFile: textOrDefault(remission.file, 'sin_archivo_pdf'),
                remissionStatus: textOrDefault(remission.status, 'Generada'),
              },
            );
            return existingRemissionId;
          }

          return insertReturningId(
            connection,
            `
            INSERT INTO remisiones (
              id_despacho,
              numero,
              fecha_generacion,
              id_usuario,
              archivo_pdf,
              estado
            )
            VALUES (
              :dispatchId,
              :remissionNumber,
              CURRENT_TIMESTAMP,
              :userId,
              :pdfFile,
              :remissionStatus
            )
            RETURNING id_remision INTO :newId
            `,
            {
              dispatchId,
              remissionNumber: textOrDefault(
                remission.number,
                `REM-${Date.now()}`,
              ),
              userId: integerOrNull(remission.userId),
              pdfFile: textOrDefault(remission.file, 'sin_archivo_pdf'),
              remissionStatus: textOrDefault(remission.status, 'Generada'),
            },
          );
        }),
      );

      res.status(201).json({ ok: true, id });
    }),
  );

  router.put(
    '/combos/:id',
    asyncHandler(async (req, res) => {
      const comboId = integerOrNull(req.params.id);
      if (comboId == null) throw new HttpError(400, 'Id de combo invalido.');
      const combo = req.body ?? {};
      const bookIds = Array.isArray(combo.bookIds) ? combo.bookIds : [];

      await withConnection((connection) =>
        executeWrite(connection, async () => {
          const result = await connection.execute(
            `
            UPDATE combos
            SET nombre = :name,
                descripcion = :description
            WHERE id_combo = :comboId
            `,
            {
              comboId,
              name: textOrDefault(combo.name, 'Combo'),
              description: textOrNull(combo.description),
            },
          );
          if ((result.rowsAffected ?? 0) === 0) {
            throw new HttpError(404, 'Combo no encontrado.');
          }

          await connection.execute(
            `DELETE FROM combo_detalle WHERE id_combo = :comboId`,
            { comboId },
          );

          for (const bookIdValue of bookIds) {
            await connection.execute(
              `
              INSERT INTO combo_detalle (id_combo, id_libro, cantidad)
              VALUES (:comboId, :bookId, 1)
              `,
              { comboId, bookId: integerOrNull(bookIdValue) },
            );
          }

          const schoolId = integerOrNull(combo.schoolId);
          const price = integerOrNull(combo.price);
          if (schoolId != null && price != null) {
            await connection.execute(
              `
              MERGE INTO precio_combo_colegio_anio target
              USING (
                SELECT
                  :comboId AS id_combo,
                  :schoolId AS id_colegio,
                  :year AS anio,
                  :price AS precio
                FROM dual
              ) source
              ON (
                target.id_combo = source.id_combo
                AND target.id_colegio = source.id_colegio
                AND target.anio = source.anio
              )
              WHEN MATCHED THEN UPDATE SET target.precio = source.precio
              WHEN NOT MATCHED THEN INSERT (id_combo, id_colegio, anio, precio)
                VALUES (source.id_combo, source.id_colegio, source.anio, source.precio)
              `,
              {
                comboId,
                schoolId,
                year: integerOrZero(combo.year),
                price,
              },
            );
          }
        }),
      );

      res.json({ ok: true, id: comboId });
    }),
  );

  router.post(
    '/returns',
    asyncHandler(async (req, res) => {
      const record = req.body ?? {};
      const details = Array.isArray(record.details) ? record.details : [];
      if (details.length === 0) throw new HttpError(400, 'La devolucion no tiene detalle.');

      const id = await withConnection((connection) =>
        executeWrite(connection, async () => {
          const returnId = await insertReturningId(
            connection,
            `
            INSERT INTO devoluciones (
              fecha,
              id_pedido,
              id_despacho,
              id_usuario,
              motivo,
              reintegrar_inventario,
              estado
            )
            VALUES (
              CURRENT_TIMESTAMP,
              :orderId,
              :dispatchId,
              :userId,
              :reason,
              :restock,
              :status
            )
            RETURNING id_devolucion INTO :newId
            `,
            {
              orderId: integerOrNull(record.orderId),
              dispatchId: integerOrNull(record.dispatchId),
              userId: integerOrNull(record.userId),
              reason: textOrNull(record.reason),
              restock: record.restock ? 1 : 0,
              status: textOrDefault(record.status, 'Registrada'),
            },
          );

          for (const detail of details) {
            await connection.execute(
              `
              INSERT INTO devolucion_detalle (
                id_devolucion,
                id_libro,
                id_combo,
                cantidad,
                estado_libro,
                observacion
              )
              VALUES (
                :returnId,
                :bookId,
                :comboId,
                :quantity,
                :bookStatus,
                :observation
              )
              `,
              {
                returnId,
                bookId: integerOrNull(detail.bookId),
                comboId: integerOrNull(detail.comboId),
                quantity: integerOrZero(detail.quantity),
                bookStatus: textOrDefault(detail.bookStatus, 'Devuelto'),
                observation: textOrNull(detail.observation),
              },
            );
          }

          const movement = record.movement;
          if (movement) {
            await insertInventoryMovement(connection, movement);
          }

          return returnId;
        }),
      );

      res.status(201).json({ ok: true, id });
    }),
  );

  router.post(
    '/inventory-movements',
    asyncHandler(async (req, res) => {
      const id = await withConnection((connection) =>
        executeWrite(connection, () => insertInventoryMovement(connection, req.body ?? {})),
      );
      res.status(201).json({ ok: true, id });
    }),
  );

  return router;
}

async function dispatchIdForOrder(connection, orderId) {
  const result = await connection.execute(
    `
    SELECT id_despacho
    FROM despachos
    WHERE id_pedido = :orderId
    ORDER BY id_despacho DESC
    FETCH FIRST 1 ROW ONLY
    `,
    { orderId },
  );
  return result.rows[0]?.ID_DESPACHO ?? null;
}

async function remissionIdForDispatch(connection, dispatchId) {
  const result = await connection.execute(
    `
    SELECT id_remision
    FROM remisiones
    WHERE id_despacho = :dispatchId
    ORDER BY id_remision DESC
    FETCH FIRST 1 ROW ONLY
    `,
    { dispatchId },
  );
  return result.rows[0]?.ID_REMISION ?? null;
}

async function insertDispatch(connection, dispatch) {
  return insertReturningId(
    connection,
    `
    INSERT INTO despachos (
      fecha,
      id_pedido,
      id_usuario,
      estado,
      numero_remision,
      observacion
    )
    VALUES (
      CURRENT_TIMESTAMP,
      :orderId,
      :userId,
      :status,
      :remissionNumber,
      :observation
    )
    RETURNING id_despacho INTO :newId
    `,
    dispatch,
  );
}

async function insertInventoryMovement(connection, movement) {
  const details = Array.isArray(movement.details) ? movement.details : [];
  if (details.length === 0) {
    throw new HttpError(400, 'El movimiento no tiene detalle.');
  }

  const movementId = await insertReturningId(
    connection,
    `
    INSERT INTO movimiento_inventario (
      fecha,
      tipo_movimiento,
      id_bodega,
      id_usuario,
      total,
      observacion
    )
    VALUES (
      CURRENT_TIMESTAMP,
      :movementType,
      :warehouseId,
      :userId,
      :total,
      :observation
    )
    RETURNING id_movimiento INTO :newId
    `,
    {
      movementType: textOrDefault(movement.movementType, 'salida'),
      warehouseId: integerOrNull(movement.warehouseId),
      userId: integerOrNull(movement.userId),
      total: integerOrZero(movement.total),
      observation: textOrNull(movement.observation),
    },
  );

  for (const detail of details) {
    await connection.execute(
      `
      INSERT INTO movimiento_detalle (id_movimiento, id_libro, cantidad)
      VALUES (:movementId, :bookId, :quantity)
      `,
      {
        movementId,
        bookId: integerOrNull(detail.bookId),
        quantity: integerOrZero(detail.quantity),
      },
    );
  }

  return movementId;
}

async function insertReturningId(connection, sql, binds) {
  const result = await connection.execute(sql, {
    ...binds,
    newId: {
      dir: oracledb.BIND_OUT,
      type: oracledb.NUMBER,
    },
  });
  return result.outBinds.newId[0];
}

async function executeWrite(connection, action) {
  try {
    const result = await action();
    await connection.commit();
    return result;
  } catch (error) {
    await connection.rollback();
    throw error;
  }
}

function integerOrNull(value) {
  if (value == null || value === '') return null;
  const parsed = Number(value);
  if (!Number.isInteger(parsed)) return null;
  return parsed;
}

function integerOrZero(value) {
  return integerOrNull(value) ?? 0;
}

function textOrNull(value) {
  if (value == null) return null;
  const text = value.toString().trim();
  return text.length === 0 ? null : text;
}

function textOrDefault(value, fallback) {
  return textOrNull(value) ?? fallback;
}
