import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../images/app_remote_or_asset_image.dart';

/// Checks if a path points to a video file or Cloudinary video URL.
bool isRecipeVideoPath(String path) {
  final trimmed = path.trim().toLowerCase();

  // Return false for empty paths.
  if (trimmed.isEmpty) return false;

  // Check for Cloudinary video URL pattern.
  if (trimmed.contains('/video/upload/')) return true;

  // Check for video file extensions.
  final uri = Uri.tryParse(trimmed);
  final pathOnly = uri?.path.toLowerCase() ?? trimmed.split('?').first;

  return const [
    '.mp4',
    '.mov',
    '.m4v',
    '.webm',
    '.mkv',
    '.avi',
    '.3gp',
  ].any(pathOnly.endsWith);
}

/// Returns a static image preview path for video media when one can be derived.
String recipeMediaStaticPreviewPath(String path) {
  final trimmed = path.trim();
  if (!isRecipeVideoPath(trimmed)) return trimmed;

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return trimmed;

  final videoUploadIndex = uri.path.indexOf('/video/upload/');
  if (videoUploadIndex < 0) return trimmed;

  final previewPath = uri.path.replaceFirst(
    '/video/upload/',
    '/video/upload/so_0/',
  );
  final withImageExtension = previewPath.replaceFirst(
    RegExp(r'\.(mp4|mov|m4v|webm|mkv|avi|3gp)$', caseSensitive: false),
    '.jpg',
  );

  return uri.replace(path: withImageExtension).toString();
}

/// Widget for displaying recipe media (images or videos).
/// Automatically detects video paths and uses VideoPlayer.
class AppRecipeMedia extends StatelessWidget {
  /// Path to the media (image URL, asset path, or video URL).
  final String mediaPath;

  /// Box fit for the media.
  final BoxFit fit;

  /// Whether to show video controls.
  final bool showVideoControls;

  /// Whether to auto-play videos.
  final bool autoPlayVideo;

  /// Whether to loop videos.
  final bool loopVideo;

  /// Whether to allow fullscreen mode.
  final bool allowFullscreen;

  /// Whether the video is currently in fullscreen.
  final bool isFullscreen;

  /// Callback when fullscreen is toggled.
  final VoidCallback? onFullscreenTap;

  /// Optional width of the media.
  final double? width;

  /// Optional height of the media.
  final double? height;

  /// Creates a new app recipe media instance.
  const AppRecipeMedia({
    super.key,
    required this.mediaPath,
    this.fit = BoxFit.cover,
    this.showVideoControls = false,
    this.autoPlayVideo = false,
    this.loopVideo = true,
    this.allowFullscreen = false,
    this.isFullscreen = false,
    this.onFullscreenTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the path is a video.
    if (isRecipeVideoPath(mediaPath)) {
      return _RecipeVideoPlayer(
        mediaPath: mediaPath,
        fit: fit,
        showControls: showVideoControls,
        autoPlay: autoPlayVideo,
        loop: loopVideo,
        allowFullscreen: allowFullscreen,
        isFullscreen: isFullscreen,
        onFullscreenTap: onFullscreenTap,
      );
    }

    // Display as image.
    return AppRemoteOrAssetImage(
      imagePath: mediaPath,
      width: width,
      height: height,
      fit: fit,
    );
  }
}

/// Preview widget for recipe media with a play overlay for videos.
class AppRecipeMediaPreview extends StatelessWidget {
  /// Path to the media.
  final String mediaPath;

  /// Box fit for the media.
  final BoxFit fit;

  /// Size of the play overlay.
  final double playOverlaySize;

  /// Size of the play icon.
  final double playIconSize;

  /// Whether video previews display the play overlay.
  final bool showPlayOverlay;

