class DbCiudad {
  final int? idCiudad;
  final String nombre;

  const DbCiudad({this.idCiudad, required this.nombre});

  Map<String, Object?> toMap() => {
        'id_ciudad': idCiudad,
        'nombre': nombre,
      };

  factory DbCiudad.fromMap(Map<String, Object?> map) => DbCiudad(
        idCiudad: map['id_ciudad'] as int?,
        nombre: map['nombre'] as String,
      );
}

class DbColegio {
  final int? idColegio;
  final String nombre;
  final String direccion;
  final String telefono;
  final int idCiudad;

  const DbColegio({
    this.idColegio,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.idCiudad,
  });

  Map<String, Object?> toMap() => {
        'id_colegio': idColegio,
        'nombre': nombre,
        'direccion': direccion,
        'telefono': telefono,
        'id_ciudad': idCiudad,
      };

  factory DbColegio.fromMap(Map<String, Object?> map) => DbColegio(
        idColegio: map['id_colegio'] as int?,
        nombre: map['nombre'] as String,
        direccion: map['direccion'] as String,
        telefono: map['telefono'] as String,
        idCiudad: map['id_ciudad'] as int,
      );
}

class DbRol {
  final int? idRol;
  final String nombre;
  final String descripcion;

  const DbRol({
    this.idRol,
    required this.nombre,
    required this.descripcion,
  });

  Map<String, Object?> toMap() => {
        'id_rol': idRol,
        'nombre': nombre,
        'descripcion': descripcion,
      };

  factory DbRol.fromMap(Map<String, Object?> map) => DbRol(
        idRol: map['id_rol'] as int?,
        nombre: map['nombre'] as String,
        descripcion: map['descripcion'] as String,
      );
}

class DbUsuario {
  final int? idUsuario;
  final String nombre;
  final String correo;
  final String contrasena;
  final String estado;

  const DbUsuario({
    this.idUsuario,
    required this.nombre,
    required this.correo,
    required this.contrasena,
    this.estado = 'activo',
  });

  Map<String, Object?> toMap() => {
        'id_usuario': idUsuario,
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena,
        'estado': estado,
      };

  factory DbUsuario.fromMap(Map<String, Object?> map) => DbUsuario(
        idUsuario: map['id_usuario'] as int?,
        nombre: map['nombre'] as String,
        correo: map['correo'] as String,
        contrasena: map['contrasena'] as String,
        estado: map['estado'] as String,
      );
}

class DbUsuarioRol {
  final int? idUsuarioRol;
  final int idUsuario;
  final int idRol;

  const DbUsuarioRol({
    this.idUsuarioRol,
    required this.idUsuario,
    required this.idRol,
  });

  Map<String, Object?> toMap() => {
        'id_usuario_rol': idUsuarioRol,
        'id_usuario': idUsuario,
        'id_rol': idRol,
      };

  factory DbUsuarioRol.fromMap(Map<String, Object?> map) => DbUsuarioRol(
        idUsuarioRol: map['id_usuario_rol'] as int?,
        idUsuario: map['id_usuario'] as int,
        idRol: map['id_rol'] as int,
      );
}

class DbBodega {
  final int? idBodega;
  final String nombre;
  final String ubicacion;

  const DbBodega({
    this.idBodega,
    required this.nombre,
    required this.ubicacion,
  });

  Map<String, Object?> toMap() => {
        'id_bodega': idBodega,
        'nombre': nombre,
        'ubicacion': ubicacion,
      };

  factory DbBodega.fromMap(Map<String, Object?> map) => DbBodega(
        idBodega: map['id_bodega'] as int?,
        nombre: map['nombre'] as String,
        ubicacion: map['ubicacion'] as String,
      );
}

class DbLibro {
  final int? idLibro;
  final String titulo;
  final String isbn;
  final String grado;
  final String area;
  final int stock;
  final String codigoQr;
  final String autor;
  final String descripcion;
  final int precioBase;
  final String fotoPortada;

