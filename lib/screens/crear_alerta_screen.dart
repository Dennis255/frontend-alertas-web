import 'package:flutter/material.dart';
import '../services/alerta_service.dart';
import 'mapa_selector_screen.dart';
import 'package:latlong2/latlong.dart';

class CrearAlertaScreen extends StatefulWidget {
  const CrearAlertaScreen({super.key});

  @override
  State<CrearAlertaScreen> createState() => _CrearAlertaScreenState();
}

class _CrearAlertaScreenState extends State<CrearAlertaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ubicacionController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _temperaturaController = TextEditingController();
  final TextEditingController _zonaController = TextEditingController(text: 'Achupallas');

  final _humedadController = TextEditingController();
  final _precipitacionController = TextEditingController();
  final _vientoController = TextEditingController();
  final _latitudController = TextEditingController();
  final _longitudController = TextEditingController();

  bool _bloquearLatLon = false;
  String? _tipoSeleccionado;
  String? _nivelSeleccionado;
  bool _isSubmitting = false;

  final AlertaService _alertaService = AlertaService();

  final List<String> tipos = ['❄️ Helada', '🌊 Inundación', '💧 Sequía', '🌧️ Lluvia intensa', '🌬️ Vientos fuertes'];
  final List<String> niveles = ['Bajo', 'Moderado', 'Alto', 'Extremo'];


  Future<void> _submit() async {
    
    if (!_formKey.currentState!.validate()) return;
    
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar creación de alerta', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro de crear esta alerta? Esta acción será visible para todos los usuarios.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF3366CC))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3366CC),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isSubmitting = true);

    if (_latitudController.text.isNotEmpty && _longitudController.text.isNotEmpty) {
  _ubicacionController.text =
      "${_latitudController.text.trim()},${_longitudController.text.trim()}";
} else {
  // Asignar coordenadas predeterminadas de Achupallas
  _latitudController.text = '-2.216556';
  _longitudController.text = '-78.667119';
  _ubicacionController.text = '-2.216556,-78.667119';
}


    try {
      final success = await _alertaService.createAlerta(
        tipo: _tipoSeleccionado!,
        nivel: _nivelSeleccionado!,
        ubicacion: _ubicacionController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        temperatura: _parseDouble(_temperaturaController.text),
        humedad: _parseDouble(_humedadController.text),
        precipitacion: _parseDouble(_precipitacionController.text),
        viento: _parseDouble(_vientoController.text),
        zona: _zonaController.text.trim(), //
        
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Alerta creada exitosamente'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Error en el servidor');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al crear la alerta'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  double? _parseDouble(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }

  Future<void> _abrirMapaYSeleccionar() async {
    final LatLng? ubicacion = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapaSelectorScreen()),
    );
    if (ubicacion != null) {
      setState(() {
        _latitudController.text = ubicacion.latitude.toStringAsFixed(6);
        _longitudController.text = ubicacion.longitude.toStringAsFixed(6);
        _ubicacionController.text = "${ubicacion.latitude.toStringAsFixed(6)},${ubicacion.longitude.toStringAsFixed(6)}";
        _bloquearLatLon = true;
      });
    }
  }

  @override
  void dispose() {
    _ubicacionController.dispose();
    _descripcionController.dispose();
    _zonaController.dispose();
    _temperaturaController.dispose();
    _humedadController.dispose();
    _precipitacionController.dispose();
    _vientoController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Alerta', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3366CC),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F9FF),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildCard(
                  children: [
                    _seccionTitulo("📌 Información Básica"),
                    _buildDropdown(
                      label: "Tipo de Alerta",
                      icon: Icons.category,
                      items: tipos,
                      value: _tipoSeleccionado,
                      onChanged: (val) => setState(() => _tipoSeleccionado = val),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: "Nivel de Riesgo",
                      icon: Icons.warning_amber,
                      items: niveles,
                      value: _nivelSeleccionado,
                      onChanged: (val) => setState(() => _nivelSeleccionado = val),
                    ),
                    const SizedBox(height: 12),
                    _buildUbicacionField(),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _zonaController,
  'Zona (predeterminada: Achupallas)',
  icon: Icons.map,
),const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _latitudController,
                            'Latitud',
                            isNumeric: true,
                            enabled: !_bloquearLatLon,
                            icon: Icons.location_on,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            _longitudController,
                            'Longitud',
                            isNumeric: true,
                            enabled: !_bloquearLatLon,
                            icon: Icons.location_on,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildCard(
                  children: [
                    _seccionTitulo("📝 Detalles de la Alerta"),
                    _buildTextField(
                      _descripcionController,
                      'Descripción detallada',
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _temperaturaController,
                            'Temperatura (°C)',
                            isNumeric: true,
                            icon: Icons.thermostat,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            _humedadController,
                            'Humedad (%)',
                            isNumeric: true,
                            icon: Icons.water_drop,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _precipitacionController,
                            'Precipitación (mm)',
                            isNumeric: true,
                            icon: Icons.cloudy_snowing,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            _vientoController,
                            'Viento (km/h)',
                            isNumeric: true,
                            icon: Icons.air,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3366CC),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Creando alerta...', style: TextStyle(color: Colors.white)),
                            ],
                          )
                        : const Text(
                            'CREAR ALERTA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _seccionTitulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            texto,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3366CC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUbicacionField() {
    return TextFormField(
      controller: _ubicacionController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Ubicación geográfica',
        hintText: 'Selecciona en el mapa',
        prefixIcon: const Icon(Icons.map, color: Color(0xFF3366CC)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.place, color: Color(0xFF3366CC)),
          onPressed: _abrirMapaYSeleccionar,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) => null,
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumeric = false,
    bool enabled = true,
    IconData? icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.multiline,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF3366CC)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade200,
      ),
      validator: (value) {
  if (!enabled) return null; // Si el campo está bloqueado, no validar
  if (value == null || value.trim().isEmpty) return null; // PERMITIR VACÍO para asignar por defecto
  if (isNumeric && double.tryParse(value.trim()) == null) {
    return 'Ingrese un número válido';
  }
  return null;
}
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF3366CC)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) => value == null || value.trim().isEmpty ? 'Selecciona una opción' : null,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(10),
      style: const TextStyle(color: Colors.black87),
    );
  }
}