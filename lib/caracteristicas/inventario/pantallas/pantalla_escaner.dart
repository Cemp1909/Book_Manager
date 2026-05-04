import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import 'package:book_manager/datos/modelos/actividad_app.dart';
import 'package:book_manager/datos/modelos/libro.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';
import 'package:book_manager/compartido/servicios/servicio_datos_temporales.dart';
import 'package:book_manager/compartido/servicios/servicio_historial.dart';

class ScannerScreen extends StatefulWidget {
  final AppUser? currentUser;
  final List<Book> books;

  const ScannerScreen({
    super.key,
    this.currentUser,
    this.books = const [],
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController cameraController = MobileScannerController(
    formats: [BarcodeFormat.qrCode, BarcodeFormat.code128, BarcodeFormat.ean13],
    torchEnabled: false,
  );

  bool _isScanning = true;
  final List<Map<String, dynamic>> _scanHistory = [];

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            errorBuilder: (context, error, child) {
              return _buildScannerError(error);
            },
            onDetect: (capture) {
              if (!_isScanning) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                  _onCodeScanned(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Marco rectangular para códigos de barras
          Center(
            child: Container(
              width: 320, // Ancho mayor
              height: 180, // Alto menor (rectangular)
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Esquinas decorativas
                  _buildCorner(Alignment.topLeft, isLeft: true, isTop: true),
                  _buildCorner(Alignment.topRight, isLeft: false, isTop: true),
                  _buildCorner(Alignment.bottomLeft,
                      isLeft: true, isTop: false),
                  _buildCorner(Alignment.bottomRight,
                      isLeft: false, isTop: false),

                  // Línea de escaneo animada (horizontal)
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(seconds: 2),
                      tween: Tween<double>(begin: -0.85, end: 0.85),
                      builder: (context, value, child) {
                        return Align(
                          alignment: Alignment(value, 0),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 2,
                        height: double.infinity,
                        color: Colors.green,
                      ),
                    ),
                  ),

                  // Indicadores de alineación
                  const Positioned(
                    left: 10,
                    top: 10,
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const Positioned(
                    right: 10,
                    top: 10,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instrucción
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Coloca el código de barras dentro del marco',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Alinea el código horizontalmente',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment,
      {required bool isLeft, required bool isTop}) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildScannerError(MobileScannerException error) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography, color: Colors.white, size: 56),
              const SizedBox(height: 16),
              const Text(
                'No se pudo abrir la camara',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _cameraErrorMessage(error),
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _cameraErrorMessage(MobileScannerException error) {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Revisa el permiso de camara en la configuracion del dispositivo.';
      case MobileScannerErrorCode.controllerUninitialized:
      case MobileScannerErrorCode.genericError:
        return 'Cierra esta pantalla e intenta abrir el escaner otra vez.';
      case MobileScannerErrorCode.unsupported:
        return 'Este dispositivo o plataforma no soporta el escaner.';
    }
  }

  void _onCodeScanned(String code) async {
    _isScanning = false;

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }

    if (!mounted) return;

    final book = _findBookByCode(code);
    final result = book == null ? 'No encontrado' : 'Libro: ${book.title}';
    final codeType = _detectCodeType(code);

    TemporaryDataService.instance.addScanLog(
      code: code,
      codeType: codeType,
      result: result,
      user: widget.currentUser,
      bookIsbn: book?.isbn,
      bookTitle: book?.title,
    );
    ActivityLogService.instance.record(
      type: ActivityType.scans,
      title: 'Escaneo registrado',
      detail: '$codeType - $result',
      actor: widget.currentUser,
    );

    setState(() {
      _scanHistory.insert(0, {
        'code': code,
        'date': DateTime.now(),
        'type': codeType,
        'result': result,
      });
    });

    _showResultDialog(code, result);
  }

  Book? _findBookByCode(String code) {
    final normalizedCode = code.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
    for (final book in widget.books) {
      final normalizedIsbn = book.isbn.toLowerCase().replaceAll(
            RegExp(r'[^a-z0-9]'),
            '',
          );
      if (normalizedIsbn == normalizedCode) return book;
    }
    return null;
  }

  String _detectCodeType(String code) {
    if (code.startsWith('http') || code.startsWith('https')) {
      return 'URL';
    } else if (code.length == 13 && RegExp(r'^[0-9]+$').hasMatch(code)) {
      return 'ISBN';
    } else if (code.length == 12 && RegExp(r'^[0-9]+$').hasMatch(code)) {
      return 'UPC';
    } else {
      return 'Código de Barras';
    }
  }

  void _showResultDialog(String code, String result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Código escaneado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipo: ${_detectCodeType(code)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              result,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '¿Qué deseas hacer?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('Escanear otro'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, code);
            },
            child: const Text('Buscar producto'),
          ),
        ],
      ),
    );
  }

  void _showHistory() {
    final scanLogs = TemporaryDataService.instance.scanLogs;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Historial de escaneos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (scanLogs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Text('No hay escaneos recientes'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: scanLogs.length,
                itemBuilder: (context, index) {
                  final item = scanLogs[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(
                        _getTypeIcon(item.codeType),
                        color: Colors.blue,
                      ),
                    ),
                    title: Text(
                      item.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${item.codeType} - ${item.result} - ${item.user?.name ?? 'Sistema'} - ${_formatDate(item.dateTime)}',
                    ),
                  );
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'URL':
        return Icons.link;
      case 'ISBN':
        return Icons.menu_book;
      case 'UPC':
        return Icons.shopping_cart;
      default:
        return Icons.qr_code;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
    });
  }
}
