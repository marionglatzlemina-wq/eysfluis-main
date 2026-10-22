import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _urlCtrl;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: ApiService.baseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final currentUrl = ApiService.baseUrl;
    ApiService.baseUrl = _urlCtrl.text.trim();

    final err = await ApiService.testConnection();

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      if (err == null) {
        _testSuccess = true;
        _testResult = '¡Conexión exitosa con la base de datos eysfwis!';
      } else {
        _testSuccess = false;
        _testResult = err;
        ApiService.baseUrl = currentUrl; // restaurar si falló
      }
    });
  }

  void _selectPreset(String url) {
    setState(() {
      _urlCtrl.text = url;
      _testResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.dns, color: Colors.blue),
          SizedBox(width: 8),
          Text('Conexión BD eysfwis'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración del Endpoint API REST de la base de datos eysfwis:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL Base de la API',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Servidores preconfigurados:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.computer, size: 16),
                  label: const Text('Localhost (Apache)'),
                  onPressed: () => _selectPreset(ApiService.localhostBaseUrl),
                ),
                ActionChip(
                  avatar: const Icon(Icons.phone_android, size: 16),
                  label: const Text('Emulador (10.0.2.2)'),
                  onPressed: () => _selectPreset(ApiService.emulatorBaseUrl),
                ),
                ActionChip(
                  avatar: const Icon(Icons.cloud, size: 16),
                  label: const Text('educaysoft.org'),
                  onPressed: () => _selectPreset(ApiService.productionBaseUrl),
                ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check),
              label: const Text('Probar Conexión'),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _testSuccess
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testSuccess
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess ? Icons.check_circle : Icons.error,
                      color: _testSuccess ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _testSuccess
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        ElevatedButton(
          onPressed: () {
            ApiService.baseUrl = _urlCtrl.text.trim();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Servidor actualizado: ${ApiService.baseUrl}'),
              ),
            );
          },
          child: const Text('Aplicar URL'),
        ),
      ],
    );
  }
}
