// Reemplaza TODO tu archivo alerta_model.dart con esto:

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
  final bool vistaPorUsuario;

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
    this.vistaPorUsuario = false, // valor por defecto
  });

  // El factory constructor CORREGIDO
  factory Alerta.fromJson(Map<String, dynamic> json) {
    
    // --- INICIO DE LA CORRECCIÓN ---

    // 1. Obtenemos el string de la fecha desde el JSON.
    String fechaString = json['fecha'] as String;

    // 2. Verificamos si el string YA termina en 'Z' (que significa UTC).
    //    Si no termina en 'Z', se la añadimos para forzar
    //    que DateTime.parse() la interprete como HORA UTC.
    if (!fechaString.endsWith('Z')) {
      fechaString += 'Z';
    }

    // 3. Ahora sí, parseamos el string (que sabemos es UTC)
    //    a un objeto DateTime.
    final DateTime fechaUtc = DateTime.parse(fechaString);

    // --- FIN DE LA CORRECCIÓN ---


    // 4. Retornamos la Alerta con la fecha UTC parseada
    return Alerta(
      id: json['id'],
      tipo: json['tipo'],
      nivel: json['nivel'],
      ubicacion: json['ubicacion'],
      descripcion: json['descripcion'],
      
      // Asignamos el objeto DateTime (en UTC) a la propiedad 'fecha'.
      fecha: fechaUtc,
      
      temperatura: (json['temperatura'] as num?)?.toDouble(),
      humedad: (json['humedad'] as num?)?.toDouble(),
      precipitacion: (json['precipitacion'] as num?)?.toDouble(),
      viento: (json['viento'] as num?)?.toDouble(),
      vistaPorUsuario: json['vista_por_usuario'] ?? false,
    );
  }
}