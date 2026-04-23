import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sighting_provider.dart';
import '../../services/connectivity_service.dart';
import '../../models/sighting.dart';
import '../../theme/app_colors.dart';
import '../../widgets/scan_viewfinder.dart';
import '../../widgets/capture_result_sheet.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _showFlash = false;
  Position? _currentPosition;
  String _locationText = 'Locating...';
  String _timestamp = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _startLocationUpdates();
    _startTimestamp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;

      _cameraController = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      if (mounted) setState(() => _isCameraInitialized = false);
    }
  }

  void _startLocationUpdates() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationText = 'GPS Unavailable');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationText = 'GPS Denied');
          return;
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (mounted) {
        setState(() {
          _locationText =
              '${_currentPosition!.latitude.toStringAsFixed(4)}°, ${_currentPosition!.longitude.toStringAsFixed(4)}°';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _locationText = 'GPS Error');
    }
  }

  void _startTimestamp() {
    _updateTimestamp();
    Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (mounted) _updateTimestamp();
    });
  }

  void _updateTimestamp() {
    setState(() {
      _timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    });
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || _cameraController == null || !_isCameraInitialized) return;

    setState(() {
      _isCapturing = true;
      _showFlash = true;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() => _showFlash = false);

    try {
      final xFile = await _cameraController!.takePicture();
      final capturedAt = DateTime.now();

      if (!mounted) return;

      final auth = context.read<AuthProvider>();
      final sightingProvider = context.read<SightingProvider>();
      final connectivity = context.read<ConnectivityService>();

      final sighting = await sightingProvider.submitSighting(
        userId: auth.currentUser?.id ?? '',
        imagePath: xFile.path,
        latitude: _currentPosition?.latitude ?? 0,
        longitude: _currentPosition?.longitude ?? 0,
        capturedAt: capturedAt,
      );

      if (sighting != null && mounted) {
        _showResultSheet(sighting, !connectivity.isOnline);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Capture failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _showResultSheet(Sighting sighting, bool isOffline) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CaptureResultSheet(
        sighting: sighting,
        isOffline: isOffline,
        onAddToCollection: () {
          Navigator.of(context).pop();
        },
        onRetake: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraPreview(),
          _buildFlashOverlay(),
          _buildViewfinderOverlay(),
          _buildHUD(),
          _buildShutterButton(),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: AppColors.bgPrimary,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return CameraPreview(_cameraController!);
  }

  Widget _buildFlashOverlay() {
    return AnimatedOpacity(
      opacity: _showFlash ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 80),
      child: Container(color: Colors.white),
    );
  }

  Widget _buildViewfinderOverlay() {
    return Positioned.fill(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 280,
                height: 320,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.accentPrimary.withOpacity(0.0),
                          width: 0,
                        ),
                      ),
                    ),
                    const ScanViewfinder(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return Positioned(
      bottom: 110,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.accentPrimary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 12, color: AppColors.accentPrimary.withOpacity(0.7)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _locationText,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: AppColors.accentPrimary.withOpacity(0.9),
                ),
              ),
            ),
            Text(
              _timestamp,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: AppColors.textSecondary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShutterButton() {
    return Positioned(
      bottom: 36,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _isCapturing ? null : _capturePhoto,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isCapturing
                  ? AppColors.accentPrimary.withOpacity(0.5)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPrimary.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: _isCapturing
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.bgPrimary,
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
