// Web download impl: build a Blob, attach an invisible anchor, click it,
// then revoke the object URL. The browser's normal download UI does the
// rest.
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import 'download_helper.dart';

Future<DownloadResult> platformDownload({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final blob = html.Blob(<dynamic>[bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  try {
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  } finally {
    html.Url.revokeObjectUrl(url);
  }
  return DownloadResult(filename: filename);
}