  const DbLibro({
    this.idLibro,
    required this.titulo,
    required this.isbn,
    required this.grado,
    required this.area,
    required this.stock,
    required this.codigoQr,
    this.autor = '',
    this.descripcion = '',
    this.precioBase = 0,
    this.fotoPortada = '',
  });

  Map<String, Object?> toMap() => {
        'id_libro': idLibro,
        'titulo': titulo,
        'isbn': isbn,
        'grado': grado,
        'area': area,
        'stock': stock,
        'codigo_qr': codigoQr,
        'autor': autor,
        'descripcion': descripcion,
        'precio_base': precioBase,
        'foto_portada': fotoPortada,
      };

  factory DbLibro.fromMap(Map<String, Object?> map) => DbLibro(
        idLibro: map['id_libro'] as int?,
        titulo: map['titulo'] as String,
        isbn: map['isbn'] as String,
        grado: map['grado'] as String,
        area: map['area'] as String,
        stock: map['stock'] as int,
        codigoQr: map['codigo_qr'] as String,
        autor: map['autor'] as String? ?? '',
        descripcion: map['descripcion'] as String? ?? '',
        precioBase: map['precio_base'] as int? ?? 0,
        fotoPortada: map['foto_portada'] as String? ?? '',
      );
}

class DbCombo {
  final int? idCombo;
  final String nombre;
  final String descripcion;

  const DbCombo({
    this.idCombo,
    required this.nombre,
    required this.descripcion,
  });

  Map<String, Object?> toMap() => {
        'id_combo': idCombo,
        'nombre': nombre,
        'descripcion': descripcion,
      };

  factory DbCombo.fromMap(Map<String, Object?> map) => DbCombo(
        idCombo: map['id_combo'] as int?,
        nombre: map['nombre'] as String,
        descripcion: map['descripcion'] as String,
      );
}

class DbComboDetalle {
  final int? idComboDetalle;
  final int idCombo;
  final int idLibro;
  final int cantidad;

  const DbComboDetalle({
    this.idComboDetalle,
    required this.idCombo,
    required this.idLibro,
    required this.cantidad,
  });

  Map<String, Object?> toMap() => {
        'id_combo_detalle': idComboDetalle,
        'id_combo': idCombo,
        'id_libro': idLibro,
        'cantidad': cantidad,
      };

  factory DbComboDetalle.fromMap(Map<String, Object?> map) => DbComboDetalle(
        idComboDetalle: map['id_combo_detalle'] as int?,
        idCombo: map['id_combo'] as int,
        idLibro: map['id_libro'] as int,
        cantidad: map['cantidad'] as int,
      );
}

class DbPrecioLibroColegioAnio {
  final int? idPrecioLibro;
  final int idLibro;
  final int idColegio;
  final int anio;
  final double precio;

  const DbPrecioLibroColegioAnio({
    this.idPrecioLibro,
    required this.idLibro,
    required this.idColegio,
    required this.anio,
    required this.precio,
  });

  Map<String, Object?> toMap() => {
        'id_precio_libro': idPrecioLibro,
        'id_libro': idLibro,
        'id_colegio': idColegio,
        'anio': anio,
        'precio': precio,
      };

  factory DbPrecioLibroColegioAnio.fromMap(Map<String, Object?> map) =>
      DbPrecioLibroColegioAnio(
        idPrecioLibro: map['id_precio_libro'] as int?,
        idLibro: map['id_libro'] as int,
        idColegio: map['id_colegio'] as int,
        anio: map['anio'] as int,
        precio: (map['precio'] as num).toDouble(),
      );
}

class DbPrecioComboColegioAnio {
  final int? idPrecioCombo;
  final int idCombo;
  final int idColegio;
  final int anio;
  final double precio;

  const DbPrecioComboColegioAnio({
    this.idPrecioCombo,
    required this.idCombo,
    required this.idColegio,
    required this.anio,
    required this.precio,
  });

