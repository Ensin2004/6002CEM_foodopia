import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../images/app_remote_or_asset_image.dart';

bool isRecipeVideoPath(String path) {
  final trimmed = path.trim().toLowerCase();
  if (trimmed.isEmpty) return false;
  if (trimmed.contains('/video/upload/')) return true;

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

class AppRecipeMedia extends StatelessWidget {
  final String mediaPath;
  final BoxFit fit;
  final bool showVideoControls;
  final bool autoPlayVideo;
  final bool loopVideo;
  final bool allowFullscreen;
  final bool isFullscreen;
  final VoidCallback? onFullscreenTap;
  final double? width;
  final double? height;

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

    return AppRemoteOrAssetImage(
      imagePath: mediaPath,
      width: width,
      height: height,
      fit: fit,
    );
  }
}

class AppRecipeMediaPreview extends StatelessWidget {
  final String mediaPath;
  final BoxFit fit;
  final double playOverlaySize;
  final double playIconSize;

  const AppRecipeMediaPreview({
    super.key,
    required this.mediaPath,
    this.fit = BoxFit.cover,
    this.playOverlaySize = 46,
    this.playIconSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRecipeVideoPath(mediaPath)) {
      return AppRecipeMedia(mediaPath: mediaPath, fit: fit);
    }

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

class _RecipeVideoPlayerState extends State<_RecipeVideoPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  bool _ignoreNextTap = false;
  _SeekFeedback? _seekFeedback;
  int _seekFeedbackToken = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant _RecipeVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaPath != widget.mediaPath) {
      _controller?.dispose();
      _initialize();
    }
  }

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

  VideoPlayerController _createController(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return VideoPlayerController.networkUrl(Uri.parse(path));
    }
    if (File(path).existsSync()) {
      return VideoPlayerController.file(File(path));
    }
    return VideoPlayerController.asset(path);
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  Future<void> _setVolume(double volume) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.setVolume(volume.clamp(0, 1).toDouble());
  }

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

  Future<void> _handleDoubleTapDown(TapDownDetails details) async {
    _ignoreNextTap = true;
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _ignoreNextTap = false;
    });
    final renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 0;
    if (width <= 0) return;

    final isRightSide = details.localPosition.dx >= width / 2;
    final token = ++_seekFeedbackToken;
    setState(() {
      _seekFeedback = _SeekFeedback(isForward: isRightSide);
    });
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted && token == _seekFeedbackToken) {
        setState(() => _seekFeedback = null);
      }
    });
    await _seekBy(Duration(seconds: isRightSide ? 10 : -10));
  }

  void _handleTap() {
    if (_ignoreNextTap) {
      _ignoreNextTap = false;
      return;
    }
    _togglePlayback();
  }

  Future<void> _openFullscreen() async {
    if (widget.isFullscreen) {
      widget.onFullscreenTap?.call();
      return;
    }

    if (widget.onFullscreenTap != null) {
      widget.onFullscreenTap!();
      return;
    }

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
    if (controller == null) return const _VideoFallback();

    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _VideoFallback();
        }

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
              FittedBox(
                fit: widget.fit,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
              if (_seekFeedback != null)
                _SeekFeedbackOverlay(feedback: _seekFeedback!),
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

class _SeekFeedback {
  final bool isForward;

  const _SeekFeedback({required this.isForward});
}

class _SeekFeedbackOverlay extends StatelessWidget {
  final _SeekFeedback feedback;

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

class _VideoControlsState extends State<_VideoControls> {
  bool _showVolumeSlider = false;

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
                      Row(
                        children: [
                          _VideoControlButton(
                            tooltip: 'Play or pause',
                            icon: value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            onPressed: widget.onTogglePlayback,
                          ),
                          _VideoControlButton(
                            tooltip: 'Volume',
                            icon: volume == 0
                                ? Icons.volume_off
                                : Icons.volume_up,
                            onPressed: _toggleVolumeSlider,
                          ),
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

  static String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

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

class _VideoFallback extends StatelessWidget {
  final bool isLoading;

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
