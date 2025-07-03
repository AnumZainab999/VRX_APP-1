// services/label_check_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class LabelCheckService {
  static const _apiKey = 'AIzaSyAUYo9Gv_FBl1eCmCkN331aQxUh2zaRln0'; // Replace with your actual API Key

  static Future<Map<String, dynamic>> checkLabel(File imageFile) async {
    try {
      // Read image as bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Initialize Gemini model
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

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
- Barcode quality and placement
- Any certification symbols (FDA, DRAP, CE) that should or should not appear

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

4. If the result is "real", also include the following additional fields:
   - "medicineName": "The name of the medicine" (e.g., "Augmentin 625mg")
   - "potency": "The strength or dosage of the medicine" (e.g., "625mg", "500mg/5ml", "200IU")
   - "price": "The approximate price of the medicine found on the packaging or if not visible, use a common estimated price for a standard pack in Pakistan (e.g., "PKR 550", "Rs. 1200")"
   - "info": "Brief general information about the medicine (manufacturer, uses, etc.)"

✅ Final response examples:
- For valid real medicine:
{
  "result": "real",
  "reason": "Fonts, logo, barcode and text are clear and properly aligned.",
  "medicineName": "Panadol Extra",
  "potency": "500mg",
  "price": "PKR 120",
  "info": "Manufacturer: GSK. Used to relieve pain and reduce fever. Contains Paracetamol and Caffeine."
}

- For fake:
{
  "result": "fake",
  "reason": "Barcode is missing and logo is misaligned."
}

Only respond with one valid JSON object and no additional explanation, comments, or markdown. Your response must begin with { and end with }.
''';

      // Create content with prompt and image
      final content = Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]);

      // Generate content using Gemini API
      final response = await model.generateContent([content]);

      final text = response.text ?? '';
      print("Gemini Raw Response: $text"); // For debugging

      // Try to extract JSON block from Gemini response
      final match = RegExp(r'\{[^}]+\}').firstMatch(text);
      if (match != null) {
        return jsonDecode(match.group(0)!);
      } else {
        return {
          'result': 'unknown',
          'reason': 'Could not parse JSON from Gemini response. Raw: $text'
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