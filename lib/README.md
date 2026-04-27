# Organizacion de `lib`

El proyecto esta separado primero por area de la app y luego por el rol de cada archivo.

## Areas principales

- `aplicacion`: configuracion general de la app, como tema y estilos globales.
- `caracteristicas`: funcionalidades grandes de la app.
- `roles`: pantallas de entrada separadas para administrador, vendedor y bodeguero.
- `compartido`: codigo reutilizable por varias caracteristicas.
- `main.dart`: punto de entrada de Flutter.

## Roles de carpetas

- `pantallas`: vistas completas que el usuario abre o navega.
- `componentes`: partes visuales reutilizables dentro de una pantalla.
- `modelos`: clases que representan datos, como libros, pedidos o usuarios.
- `servicios`: logica para guardar, cargar, autenticar o manejar datos.
- `tema`: colores, tipografias y estilos globales.

## Que tocar segun el cambio

- Cambios visuales de una pagina completa: busca en `pantallas`.
- Cambios visuales de una tarjeta, fila, boton o seccion repetida: busca en `componentes`.
- Cambios en los datos que guarda una entidad: busca en `modelos`.
- Cambios en carga, guardado, login, base de datos o datos temporales: busca en `servicios`.
- Cambios de colores o estilo general: busca en `aplicacion/tema`.
- Cambios en lo que puede ver o hacer cada rol: busca en `caracteristicas/autenticacion/modelos/usuario_app.dart`.
- Cambios en las pestañas que aparecen para administrador: busca en `roles/administrador/pantallas/pantalla_inicio_administrador.dart`.
- Cambios en las pestañas que aparecen para vendedor: busca en `roles/vendedor/pantallas/pantalla_inicio_vendedor.dart`.
- Cambios en las pestañas que aparecen para bodeguero: busca en `roles/bodeguero/pantallas/pantalla_inicio_bodeguero.dart`.

## Roles de usuario

Cada rol tiene su propia pantalla de inicio. Eso permite cambiar la navegacion o experiencia de un rol sin tocar directamente la de los otros.

Las pantallas internas importantes, como inventario, pedidos y combos, siguen en `caracteristicas` para compartir logica y evitar copiar codigo.

Los permisos estan en:

- `caracteristicas/autenticacion/modelos/usuario_app.dart`

La pantalla que decide a que inicio enviar cada usuario esta en:

- `caracteristicas/inicio/pantallas/pantalla_inicio.dart`

La base comun del menu superior, navegacion inferior, escaner y cierre de sesion esta en:

- `caracteristicas/inicio/componentes/base_inicio_rol.dart`

### Administrador

Puede ver y editar casi todo.

- Inicio / panel: `caracteristicas/inicio/pantallas/pantalla_panel.dart`
- Navegacion del administrador: `roles/administrador/pantallas/pantalla_inicio_administrador.dart`
- Inventario: `caracteristicas/inventario/pantallas/pantalla_inventario.dart`
- Agregar o editar libros: `caracteristicas/inventario/pantallas/pantalla_agregar_libro.dart`
- Combos: `caracteristicas/combos/pantallas/pantalla_combos.dart`
- Pedidos: `caracteristicas/pedidos/pantallas/pantalla_pedidos.dart`
- Despachos: `caracteristicas/pedidos/pantallas/pantalla_despachos.dart`
- Configuracion: `caracteristicas/configuracion/pantallas/pantalla_configuracion.dart`

Para cambiar lo que solo el administrador puede hacer, revisa permisos como:

- `canManageInventory`
- `canEditCombos`
- `canManageSettings`
- `canDispatchOrders`

### Vendedor

Trabaja principalmente con pedidos, combos e informacion visible para vender.

- Inicio / panel: `caracteristicas/inicio/pantallas/pantalla_panel.dart`
- Navegacion del vendedor: `roles/vendedor/pantallas/pantalla_inicio_vendedor.dart`
- Inventario visible para venta: `caracteristicas/inventario/pantallas/pantalla_inventario.dart`
- Combos: `caracteristicas/combos/pantallas/pantalla_combos.dart`
- Pedidos: `caracteristicas/pedidos/pantallas/pantalla_pedidos.dart`
- Despachos en modo consulta: `caracteristicas/pedidos/pantallas/pantalla_despachos.dart`

Para cambiar lo que el vendedor puede hacer, revisa permisos como:

- `canCreateOrders`
- `canEditOrders`
- `canAdvanceOrders`
- `canSeePrices`
- `canViewCombos`

### Bodeguero

Trabaja principalmente con inventario, escaner y stock.

- Inventario: `caracteristicas/inventario/pantallas/pantalla_inventario.dart`
- Navegacion del bodeguero: `roles/bodeguero/pantallas/pantalla_inicio_bodeguero.dart`
- Escaner: `caracteristicas/inventario/pantallas/pantalla_escaner.dart`
- Tarjeta visual de libro: `caracteristicas/inventario/componentes/tarjeta_libro.dart`

Para cambiar lo que el bodeguero puede hacer, revisa permisos como:

- `canViewInventory`
- `canEditStockOnly`
- `canUseScanner`
- `canSeePrices`
- `canSeeInventoryDetails`

## Regla rapida

Si quieres cambiar una pantalla para un rol especifico:

1. Busca la pantalla en la lista del rol.
2. Revisa que permisos recibe desde la pantalla de inicio de ese rol en `roles`.
3. Cambia la condicion del permiso en `usuario_app.dart` si el rol debe tener una capacidad distinta en toda la app.
4. Cambia la UI de la pantalla si el boton, texto o accion debe verse diferente.

## Ejemplos

- Inventario de libros: `caracteristicas/inventario`.
- Combos de libros: `caracteristicas/combos`.
- Pedidos y despachos: `caracteristicas/pedidos`.
- Login y usuario: `caracteristicas/autenticacion`.
- Pantalla inicial y panel: `caracteristicas/inicio`.
- Configuracion de empresa: `caracteristicas/configuracion`.
