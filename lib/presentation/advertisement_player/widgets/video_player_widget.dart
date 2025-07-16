import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final Function(bool isPlaying, bool isLoaded, int duration) onStateChanged;
  final bool preventControls;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    required this.onStateChanged,
    this.preventControls = false,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _isPlaying = false;
  bool _isLoaded = false;
  bool _isBuffering = false;
  bool _hasError = false;
  bool _showControls = false;

  int _duration = 0;
  int _position = 0;
  double _volume = 1.0;

  Timer? _hideControlsTimer;
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _positionTimer?.cancel();
    super.dispose();
  }

  void _initializeVideo() {
    // Simulate video initialization
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoaded = true;
          _duration = 30; // 30 second video
          _hasError = false;
        });

        widget.onStateChanged(_isPlaying, _isLoaded, _duration);

        // Auto-start video
        _playVideo();
      }
    });
  }

  void _playVideo() {
    if (!_isLoaded) return;

    setState(() {
      _isPlaying = true;
      _isBuffering = false;
    });

    widget.onStateChanged(_isPlaying, _isLoaded, _duration);

    // Start position timer
    _positionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isPlaying && _position < _duration) {
        setState(() {
          _position++;
        });
      } else if (_position >= _duration) {
        _pauseVideo();
        timer.cancel();
      }
    });
  }

  void _pauseVideo() {
    setState(() {
      _isPlaying = false;
    });

    _positionTimer?.cancel();
    widget.onStateChanged(_isPlaying, _isLoaded, _duration);
  }

  void _togglePlayPause() {
    if (widget.preventControls) return;

    if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }

  void _seekTo(int seconds) {
    if (widget.preventControls) return;

    setState(() {
      _position = seconds.clamp(0, _duration);
    });
  }

  void _setVolume(double volume) {
    setState(() {
      _volume = volume.clamp(0.0, 1.0);
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });

    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showControlsTemporarily,
      child: Container(
        width: 100.w,
        height: 100.h,
        color: Colors.black,
        child: Stack(
          children: [
            // Video display area
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildVideoContent(),
                ),
              ),
            ),

            // Loading indicator
            if (_isBuffering)
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),

            // Error state
            if (_hasError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 8.w,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Error loading video',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    ElevatedButton(
                      onPressed: _initializeVideo,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),

            // Controls overlay
            if (_showControls && !widget.preventControls)
              _buildControlsOverlay(),

            // Volume control
            if (_showControls) _buildVolumeControl(),

            // Progress bar
            _buildProgressBar(),

            // Anti-manipulation overlay
            if (widget.preventControls) _buildAntiManipulationOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (!_isLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 2.h),
            Text(
              'Loading video...',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Simulate video frames with gradient animation
    return AnimatedContainer(
      duration: Duration(seconds: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withAlpha(153),
            Colors.purple.withAlpha(153),
            Colors.pink.withAlpha(153),
          ],
          stops: [
            (_position / _duration) * 0.33,
            (_position / _duration) * 0.66,
            (_position / _duration),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isPlaying ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
              size: 12.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Ad Video Playing',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(77),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rewind button
              IconButton(
                onPressed: () => _seekTo(_position - 10),
                icon: Icon(
                  Icons.replay_10,
                  color: Colors.white,
                  size: 8.w,
                ),
              ),

              SizedBox(width: 4.w),

              // Play/Pause button
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 15.w,
                  height: 15.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 8.w,
                  ),
                ),
              ),

              SizedBox(width: 4.w),

              // Forward button
              IconButton(
                onPressed: () => _seekTo(_position + 10),
                icon: Icon(
                  Icons.forward_10,
                  color: Colors.white,
                  size: 8.w,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeControl() {
    return Positioned(
      right: 4.w,
      top: 4.h,
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(179),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _volume > 0.5
                  ? Icons.volume_up
                  : _volume > 0
                      ? Icons.volume_down
                      : Icons.volume_off,
              color: Colors.white,
              size: 6.w,
            ),
            SizedBox(height: 2.h),
            RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: _volume,
                  onChanged: _setVolume,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withAlpha(179),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  _formatDuration(_position),
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    child: LinearProgressIndicator(
                      value: _duration > 0 ? _position / _duration : 0,
                      backgroundColor: Colors.white.withAlpha(77),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.primaryColor,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAntiManipulationOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                color: Colors.white.withAlpha(179),
                size: 6.w,
              ),
              SizedBox(height: 1.h),
              Text(
                'Controls disabled during reward period',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withAlpha(179),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
