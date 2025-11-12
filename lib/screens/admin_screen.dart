import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminScreen extends StatefulWidget {
  final String adminId;
  const AdminScreen({super.key, required this.adminId});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AuthService authService = AuthService();
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  void loadUsers() async {
    final result = await authService.fetchUsers();
    if (result != null) {
      setState(() {
        users = result;
        isLoading = false;
      });
    }
  }

  void updateUserRole(String userId, String newRole) async {
    final success = await authService.updateUserRole(userId, newRole);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Rol actualizado a $newRole")));
      loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al actualizar rol")));
    }
  }

  void deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Eliminar usuario?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Eliminar")),
        ],
      ),
    );

    if (confirm == true) {
      final success = await authService.deleteUser(userId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario eliminado")));
        loadUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al eliminar usuario")));
      }
    }
  }

  void createUserAsAdmin() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    String selectedRole = 'usuario';

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Crear Usuario"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: emailController, decoration: const InputDecoration(labelText: "Correo")),
                TextField(controller: passwordController, decoration: const InputDecoration(labelText: "Contraseña")),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nombre")),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: ['admin', 'autoridad', 'usuario', 'invitado']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) selectedRole = value;
                  },
                  decoration: const InputDecoration(labelText: "Rol"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Crear"),
              onPressed: () async {
                final success = await authService.createUserAsAdmin(
                  emailController.text,
                  passwordController.text,
                  nameController.text,
                  selectedRole,
                );
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario creado")));
                  loadUsers();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al crear usuario")));
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
  title: const Text("Administrar Usuarios"),
  backgroundColor: const Color(0xFF3366CC),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      Navigator.pushReplacementNamed(context, '/dashboard');
    },
  ),
  actions: [
    IconButton(
      tooltip: 'Ver monitoreo de datos',
      icon: const Icon(Icons.analytics_outlined),
      onPressed: () {
        Navigator.pushNamed(context, '/monitoreo');
      },
    ),
  ],
),

    floatingActionButton: FloatingActionButton(
      backgroundColor: const Color(0xFF3366CC),
      onPressed: createUserAsAdmin,
      child: const Icon(Icons.add),
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(user['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("📧 ${user['email']}  •  Rol: ${user['role']}"),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'eliminar') {
                        deleteUser(user['id'].toString());
                      } else {
                        updateUserRole(user['id'].toString(), value);
                      }
                    },
                    itemBuilder: (_) => [
                      ...['admin', 'autoridad', 'usuario', 'invitado']
                          .map((r) => PopupMenuItem(value: r, child: Text("Cambiar a $r"))),
                      const PopupMenuItem(value: 'eliminar', child: Text("🗑️ Eliminar")),
                    ],
                  ),
                ),
              );
            },
          ),
  );
}
}
