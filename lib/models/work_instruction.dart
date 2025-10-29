class WorkInstruction {
  final String id;
  final String title;
  final String description;
  final String
  videoPath; // can be 'file:///storage/emulated/0/...mp4' OR 'assets/videos/x.mp4' OR network URL
  final String thumbnail; // optional future use

  const WorkInstruction({
    required this.id,
    required this.title,
    required this.description,
    required this.videoPath,
    this.thumbnail = '',
  });
}
