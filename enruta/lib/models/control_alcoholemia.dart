class ControlAlcoholemia {
  final int? id;
  final int agenteId;
  final String fecha;
  final String resultado;
  final double? graduacion;
  final String? servicioExtra;
  final String? observacion;
  final String? createdAt;

  ControlAlcoholemia({
    this.id,
    required this.agenteId,
    required this.fecha,
    required this.resultado,
    this.graduacion,
    this.servicioExtra,
    this.observacion,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'agente_id': agenteId,
      'fecha': fecha,
      'resultado': resultado,
      'graduacion': graduacion,
      'servicio_extra': servicioExtra,
      'observacion': observacion,
      'created_at': createdAt,
    };
  }

  factory ControlAlcoholemia.fromMap(Map<String, dynamic> map) {
    return ControlAlcoholemia(
      id: map['id'] as int?,
      agenteId: map['agente_id'] as int,
      fecha: map['fecha'] as String,
      resultado: map['resultado'] as String,
      graduacion: (map['graduacion'] as num?)?.toDouble(),
      servicioExtra: map['servicio_extra'] as String?,
      observacion: map['observacion'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agente_id': agenteId,
      'fecha': fecha,
      'resultado': resultado,
      'graduacion': graduacion,
      'servicio_extra': servicioExtra,
      'observacion': observacion,
    };
  }

  ControlAlcoholemia copyWith({
    int? id,
    int? agenteId,
    String? fecha,
    String? resultado,
    double? graduacion,
    String? servicioExtra,
    String? observacion,
    String? createdAt,
  }) {
    return ControlAlcoholemia(
      id: id ?? this.id,
      agenteId: agenteId ?? this.agenteId,
      fecha: fecha ?? this.fecha,
      resultado: resultado ?? this.resultado,
      graduacion: graduacion ?? this.graduacion,
      servicioExtra: servicioExtra ?? this.servicioExtra,
      observacion: observacion ?? this.observacion,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
