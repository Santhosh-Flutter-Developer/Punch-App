import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> writeFileBytes(String path, Uint8List bytes) async {
  await File(path).writeAsBytes(bytes, flush: true);
}

/// Saves the file to the public Downloads folder (Android) or temp dir (iOS),
/// then triggers the OS share/save sheet so the user can save it to Files.
Future<void> saveToDownloadsAndShare(Uint8List bytes, String filename) async {
  String filePath;

  if (Platform.isAndroid) {
    // Save directly to /storage/emulated/0/Download — always visible in Files
    const downloadsPath = '/storage/emulated/0/Download';
    final dir = Directory(downloadsPath);
    if (!dir.existsSync()) {
      // Fallback: app documents dir
      final appDir = await getApplicationDocumentsDirectory();
      filePath = '${appDir.path}/$filename';
    } else {
      filePath = '$downloadsPath/$filename';
    }
  } else {
    // iOS: save to temp then share so user can pick destination (Files, etc.)
    final tempDir = await getTemporaryDirectory();
    filePath = '${tempDir.path}/$filename';
  }

  final file = File(filePath);
  await file.writeAsBytes(bytes, flush: true);

  // Share sheet — on Android lets user open/save; on iOS lets user pick Files location
  await Share.shareXFiles([XFile(filePath)], subject: filename);
}
