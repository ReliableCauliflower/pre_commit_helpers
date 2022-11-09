import 'dart:io';

import 'package:yaml/yaml.dart';

class PackageData {
  final File pubspecFile;
  final List<File> dartFiles;

  String get packageName {
    final pubspecYaml = loadYaml(pubspecFile.readAsStringSync());
    return pubspecYaml['name'];
  }

  PackageData({
    required this.pubspecFile,
    required this.dartFiles,
  });
}