  Map<String, Object?> toMap() => {
        'id_precio_combo': idPrecioCombo,
        'id_combo': idCombo,
        'id_colegio': idColegio,
        'anio': anio,
        'precio': precio,
      };

  factory DbPrecioComboColegioAnio.fromMap(Map<String, Object?> map) =>
      DbPrecioComboColegioAnio(
        idPrecioCombo: map['id_precio_combo'] as int?,
        idCombo: map['id_combo'] as int,
        idColegio: map['id_colegio'] as int,
        anio: map['anio'] as int,
        precio: (map['precio'] as num).toDouble(),
      );
}

class DbPedido {
  final int? idPedido;
  final DateTime fecha;
  final int idColegio;
  final int idUsuario;
  final double total;
  final String estado;

  const DbPedido({
    this.idPedido,
    required this.fecha,
    required this.idColegio,
    required this.idUsuario,
    required this.total,
    required this.estado,
  });

  Map<String, Object?> toMap() => {
        'id_pedido': idPedido,
        'fecha': fecha.toIso8601String(),
        'id_colegio': idColegio,
        'id_usuario': idUsuario,
        'total': total,
        'estado': estado,
      };

  factory DbPedido.fromMap(Map<String, Object?> map) => DbPedido(
        idPedido: map['id_pedido'] as int?,
        fecha: DateTime.parse(map['fecha'] as String),
        idColegio: map['id_colegio'] as int,
        idUsuario: map['id_usuario'] as int,
        total: (map['total'] as num).toDouble(),
        estado: map['estado'] as String,
      );
}

