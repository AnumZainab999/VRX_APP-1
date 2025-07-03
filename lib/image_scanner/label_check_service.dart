import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class LabelCheckService {
  static const _apiKey = 'AIzaSyAUYo9Gv_FBl1eCmCkN331aQxUh2zaRln0';

  static Future<Map<String, dynamic>> checkLabel(File imageFile) async {
    try {
      // Read image as bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Initialize Gemini model
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      // Strict inspection prompt
      const prompt = '''
You are a strict pharmaceutical packaging inspector AI. Your job is to analyze medicine packaging images (medicine boxes or blister packs only) and identify if they are authentic or fake.

Multilingual Note: The packaging may contain text in English, Urdu, Arabic, or other regional languages.

Carefully evaluate the image for:

- Is this clearly a pharmaceutical/medicine packaging (not food, cosmetics, household, etc.)?
- Fonts and font consistency (mismatched styles, unusual fonts)
- Text clarity and alignment (misplaced labels, misprints)
- Spelling or translation errors (in any language)
- Logo positioning and brand alignment
- Signs of counterfeit like poor printing, blur, tampered barcodes, faded seals

Now follow these rules strictly:

1. If the image is not clear enough to judge (blurry, dark, or low quality), respond with:
{
  "result": "unclear",
  "reason": "Image is too unclear or blurry to inspect the packaging."
}

2. If the image does not appear to be medicine packaging, respond with:
{
  "result": "invalid",
  "reason": "This is not a medicine package."
}

3. If the image is valid and shows medicine packaging, respond with:
{
  "result": "real" or "fake",
  "reason": "short explanation of what looks authentic or fake"
}

Only respond with one JSON object and no extra text.
''';
      // Create content with prompt and image
      final content = Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg',imageBytes),
      ]);

      // Generate content using Gemini API
      final response = await model.generateContent([content]);

      final text = response.text ?? '';

      // Try to extract JSON block from Gemini response
      final match = RegExp(r'\{[^}]+\}').firstMatch(text);
      if (match != null) {
        return jsonDecode(match.group(0)!);
      } else {
        return {
          'result': 'unknown',
          'reason': 'Could not parse JSON from Gemini response.'
        };
      }
    } catch (e) {
      return {
        'result': 'error',
        'reason': 'Exception: ${e.toString()}',
      };
    }
  }
}