class BackupSnapshot {
  const BackupSnapshot({
    required this.path,
    required this.fileName,
    required this.createdAt,
    required this.sizeBytes,
  });

  final String path;
  final String fileName;
  final DateTime createdAt;
  final int sizeBytes;

  String get sizeLabel {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    }
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
