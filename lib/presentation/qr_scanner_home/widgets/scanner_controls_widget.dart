import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class ScannerControlsWidget extends StatelessWidget {
  final bool isFlashOn;
  final VoidCallback onFlashToggle;
  final VoidCallback onCameraFlip;
  final VoidCallback onGalleryTap;

  const ScannerControlsWidget({
    Key? key,
    required this.isFlashOn,
    required this.onFlashToggle,
    required this.onCameraFlip,
    required this.onGalleryTap,
  }) : super(key: key);

  // Helper method to convert IconData to String
  String _getIconName(IconData iconData) {
    final Map<IconData, String> iconMap = {
      Icons.photo_library_outlined: 'photo_library',
      Icons.flash_on: 'flash_on',
      Icons.flash_off: 'flash_off',
      Icons.flip_camera_ios: 'flip_camera_ios',
      Icons.camera_alt: 'camera_alt',
      Icons.photo: 'photo',
      Icons.image: 'image',
      Icons.collections: 'collections',
    };

    return iconMap[iconData] ?? 'info'; // Default to 'info' if not found
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          // Gallery button
          _buildControlButton(
              icon: Icons.photo_library_outlined,
              isActive: false,
              onTap: onGalleryTap,
              label: 'Gallery'),

          // Flash toggle
          _buildControlButton(
              icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
              isActive: isFlashOn,
              onTap: onFlashToggle,
              label: 'Flash'),

          // Camera flip
          _buildControlButton(
              icon: Icons.flip_camera_ios,
              isActive: false,
              onTap: onCameraFlip,
              label: 'Flip'),
        ]));
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required String label,
  }) {
    return GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 15.w,
              height: 15.w,
              decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryLight
                      : Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(25),
                  border:
                      Border.all(color: Colors.white.withAlpha(77), width: 1)),
              child: CustomIconWidget(
                  iconName: _getIconName(icon),
                  color: isActive ? Colors.white : Colors.grey[300],
                  size: 24)),
          SizedBox(height: 1.h),
          Text(label,
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
        ]));
  }
}
