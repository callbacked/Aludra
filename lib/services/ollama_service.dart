import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OllamaService {
  static final OllamaService _instance = OllamaService._internal();
  static OllamaService get = _instance;
  
  static const String _endpointKey = 'ollama_endpoint';
  static const String _modelKey = 'ollama_model';
  String _baseUrl = 'http://localhost:11434';
  String _model = 'mistral';

  OllamaService._internal() {
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_endpointKey) ?? _baseUrl;
    _model = prefs.getString(_modelKey) ?? _model;
  }

  Future<void> setEndpoint(String endpoint) async {
    _baseUrl = endpoint;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_endpointKey, endpoint);
  }

  Future<void> setModel(String model) async {
    _model = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model);
  }

  String get currentEndpoint => _baseUrl;
  String get currentModel => _model;

  Future<List<String>> listModels() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tags'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> models = jsonDecode(response.body)['models'];
        return models.map((model) => model['name'] as String).toList();
      } else {
        throw Exception('Failed to list models: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error communicating with Ollama: $e');
    }
  }

  Future<String> generateResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _model,
          'prompt': prompt,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['response'] as String;
      } else {
        throw Exception('Failed to generate response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error communicating with Ollama: $e');
    }
  }
} 