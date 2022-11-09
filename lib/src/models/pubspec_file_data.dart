import 'dart:io';

class PubspecFileData {
  final File file;
  final List<File> packageFiles;

  PubspecFileData({
    required this.file,
    required this.packageFiles,
  });
}
