import 'dart:io';

import 'package:path/path.dart';
import 'models/package_data.dart';

/// Get the project pubspec file(s) and a list of related dart files. The
/// current algorithm assumes that pubspec.yaml files do not exist in the
/// same folder with dart files
List<PackageData> getPackagesData({
  required String currentPath,
  List<String> additionalPaths = const [],
  List<String> ignorePaths = const [],
}) {
  final basePubspecPath = getPubspecPath(currentPath);
  final packagesDartFiles = <String, List<File>>{
    basePubspecPath: _getPackageBaseFiles(currentPath),
  };

  void addFile(String pubspecPath, File file) {
    if (packagesDartFiles[pubspecPath] == null) {
      packagesDartFiles[pubspecPath] = [file];
    } else {
      packagesDartFiles[pubspecPath]!.add(file);
    }
  }

  _handleAdditionalPaths(
    packagePath: currentPath,
    onPubspecFile: (file) {
      final pubspecPath = file.path;
      final packagePath = dirname(pubspecPath);
      if (!_isIgnore(
        packagePath: packagePath,
        filePath: pubspecPath,
        ignorePaths: ignorePaths,
      )) {
        packagesDartFiles[pubspecPath] = _getPackageBaseFiles(file.parent.path);
      }
    },
    onDartFile: (file, pubspecPath) {
      final packagePath = dirname(pubspecPath);
      if (!_isIgnore(
        packagePath: packagePath,
        filePath: file.path,
        ignorePaths: ignorePaths,
      )) {
        addFile(pubspecPath, file);
      }
    },
  );

  final List<PackageData> pubspecFilesData = [];

  for (final entry in packagesDartFiles.entries) {
    pubspecFilesData.add(PackageData(
      pubspecFile: File(entry.key),
      dartFiles: entry.value,
    ));
  }

  return pubspecFilesData;
}

bool _isIgnore({
  required String packagePath,
  required String filePath,
  required List<String> ignorePaths,
}) {
  String fileRelativePath = packagePath.replaceFirst(packagePath, '');
  if (fileRelativePath.startsWith(separator)) {
    fileRelativePath = fileRelativePath.substring(1);
  }
  for (String ignorePath in ignorePaths) {
    if (ignorePath.startsWith(separator)) {
      ignorePath = ignorePath.substring(1);
    }
    if (fileRelativePath.startsWith(ignorePath)) {
      return true;
    }
  }
  return false;
}

void _handleAdditionalPaths({
  required String packagePath,
  void Function(File pubspecFile)? onPubspecFile,
  void Function(File dartFile, String pubspecPath)? onDartFile,
  List<String> additionalPaths = const [],
}) {
  final pubspecPath = getPubspecPath(packagePath);

  void checkDir(String dirPath) {
    final contents = _readDir(
      dirPath,
      recursive: false,
      withDirs: true,
    )..sort((a, b) {
        if (a is File) {
          return -1;
        }
        if (b is File) {
          return 1;
        }
        return 0;
      });
    for (final fileEntity in contents) {
      final fileEntityPath = fileEntity.path;
      if (fileEntity is File) {
        if (_isPubspecFile(fileEntityPath)) {
          onPubspecFile?.call(fileEntity);
          _handleAdditionalPaths(packagePath: dirPath);
          return;
        } else {
          onDartFile?.call(fileEntity, pubspecPath);
        }
      } else if (fileEntity is Directory) {
        checkDir(fileEntity.path);
      }
    }
  }

  for (final path in additionalPaths) {
    checkDir('$packagePath$separator$path');
  }
}

List<File> _getPackageBaseFiles(String packagePath) {
  String getSubDir(String subDirName) {
    return '$packagePath$separator$subDirName';
  }

  return [
    ..._readDir(getSubDir('lib')),
    ..._readDir(getSubDir('bin')),
    ..._readDir(getSubDir('test')),
    ..._readDir(getSubDir('tests')),
    ..._readDir(getSubDir('test_driver')),
    ..._readDir(getSubDir('integration_test')),
  ].cast<File>();
}

List<FileSystemEntity> _readDir(
  String dirPath, {
  bool recursive: true,
  bool withDirs: false,
}) {
  final dir = Directory(dirPath);
  if (dir.existsSync()) {
    return dir
        .listSync(recursive: recursive)
        .where((el) => withDirs ? true : el is! Directory)
        .where((el) {
      if (withDirs && el is Directory) {
        return true;
      }
      final filePath = el.path;
      return _isPubspecFile(filePath) || _isDartFile(filePath);
    }).toList();
  }
  return [];
}

bool _isPubspecFile(String path) {
  return path.endsWith('pubspec.yaml');
}

bool _isDartFile(String path) {
  return path.endsWith('.dart');
}

String getPubspecPath(String packagePath) {
  return '$packagePath${separator}pubspec.yaml';
}
