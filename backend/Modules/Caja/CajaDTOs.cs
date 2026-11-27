namespace TecNM.Api.Modules.Caja;

// =============================================================================
// 1. Catálogos Académicos
// =============================================================================

public sealed record CarreraDTO(
    int IdCarrera,
    string Carrera,
    string NombreCarrera,
    string? Titulo,
    bool Activo);

public sealed record PeriodoDTO(
    int IdPeriodo,
    string Codigo,
    string? Descripcion,
    short Anio,
    string Ciclo,
    DateOnly? FechaInicio,
    DateOnly? FechaFin,
    bool Activo);

// =============================================================================
// 2. Alumnos y Matrículas
// =============================================================================

public sealed record AlumnoDTO(
    string Matricula,
    string NombreCompleto,
    string Carrera,
    int Semestre,
    string Turno,
    string Estatus,
    bool TieneBeca,
    decimal PorcentajeBeca,
    int? IdCarrera = null,
    string? NumeroFicha = null,
    int? CuentaA = null,
    string? MatriculaPrevia = null);

public sealed record MatriculaHistorialDTO(
    long IdHistorial,
    string MatriculaAlumno,
    string MatriculaPrevia,
    string? PeriodoCodigo,
    DateTimeOffset FechaRegistro,
    string? MotivoCambio);

public sealed record CambiarMatriculaRequest(
    string NuevaMatricula,
    string MotivoCambio,
    int? IdPeriodo = null);

// =============================================================================
// 3. Adeudos y Becas -> Desacoplados a TecNM.Api.Modules.Adeudos
// =============================================================================

// =============================================================================
// 4. Cuentas y Empleados (Distinción entre Usuario, Cuenta y Banco)
// =============================================================================

public sealed record EmpleadoDTO(
    Guid Id,
    string Username,
    string Name,
    string Email,
    string Role,
    bool IsActive);

public sealed record CrearEmpleadoRequest(
    string Username,
    string Name,
    string Email,
    string Role,
    string Password);

public sealed record CuentaConceptoDTO(
    Guid Id,
    string Cuenta,
    string Descripcion,
    decimal Costo,
    string Categoria,
    bool AplicaBeca);

public sealed record CrearCuentaConceptoRequest(
    string Cuenta,
    string Descripcion,
    decimal Costo,
    string? Categoria = "Inscripción");

public sealed record ActualizarCuentaConceptoRequest(
    string Descripcion,
    decimal Costo,
    string? Categoria = null);

public sealed record ConceptoDTO(
    Guid Id,
    string Clave,
    string Descripcion,
    decimal CuotaBase,
    bool AplicaBeca,
    string Categoria,
    string? CuentaReferencia = null,
    int? Orden = null);

// =============================================================================
// 5. Análisis y Desglose de Referencias Bancarias (5+5)
// =============================================================================

public sealed record DesgloseReferenciaDTO(
    string ReferenciaOriginal,
    string CodigoEstudiante5,
    string CodigoConcepto5,
    AlumnoDTO? AlumnoDetectado,
    ConceptoDTO? ConceptoDetectado,
    List<ReciboResponse> RecibosPrevios,
    bool ReferenciaDuplicada,
    string Mensaje);

// =============================================================================
// 6. Recibos, Cobros y Cancelación
// =============================================================================

public sealed record DetalleItemRequest(
    Guid? ConceptoId,
    string Descripcion,
    int Cantidad,
    decimal CuotaUnitario,
    decimal DescuentoBeca,
    decimal ImporteTotal,
    string? PeriodoAno);

public sealed record CrearReciboRequest(
    string Matricula,
    string NombreCompleto,
    string Carrera,
    int Semestre,
    string Turno,
    string MetodoPago,
    string? ReferenciaBancaria,
    string? CuentaBancaria,
    DateTimeOffset? FechaBancaria,
    List<DetalleItemRequest> Detalles,
    DateTimeOffset? FechaOperacion = null,
    string? JustificacionFecha = null);

public sealed record DetalleItemResponse(
    Guid Id,
    Guid? ConceptoId,
    string Descripcion,
    int Cantidad,
    decimal CuotaUnitario,
    decimal DescuentoBeca,
    decimal ImporteTotal,
    string? PeriodoAno);

public sealed record ReciboResponse(
    Guid Id,
    long NumeroRecibo,
    string FolioAdministrativo,
    DateTimeOffset FechaOperacion,
    string AlumnoMatricula,
    string AlumnoNombre,
    string AlumnoCarrera,
    int AlumnoSemestre,
    string AlumnoTurno,
    string MetodoPago,
    string? ReferenciaBancaria,
    string? CuentaBancaria,
    DateTimeOffset? FechaBancaria,
    decimal Subtotal,
    decimal DescuentoTotal,
    decimal Total,
    string Estado,
    string? MotivoCancelacion,
    DateTimeOffset? FechaCancelacion,
    string CajeroUsuario,
    string CajeroNombre,
    List<DetalleItemResponse> Detalles);

public sealed record CancelarReciboRequest(
    string Motivo);

// =============================================================================
// 7. Corte Diario, Pólizas y Reportes Especializados
// =============================================================================

public sealed record CorteCajaResponse(
    DateOnly Fecha,
    decimal TotalEfectivo,
    decimal TotalBanco,
    decimal TotalRecaudado,
    int TotalRecibosEmitidos,
    int TotalRecibosCancelados);

public sealed record ReporteReciboDetalladoDTO(
    Guid ReciboId,
    long NumeroRecibo,
    string FolioAdministrativo,
    DateTimeOffset FechaOperacion,
    string AlumnoMatricula,
    string AlumnoNombre,
    string AlumnoCarrera,
    int AlumnoSemestre,
    string AlumnoTurno,
    string ConceptoDetalle,
    int Cantidad,
    decimal CuotaUnitario,
    decimal DescuentoBeca,
    decimal ImporteRenglon,
    decimal TotalRecibo,
    string MetodoPago,
    string? ReferenciaBancaria,
    string EstadoRecibo,
    string CajeroUsuario,
    string CajeroNombre);

public sealed record PolizaIngresoFilaDTO(
    string Cuenta,
    string Concepto,
    int Cantidad,
    decimal Total);

public sealed record PolizaIngresoResumenDTO(
    string Fecha,
    decimal TotalGeneral,
    List<PolizaIngresoFilaDTO> Filas);

public sealed record ReporteIngresoFilaDTO(
    string Folio,
    string Concepto,
    string Nombre,
    decimal Total,
    string Estatus);

public sealed record ReporteIngresoResumenDTO(
    string Fecha,
    decimal TotalGeneral,
    List<ReporteIngresoFilaDTO> Filas);

public sealed record ReporteVeranoItemDTO(
    string ReciboNo,
    string Matricula,
    string Alumno,
    string Concepto,
    decimal Cuota,
    string Fecha);

public sealed record ReporteVeranoResumenDTO(
    string FechaInicio,
    string FechaFin,
    string Concepto,
    decimal CuotaUnitario,
    int TotalRegistros,
    decimal TotalRecaudado,
    List<ReporteVeranoItemDTO> Registros);
