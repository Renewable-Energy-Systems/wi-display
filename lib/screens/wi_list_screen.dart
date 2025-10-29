import 'package:flutter/material.dart';
import '../models/work_instruction.dart';
import '../widgets/wi_card.dart';
import 'video_player_screen.dart';

class WIListScreen extends StatelessWidget {
  const WIListScreen({super.key});

  // Demo static list
  List<WorkInstruction> _demoWI() {
    return const [
      WorkInstruction(
        id: 'WI-ANODE-PRESS-001',
        title: 'Anode Pellet Pressing',
        description:
            'Die setup, press tonnage, eject handling. Follow dry-box protocol.',
        videoPath: 'file:///storage/emulated/0/kiosk_videos/anode_press.mp4',
      ),
      WorkInstruction(
        id: 'WI-STACK-ASM-002',
        title: 'Stack Assembly Procedure',
        description: 'Electrolyte separator placement and cathode orientation.',
        videoPath: 'file:///storage/emulated/0/kiosk_videos/stack_asm.mp4',
      ),
      WorkInstruction(
        id: 'WI-GB-ENTRY-003',
        title: 'Glovebox Entry & Log Sheet',
        description: 'How to purge, take reading, update log.',
        videoPath: 'file:///storage/emulated/0/kiosk_videos/glovebox_log.mp4',
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