class DbPedidoDetalle {
  final int? idPedidoDetalle;
  final int idPedido;
  final String tipoProducto;
  final int? idLibro;
  final int? idCombo;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  const DbPedidoDetalle({
    this.idPedidoDetalle,
    required this.idPedido,
    required this.tipoProducto,
    this.idLibro,
    this.idCombo,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  Map<String, Object?> toMap() => {
        'id_pedido_detalle': idPedidoDetalle,
        'id_pedido': idPedido,
        'tipo_producto': tipoProducto,
        'id_libro': idLibro,
        'id_combo': idCombo,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'subtotal': subtotal,
      };

  factory DbPedidoDetalle.fromMap(Map<String, Object?> map) => DbPedidoDetalle(
        idPedidoDetalle: map['id_pedido_detalle'] as int?,
        idPedido: map['id_pedido'] as int,
        tipoProducto: map['tipo_producto'] as String,
        idLibro: map['id_libro'] as int?,
        idCombo: map['id_combo'] as int?,
        cantidad: map['cantidad'] as int,
        precioUnitario: (map['precio_unitario'] as num).toDouble(),
        subtotal: (map['subtotal'] as num).toDouble(),
      );
}

class DbMovimientoInventario {
  final int? idMovimiento;
  final DateTime fecha;
  final String tipoMovimiento;
  final int idBodega;
  final int idUsuario;
  final double total;
  final String observacion;

  const DbMovimientoInventario({
    this.idMovimiento,
    required this.fecha,
    required this.tipoMovimiento,
    required this.idBodega,
    required this.idUsuario,
    required this.total,
    this.observacion = '',
  });

  Map<String, Object?> toMap() => {
        'id_movimiento': idMovimiento,
        'fecha': fecha.toIso8601String(),
        'tipo_movimiento': tipoMovimiento,
        'id_bodega': idBodega,
        'id_usuario': idUsuario,
        'total': total,
        'observacion': observacion,
      };

  factory DbMovimientoInventario.fromMap(Map<String, Object?> map) =>
      DbMovimientoInventario(
        idMovimiento: map['id_movimiento'] as int?,
        fecha: DateTime.parse(map['fecha'] as String),
        tipoMovimiento: map['tipo_movimiento'] as String,
        idBodega: map['id_bodega'] as int,
        idUsuario: map['id_usuario'] as int,
        total: (map['total'] as num).toDouble(),
        observacion: map['observacion'] as String? ?? '',
      );
}

class DbMovimientoDetalle {
  final int? idMovimientoDetalle;
  final int idMovimiento;
  final int idLibro;
  final int cantidad;

  const DbMovimientoDetalle({
    this.idMovimientoDetalle,
    required this.idMovimiento,
    required this.idLibro,
    required this.cantidad,
  });

  Map<String, Object?> toMap() => {
        'id_movimiento_detalle': idMovimientoDetalle,
        'id_movimiento': idMovimiento,
        'id_libro': idLibro,
        'cantidad': cantidad,
      };

  factory DbMovimientoDetalle.fromMap(Map<String, Object?> map) =>
      DbMovimientoDetalle(
        idMovimientoDetalle: map['id_movimiento_detalle'] as int?,
        idMovimiento: map['id_movimiento'] as int,
        idLibro: map['id_libro'] as int,
        cantidad: map['cantidad'] as int,
      );
}

class DbLogEscaneo {
  final int? idLogEscaneo;
  final DateTime fechaHora;
  final int idUsuario;
  final int? idLibro;
  final int? idCombo;
  final String resultado;

  const DbLogEscaneo({
    this.idLogEscaneo,
    required this.fechaHora,
    required this.idUsuario,
    this.idLibro,
    this.idCombo,
    required this.resultado,
  });

  Map<String, Object?> toMap() => {
        'id_log_escaneo': idLogEscaneo,
        'fecha_hora': fechaHora.toIso8601String(),
        'id_usuario': idUsuario,
        'id_libro': idLibro,
        'id_combo': idCombo,
        'resultado': resultado,
      };

  factory DbLogEscaneo.fromMap(Map<String, Object?> map) => DbLogEscaneo(
        idLogEscaneo: map['id_log_escaneo'] as int?,
        fechaHora: DateTime.parse(map['fecha_hora'] as String),
        idUsuario: map['id_usuario'] as int,
        idLibro: map['id_libro'] as int?,
        idCombo: map['id_combo'] as int?,
        resultado: map['resultado'] as String,
      );
}

class DbDespacho {
  final int? idDespacho;
  final DateTime fecha;
  final int idPedido;
  final int idUsuario;
  final String estado;
  final String numeroRemision;
  final String observacion;

  const DbDespacho({
    this.idDespacho,
    required this.fecha,
    required this.idPedido,
    required this.idUsuario,
    required this.estado,
    this.numeroRemision = '',
    this.observacion = '',
  });

  Map<String, Object?> toMap() => {
        'id_despacho': idDespacho,
        'fecha': fecha.toIso8601String(),
        'id_pedido': idPedido,
        'id_usuario': idUsuario,
        'estado': estado,
        'numero_remision': numeroRemision,
        'observacion': observacion,
      };

  factory DbDespacho.fromMap(Map<String, Object?> map) => DbDespacho(
        idDespacho: map['id_despacho'] as int?,
        fecha: DateTime.parse(map['fecha'] as String),
        idPedido: map['id_pedido'] as int,
        idUsuario: map['id_usuario'] as int,
        estado: map['estado'] as String,
        numeroRemision: map['numero_remision'] as String? ?? '',
        observacion: map['observacion'] as String? ?? '',
      );
}

class DbDespachoDetalle {
  final int? idDespachoDetalle;
  final int idDespacho;
  final int idLibro;
  final int cantidad;

  const DbDespachoDetalle({
    this.idDespachoDetalle,
    required this.idDespacho,
    required this.idLibro,
    required this.cantidad,
  });

  Map<String, Object?> toMap() => {
        'id_despacho_detalle': idDespachoDetalle,
        'id_despacho': idDespacho,
        'id_libro': idLibro,
        'cantidad': cantidad,
      };

  factory DbDespachoDetalle.fromMap(Map<String, Object?> map) =>
      DbDespachoDetalle(
        idDespachoDetalle: map['id_despacho_detalle'] as int?,
        idDespacho: map['id_despacho'] as int,
        idLibro: map['id_libro'] as int,
        cantidad: map['cantidad'] as int,
      );
}

class DbRemision {
  final int? idRemision;
  final int idDespacho;
  final String numero;
  final DateTime fechaGeneracion;
  final int idUsuario;
  final String archivoPdf;
  final String estado;

  const DbRemision({
    this.idRemision,
    required this.idDespacho,
    required this.numero,
    required this.fechaGeneracion,
    required this.idUsuario,
    this.archivoPdf = '',
    this.estado = 'generada',
  });

  Map<String, Object?> toMap() => {
        'id_remision': idRemision,
        'id_despacho': idDespacho,
        'numero': numero,
        'fecha_generacion': fechaGeneracion.toIso8601String(),
        'id_usuario': idUsuario,
        'archivo_pdf': archivoPdf,
        'estado': estado,
      };

  factory DbRemision.fromMap(Map<String, Object?> map) => DbRemision(
        idRemision: map['id_remision'] as int?,
        idDespacho: map['id_despacho'] as int,
        numero: map['numero'] as String,
        fechaGeneracion: DateTime.parse(map['fecha_generacion'] as String),
        idUsuario: map['id_usuario'] as int,
        archivoPdf: map['archivo_pdf'] as String? ?? '',
        estado: map['estado'] as String? ?? 'generada',
      );
}

class DbDevolucion {
  final int? idDevolucion;
  final DateTime fecha;
  final int idPedido;
  final int? idDespacho;
  final int idUsuario;
  final String motivo;
  final bool reintegrarInventario;
  final String estado;

  const DbDevolucion({
    this.idDevolucion,
    required this.fecha,
    required this.idPedido,
    this.idDespacho,
    required this.idUsuario,
    required this.motivo,
    required this.reintegrarInventario,
    this.estado = 'registrada',
  });

  Map<String, Object?> toMap() => {
        'id_devolucion': idDevolucion,
        'fecha': fecha.toIso8601String(),
        'id_pedido': idPedido,
        'id_despacho': idDespacho,
        'id_usuario': idUsuario,
        'motivo': motivo,
        'reintegrar_inventario': reintegrarInventario ? 1 : 0,
        'estado': estado,
      };

  factory DbDevolucion.fromMap(Map<String, Object?> map) => DbDevolucion(
        idDevolucion: map['id_devolucion'] as int?,
        fecha: DateTime.parse(map['fecha'] as String),
        idPedido: map['id_pedido'] as int,
        idDespacho: map['id_despacho'] as int?,
        idUsuario: map['id_usuario'] as int,
        motivo: map['motivo'] as String,
        reintegrarInventario: (map['reintegrar_inventario'] as int) == 1,
        estado: map['estado'] as String? ?? 'registrada',
      );
}

class DbDevolucionDetalle {
  final int? idDevolucionDetalle;
  final int idDevolucion;
  final int? idLibro;
  final int? idCombo;
  final int cantidad;
  final String estadoLibro;
  final String observacion;

  const DbDevolucionDetalle({
    this.idDevolucionDetalle,
    required this.idDevolucion,
    this.idLibro,
    this.idCombo,
    required this.cantidad,
    this.estadoLibro = '',
    this.observacion = '',
  });

  Map<String, Object?> toMap() => {
        'id_devolucion_detalle': idDevolucionDetalle,
        'id_devolucion': idDevolucion,
        'id_libro': idLibro,
        'id_combo': idCombo,
        'cantidad': cantidad,
        'estado_libro': estadoLibro,
        'observacion': observacion,
      };

  factory DbDevolucionDetalle.fromMap(Map<String, Object?> map) =>
      DbDevolucionDetalle(
        idDevolucionDetalle: map['id_devolucion_detalle'] as int?,
        idDevolucion: map['id_devolucion'] as int,
        idLibro: map['id_libro'] as int?,
        idCombo: map['id_combo'] as int?,
        cantidad: map['cantidad'] as int,
        estadoLibro: map['estado_libro'] as String? ?? '',
        observacion: map['observacion'] as String? ?? '',
      );
}