  /// Creates a new app recipe media preview instance.
  const AppRecipeMediaPreview({
    super.key,
    required this.mediaPath,
    this.fit = BoxFit.cover,
    this.playOverlaySize = 46,
    this.playIconSize = 30,
    this.showPlayOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    // Display image without overlay.
    if (!isRecipeVideoPath(mediaPath)) {
      return AppRecipeMedia(mediaPath: mediaPath, fit: fit);
    }

    if (!showPlayOverlay) {
      return AppRecipeMedia(mediaPath: mediaPath, fit: fit);
    }

    // Display video with play overlay.
    return Stack(
      fit: StackFit.expand,
      children: [
        AppRecipeMedia(mediaPath: mediaPath, fit: fit),
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.52),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: playOverlaySize,
              height: playOverlaySize,
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: playIconSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows a fullscreen dialog for viewing media.
Future<void> showRecipeMediaDialog(
  BuildContext context,
  String mediaPath,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              // Media content.
              Center(
                child: mediaPath.trim().isEmpty
                    ? const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white70,
                        size: 56,
                      )
                    : isRecipeVideoPath(mediaPath)
                    ? AppRecipeMedia(
                        mediaPath: mediaPath,
                        fit: BoxFit.contain,
                        showVideoControls: true,
                        autoPlayVideo: true,
                        allowFullscreen: true,
                        isFullscreen: true,
                        onFullscreenTap: () =>
                            Navigator.of(dialogContext).pop(),
                      )
                    : InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: AppRecipeMedia(
                          mediaPath: mediaPath,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
              // Close button.
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Internal video player widget.
class _RecipeVideoPlayer extends StatefulWidget {
  final String mediaPath;
  final BoxFit fit;
  final bool showControls;
  final bool autoPlay;
  final bool loop;
  final bool allowFullscreen;
  final bool isFullscreen;
  final VoidCallback? onFullscreenTap;

  const _RecipeVideoPlayer({
    required this.mediaPath,
    required this.fit,
    required this.showControls,
    required this.autoPlay,
    required this.loop,
    required this.allowFullscreen,
    required this.isFullscreen,
    required this.onFullscreenTap,
  });

  @override
  State<_RecipeVideoPlayer> createState() => _RecipeVideoPlayerState();
}

/// State for the recipe video player.
class _RecipeVideoPlayerState extends State<_RecipeVideoPlayer> {
  /// Video player controller.
  VideoPlayerController? _controller;

  /// Future for initialization.
  Future<void>? _initializeFuture;

  /// Whether to ignore the next tap.
  bool _ignoreNextTap = false;

  /// Seek feedback state.
  _SeekFeedback? _seekFeedback;

  /// Token for seek feedback.
  int _seekFeedbackToken = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant _RecipeVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reinitialize if media path changed.
    if (oldWidget.mediaPath != widget.mediaPath) {
      _controller?.dispose();
      _initialize();
    }
  }

  /// Initializes the video player.
  void _initialize() {
    final path = widget.mediaPath.trim();
    final controller = _createController(path);

    _controller = controller;
    _initializeFuture = controller.initialize().then((_) async {
      await controller.setLooping(widget.loop);
      if (!widget.showControls) {
        await controller.setVolume(0);
      }
      if (widget.autoPlay) {
        await controller.play();
      }
      if (mounted) setState(() {});
    });
  }

  /// Creates a video player controller based on the path type.
  VideoPlayerController _createController(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return VideoPlayerController.networkUrl(Uri.parse(path));
    }
    if (File(path).existsSync()) {
      return VideoPlayerController.file(File(path));
    }
    return VideoPlayerController.asset(path);
  }

  /// Toggles play/pause.
  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  /// Sets the volume.
  Future<void> _setVolume(double volume) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.setVolume(volume.clamp(0, 1).toDouble());
  }

  /// Seeks by a duration offset.
  Future<void> _seekBy(Duration offset) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final duration = controller.value.duration;
    final current = controller.value.position;
    var next = current + offset;

    if (next < Duration.zero) next = Duration.zero;
    if (duration > Duration.zero && next > duration) next = duration;

    await controller.seekTo(next);
  }

  /// Handles double tap for seeking.
  Future<void> _handleDoubleTapDown(TapDownDetails details) async {
    // Set ignore flag to prevent single tap after double tap.
    _ignoreNextTap = true;
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _ignoreNextTap = false;
    });

    // Determine which side was tapped.
    final renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 0;
    if (width <= 0) return;

    final isRightSide = details.localPosition.dx >= width / 2;

    // Show seek feedback.
    final token = ++_seekFeedbackToken;
    setState(() {
      _seekFeedback = _SeekFeedback(isForward: isRightSide);
    });

    // Hide feedback after delay.
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted && token == _seekFeedbackToken) {
        setState(() => _seekFeedback = null);
      }
    });

    // Seek forward or backward.
    await _seekBy(Duration(seconds: isRightSide ? 10 : -10));
  }

  /// Handles single tap.
  void _handleTap() {
    if (_ignoreNextTap) {
      _ignoreNextTap = false;
      return;
    }
    _togglePlayback();
  }

  /// Opens fullscreen mode.
  Future<void> _openFullscreen() async {
    if (widget.isFullscreen) {
      widget.onFullscreenTap?.call();
      return;
    }

    if (widget.onFullscreenTap != null) {
      widget.onFullscreenTap!();
      return;
    }

    // Pause video before showing fullscreen.
    final controller = _controller;
    if (controller?.value.isInitialized == true) {
      await controller!.pause();
    }

    if (!mounted) return;
    await showRecipeMediaDialog(context, widget.mediaPath);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    // Show fallback if controller is null.
    if (controller == null) return const _VideoFallback();

    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        // Show fallback on error.
        if (snapshot.hasError) {
          return const _VideoFallback();
        }

        // Show loading state.
        if (snapshot.connectionState != ConnectionState.done ||
            !controller.value.isInitialized) {
          return const _VideoFallback(isLoading: true);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.showControls ? _handleTap : null,
          onDoubleTapDown: widget.showControls ? _handleDoubleTapDown : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video content.
              FittedBox(
                fit: widget.fit,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
              // Seek feedback overlay.
              if (_seekFeedback != null)
                _SeekFeedbackOverlay(feedback: _seekFeedback!),
              // Video controls.
              if (widget.showControls)
                _VideoControls(
                  controller: controller,
                  onTogglePlayback: _togglePlayback,
                  onVolumeChanged: _setVolume,
                  isFullscreen: widget.isFullscreen,
                  onFullscreen: widget.allowFullscreen ? _openFullscreen : null,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Seek feedback data class.
class _SeekFeedback {
  /// Whether seeking forward.
  final bool isForward;

  /// Creates a new seek feedback instance.
  const _SeekFeedback({required this.isForward});
}

/// Seek feedback overlay widget.
class _SeekFeedbackOverlay extends StatelessWidget {
  /// The seek feedback data.
  final _SeekFeedback feedback;

  /// Creates a new seek feedback overlay instance.
  const _SeekFeedbackOverlay({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: feedback.isForward
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(48),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  feedback.isForward ? '>>' : '<<',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '10s',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Video controls widget.
class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onTogglePlayback;
  final ValueChanged<double> onVolumeChanged;
  final bool isFullscreen;
  final VoidCallback? onFullscreen;

  const _VideoControls({
    required this.controller,
    required this.onTogglePlayback,
    required this.onVolumeChanged,
    required this.isFullscreen,
    required this.onFullscreen,
  });

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

/// State for video controls.
class _VideoControlsState extends State<_VideoControls> {
  /// Whether to show the volume slider.
  bool _showVolumeSlider = false;

  /// Toggles the volume slider visibility.
  void _toggleVolumeSlider() {
    setState(() => _showVolumeSlider = !_showVolumeSlider);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final value = widget.controller.value;
        final duration = value.duration;
        final position = value.position > duration && duration > Duration.zero
            ? duration
            : value.position;
        final volume = value.volume.clamp(0.0, 1.0).toDouble();

        return Stack(
          children: [
            // Play button overlay when paused.
            if (!value.isPlaying)
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.56),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: widget.onTogglePlayback,
                    icon: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
            // Controls bar at bottom.
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.64),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress bar.
                      VideoProgressIndicator(
                        widget.controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Control buttons row.
                      Row(
                        children: [
                          // Play/Pause button.
                          _VideoControlButton(
                            tooltip: 'Play or pause',
                            icon: value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            onPressed: widget.onTogglePlayback,
                          ),
                          // Volume button.
                          _VideoControlButton(
                            tooltip: 'Volume',
                            icon: volume == 0
                                ? Icons.volume_off
                                : Icons.volume_up,
                            onPressed: _toggleVolumeSlider,
                          ),
                          // Volume slider (animated).
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return SizeTransition(
                                sizeFactor: animation,
                                axis: Axis.horizontal,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: _showVolumeSlider
                                ? SizedBox(
                                    key: const ValueKey('volume-slider'),
                                    width: 78,
                                    child: SliderTheme(
                                      data: _volumeSliderTheme(context),
                                      child: Slider(
                                        value: volume,
                                        min: 0,
                                        max: 1,
                                        onChanged: widget.onVolumeChanged,
                                      ),
                                    ),
                                  )
                                : const SizedBox(
                                    key: ValueKey('volume-slider-hidden'),
                                    width: 0,
                                  ),
                          ),
                          // Time display.
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 86),
                            child: Text(
                              '${_formatDuration(position)}/${_formatDuration(duration)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Fullscreen button.
                          if (widget.onFullscreen != null)
                            _VideoControlButton(
                              tooltip: widget.isFullscreen
                                  ? 'Exit full screen'
                                  : 'Full screen',
                              icon: widget.isFullscreen
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                              onPressed: widget.onFullscreen!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Formats a duration as MM:SS.
  static String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Returns the volume slider theme.
  SliderThemeData _volumeSliderTheme(BuildContext context) {
    return SliderTheme.of(context).copyWith(
      trackHeight: 2,
      trackShape: const RoundedRectSliderTrackShape(),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
      activeTrackColor: Colors.white,
      inactiveTrackColor: Colors.white24,
      thumbColor: Colors.white,
    );
  }
}

/// Video control button widget.
class _VideoControlButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _VideoControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

/// Video fallback widget.
class _VideoFallback extends StatelessWidget {
  /// Whether loading.
  final bool isLoading;

  /// Creates a new video fallback instance.
  const _VideoFallback({this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFEDEFF2),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(strokeWidth: 2)
            : const Icon(Icons.videocam_off_outlined),
      ),
    );
  }
}
