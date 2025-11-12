import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/global_config.dart';

class UmbralesScreen extends StatefulWidget {
  const UmbralesScreen({super.key});

  @override
  State<UmbralesScreen> createState() => _UmbralesScreenState();
}

class _UmbralesScreenState extends State<UmbralesScreen> {
  List<Map<String, dynamic>> _umbrales = [];
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _nuevoUmbral = {
    'tipo_dato': '',
    'tipo_alerta': '',
    'minimo': '',
    'maximo': '',
    'nivel': '',
    'prioridad': ''
  };
  final String apiUrl = '${GlobalConfig.baseURL}/api/umbrales';

  @override
  void initState() {
    super.initState();
    _cargarUmbrales();
  }

  Future<void> _cargarUmbrales() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      print('Respuesta del servidor: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _umbrales = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print('Error en la respuesta: ${response.reasonPhrase}');
        _mostrarError('Error al cargar umbrales: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Excepción al cargar umbrales: $e');
      _mostrarError('Error de conexión: $e');
    }
  }

  Future<void> _guardarUmbral() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'tipo_dato': _nuevoUmbral['tipo_dato'],
            'tipo_alerta': _nuevoUmbral['tipo_alerta'],
            'minimo': double.tryParse(_nuevoUmbral['minimo'] ?? '0'),
            'maximo': double.tryParse(_nuevoUmbral['maximo'] ?? '0'),
            'nivel': _nuevoUmbral['nivel'],
            'prioridad': int.tryParse(_nuevoUmbral['prioridad'] ?? '0'),
          }),
        );
        
        if (response.statusCode == 201) {
          _formKey.currentState!.reset();
          _cargarUmbrales();
          _mostrarExito('Umbral creado exitosamente');
        } else {
          _mostrarError('No se pudo guardar el umbral: ${response.body}');
        }
      } catch (e) {
        _mostrarError('Error al guardar: $e');
      }
    }
  }

  Future<void> _eliminarUmbral(int id) async {
    try {
      final response = await http.delete(Uri.parse('$apiUrl/$id'));
      if (response.statusCode == 200) {
        _cargarUmbrales();
        _mostrarExito('Umbral eliminado');
      } else {
        _mostrarError('No se pudo eliminar: ${response.body}');
      }
    } catch (e) {
      _mostrarError('Error al eliminar: $e');
    }
  }

  Future<void> _editarUmbral(int id, Map<String, dynamic> valores) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(valores),
      );
      if (response.statusCode == 200) {
        _cargarUmbrales();
        _mostrarExito('Umbral actualizado');
      } else {
        _mostrarError('Error al actualizar: ${response.body}');
      }
    } catch (e) {
      _mostrarError('Error al editar: $e');
    }
  }

  Future<void> _verHistorial(int umbralId) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/historial/$umbralId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Historial de cambios'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var item in data['historial'])
                    ListTile(
                      title: Text('Fecha: ${item['fecha_modificado']}'),
                      subtitle: Text('Min: ${item['minimo']} | Max: ${item['maximo']}'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      } else {
        _mostrarError('No se pudo cargar el historial');
      }
    } catch (e) {
      _mostrarError('Error al obtener historial: $e');
    }
  }

  void _mostrarDialogoEdicion(Map<String, dynamic> umbral) {
    final _editado = Map<String, dynamic>.from(umbral);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Umbral', style: TextStyle(color: Colors.blue)),
          backgroundColor: Colors.blue[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campoTexto('Tipo de dato', _editado, 'tipo_dato'),
                _campoTexto('Tipo de alerta', _editado, 'tipo_alerta'),
                _campoTexto('Mínimo', _editado, 'minimo', numero: true),
                _campoTexto('Máximo', _editado, 'maximo', numero: true),
                _campoTexto('Nivel', _editado, 'nivel'),
                _campoTexto('Prioridad', _editado, 'prioridad', numero: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.blue)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _editarUmbral(umbral['id'], {
                  'tipo_dato': _editado['tipo_dato'],
                  'tipo_alerta': _editado['tipo_alerta'],
                  'minimo': double.tryParse(_editado['minimo'].toString()) ?? 0,
                  'maximo': double.tryParse(_editado['maximo'].toString()) ?? 0,
                  'nivel': _editado['nivel'],
                  'prioridad': int.tryParse(_editado['prioridad'].toString()) ?? 0,
                });
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _campoTexto(String label, Map<String, dynamic> data, String campo, {bool numero = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: data[campo].toString(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blue[700]),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue[300]!),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blue),
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.blue[50],
        ),
        keyboardType: numero ? TextInputType.number : TextInputType.text,
        onChanged: (value) => data[campo] = value,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo es requerido';
          }
          if (numero && double.tryParse(value) == null) {
            return 'Ingrese un número válido';
          }
          return null;
        },
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Umbrales', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[700],
        elevation: 5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.blue[100]!],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              const Text('Nuevo Umbral', 
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _campoTexto('Tipo de dato', _nuevoUmbral, 'tipo_dato'),
                              _campoTexto('Tipo de alerta', _nuevoUmbral, 'tipo_alerta'),
                              _campoTexto('Mínimo', _nuevoUmbral, 'minimo', numero: true),
                              _campoTexto('Máximo', _nuevoUmbral, 'maximo', numero: true),
                              _campoTexto('Nivel', _nuevoUmbral, 'nivel'),
                              _campoTexto('Prioridad', _nuevoUmbral, 'prioridad', numero: true),
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: _guardarUmbral,
                                  child: const Text('Guardar', style: TextStyle(color: Colors.white, fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Umbrales Existentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _umbrales.isEmpty
                        ? const Center(child: Text('No hay umbrales registrados'))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _umbrales.length,
                            itemBuilder: (context, index) {
                              final u = _umbrales[index];
                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue[100]!),
                                  ),
                                  child: ListTile(
                                    title: Text('${u['tipo_alerta']} (${u['tipo_dato']}) - Nivel ${u['nivel']}',
                                      style: TextStyle(
                                        color: Colors.blue[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text('Min: ${u['minimo']} | Max: ${u['maximo']} | Prioridad: ${u['prioridad']}',
                                      style: TextStyle(color: Colors.blue[600]),
                                    ),
                                    trailing: Wrap(
                                      spacing: 10,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.history, color: Colors.blue[700]),
                                          onPressed: () => _verHistorial(u['id']),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit, color: Colors.blue[700]),
                                          onPressed: () => _mostrarDialogoEdicion(u),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red[700]),
                                          onPressed: () => _eliminarUmbral(u['id']),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}