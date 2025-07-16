import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScannerService {
  static final QRScannerService _instance = QRScannerService._internal();
  factory QRScannerService() => _instance;
  QRScannerService._internal();

  QRViewController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  // Initialize camera system
  Future<bool> initializeCamera() async {
    try {
      if (_isInitialized) return true;

      // Request camera permission
      final permissionStatus = await _requestCameraPermission();
      if (!permissionStatus) {
        debugPrint('Camera permission denied');
        return false;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('No cameras available');
        return false;
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      return false;
    }
  }

  // Request camera permission
  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) {
      return true; // Browser handles camera permissions
    }

    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    if (kIsWeb) return true;

    final status = await Permission.camera.status;
    return status.isGranted;
  }

  // Set QR controller reference
  void setController(QRViewController controller) {
    _controller = controller;
  }

  // Toggle flashlight
  Future<void> toggleFlash() async {
    if (_controller == null) return;

    try {
      await _controller!.toggleFlash();
    } catch (e) {
      debugPrint('Flash toggle failed: $e');
    }
  }

  // Flip camera (front/back)
  Future<void> flipCamera() async {
    if (_controller == null) return;

    try {
      await _controller!.flipCamera();
    } catch (e) {
      debugPrint('Camera flip failed: $e');
    }
  }

  // Pause camera preview
  Future<void> pauseCamera() async {
    if (_controller == null) return;

    try {
      await _controller!.pauseCamera();
    } catch (e) {
      debugPrint('Camera pause failed: $e');
    }
  }

  // Resume camera preview
  Future<void> resumeCamera() async {
    if (_controller == null) return;

    try {
      await _controller!.resumeCamera();
    } catch (e) {
      debugPrint('Camera resume failed: $e');
    }
  }

  // Validate QR code format
  bool isValidQRCode(String? qrCode) {
    if (qrCode == null || qrCode.isEmpty) return false;

    // Check if QR code matches expected format (starts with QR_)
    return qrCode.startsWith('QR_') && qrCode.length >= 10;
  }

  // Process scanned QR code
  Map<String, dynamic> processQRCode(String qrCode) {
    if (!isValidQRCode(qrCode)) {
      return {
        'isValid': false,
        'error': 'Invalid QR code format',
        'qrCode': qrCode,
      };
    }

    return {
      'isValid': true,
      'qrCode': qrCode,
      'businessCode': qrCode,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Dispose resources
  Future<void> dispose() async {
    try {
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
    } catch (e) {
      debugPrint('QR scanner disposal failed: $e');
    }
  }

  // Get camera count
  int get cameraCount => _cameras?.length ?? 0;

  // Check if initialized
  bool get isInitialized => _isInitialized;

  // Get controller
  QRViewController? get controller => _controller;
}
