import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiOCRService {
  late final GenerativeModel _model;
  final String apiKey;

  GeminiOCRService({required this.apiKey}) {
    _model = GenerativeModel(model: 'gemini-pro-vision', apiKey: apiKey);
  }

  /// Extract text & items dari receipt image menggunakan Gemini Vision
  Future<Map<String, dynamic>> extractReceiptData(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      // Determine MIME type
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      const prompt = '''
Analyze this receipt/invoice image and extract the following information in JSON format:

{
  "items": [
    {
      "name": "item name",
      "price": 50000,
      "quantity": 1
    }
  ],
  "subtotal": 50000,
  "tax": 0,
  "service_charge": 0,
  "discount": 0,
  "total": 50000,
  "restaurant_name": "name if visible",
  "date": "date if visible"
}

Return ONLY valid JSON, no markdown or extra text.
If a field is not found, use 0 for numbers or empty string for text.
Prices should be in numeric format (e.g., 50000 not "50.000").
''';

      final response = await _model.generateContent([
        Content.multi([TextPart(prompt), DataPart(mimeType, imageBytes)]),
      ]);

      final text = response.text ?? '';
      return _parseReceiptJson(text);
    } catch (e) {
      print('Gemini OCR Error: $e');
      rethrow;
    }
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Map<String, dynamic> _parseReceiptJson(String jsonString) {
    try {
      // Clean up response (remove markdown code blocks if present)
      String cleaned = jsonString
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Simple JSON parsing
      final jsonMap = _simpleJsonParse(cleaned);
      return jsonMap;
    } catch (e) {
      print('JSON Parse Error: $e');
      return {
        'items': [],
        'subtotal': 0.0,
        'tax': 0.0,
        'service_charge': 0.0,
        'discount': 0.0,
        'total': 0.0,
        'restaurant_name': '',
        'date': '',
      };
    }
  }

  // Simple JSON parser untuk menangani response dari Gemini
  Map<String, dynamic> _simpleJsonParse(String json) {
    // Ini basic implementation - untuk production, gunakan proper JSON decoder
    try {
      // Try standard JSON decode dulu
      // Sebenarnya bisa langsung pakai jsonDecode dari dart:convert
      // Tapi untuk safety, kita handle manual parsing juga

      final Map<String, dynamic> result = {
        'items': [],
        'subtotal': 0.0,
        'tax': 0.0,
        'service_charge': 0.0,
        'discount': 0.0,
        'total': 0.0,
        'restaurant_name': '',
        'date': '',
      };

      // Extract items array
      final itemsMatch = RegExp(
        r'"items"\s*:\s*\[(.*?)\]',
        dotAll: true,
      ).firstMatch(json);
      if (itemsMatch != null) {
        final itemsJson = '[${itemsMatch.group(1)}]';
        try {
          // Parse items
          List<Map<String, dynamic>> items = [];
          final itemObjects = RegExp(
            r'\{[^{}]*\}',
          ).allMatches(itemsJson).map((m) => m.group(0)!).toList();

          for (final itemStr in itemObjects) {
            final name = _extractStringField(itemStr, 'name');
            final price = _extractNumField(itemStr, 'price');
            final quantity = _extractNumField(itemStr, 'quantity');

            if (name.isNotEmpty && price > 0) {
              items.add({
                'name': name,
                'price': price,
                'quantity': quantity > 0 ? quantity : 1,
              });
            }
          }
          result['items'] = items;
        } catch (e) {
          print('Items parse error: $e');
        }
      }

      // Extract numeric fields
      result['subtotal'] = _extractNumField(json, 'subtotal');
      result['tax'] = _extractNumField(json, 'tax');
      result['service_charge'] = _extractNumField(json, 'service_charge');
      result['discount'] = _extractNumField(json, 'discount');
      result['total'] = _extractNumField(json, 'total');

      // Extract string fields
      result['restaurant_name'] = _extractStringField(json, 'restaurant_name');
      result['date'] = _extractStringField(json, 'date');

      return result;
    } catch (e) {
      print('Simple JSON parse failed: $e');
      return {
        'items': [],
        'subtotal': 0.0,
        'tax': 0.0,
        'service_charge': 0.0,
        'discount': 0.0,
        'total': 0.0,
        'restaurant_name': '',
        'date': '',
      };
    }
  }

  String _extractStringField(String json, String field) {
    final pattern = RegExp('"$field"\\s*:\\s*"([^"]*)');
    final match = pattern.firstMatch(json);
    return match?.group(1) ?? '';
  }

  double _extractNumField(String json, String field) {
    final pattern = RegExp('"$field"\\s*:\\s*(\\d+(?:\\.\\d+)?)');
    final match = pattern.firstMatch(json);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }
    return 0.0;
  }
}
