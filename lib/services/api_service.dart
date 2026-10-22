import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/persona_model.dart';
import '../models/sexo_model.dart';
import '../models/estado_civil_model.dart';
import '../models/correo_model.dart';

class ApiService {
  static String? _customBaseUrl;

  /// URL para servidor local en la máquina host
  static const String localhostBaseUrl = 'http://localhost/eysfwis/index.php/api';

  /// URL para emulador Android de Google (acceso al localhost del host mediante 10.0.2.2)
  static const String emulatorBaseUrl = 'http://10.0.2.2/eysfwis/index.php/api';

  /// URL de servidor remoto en producción
  static const String productionBaseUrl = 'https://educaysoft.org/eysfwis/index.php/api';

  static String get defaultBaseUrl {
    // Si corre en web o linux/desktop usa localhost por defecto;
    // Si corre en emulador Android o dispositivo se puede configurar según el entorno.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return emulatorBaseUrl;
    }
    return localhostBaseUrl;
  }

  static String get baseUrl => _customBaseUrl ?? defaultBaseUrl;

  static set baseUrl(String url) {
    _customBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  static void resetToDefault() {
    _customBaseUrl = null;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  /// Probar conexión con el backend de eysfwis
  static Future<String?> testConnection() async {
    try {
      final uri = Uri.parse('$baseUrl/catalogos');
      final res = await http.get(uri, headers: _headers).timeout(
            const Duration(seconds: 6),
          );
      if (res.statusCode == 200) {
        return null; // Conexión exitosa
      } else {
        return 'El servidor respondió con código ${res.statusCode}';
      }
    } catch (e) {
      return 'No se pudo conectar: $e';
    }
  }

  // ========================================================================
  // 1. GESTIÓN DE PERSONAS (persona)
  // ========================================================================

  static Future<List<Persona>> fetchPersonas({String? query}) async {
    final queryParams = <String, String>{};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['q'] = query.trim();
    }

    final uri = Uri.parse('$baseUrl/persona').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final res = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 10),
        );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final list = (decoded['data'] as List<dynamic>?) ?? [];
      return list
          .map((item) => Persona.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al cargar personas: Código ${res.statusCode}');
    }
  }

  static Future<PersonaDetail> fetchPersonaDetail(int id) async {
    final uri = Uri.parse('$baseUrl/persona/$id');
    final res = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 10),
        );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final data = decoded['data'] as Map<String, dynamic>;
      return PersonaDetail.fromJson(data);
    } else {
      throw Exception('Error al obtener detalle de la persona');
    }
  }

  static Future<Map<String, dynamic>> createPersona({
    required String cedula,
    required String nombres,
    required String apellidos,
    String? fechanacimiento,
    int? idsexo,
    int? idestadocivil,
    String? correo,
    String? direccion,
    bool esCliente = false,
  }) async {
    final uri = Uri.parse('$baseUrl/persona');
    final payload = {
      'cedula': cedula.trim(),
      'nombres': nombres.trim(),
      'apellidos': apellidos.trim(),
      'fechanacimiento':
          fechanacimiento?.trim().isNotEmpty == true ? fechanacimiento : null,
      'idsexo': idsexo,
      'idestadocivil': idestadocivil,
      'correo': correo?.trim().isNotEmpty == true ? correo : null,
      'direccion': direccion?.trim().isNotEmpty == true ? direccion : null,
      'es_cliente': esCliente ? 1 : 0,
    };

    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 12));

    final decoded = jsonDecode(res.body);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return {'success': true, 'data': decoded};
    } else {
      final msg = decoded['messages'] ??
          decoded['message'] ??
          'Error al registrar la persona';
      return {'success': false, 'error': msg.toString()};
    }
  }

  static Future<Map<String, dynamic>> updatePersona({
    required int idpersona,
    required String cedula,
    required String nombres,
    required String apellidos,
    String? fechanacimiento,
    int? idsexo,
    bool esCliente = false,
  }) async {
    final uri = Uri.parse('$baseUrl/persona/$idpersona');
    final payload = {
      'cedula': cedula.trim(),
      'nombres': nombres.trim(),
      'apellidos': apellidos.trim(),
      'fechanacimiento':
          fechanacimiento?.trim().isNotEmpty == true ? fechanacimiento : null,
      'idsexo': idsexo,
      'es_cliente': esCliente ? 1 : 0,
    };

    final res = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 12));

    final decoded = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return {'success': true, 'data': decoded};
    } else {
      final msg = decoded['messages'] ??
          decoded['message'] ??
          'Error al actualizar la persona';
      return {'success': false, 'error': msg.toString()};
    }
  }

  static Future<bool> deletePersona(int idpersona) async {
    final uri = Uri.parse('$baseUrl/persona/$idpersona');
    final res = await http.delete(uri, headers: _headers).timeout(
          const Duration(seconds: 10),
        );

    if (res.statusCode == 200) {
      return true;
    } else {
      final decoded = jsonDecode(res.body);
      throw Exception(
        decoded['messages'] ??
            decoded['message'] ??
            'Error al eliminar la persona',
      );
    }
  }

  // ========================================================================
  // 2. GESTIÓN DE SEXO (sexo)
  // ========================================================================

  static Future<List<Sexo>> fetchSexos() async {
    final uri = Uri.parse('$baseUrl/sexo');
    final res = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 8),
        );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final list = (decoded['data'] as List<dynamic>?) ?? [];
      return list
          .map((item) => Sexo.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      // Intento de respaldo a través de catalogos si /sexo no estuviese disponible
      return fetchSexosFromCatalogos();
    }
  }

  static Future<List<Sexo>> fetchSexosFromCatalogos() async {
    final uri = Uri.parse('$baseUrl/catalogos');
    final res = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 8),
        );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final data = decoded['data'] as Map<String, dynamic>? ?? {};
      final list = (data['sexos'] as List<dynamic>?) ?? [];
      return list
          .map((item) => Sexo.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> createSexo(String nombre) async {
    final uri = Uri.parse('$baseUrl/sexo');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'nombre': nombre.trim()}),
    ).timeout(const Duration(seconds: 8));

    final decoded = jsonDecode(res.body);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return {'success': true, 'data': decoded};
    } else {
      final msg = decoded['messages'] ??
          decoded['message'] ??
          'Error al registrar sexo';
      return {'success': false, 'error': msg.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateSexo(
      int idsexo, String nombre) async {
    final uri = Uri.parse('$baseUrl/sexo/$idsexo');
    final res = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode({'nombre': nombre.trim()}),
    ).timeout(const Duration(seconds: 8));

    final decoded = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return {'success': true, 'data': decoded};
    } else {
      final msg = decoded['messages'] ??
          decoded['message'] ??
          'Error al actualizar sexo';
      return {'success': false, 'error': msg.toString()};
    }
  }

  static Future<bool> deleteSexo(int idsexo) async {
    final uri = Uri.parse('$baseUrl/sexo/$idsexo');
    final res = await http.delete(uri, headers: _headers).timeout(
          const Duration(seconds: 8),
        );

    if (res.statusCode == 200) {
      return true;
    } else {
      final decoded = jsonDecode(res.body);
      throw Exception(
        decoded['messages'] ??
            decoded['message'] ??
            'Error al eliminar sexo (puede estar asignado a personas).',
      );
    }
  }

  // ========================================================================
  // 3. GESTIÓN DE ESTADO CIVIL (estadocivil)
  // ========================================================================

  static Future<List<EstadoCivil>> fetchEstadosCiviles() async {
    final uri = Uri.parse('$baseUrl/estadocivil');
    final res = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 8),
        );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final list = (decoded['data'] as List<dynamic>?) ?? [];
      return list
          .map((item) => EstadoCivil.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      return fetchEstadosCivilesFromCatalogos();
    }
  }

  static Future<List<EstadoCivil>> fetchEstadosCivilesFromCatalogos() async {
    final uri = Uri.parse('$baseUrl/catalogos');
    final res = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 8),
        );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final data = decoded['data'] as Map<String, dynamic>? ?? {};
      final list = (data['estadosCiviles'] as List<dynamic>?) ?? [];
      return list
          .map((item) => EstadoCivil.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> createEstadoCivil(String nombre) async {
    final uri = Uri.parse('$baseUrl/estadocivil');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'nombre': nombre.trim()}),
    ).timeout(const Duration(seconds: 8));

    final decoded = jsonDecode(res.body);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return {'success': true, 'data': decoded};
    } else {
      final msg = decoded['messages'] ??
          decoded['message'] ??
          'Error al registrar estado civil';
      return {'success': false, 'error': msg.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateEstadoCivil(
      int idestadocivil, String nombre) async {
    final uri = Uri.parse('$baseUrl/estadocivil/$idestadocivil');
    final res = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode({'nombre': nombre.trim()}),
    ).timeout(const Duration(seconds: 8));

    final decoded = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return {'success': true, 'data': decoded};
    } else {
      final msg = decoded['messages'] ??
          decoded['message'] ??
          'Error al actualizar estado civil';
      return {'success': false, 'error': msg.toString()};
    }
  }

  static Future<bool> deleteEstadoCivil(int idestadocivil) async {
    final uri = Uri.parse('$baseUrl/estadocivil/$idestadocivil');
    final res = await http.delete(uri, headers: _headers).timeout(
          const Duration(seconds: 8),
        );

    if (res.statusCode == 200) {
      return true;
    } else {
      final decoded = jsonDecode(res.body);
      throw Exception(
        decoded['messages'] ??
            decoded['message'] ??
            'Error al eliminar estado civil.',
      );
    }
  }

  // ========================================================================
  // 4. GESTIÓN DE CORREOS ELECTRÓNICOS (correo)
  // ========================================================================

  static Future<List<Correo>> fetchCorreos({
    String? query,
    int? idpersona,
  }) async {
    final queryParams = <String, String>{};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['q'] = query.trim();
    }
    if (idpersona != null && idpersona > 0) {
      queryParams['idpersona'] = idpersona.toString();
    }

    final uri = Uri.parse('$baseUrl/correo').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final res = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 10),
        );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final list = (decoded['data'] as List<dynamic>?) ?? [];
      return list
          .map((item) => Correo.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al cargar correos: Código ${res.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> createCorreo({
    required int idpersona,
    required String correo,
    String? fechaoptencion,
  }) async {
    final uri = Uri.parse('$baseUrl/correo');
    final payload = {
      'idpersona': idpersona,
      'correo': correo.trim(),
      'fechaoptencion': fechaoptencion?.trim().isNotEmpty == true
          ? fechaoptencion
          : DateTime.now().toIso8601String().substring(0, 10),
    };

    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 8));

    final decoded = jsonDecode(res.body);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return {'success': true, 'data': decoded};
    } else {
      final msg = decoded['messages'] ??
          decoded['message'] ??
          'Error al registrar correo electrónico';
      return {'success': false, 'error': msg.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateCorreo({
    required int idcorreo,
    required String correo,
    String? fechaoptencion,
    int? idpersona,
  }) async {
    final uri = Uri.parse('$baseUrl/correo/$idcorreo');
    final payload = <String, dynamic>{
      'correo': correo.trim(),
    };
    if (fechaoptencion != null && fechaoptencion.isNotEmpty) {
      payload['fechaoptencion'] = fechaoptencion;
    }
    if (idpersona != null) {
      payload['idpersona'] = idpersona;
    }

    final res = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 8));

    final decoded = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return {'success': true, 'data': decoded};
    } else {
      final msg = decoded['messages'] ??
          decoded['message'] ??
          'Error al actualizar correo electrónico';
      return {'success': false, 'error': msg.toString()};
    }
  }

  static Future<bool> deleteCorreo(int idcorreo) async {
    final uri = Uri.parse('$baseUrl/correo/$idcorreo');
    final res = await http.delete(uri, headers: _headers).timeout(
          const Duration(seconds: 8),
        );

    if (res.statusCode == 200) {
      return true;
    } else {
      final decoded = jsonDecode(res.body);
      throw Exception(
        decoded['messages'] ??
            decoded['message'] ??
            'Error al eliminar correo electrónico',
      );
    }
  }
}
