class Alerta {
  final int id;
  final String tipo;
  final String nivel;
  final String ubicacion;
  final String descripcion;
  final DateTime fecha;
  final double? temperatura;
  final double? humedad;
  final double? precipitacion;
  final double? viento;
  final bool vistaPorUsuario; // ✅ NUEVO

  Alerta({
    required this.id,
    required this.tipo,
    required this.nivel,
    required this.ubicacion,
    required this.descripcion,
    required this.fecha,
    this.temperatura,
    this.humedad,
    this.precipitacion,
    this.viento,
    this.vistaPorUsuario = false, // ✅ valor por defecto
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      id: json['id'],
      tipo: json['tipo'],
      nivel: json['nivel'],
      ubicacion: json['ubicacion'],
      descripcion: json['descripcion'],
      fecha: DateTime.parse(json['fecha']),
      temperatura: (json['temperatura'] as num?)?.toDouble(),
      humedad: (json['humedad'] as num?)?.toDouble(),
      precipitacion: (json['precipitacion'] as num?)?.toDouble(),
      viento: (json['viento'] as num?)?.toDouble(),
      vistaPorUsuario: json['vista_por_usuario'] ?? false, // ✅ Lógica nueva
    );
  }
}
