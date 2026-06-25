class Agente {
  final int? id;
  final String legajo;
  final String apellidoNombre;
  final String? fechaIngreso;
  final String? dependencia;
  final String? cargo;
  final String? turno;
  final String? createdAt;
  final String? updatedAt;

  Agente({
    this.id,
    required this.legajo,
    required this.apellidoNombre,
    this.fechaIngreso,
    this.dependencia,
    this.cargo,
    this.turno,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'legajo': legajo,
      'apellido_nombre': apellidoNombre,
      'fecha_ingreso': fechaIngreso,
      'dependencia': dependencia,
      'cargo': cargo,
      'turno': turno,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Agente.fromMap(Map<String, dynamic> map) {
    return Agente(
      id: map['id'] as int?,
      legajo: map['legajo'] as String,
      apellidoNombre: map['apellido_nombre'] as String,
      fechaIngreso: map['fecha_ingreso'] as String?,
      dependencia: map['dependencia'] as String?,
      cargo: map['cargo'] as String?,
      turno: map['turno'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'legajo': legajo,
      'apellidoNombre': apellidoNombre,
      'fechaIngreso': fechaIngreso,
      'dependencia': dependencia,
      'cargo': cargo,
      'turno': turno,
    };
  }

  factory Agente.fromApiJson(Map<String, dynamic> map) {
    return Agente(
      id: map['id'] as int?,
      legajo: map['legajo'] as String,
      apellidoNombre: map['apellidoNombre'] as String,
      fechaIngreso: map['fechaIngreso'] as String?,
      dependencia: map['dependencia'] as String?,
      cargo: map['cargo'] as String?,
      turno: map['turno'] as String?,
      createdAt: map['createdAt'] as String?,
      updatedAt: map['updatedAt'] as String?,
    );
  }

  Agente copyWith({
    int? id,
    String? legajo,
    String? apellidoNombre,
    String? fechaIngreso,
    String? dependencia,
    String? cargo,
    String? turno,
    String? createdAt,
    String? updatedAt,
  }) {
    return Agente(
      id: id ?? this.id,
      legajo: legajo ?? this.legajo,
      apellidoNombre: apellidoNombre ?? this.apellidoNombre,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      dependencia: dependencia ?? this.dependencia,
      cargo: cargo ?? this.cargo,
      turno: turno ?? this.turno,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
