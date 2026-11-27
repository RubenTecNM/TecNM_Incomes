namespace TecNM.Api.Modules.Adeudos;

public sealed record AdeudoItemDTO(
    long IdAdeudo,
    string Matricula,
    string ConceptoCobro,
    int IdPeriodo,
    string PeriodoCodigo,
    decimal MontoOriginal,
    decimal SaldoPendiente,
    DateOnly? FechaLimite,
    string Estado,
    bool EstaVencido,
    int DiasVencido);

public sealed record AdeudoDetalleDTO(
    long IdAdeudo,
    string Matricula,
    string AlumnoNombre,
    string Carrera,
    string EstatusAlumno,
    string ConceptoCobro,
    int IdPeriodo,
    string PeriodoCodigo,
    short PeriodoAnio,
    string PeriodoCiclo,
    decimal MontoOriginal,
    decimal SaldoPendiente,
    DateOnly? FechaLimite,
    string Estado,
    bool EstaVencido,
    int DiasVencido);

public sealed record DeudorFiltroResultadoDTO(
    long IdAdeudo,
    string Matricula,
    string NombreCompleto,
    string Carrera,
    string ConceptoCobro,
    string PeriodoCodigo,
    DateOnly? FechaLimite,
    decimal MontoOriginal,
    decimal SaldoPendiente,
    string Estado,
    bool EstaVencido);

public sealed record ResumenSaldosVencidosDTO(
    int TotalAdeudosPendientes,
    int TotalVencidos,
    int TotalPorVencer,
    decimal MontoOriginalTotal,
    decimal SaldoPendienteTotal,
    decimal SaldoVencidoTotal,
    decimal SaldoPorVencerTotal,
    DateOnly FechaReferencia);

public sealed record CrearAdeudoRequest(
    string Matricula,
    string ConceptoCobro,
    int IdPeriodo,
    decimal MontoOriginal,
    DateOnly? FechaLimite = null);

public sealed record AbonarAdeudoRequest(
    decimal MontoAbono);

public sealed record BecaDescuentoDTO(
    long IdBeca,
    string Matricula,
    string AlumnoNombre,
    int IdPeriodo,
    string PeriodoCodigo,
    string TipoBeca,
    decimal Porcentaje,
    decimal MontoFijo,
    string? Motivo,
    bool Activa);

public sealed record AplicarBecaRequest(
    string Matricula,
    int IdPeriodo,
    string TipoBeca,
    decimal Porcentaje,
    decimal MontoFijo,
    string? Motivo = null,
    bool RecalcularAdeudosPendientes = true);

public sealed record AplicarBecaResponse(
    BecaDescuentoDTO Beca,
    int AdeudosActualizados,
    decimal DescuentoTotalAplicado);
