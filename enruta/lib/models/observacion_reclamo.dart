class ObservacionReclamo {
  final int? id;
  final int agenteId;
  final String tipo;
  final String descripcion;
  final String fecha;
  final String? createdAt;

  ObservacionReclamo({
    this.id,
    required this.agenteId,
    required this.tipo,
    required this.descripcion,
    required this.fecha,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'agente_id': agenteId,
      'tipo': tipo,
      'descripcion': descripcion,
      'fecha': fecha,
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
    };
  }

  ObservacionReclamo copyWith({
    int? id,
    int? agenteId,
    String? tipo,
    String? descripcion,
    String? fecha,
    String? createdAt,
  }) {
    return ObservacionReclamo(
      id: id ?? this.id,
      agenteId: agenteId ?? this.agenteId,
      tipo: tipo ?? this.tipo,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
