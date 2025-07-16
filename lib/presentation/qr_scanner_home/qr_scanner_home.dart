import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/campaign_service.dart';
import '../../services/qr_scanner_service.dart';
import './widgets/nearby_businesses_carousel_widget.dart';
import './widgets/qr_scanner_overlay_widget.dart';
import './widgets/scanner_controls_widget.dart';

class QRScannerHome extends StatefulWidget {
  const QRScannerHome({Key? key}) : super(key: key);

  @override
  State<QRScannerHome> createState() => _QRScannerHomeState();
}

class _QRScannerHomeState extends State<QRScannerHome>
    with TickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final QRScannerService _scannerService = QRScannerService();
  final CampaignService _campaignService = CampaignService();

  QRViewController? _controller;
  bool _isScanning = true;
  bool _isFlashOn = false;
  bool _isLoading = false;
  String? _lastScannedCode;
  List<Map<String, dynamic>> _nearbyBusinesses = [];

  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    _loadNearbyBusinesses();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseAnimationController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(
            parent: _pulseAnimationController, curve: Curves.easeInOut));

    _pulseAnimationController.repeat(reverse: true);
  }

  Future<void> _initializeScanner() async {
    try {
      final isInitialized = await _scannerService.initializeCamera();
      if (!isInitialized) {
        _showError('Camera initialization failed');
      }
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  Future<void> _loadNearbyBusinesses() async {
    try {
      final businesses = await _campaignService.getNearbyBusinesses();
      if (mounted) {
        setState(() {
          _nearbyBusinesses = businesses;
        });
      }
    } catch (e) {
      debugPrint('Error loading nearby businesses: $e');
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _controller = controller;
    });

    _scannerService.setController(controller);

    controller.scannedDataStream.listen((scanData) {
      if (_isScanning && scanData.code != null) {
        _handleQRScanned(scanData.code!);
      }
    });
  }

  void _handleQRScanned(String qrCode) async {
    if (_lastScannedCode == qrCode || _isLoading) return;

    setState(() {
      _lastScannedCode = qrCode;
      _isScanning = false;
      _isLoading = true;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    try {
      // Validate QR code
      if (!_scannerService.isValidQRCode(qrCode)) {
        _showError('Invalid QR code format');
        return;
      }

      // Get campaign details
      final campaignData = await _campaignService.getCampaignByQRCode(qrCode);

      if (campaignData == null) {
        _showError('No active campaign found for this QR code');
        return;
      }

      // Navigate to business details
      Navigator.pushNamed(context, AppRoutes.businessDetailsPreview,
          arguments: campaignData);
    } catch (e) {
      _showError('Error processing QR code: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Resume scanning after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isScanning = true;
              _lastScannedCode = null;
            });
          }
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3)));
  }

  Future<void> _toggleFlash() async {
    try {
      await _scannerService.toggleFlash();
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      _showError('Failed to toggle flash');
    }
  }

  Future<void> _flipCamera() async {
    try {
      await _scannerService.flipCamera();
    } catch (e) {
      _showError('Failed to flip camera');
    }
  }

  void _onBusinessTapped(Map<String, dynamic> business) {
    Navigator.pushNamed(context, AppRoutes.businessDetailsPreview,
        arguments: business);
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _controller?.dispose();
    _scannerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          // Camera preview
          if (_scannerService.isInitialized)
            QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                    borderRadius: 12,
                    borderLength: 30,
                    borderWidth: 4,
                    cutOutSize: 50.w),
                onPermissionSet: (ctrl, p) =>
                    _onPermissionSet(context, ctrl, p)),

          // Header with logo and profile
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                  height: 12.h,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                        Colors.black.withAlpha(204),
                        Colors.transparent,
                      ])),
                  child: SafeArea(
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Row(children: [
                            // Back button
                            IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white)),

                            const Spacer(),

                            // Lucky Rascals logo
                            Text('Lucky Rascals',
                                style: GoogleFonts.inter(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),

                            const Spacer(),

                            // Profile icon
                            CircleAvatar(
                                radius: 20,
                                child: CustomIconWidget(
                                    iconName: 'profile',
                                    color: Colors.white,
                                    size: 24)),
                          ]))))),

          // QR Scanner overlay with animation
          if (_isScanning)
            Center(
                child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: QRScannerOverlayWidget(
                              isScanning: _isScanning, size: 50.w));
                    })),

          // Loading overlay
          if (_isLoading)
            Container(
                color: Colors.black.withAlpha(128),
                child: const Center(
                    child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)))),

          // Scanner controls
          Positioned(
              bottom: 25.h,
              left: 0,
              right: 0,
              child: ScannerControlsWidget(
                  isFlashOn: _isFlashOn,
                  onFlashToggle: _toggleFlash,
                  onCameraFlip: _flipCamera,
                  onGalleryTap: () {
                    // TODO: Implement gallery QR scanning
                  })),

          // Nearby businesses carousel
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                  height: 22.h,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(230),
                      ])),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.w, vertical: 2.h),
                            child: Text('Nearby Businesses',
                                style: GoogleFonts.inter(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white))),
                        Expanded(
                            child: NearbyBusinessesCarouselWidget(
                                businesses: _nearbyBusinesses,
                                onBusinessTapped: _onBusinessTapped)),
                      ]))),

          // Scanning instruction
          if (_isScanning && !_isLoading)
            Positioned(
                top: 35.h,
                left: 0,
                right: 0,
                child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.h),
                    child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 1.h),
                        decoration: BoxDecoration(
                            color: Colors.black.withAlpha(179),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(
                            'Point your camera at the QR code on business poster',
                            style: GoogleFonts.inter(
                                fontSize: 14.sp, color: Colors.white),
                            textAlign: TextAlign.center)))),
        ]));
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission required')));
    }
  }
}
