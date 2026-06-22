class ObservacionReclamo {
  final int? id;
  final int agenteId;
  final String tipo;
  final String descripcion;
  final String fecha;
  final bool resuelto;
  final String? createdAt;

  ObservacionReclamo({
    this.id,
    required this.agenteId,
    required this.tipo,
    required this.descripcion,
    required this.fecha,
    this.resuelto = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'agente_id': agenteId,
      'tipo': tipo,
      'descripcion': descripcion,
      'fecha': fecha,
      'resuelto': resuelto ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory ObservacionReclamo.fromMap(Map<String, dynamic> map) {
    return ObservacionReclamo(
      id: map['id'] as int?,
      agenteId: map['agente_id'] as int,
      tipo: map['tipo'] as String,
      descripcion: map['descripcion'] as String,
      fecha: map['fecha'] as String,
      resuelto: (map['resuelto'] as int?) == 1,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agente_id': agenteId,
      'tipo': tipo,
      'descripcion': descripcion,
      'fecha': fecha,
      'resuelto': resuelto,
    };
  }

  ObservacionReclamo copyWith({
    int? id,
    int? agenteId,
    String? tipo,
    String? descripcion,
    String? fecha,
    bool? resuelto,
    String? createdAt,
  }) {
    return ObservacionReclamo(
      id: id ?? this.id,
      agenteId: agenteId ?? this.agenteId,
      tipo: tipo ?? this.tipo,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      resuelto: resuelto ?? this.resuelto,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
