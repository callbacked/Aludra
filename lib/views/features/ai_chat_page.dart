import 'package:aludra/ble_manager.dart';
import 'package:aludra/services/ollama_service.dart';
import 'package:aludra/services/text_service.dart';
import 'package:flutter/material.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  _AIChatPageState createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _endpointController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingModels = false;
  String _lastResponse = '';
  List<String> _availableModels = [];
  String? _selectedModel;

  @override
  void initState() {
    super.initState();
    _endpointController.text = OllamaService.get.currentEndpoint;
    _selectedModel = OllamaService.get.currentModel;
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoadingModels = true;
    });

    try {
      final models = await OllamaService.get.listModels();
      setState(() {
        _availableModels = models;
        if (!models.contains(_selectedModel)) {
          _selectedModel = models.isNotEmpty ? models.first : null;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading models: $e')),
      );
    } finally {
      setState(() {
        _isLoadingModels = false;
      });
    }
  }

  Future<void> _updateEndpoint() async {
    final endpoint = _endpointController.text.trim();
    if (endpoint.isEmpty) return;

    try {
      await OllamaService.get.setEndpoint(endpoint);
      await _loadModels();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating endpoint: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    // When glasses arrive, uncomment this line to require BLE connection:
    // if (_messageController.text.isEmpty || !BleManager.get().isConnected) return;
    
    // For development without glasses:
    if (_messageController.text.isEmpty) return;

    final message = _messageController.text;
    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedModel != null && _selectedModel != OllamaService.get.currentModel) {
        await OllamaService.get.setModel(_selectedModel!);
      }
      
      final response = await OllamaService.get.generateResponse(message);
      setState(() {
        _lastResponse = response;
      });

      // Only try to send to glasses if connected
      if (BleManager.get().isConnected) {
        await TextService.get.startSendText(response);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('AI Chat'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Settings'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _endpointController,
                            decoration: const InputDecoration(
                              labelText: 'Endpoint URL',
                              hintText: 'http://localhost:11434',
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_isLoadingModels)
                            const CircularProgressIndicator()
                          else if (_availableModels.isNotEmpty)
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedModel,
                              items: _availableModels.map((model) => DropdownMenuItem(
                                value: model,
                                child: Text(
                                  model,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedModel = value;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Model',
                              ),
                            ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _updateEndpoint();
                          Navigator.pop(context);
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedModel != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Using model: $_selectedModel',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Text(
                          _lastResponse.isEmpty
                              ? 'AI responses will appear here and be sent to your glasses'
                              : _lastResponse,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : Icon(
                              Icons.send,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
} 