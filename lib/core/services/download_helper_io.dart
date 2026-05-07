// Native (mobile / desktop) download impl: write the bytes to the OS
// temp dir and return the absolute path. The caller surfaces it via a
// snackbar so the user can find / share the saved file.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'download_helper.dart';

Future<DownloadResult> platformDownload({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$filename';
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return DownloadResult(filename: filename, savedPath: path);
}
