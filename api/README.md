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
- `historial-actividad`

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

Registrar historial:

```bash
curl -X POST http://localhost:3000/api/v1/historial-actividad \
  -H "Content-Type: application/json" \
  -d '{
    "tipo":"orders",
    "titulo":"Pedido despachado",
    "detalle":"Pedido #1001 fue marcado como despachado.",
    "id_usuario":1,
    "nombre_usuario":"Administrador",
    "rol_usuario":"Administrador",
    "fecha_hora":"2026-05-04T10:30:00",
    "tipo_entidad":"pedido",
    "id_entidad":"1001",
    "nombre_entidad":"Pedido #1001"
  }'
```

## Notas importantes

- La API usa whitelist de tablas y columnas. El cliente no puede enviar nombres de tabla libres.
- Las columnas con string vacio se convierten a `null`, porque Oracle trata `''` como `NULL`.
- Para produccion faltara agregar autenticacion por token/JWT antes de exponer la API publicamente.

## Tabla adicional para historial

Si todavia no la creaste en Oracle, agrega:

```sql
CREATE TABLE historial_actividad (
    id_actividad NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo VARCHAR2(50) NOT NULL,
    titulo VARCHAR2(150) NOT NULL,
    detalle VARCHAR2(1000) NOT NULL,
    id_usuario NUMBER,
    nombre_usuario VARCHAR2(150) NOT NULL,
    rol_usuario VARCHAR2(80) NOT NULL,
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tipo_entidad VARCHAR2(50),
    id_entidad VARCHAR2(100),
    nombre_entidad VARCHAR2(200),
    CONSTRAINT fk_historial_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario)
);

CREATE INDEX idx_historial_tipo ON historial_actividad(tipo);
CREATE INDEX idx_historial_usuario ON historial_actividad(id_usuario);
CREATE INDEX idx_historial_entidad ON historial_actividad(tipo_entidad, id_entidad);
CREATE INDEX idx_historial_fecha ON historial_actividad(fecha_hora);
```
