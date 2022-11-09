import 'dart:io';

class PackageData {
  final File pubspecFile;
  final List<File> dartFiles;

  PackageData({
    required this.pubspecFile,
    required this.dartFiles,
  });
}
