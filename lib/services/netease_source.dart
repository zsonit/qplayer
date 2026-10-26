import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart';
import 'package:http/http.dart' as http;
import 'online_models.dart';
import 'online_source.dart';

const String _modulus =
    '00e0b509f6259df8642dbc35662901477df22677ec152b5ff68ace615bb7b725152b3ab17a876aea8a5aa76d2e417629ec4ee341f56135fccf695280104e0312ecbda92557c93870114af6c9d05c4f7f0c3685b7a46bee255932575cce10b424d813cfe4875d3e82047b97ddef52741d546b8e289dc6935b3ece0462db0a22b8e7';
const String _pubExp = '010001';
const String _nonce = '0CoJUm6Qyw8W8jud';
const String _vi = '0102030405060708';
const String _userAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36';

/// 网易云音乐音源。
///
/// [baseUrl] 为空时使用「直连」模式（App 内自行完成 weapi 加密，直接请求
/// music.163.com）。该模式对网络环境敏感，可能被反爬拦截。
///
/// [baseUrl] 非空时使用「代理」模式，把请求发给你自己部署的
/// NeteaseCloudMusicApi 服务（https://github.com/Binaryify/NeteaseCloudMusicApi），
/// 由服务端完成加密与 Cookie 处理，最稳定。建议用此模式。
class NeteaseSource implements OnlineSource {
  /// 代理服务地址，如 'https://my-proxy.example.com'。空字符串表示直连。
  final String baseUrl;

  NeteaseSource([this.baseUrl = '']);

  @override
  String get id => 'netease';

  @override
  String get name => baseUrl.isEmpty ? '网易云音乐（直连）' : '网易云音乐（代理）';

  String _randomKey() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final r = Random();
    return List.generate(16, (_) => chars[r.nextInt(chars.length)]).join();
  }

  String _aes(String text, String key) {
    final k = enc.Key(utf8.encode(key));
    final iv = enc.IV(utf8.encode(_vi));
    final e = enc.Encrypter(
        enc.AES(k, mode: enc.AESMode.ecb, padding: 'PKCS7'));
    return e.encrypt(text, iv: iv).base64;
  }

  String _rsa(String text) {
    final modulus = BigInt.parse(_modulus, radix: 16);
    final exp = BigInt.parse(_pubExp, radix: 16);
    final cipher = RSAEngine()
      ..init(true, PublicKeyParameter<RSAPublicKey>(RSAPublicKey(modulus, exp)));
    final bytes = utf8.encode(text);
    final padded = Uint8List(128);
    padded.setRange(128 - bytes.length, 128, bytes);
    final out = cipher.process(padded);
    return out.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Map<String, String> _weapi(Map<String, dynamic> obj) {
    final text = jsonEncode(obj);
    final secKey = _randomKey();
    final params = _aes(_aes(text, _nonce), secKey);
    final encSecKey = _rsa(secKey.split('').reversed.join());
    return {'params': params, 'encSecKey': encSecKey};
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    if (baseUrl.isNotEmpty) {
      // 代理模式：直接转发明文 JSON，由代理完成加密。
      final res = await http
          .post(Uri.parse('$baseUrl$path'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    // 直连模式：本地完成 weapi 加密。
    final we = _weapi(body);
    final res = await http
        .post(Uri.parse('https://music.163.com$path'),
            headers: {
              'User-Agent': _userAgent,
              'Content-Type': 'application/x-www-form-urlencoded',
              'Referer': 'https://music.163.com/',
            },
            body: we)
        .timeout(const Duration(seconds: 20));
    if (res.bodyBytes.isEmpty) {
      throw Exception('直连网易云失败（返回为空，可能被网络或反爬拦截）。'
          '请在「设置」中填入 NeteaseCloudMusicApi 代理地址后重试。');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  @override
  Future<List<OnlineTrack>> search(String keyword, {int limit = 30}) async {
    final data = await _post('/weapi/cloudsearch/get/web',
        {'s': keyword, 'type': 1, 'limit': limit, 'offset': 0, 'total': true});
    final songs = data['result']?['songs'] as List? ?? [];
    return songs
        .whereType<Map<String, dynamic>>()
        .map((s) => OnlineTrack.fromNetease(s))
        .toList();
  }

  @override
  Future<String?> songUrl(String id) async {
    if (baseUrl.isNotEmpty) {
      final res = await http
          .get(Uri.parse('$baseUrl/song/url?id=$id&level=standard'))
          .timeout(const Duration(seconds: 20));
      final d = jsonDecode(utf8.decode(res.bodyBytes));
      if (d['data'] is List) {
        final first = (d['data'] as List).firstWhere(
            (e) => e is Map && (e['url']?.toString().isNotEmpty ?? false),
            orElse: () => null);
        return first?['url'];
      }
      return d['data']?['url'];
    }
    final data = await _post('/weapi/song/enhance/player/url/v1',
        {'ids': [id], 'level': 'standard', 'encodeType': 'flac'});
    final list = data['data'] as List? ?? [];
    for (final e in list) {
      if (e is Map && (e['url']?.toString().isNotEmpty ?? false)) {
        return e['url'];
      }
    }
    return null;
  }

  @override
  Future<String?> lyric(String id) async {
    if (baseUrl.isNotEmpty) {
      final res =
          await http.get(Uri.parse('$baseUrl/lyric?id=$id')).timeout(
              const Duration(seconds: 20));
      final d = jsonDecode(utf8.decode(res.bodyBytes));
      return d['lrc']?['lyric'];
    }
    final data = await _post(
        '/weapi/song/lyric', {'id': id, 'lv': -1, 'kv': -1, 'tv': -1});
    return data['lrc']?['lyric'];
  }
}
