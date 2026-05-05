import { Router } from 'express';
import { createCrudController } from '../controllers/crudController.js';
import { tableSchemas } from '../config/tables.js';
import { asyncHandler } from '../utils/http.js';

const routeMap = [
  ['ciudades', tableSchemas.ciudades],
  ['colegios', tableSchemas.colegios],
  ['roles', tableSchemas.roles],
  ['usuarios', tableSchemas.usuarios],
  ['usuario-rol', tableSchemas.usuarioRol],
  ['bodegas', tableSchemas.bodegas],
  ['libros', tableSchemas.libros],
  ['combos', tableSchemas.combos],
  ['combo-detalle', tableSchemas.comboDetalle],
  ['precio-libro-colegio-anio', tableSchemas.precioLibroColegioAnio],
  ['precio-combo-colegio-anio', tableSchemas.precioComboColegioAnio],
  ['pedidos', tableSchemas.pedidos],
  ['pedido-detalle', tableSchemas.pedidoDetalle],
  ['movimiento-inventario', tableSchemas.movimientoInventario],
  ['movimiento-detalle', tableSchemas.movimientoDetalle],
  ['log-escaneos', tableSchemas.logEscaneos],
  ['despachos', tableSchemas.despachos],
  ['despacho-detalle', tableSchemas.despachoDetalle],
  ['remisiones', tableSchemas.remisiones],
  ['devoluciones', tableSchemas.devoluciones],
  ['devolucion-detalle', tableSchemas.devolucionDetalle],
  ['historial-actividad', tableSchemas.historialActividad],
];

export function buildResourceRoutes() {
  const router = Router();

  for (const [path, schema] of routeMap) {
    const controller = createCrudController(schema);
    const resource = Router();

    resource.get('/', asyncHandler(controller.list));
    resource.get('/:id', asyncHandler(controller.getById));
    resource.post('/', asyncHandler(controller.create));
    resource.put('/:id', asyncHandler(controller.update));
    resource.delete('/:id', asyncHandler(controller.remove));

    router.use(`/${path}`, resource);
  }

  return router;
}
