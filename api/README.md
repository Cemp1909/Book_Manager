# Book Manager API

REST API para conectar la app Flutter con Oracle Cloud Database.

## Requisitos

- Node.js 20 o superior
- Oracle Database/Autonomous Database en Oracle Cloud
- Credenciales de la base y `connectString`

## Configuracion

```bash
cd api
cp .env.example .env
npm install
```

Edita `.env`:

```env
PORT=3000
ORACLE_USER=BOOK_MANAGER
ORACLE_PASSWORD=tu_clave
ORACLE_CONNECT_STRING=host:1521/service_name
```

Si usas wallet de Autonomous Database, configura tambien:

```env
TNS_ADMIN=/ruta/a/wallet
```

## Ejecutar

```bash
npm run dev
```

Pruebas rapidas:

```bash
curl http://localhost:3000/health
curl http://localhost:3000/health/db
```

## Rutas CRUD

Todas las rutas usan JSON.

Formato:

```txt
GET    /api/v1/<recurso>
GET    /api/v1/<recurso>/<id>
POST   /api/v1/<recurso>
PUT    /api/v1/<recurso>/<id>
DELETE /api/v1/<recurso>/<id>
```

Recursos disponibles:

- `ciudades`
- `colegios`
- `roles`
- `usuarios`
- `usuario-rol`
- `bodegas`
- `libros`
- `combos`
- `combo-detalle`
- `precio-libro-colegio-anio`
- `precio-combo-colegio-anio`
- `pedidos`
- `pedido-detalle`
- `movimiento-inventario`
- `movimiento-detalle`
- `log-escaneos`
- `despachos`
- `despacho-detalle`
- `remisiones`
- `devoluciones`
- `devolucion-detalle`

## Ejemplos

Crear ciudad:

```bash
curl -X POST http://localhost:3000/api/v1/ciudades \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Bogota"}'
```

Crear colegio:

```bash
curl -X POST http://localhost:3000/api/v1/colegios \
  -H "Content-Type: application/json" \
  -d '{
    "nombre":"Colegio Los Alamos",
    "direccion":"Cra. 12 #45-20",
    "telefono":"601 555 1200",
    "id_ciudad":1
  }'
```

Crear libro:

```bash
curl -X POST http://localhost:3000/api/v1/libros \
  -H "Content-Type: application/json" \
  -d '{
    "titulo":"Cien anos de soledad",
    "isbn":"978-84-376-0494-7",
    "grado":"10",
    "area":"Literatura",
    "stock":50,
    "codigo_qr":"978-84-376-0494-7",
    "autor":"Gabriel Garcia Marquez",
    "descripcion":"Lectura principal para plan lector.",
    "precio_base":45000,
    "foto_portada":null
  }'
```

## Notas importantes

- La API usa whitelist de tablas y columnas. El cliente no puede enviar nombres de tabla libres.
- Las columnas con string vacio se convierten a `null`, porque Oracle trata `''` como `NULL`.
- Para produccion faltara agregar autenticacion por token/JWT antes de exponer la API publicamente.
