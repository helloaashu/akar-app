import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/road_issue_analysis.dart';

class GeminiService {
  GeminiService._(); // private constructor for static-only class

  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static final Uri _endpoint = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey');

  /// Strips optional ```json fences that Gemini might add
  static String _stripFences(String raw) {
    raw = raw.trim();
    if (raw.startsWith('```')) {
      final lines = raw.split('\n');
      final buffer = StringBuffer();
      for (var i = 1; i < lines.length; i++) {
        if (lines[i].trim() == '```') break;
        buffer.writeln(lines[i]);
      }
      return buffer.toString().trim();
    }
    return raw;
  }

  static Future<RoadIssueAnalysis> analyzeRoadImage(File imageFile) async {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY missing in .env');
    }

    final bytes = await imageFile.readAsBytes();
    final b64 = base64Encode(bytes);

    final payload = {
      'contents': [
        {
          'parts': [
            {
              'text': '''Analyze this image for a road maintenance complaint app in Nepal and reply ONLY with JSON in the following exact schema (no markdown fences):\n{\n  "isRelevant": boolean,\n  "category": "string",\n  "severity": number,\n  "department": "string",\n  "explanation": "string",\n  "suggestions": ["string"],\n  "confidence": number\n}'''
            },
            {
              'inlineData': {
                'mimeType': 'image/jpeg',
                'data': b64,
              }
            }
          ]
        }
      ]
    };

    try {
      final res = await http
          .post(_endpoint, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 60));

      if (res.statusCode != 200) {
        throw Exception('Gemini HTTP ${res.statusCode}: ${res.body}');
      }

      final Map<String, dynamic> data = jsonDecode(res.body);
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No Gemini candidates returned');
      }
      final text = candidates.first['content']['parts'][0]['text'] as String? ?? '';
      final cleaned = _stripFences(text);
      final Map<String, dynamic> jsonResp = jsonDecode(cleaned);
      return RoadIssueAnalysis.fromJson(jsonResp);
    } catch (e) {
      if (kDebugMode) print('[GeminiService] $e');
      rethrow;
    }
  }
}