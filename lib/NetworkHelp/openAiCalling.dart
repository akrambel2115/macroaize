import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../Model/openAIModel.dart';
import '../constant/Appkey.dart';

class OpenAiCalling {

  static Future<String> sentImageApi(File image) async {
    try {
      // Get current app language for response localization
      final currentLang = _getLanguageName();
      
      // Changed to OpenRouter endpoint
      String apiEndpoint = 'https://openrouter.ai/api/v1/chat/completions';
      final headers = {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'YOUR_APP_URL', // Optional, for OpenRouter analytics
        'X-Title': 'Food Calorie Tracker', // Optional, for OpenRouter analytics
      };
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final parameters = {
        'model': 'qwen/qwen2.5-vl-72b-instruct:free',
        'messages': [
          {
            'role': 'system',
            'content': "You are a nutrition analysis assistant. Given a food photo you MUST return ONLY compact JSON with integer values in kcal/grams. No commentary, no markdown. If multiple foods are present, estimate TOTAL combined values. JSON shape: {\\n  \"food_name\": <string>,\\n  \"calories\": <int>,\\n  \"protein_g\": <int>,\\n  \"carbohydrates_g\": <int>,\\n  \"fats_g\": <int>\\n}. The food_name should be short, human-friendly, and written in $currentLang (e.g., 'Grilled chicken with salad'). If unsure, provide your best reasonable estimate; never output 0 unless clearly no food.",
          },
          {
            'role': 'user',
            'content': [
              { 'type': 'text', 'text': 'Analyze this image and output ONLY the JSON described. Make sure the food_name is in $currentLang.' },
              { 'type': 'image_url', 'image_url': { 'url': "data:image/jpeg;base64,$base64Image" } },
            ],
          },
        ],
        'temperature': 0,
        'max_tokens': 300,
      };
      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: headers,
        body: jsonEncode(parameters),
      );

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final decodedJson = jsonDecode(responseBody);
        OpenAiModel data = OpenAiModel.fromJson(decodedJson);
        return data.choices!.first.message!.content.toString();
      } else {
        if (kDebugMode) {
          print(response.statusCode);
          print(response.body);
        }
        return "Something Went Wrong";
      }
    } catch (e) {
      if (kDebugMode) {
        print("error is====> $e");
      }
      return "Something Went Wrong";
    }
  }
  
  // Helper method to get readable language name for AI prompts
  static String _getLanguageName() {
    final currentLang = Get.locale?.languageCode.toLowerCase() ?? 'en';
    
    // Map language codes to full language names for better AI understanding
    final languageMap = {
      'en': 'English',
      'ar': 'Arabic',
      'fr': 'French', 
      'es': 'Spanish',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'zh': 'Chinese',
      'ja': 'Japanese',
      'ko': 'Korean',
      'hi': 'Hindi',
      'ur': 'Urdu',
      'tr': 'Turkish',
      'nl': 'Dutch',
    };
    
    return languageMap[currentLang] ?? 'English';
  }
}
