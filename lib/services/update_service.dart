import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:ota_update/ota_update.dart'; // Keeping for UI compatibility (OtaEvent)
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  // Check for updates
  Future<Map<String, dynamic>?> checkForUpdate(String baseUrl) async {
    try {
      if (!baseUrl.endsWith('/')) baseUrl = '$baseUrl/';
      final url = Uri.parse('${baseUrl}metadata.json');
      print('Checking updates at $url');
      
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        String jsonStr = utf8.decode(response.bodyBytes);
        // Strip BOM if present
        if (jsonStr.startsWith('\ufeff')) {
          jsonStr = jsonStr.substring(1);
        }
        final data = json.decode(jsonStr);
        final latestVersion = data['version'];
        final hash = data['hash']; // SHA-256 hash
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        
        print('Current: $currentVersion, Latest: $latestVersion');
        
        if (_isNewer(latestVersion, currentVersion)) {
          return {
            'updateAvailable': true,
            'latestVersion': latestVersion,
            'currentVersion': currentVersion,
            'apkUrl': '${baseUrl}${data['apkUrl']}',
            'hash': hash,
            'releaseNotes': data['releaseNotes'] ?? 'Automated update.',
          };
        } else {
             return {
            'updateAvailable': false,
            'currentVersion': currentVersion,
          };
        }
      }
    } catch (e) {
      print('Update check failed: $e');
      return {'error': e.toString()};
    }
    return null;
  }

  bool _isNewer(String latest, String current) {
    List<int> l = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> c = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
        int lv = (i < l.length) ? l[i] : 0;
        int cv = (i < c.length) ? c[i] : 0;
        if (lv > cv) return true;
        if (lv < cv) return false;
    }
    return false;
  }

  // Secure Update Flow
  Stream<OtaEvent> runUpdate(String apkUrl, {String? expectedHash}) async* {
    yield OtaEvent(OtaStatus.DOWNLOADING, '0');

    try {
      // 1. Prepare Path
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/update.apk';
      
      // 2. Download
      final dio = Dio();
      await dio.download(
        apkUrl, 
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
             final progress = (received / total * 100).toStringAsFixed(0);
             // We can't yield from within a callback comfortably in async*, 
             // but strictly speaking we should just let the stream controller handle it or ignore smooth progress for now
             // For simplicity in async* generator, we might verify if we can yield. 
             // Actually, async* doesn't allow yield here. 
             // We'll skip fine-grained progress or use a StreamController approach if strictly needed.
             // But to keep it simple, let's just use 0, 50, 100 or assume rapid wifi.
             // OR better: use a StreamController properly.
          }
        },
      );
      // Simulating progress for UX since we can't yield in callback easily without StreamController
      yield OtaEvent(OtaStatus.DOWNLOADING, '100');
      
      // 3. Verify Hash (Integrity Check)
      if (expectedHash != null) {
         yield OtaEvent(OtaStatus.INSTALLING, 'Verifying...');
         final file = File(filePath);
         final digest = await sha256.bind(file.openRead()).first;
         final fileHash = digest.toString();
         
         print('File Hash: $fileHash');
         print('Expected : $expectedHash');
         
         if (fileHash.toLowerCase() != expectedHash.toLowerCase()) {
            yield OtaEvent(OtaStatus.DOWNLOAD_ERROR, 'Hash Mismatch! Security Alert.');
            return;
         }
      }

      // 4. Install
      yield OtaEvent(OtaStatus.INSTALLING, 'Installing...');
      final result = await OpenFilex.open(filePath);
      
      if (result.type != ResultType.done) {
         yield OtaEvent(OtaStatus.INTERNAL_ERROR, 'Install failed: ${result.message}');
      }

    } catch (e) {
      yield OtaEvent(OtaStatus.INTERNAL_ERROR, e.toString());
    }
  }
}
