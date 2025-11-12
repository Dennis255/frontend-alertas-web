import 'package:flutter/material.dart';
import '../services/session_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String _nombre = '';
  String _email = '';
  String _rol = '';
  String _telefono = '';
  bool _isEditing = false;
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarDatosUsuario();
  }

  Future<void> cargarDatosUsuario() async {
    final nombre = await SessionService.getUserName();
    
    final rol = await SessionService.getUserRole();
    
    
    setState(() {
      _nombre = nombre;
      
      _rol = rol;
      
      _nombreController.text = nombre;
      
    });
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar cierre de sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await SessionService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _guardarCambios() async {
    setState(() {
      _isEditing = false;
      _nombre = _nombreController.text;
      _telefono = _telefonoController.text;
    });
    
    // Aquí iría la lógica para guardar los cambios en el backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cambios guardados exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3366CC), size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text('👤 Mi Perfil'),
        backgroundColor: const Color(0xFF3366CC),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            tooltip: _isEditing ? 'Guardar cambios' : 'Editar perfil',
            onPressed: () {
              if (_isEditing) {
                _guardarCambios();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
          child: Column(
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: Color(0xFF3366CC),
                            child: Icon(Icons.person, size: 60, color: Colors.white),
                          ),
                          if (_isEditing)
                            FloatingActionButton.small(
                              onPressed: () {
                                // Lógica para cambiar foto de perfil
                              },
                              backgroundColor: Colors.blue[200],
                              child: const Icon(Icons.camera_alt, size: 18),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _isEditing
                          ? _buildEditableField('Nombre', _nombreController)
                          : Text(
                              _nombre.isNotEmpty ? _nombre : 'Usuario',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                      const SizedBox(height: 8),
                      Text(
                        _rol,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      _isEditing
                          ? Column(
                              children: [
                                _buildEditableField('Email', _emailController),
                                _buildEditableField('Teléfono', _telefonoController),
                              ],
                            )
                          : Column(
                              children: [
                                _buildInfoItem(Icons.email, 'Correo electrónico', _email),
                                _buildInfoItem(Icons.phone, 'Teléfono', _telefono.isNotEmpty ? _telefono : 'No especificado'),
                                _buildInfoItem(Icons.shield, 'Rol', _rol),
                              ],
                            ),
                      const SizedBox(height: 24),
                      if (!_isEditing)
                        ElevatedButton.icon(
                          onPressed: _cerrarSesion,
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text('Cerrar sesión'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                      if (_isEditing)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () => setState(() => _isEditing = false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: _guardarCambios,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3366CC),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Guardar'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.settings, color: Color(0xFF3366CC)),
                        title: const Text('Configuración'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navegar a pantalla de configuración
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications, color: Color(0xFF3366CC)),
                        title: const Text('Notificaciones'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navegar a pantalla de notificaciones
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help, color: Color(0xFF3366CC)),
                        title: const Text('Ayuda y soporte'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navegar a pantalla de ayuda
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}