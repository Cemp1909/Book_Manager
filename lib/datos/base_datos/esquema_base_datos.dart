class DbTables {
  const DbTables._();

  static const ciudades = 'ciudades';
  static const colegios = 'colegios';
  static const roles = 'roles';
  static const usuarios = 'usuarios';
  static const usuarioRol = 'usuario_rol';
  static const bodegas = 'bodegas';
  static const libros = 'libros';
  static const combos = 'combos';
  static const comboDetalle = 'combo_detalle';
  static const precioLibroColegioAnio = 'precio_libro_colegio_anio';
  static const precioComboColegioAnio = 'precio_combo_colegio_anio';
  static const pedidos = 'pedidos';
  static const pedidoDetalle = 'pedido_detalle';
  static const movimientoInventario = 'movimiento_inventario';
  static const movimientoDetalle = 'movimiento_detalle';
  static const logEscaneos = 'log_escaneos';
  static const despachos = 'despachos';
  static const despachoDetalle = 'despacho_detalle';
  static const remisiones = 'remisiones';
  static const devoluciones = 'devoluciones';
  static const devolucionDetalle = 'devolucion_detalle';
}

class DatabaseSchema {
  const DatabaseSchema._();

  static const version = 1;
  static const databaseName = 'book_manager_completa.db';

