import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String
  videoPath; // "file:///...", "/storage/...mp4", "assets/...mp4", or "http..."

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
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _init();
  }

  Future<void> _init() async {
    // 1. Ask for storage permission if we are trying to read from external storage
    final needsStorage =
        widget.videoPath.startsWith('/storage/') ||
        widget.videoPath.startsWith('file:///storage');

    if (needsStorage) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        setState(() {
          _errorText = 'Storage permission denied.\nCannot open video.';
        });
        return;
      }
    }

    // 2. Build the proper controller
    try {
      _videoController = await _buildController(widget.videoPath);

      // 3. Initialize
      await _videoController!.initialize();

      // 4. Wrap Chewie
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
    } catch (e) {
      setState(() {
        _errorText = 'Could not load video:\n$e';
      });
    }
  }

  Future<VideoPlayerController> _buildController(String path) async {
    // network URL?
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return VideoPlayerController.networkUrl(Uri.parse(path));
    }

    // file:// URI?
    if (path.startsWith('file://')) {
      final file = File(Uri.parse(path).toFilePath());
      return VideoPlayerController.file(file);
    }

    // absolute device path? (/storage/emulated/0/...)
    if (path.startsWith('/storage/')) {
      final file = File(path);
      return VideoPlayerController.file(file);
    }

    // bundled asset?
    if (path.startsWith('assets/')) {
      return VideoPlayerController.asset(path);
    }

    // fallback: try raw as file
    return VideoPlayerController.file(File(path));
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
    final header = AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(widget.title, style: const TextStyle(color: Colors.white)),
    );

    if (_errorText != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: header,
        body: Center(
          child: Text(
            _errorText!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_ready || _chewieController == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: header,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: header,
      body: Center(child: Chewie(controller: _chewieController!)),
    );
  }
}
