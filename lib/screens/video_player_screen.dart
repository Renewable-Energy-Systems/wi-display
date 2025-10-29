import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String videoPath; // "http...", "file:///...", "assets/..."

  const VideoPlayerScreen({
    super.key,
    required this.title,
    required this.videoPath,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // keep the tablet awake during playback
    WakelockPlus.enable();
    _setupControllers();
  }

  Future<void> _setupControllers() async {
    // 1. choose controller
    if (widget.videoPath.startsWith('http')) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoPath),
      );
    } else if (widget.videoPath.startsWith('file://')) {
      final file = File(Uri.parse(widget.videoPath).toFilePath());
      _videoController = VideoPlayerController.file(file);
    } else if (widget.videoPath.startsWith('assets/')) {
      _videoController = VideoPlayerController.asset(widget.videoPath);
    } else {
      // assume raw file path like /storage/emulated/0/...
      _videoController = VideoPlayerController.file(File(widget.videoPath));
    }

    // 2. init video
    await _videoController!.initialize();

    // 3. wrap with Chewie
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowPlaybackSpeedChanging: false,
      allowMuting: true,
      showControlsOnInitialize: true,
    );

    setState(() {
      _ready = true;
    });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: _ready && _chewieController != null
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(),
      ),
    );
  }
}