  static const createStatements = [
    '''
    CREATE TABLE ciudades (
      id_ciudad INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL UNIQUE
    )
    ''',
    '''
    CREATE TABLE colegios (
      id_colegio INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      direccion TEXT NOT NULL,
      telefono TEXT NOT NULL,
      id_ciudad INTEGER NOT NULL,
      FOREIGN KEY (id_ciudad) REFERENCES ciudades (id_ciudad)
        ON UPDATE CASCADE ON DELETE RESTRICT
    )
    ''',
    '''
    CREATE TABLE roles (
      id_rol INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL UNIQUE,
      descripcion TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE usuarios (
      id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      correo TEXT NOT NULL UNIQUE,
      contrasena TEXT NOT NULL,
      estado TEXT NOT NULL DEFAULT 'activo'
    )
    ''',
    '''
    CREATE TABLE usuario_rol (
      id_usuario_rol INTEGER PRIMARY KEY AUTOINCREMENT,
      id_usuario INTEGER NOT NULL,
      id_rol INTEGER NOT NULL,
      UNIQUE (id_usuario, id_rol),
      FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE ON DELETE CASCADE,
      FOREIGN KEY (id_rol) REFERENCES roles (id_rol)
        ON UPDATE CASCADE ON DELETE RESTRICT
    )
    ''',
    '''
    CREATE TABLE bodegas (
      id_bodega INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      ubicacion TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE libros (
      id_libro INTEGER PRIMARY KEY AUTOINCREMENT,
      titulo TEXT NOT NULL,
      isbn TEXT NOT NULL UNIQUE,
      grado TEXT NOT NULL,
      area TEXT NOT NULL,
      stock INTEGER NOT NULL DEFAULT 0,
      codigo_qr TEXT NOT NULL,
      autor TEXT NOT NULL DEFAULT '',
      descripcion TEXT NOT NULL DEFAULT '',
      precio_base INTEGER NOT NULL DEFAULT 0,
      foto_portada TEXT NOT NULL DEFAULT ''
    )
    ''',
    '''
    CREATE TABLE combos (
      id_combo INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      descripcion TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE combo_detalle (
      id_combo_detalle INTEGER PRIMARY KEY AUTOINCREMENT,
      id_combo INTEGER NOT NULL,
      id_libro INTEGER NOT NULL,
      cantidad INTEGER NOT NULL DEFAULT 1,
      UNIQUE (id_combo, id_libro),
      FOREIGN KEY (id_combo) REFERENCES combos (id_combo)
        ON UPDATE CASCADE ON DELETE CASCADE,
      FOREIGN KEY (id_libro) REFERENCES libros (id_libro)
        ON UPDATE CASCADE ON DELETE RESTRICT
    )
    ''',
    '''
    CREATE TABLE precio_libro_colegio_anio (
      id_precio_libro INTEGER PRIMARY KEY AUTOINCREMENT,
      id_libro INTEGER NOT NULL,
      id_colegio INTEGER NOT NULL,
      anio INTEGER NOT NULL,
      precio REAL NOT NULL,
      UNIQUE (id_libro, id_colegio, anio),
      FOREIGN KEY (id_libro) REFERENCES libros (id_libro)
        ON UPDATE CASCADE ON DELETE CASCADE,
      FOREIGN KEY (id_colegio) REFERENCES colegios (id_colegio)
        ON UPDATE CASCADE ON DELETE CASCADE
    )
    ''',
    '''
    CREATE TABLE precio_combo_colegio_anio (
      id_precio_combo INTEGER PRIMARY KEY AUTOINCREMENT,
      id_combo INTEGER NOT NULL,
      id_colegio INTEGER NOT NULL,
      anio INTEGER NOT NULL,
      precio REAL NOT NULL,
      UNIQUE (id_combo, id_colegio, anio),
      FOREIGN KEY (id_combo) REFERENCES combos (id_combo)
        ON UPDATE CASCADE ON DELETE CASCADE,
      FOREIGN KEY (id_colegio) REFERENCES colegios (id_colegio)
        ON UPDATE CASCADE ON DELETE CASCADE
    )
    ''',
    '''
    CREATE TABLE pedidos (
      id_pedido INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT NOT NULL,
      id_colegio INTEGER NOT NULL,
      id_usuario INTEGER NOT NULL,
      total REAL NOT NULL DEFAULT 0,
      estado TEXT NOT NULL,
      FOREIGN KEY (id_colegio) REFERENCES colegios (id_colegio)
        ON UPDATE CASCADE ON DELETE RESTRICT,
      FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
    )
    ''',
    '''
    CREATE TABLE pedido_detalle (
      id_pedido_detalle INTEGER PRIMARY KEY AUTOINCREMENT,
      id_pedido INTEGER NOT NULL,
      tipo_producto TEXT NOT NULL CHECK (tipo_producto IN ('libro', 'combo')),
      id_libro INTEGER,
      id_combo INTEGER,
      cantidad INTEGER NOT NULL,
      precio_unitario REAL NOT NULL,
      subtotal REAL NOT NULL,
      CHECK (
        (tipo_producto = 'libro' AND id_libro IS NOT NULL AND id_combo IS NULL)
        OR
        (tipo_producto = 'combo' AND id_combo IS NOT NULL AND id_libro IS NULL)
      ),
      FOREIGN KEY (id_pedido) REFERENCES pedidos (id_pedido)
        ON UPDATE CASCADE ON DELETE CASCADE,
      FOREIGN KEY (id_libro) REFERENCES libros (id_libro)
        ON UPDATE CASCADE ON DELETE RESTRICT,
      FOREIGN KEY (id_combo) REFERENCES combos (id_combo)
        ON UPDATE CASCADE ON DELETE RESTRICT
    )
    ''',
    '''
    CREATE TABLE movimiento_inventario (
      id_movimiento INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT NOT NULL,
      tipo_movimiento TEXT NOT NULL,
      id_bodega INTEGER NOT NULL,
      id_usuario INTEGER NOT NULL,
      total REAL NOT NULL DEFAULT 0,
      observacion TEXT NOT NULL DEFAULT '',
      FOREIGN KEY (id_bodega) REFERENCES bodegas (id_bodega)
        ON UPDATE CASCADE ON DELETE RESTRICT,
      FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
    )
    ''',
    '''
    CREATE TABLE movimiento_detalle (
      id_movimiento_detalle INTEGER PRIMARY KEY AUTOINCREMENT,
      id_movimiento INTEGER NOT NULL,
      id_libro INTEGER NOT NULL,
      cantidad INTEGER NOT NULL,
      FOREIGN KEY (id_movimiento) REFERENCES movimiento_inventario (id_movimiento)
        ON UPDATE CASCADE ON DELETE CASCADE,
      FOREIGN KEY (id_libro) REFERENCES libros (id_libro)
        ON UPDATE CASCADE ON DELETE RESTRICT
    )
    ''',
    '''
    CREATE TABLE log_escaneos (
      id_log_escaneo INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha_hora TEXT NOT NULL,
      id_usuario INTEGER NOT NULL,
      id_libro INTEGER,
      id_combo INTEGER,
      resultado TEXT NOT NULL,
      FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
      FOREIGN KEY (id_libro) REFERENCES libros (id_libro)
        ON UPDATE CASCADE ON DELETE SET NULL,
      FOREIGN KEY (id_combo) REFERENCES combos (id_combo)
        ON UPDATE CASCADE ON DELETE SET NULL
    )
    ''',
    '''
    CREATE TABLE despachos (
      id_despacho INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT NOT NULL,
      id_pedido INTEGER NOT NULL,
      id_usuario INTEGER NOT NULL,
      estado TEXT NOT NULL,
      numero_remision TEXT NOT NULL DEFAULT '',
      observacion TEXT NOT NULL DEFAULT '',
      FOREIGN KEY (id_pedido) REFERENCES pedidos (id_pedido)
        ON UPDATE CASCADE ON DELETE RESTRICT,
      FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
    )
    ''',
    '''
    CREATE TABLE despacho_detalle (
      id_despacho_detalle INTEGER PRIMARY KEY AUTOINCREMENT,
      id_despacho INTEGER NOT NULL,
      id_libro INTEGER NOT NULL,
      cantidad INTEGER NOT NULL,
      FOREIGN KEY (id_despacho) REFERENCES despachos (id_despacho)
        ON UPDATE CASCADE ON DELETE CASCADE,
      FOREIGN KEY (id_libro) REFERENCES libros (id_libro)
        ON UPDATE CASCADE ON DELETE RESTRICT
    )
    ''',
    '''
    CREATE TABLE remisiones (
      id_remision INTEGER PRIMARY KEY AUTOINCREMENT,
      id_despacho INTEGER NOT NULL,
      numero TEXT NOT NULL UNIQUE,
      fecha_generacion TEXT NOT NULL,
      id_usuario INTEGER NOT NULL,
      archivo_pdf TEXT NOT NULL DEFAULT '',
      estado TEXT NOT NULL DEFAULT 'generada',
      FOREIGN KEY (id_despacho) REFERENCES despachos (id_despacho)
        ON UPDATE CASCADE ON DELETE CASCADE,
      FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
    )
    ''',
    '''
    CREATE TABLE devoluciones (
      id_devolucion INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT NOT NULL,
      id_pedido INTEGER NOT NULL,
      id_despacho INTEGER,
      id_usuario INTEGER NOT NULL,
      motivo TEXT NOT NULL,
      reintegrar_inventario INTEGER NOT NULL DEFAULT 0,
      estado TEXT NOT NULL DEFAULT 'registrada',
      FOREIGN KEY (id_pedido) REFERENCES pedidos (id_pedido)
        ON UPDATE CASCADE ON DELETE RESTRICT,
      FOREIGN KEY (id_despacho) REFERENCES despachos (id_despacho)
        ON UPDATE CASCADE ON DELETE SET NULL,
      FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
    )
    ''',
    '''
    CREATE TABLE devolucion_detalle (
      id_devolucion_detalle INTEGER PRIMARY KEY AUTOINCREMENT,
      id_devolucion INTEGER NOT NULL,
      id_libro INTEGER,
      id_combo INTEGER,
      cantidad INTEGER NOT NULL,
      estado_libro TEXT NOT NULL DEFAULT '',
      observacion TEXT NOT NULL DEFAULT '',
      CHECK (id_libro IS NOT NULL OR id_combo IS NOT NULL),
      FOREIGN KEY (id_devolucion) REFERENCES devoluciones (id_devolucion)
        ON UPDATE CASCADE ON DELETE CASCADE,
      FOREIGN KEY (id_libro) REFERENCES libros (id_libro)
        ON UPDATE CASCADE ON DELETE RESTRICT,
      FOREIGN KEY (id_combo) REFERENCES combos (id_combo)
        ON UPDATE CASCADE ON DELETE RESTRICT
    )
    ''',
  ];

  static const indexStatements = [
    'CREATE INDEX idx_colegios_ciudad ON colegios (id_ciudad)',
    'CREATE INDEX idx_libros_isbn ON libros (isbn)',
    'CREATE INDEX idx_pedidos_colegio ON pedidos (id_colegio)',
    'CREATE INDEX idx_pedidos_usuario ON pedidos (id_usuario)',
    'CREATE INDEX idx_pedido_detalle_pedido ON pedido_detalle (id_pedido)',
    'CREATE INDEX idx_movimiento_bodega ON movimiento_inventario (id_bodega)',
    'CREATE INDEX idx_movimiento_usuario ON movimiento_inventario (id_usuario)',
    'CREATE INDEX idx_despachos_pedido ON despachos (id_pedido)',
    'CREATE INDEX idx_devoluciones_pedido ON devoluciones (id_pedido)',
    'CREATE INDEX idx_log_escaneos_usuario ON log_escaneos (id_usuario)',
  ];
}
