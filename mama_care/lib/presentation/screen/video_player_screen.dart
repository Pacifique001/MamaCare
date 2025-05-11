import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:flutter/services.dart'; // For device orientation

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl; // Full URL or just the ID
  final String? videoTitle; // Optional title for the video

  const VideoPlayerScreen({super.key, required this.videoUrl, this.videoTitle});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isFullScreen = false;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();

    // Set preferred orientations for better video viewing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _initializePlayer() {
    final String? videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    if (videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          showLiveFullscreenButton: true,
          forceHD: false, // Set to true if you want to force HD
          hideControls: false,
          disableDragSeek: false,
          loop: false,
        ),
      );

      // Listen to player state changes
      _controller.addListener(_playerListener);
    } else {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = "Invalid YouTube URL: ${widget.videoUrl}";
      });

      // Show error after frame is built
      _showErrorAndNavigateBack();
    }
  }

  void _playerListener() {
    if (_controller.value.hasError) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = "An error occurred while playing the video";
      });
    }

    // Track loading state
    if (_controller.value.isReady && _isLoading) {
      setState(() {
        _isLoading = false;
      });
    }

    // Track fullscreen state
    if (_controller.value.isFullScreen != _isFullScreen) {
      setState(() {
        _isFullScreen = _controller.value.isFullScreen;
      });
    }
  }

  void _showErrorAndNavigateBack() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
            duration: const Duration(seconds: 5),
          ),
        );

        // Give user some time to read the error before navigating back
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    });
  }

  void _toggleFullScreen() {
    if (_isFullScreen) {
      // Exit full screen
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      setState(() {
        _isFullScreen = false;
      });
    } else {
      // Enter full screen
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      setState(() {
        _isFullScreen = true;
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
  }

  @override
  void dispose() {
    // Restore preferred orientations
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Dispose controller if initialized
    if (!_hasError) {
      _controller.removeListener(_playerListener);
      _controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _toggleFullScreen();
          return false;
        }
        return true;
      },
      child: YoutubePlayerBuilder(
        // Use YoutubePlayerBuilder for better fullscreen handling
        onExitFullScreen: () {
          // The player forces portrait when exiting fullscreen
          // This fixes that by setting orientations again
          if (_isFullScreen) {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
          } else {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
          }
        },
        onEnterFullScreen: () {
          setState(() {
            _isFullScreen = true;
          });
        },
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Theme.of(context).primaryColor,
          progressColors: ProgressBarColors(
            playedColor: Theme.of(context).primaryColor,
            handleColor: Theme.of(context).primaryColorDark,
          ),
          bottomActions: [
            // Customize controls
            CurrentPosition(),
            const SizedBox(width: 10),
            ProgressBar(
              isExpanded: true,
              colors: ProgressBarColors(
                playedColor: Theme.of(context).primaryColor,
                handleColor: Theme.of(context).primaryColorDark,
                bufferedColor: Theme.of(context).primaryColorLight,
                backgroundColor: Colors.grey[300],
              ),
            ),
            const SizedBox(width: 10),
            RemainingDuration(),
            // Add FullscreenButton() by default
          ],
          onReady: () {
            setState(() {
              _isLoading = false;
            });
            print('Player is ready');
          },
          topActions: [
            // Optional title display at the top
            if (widget.videoTitle != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    widget.videoTitle!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
          ],
          bufferIndicator: const Center(child: CircularProgressIndicator()),
          aspectRatio: _isFullScreen ? 16 / 9 : 16 / 9,
        ),
        builder: (context, player) {
          return Scaffold(
            extendBodyBehindAppBar: _isFullScreen,
            extendBody: _isFullScreen,
            backgroundColor: Colors.black,
            appBar:
                _isFullScreen
                    ? null
                    : MamaCareAppBar(
                      title: widget.videoTitle ?? "Video Player",
                    ),
            body: GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                children: [
                  // Player takes priority in the layout
                  _isFullScreen
                      ? Center(
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.black,
                          child: player,
                        ),
                      )
                      : Column(
                        children: [
                          player,
                          // Show loading indicator or error message
                          if (_isLoading && !_hasError)
                            const Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                      "Loading video...",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Error view with retry option
                          if (_hasError)
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 60,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _isLoading = true;
                                          _hasError = false;
                                        });
                                        _initializePlayer();
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text("Try Again"),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Video playback controls (outside YouTube player)
                          if (!_isLoading && !_hasError && !_isFullScreen)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.videoTitle != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12.0,
                                          ),
                                          child: Text(
                                            widget.videoTitle!,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              _controller.value.isPlaying
                                                  ? Icons.pause_circle_filled
                                                  : Icons.play_circle_filled,
                                              size: 36,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColor,
                                            ),
                                            onPressed: () {
                                              if (_controller.value.isPlaying) {
                                                _controller.pause();
                                              } else {
                                                _controller.play();
                                              }
                                              setState(() {});
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.replay_10,
                                              size: 36,
                                            ),
                                            onPressed: () {
                                              final newPosition =
                                                  _controller.value.position -
                                                  const Duration(seconds: 10);
                                              _controller.seekTo(newPosition);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.forward_10,
                                              size: 36,
                                            ),
                                            onPressed: () {
                                              final newPosition =
                                                  _controller.value.position +
                                                  const Duration(seconds: 10);
                                              _controller.seekTo(newPosition);
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              _controller.value.volume > 0
                                                  ? Icons.volume_up
                                                  : Icons.volume_off,
                                              size: 36,
                                            ),
                                            onPressed: () {
                                              if (_controller.value.volume >
                                                  0) {
                                                _controller.mute();
                                              } else {
                                                _controller.unMute();
                                              }
                                              setState(() {});
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.fullscreen,
                                              size: 36,
                                            ),
                                            onPressed: _toggleFullScreen,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                  // Custom fullscreen controls overlay
                  if (_isFullScreen && _controlsVisible)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black38,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: _toggleFullScreen,
                            ),
                            if (widget.videoTitle != null)
                              Expanded(
                                child: Text(
                                  widget.videoTitle!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _controller.value.volume > 0
                                        ? Icons.volume_up
                                        : Icons.volume_off,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    if (_controller.value.volume > 0) {
                                      _controller.mute();
                                    } else {
                                      _controller.unMute();
                                    }
                                    setState(() {});
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.fullscreen_exit,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: _toggleFullScreen,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Custom playback control overlay in fullscreen
                  if (_isFullScreen && _controlsVisible)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Progress bar
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
                                thumbColor: Theme.of(context).primaryColor,
                                activeTrackColor:
                                    Theme.of(context).primaryColor,
                                inactiveTrackColor: Colors.white30,
                              ),
                              child: Slider(
                                value:
                                    _controller.value.position.inSeconds
                                        .toDouble(),
                                min: 0,
                                max:
                                    _controller.metadata.duration.inSeconds
                                        .toDouble(),
                                onChanged: (value) {
                                  _controller.seekTo(
                                    Duration(seconds: value.toInt()),
                                  );
                                },
                              ),
                            ),

                            // Time and controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Duration texts
                                Row(
                                  children: [
                                    Text(
                                      _formatDuration(
                                        _controller.value.position,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Text(
                                      ' / ',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(
                                        _controller.metadata.duration,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),

                                // Playback controls
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.replay_10,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      onPressed: () {
                                        final newPosition =
                                            _controller.value.position -
                                            const Duration(seconds: 10);
                                        _controller.seekTo(newPosition);
                                      },
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      iconSize: 60,
                                      icon: Icon(
                                        _controller.value.isPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        if (_controller.value.isPlaying) {
                                          _controller.pause();
                                        } else {
                                          _controller.play();
                                        }
                                        setState(() {});
                                      },
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.forward_10,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      onPressed: () {
                                        final newPosition =
                                            _controller.value.position +
                                            const Duration(seconds: 10);
                                        _controller.seekTo(newPosition);
                                      },
                                    ),
                                  ],
                                ),

                                // Placeholder to maintain alignment
                                const SizedBox(width: 80),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}
