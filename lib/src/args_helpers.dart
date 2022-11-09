import 'dart:io';

import 'package:yaml/yaml.dart';

List<String> getArgList({
  required String pubspecPath,
  required String configName,
  required String argName,
}) {
  final pubspecYaml = loadYaml(File(pubspecPath).readAsStringSync());

  if (pubspecYaml.containsKey(configName)) {
    final config = pubspecYaml[configName];
    if (config.containsKey(argName)) {
      final yamlList = config[argName];
      return List<String>.from(yamlList);
    }
  }
  return [];
}
