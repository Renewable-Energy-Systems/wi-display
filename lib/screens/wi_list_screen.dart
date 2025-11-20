import 'package:flutter/material.dart';
import '../models/work_instruction.dart';
import '../widgets/wi_card.dart';
import 'video_player_screen.dart';
import 'gauge_screen.dart'; // Import the gauge screen

class WIListScreen extends StatelessWidget {
  const WIListScreen({super.key});

  // Demo static list
  List<WorkInstruction> _demoWI() {
    return const [
      WorkInstruction(
        id: 'WI-PRD-28',
        title: 'Pellet Manufacturing',
        description: 'WI-PRD-28',
        videoPath: 'file:///storage/emulated/0/videos/pellet_manufacturing.mp4',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final wis = _demoWI();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Work Instructions',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: wis.length,
        itemBuilder: (context, index) {
          final wi = wis[index];
          return WICard(
            wi: wi,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(
                    title: wi.title,
                    videoPath: wi.videoPath,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
