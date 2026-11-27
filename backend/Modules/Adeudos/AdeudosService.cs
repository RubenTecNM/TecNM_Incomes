using Microsoft.EntityFrameworkCore;
using TecNM.Api.Core.Entities;
using TecNM.Api.Data;

namespace TecNM.Api.Modules.Adeudos;

/// <summary>
/// Provides student debt (adeudos), overdue balance calculations, and scholarship/discount operations.
/// </summary>
public sealed class AdeudosService(TecNMDbContext dbContext)
{
    public async Task<List<AdeudoDetalleDTO>> ConsultarAdeudosGeneralAsync(
        string? matricula,
        string? nombre,
        string? concepto,
        int? periodoId,
        string? estado,
        DateOnly? fechaCorte,
        bool soloVencidos,
        CancellationToken cancellationToken)
    {
        var hoy = DateOnly.FromDateTime(DateTime.UtcNow);
        var query = dbContext.Adeudos
            .AsNoTracking()
            .Include(a => a.Alumno)
            .Include(a => a.Periodo)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(matricula))
        {
            var mat = matricula.Trim().ToLower();
            var matriculasEquivalentes = await dbContext.AlumnoMatriculasHistorial
                .AsNoTracking()
                .Where(h => h.MatriculaPrevia.ToLower().Contains(mat))
                .Select(h => h.MatriculaAlumno.ToLower())
                .Distinct()
                .ToListAsync(cancellationToken);

            query = query.Where(a =>
                a.Matricula.ToLower().Contains(mat)
                || matriculasEquivalentes.Contains(a.Matricula.ToLower()));
        }

        if (!string.IsNullOrWhiteSpace(nombre))
        {
            var nom = nombre.Trim().ToLower();
            query = query.Where(a => a.Alumno != null && a.Alumno.NombreCompleto.ToLower().Contains(nom));
        }

        if (!string.IsNullOrWhiteSpace(concepto))
        {
            var c = concepto.Trim().ToLower();
            query = query.Where(a => a.ConceptoCobro.ToLower().Contains(c));
        }

        if (periodoId.HasValue)
        {
            query = query.Where(a => a.IdPeriodo == periodoId.Value);
        }

        if (!string.IsNullOrWhiteSpace(estado))
        {
            var est = estado.Trim().ToUpper();
            query = query.Where(a => a.Estado == est);
        }

        if (fechaCorte.HasValue)
        {
            var fc = fechaCorte.Value;
            query = query.Where(a => a.FechaLimite == null || a.FechaLimite <= fc);
        }

        if (soloVencidos)
        {
            query = query.Where(a =>
                (a.Estado == "PENDIENTE" || a.Estado == "PARCIAL")
                && a.FechaLimite != null
                && a.FechaLimite < hoy);
        }

        var rows = await query
            .OrderBy(a => a.Matricula)
            .ThenBy(a => a.Periodo != null ? a.Periodo.Anio : 0)
            .ToListAsync(cancellationToken);

        return rows.Select(a => ToDetalleDto(a, hoy)).ToList();
    }

    public async Task<List<DeudorFiltroResultadoDTO>> ConsultarDeudoresFechaCorteAsync(
        string? concepto,
        DateOnly? fechaCorte,
        bool quitarPagados,
        CancellationToken cancellationToken)
    {
        var hoy = DateOnly.FromDateTime(DateTime.UtcNow);
        var query = dbContext.Adeudos
            .AsNoTracking()
            .Include(a => a.Alumno)
            .Include(a => a.Periodo)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(concepto))
        {
            var c = concepto.Trim().ToLower();
            query = query.Where(a => a.ConceptoCobro.ToLower().Contains(c));
        }

        if (fechaCorte.HasValue)
        {
            var fc = fechaCorte.Value;
            query = query.Where(a => a.FechaLimite == null || a.FechaLimite <= fc);
        }

        if (quitarPagados)
        {
            query = query.Where(a => a.SaldoPendiente > 0 && a.Estado != "LIQUIDADO");
        }

        var rows = await query
            .OrderBy(a => a.FechaLimite ?? hoy)
            .ThenBy(a => a.Matricula)
            .ToListAsync(cancellationToken);

        return rows.Select(a => ToDeudorFiltroDto(a, hoy)).ToList();
    }

    public async Task<List<DeudorFiltroResultadoDTO>> ConsultarDeudoresFechaCuentaAsync(
        DateOnly? fecha,
        string? conceptos,
        CancellationToken cancellationToken)
    {
        var hoy = DateOnly.FromDateTime(DateTime.UtcNow);
        var query = dbContext.Adeudos
            .AsNoTracking()
            .Include(a => a.Alumno)
            .Include(a => a.Periodo)
            .Where(a => a.SaldoPendiente > 0 && a.Estado != "LIQUIDADO");

        if (fecha.HasValue)
        {
            var f = fecha.Value;
            query = query.Where(a => a.FechaLimite == null || a.FechaLimite <= f);
        }

        if (!string.IsNullOrWhiteSpace(conceptos))
        {
            var lista = conceptos
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .Select(x => x.ToLower())
                .ToList();

            if (lista.Count > 0)
            {
                query = query.Where(a => lista.Any(c => a.ConceptoCobro.ToLower().Contains(c)));
            }
        }

        var rows = await query
            .OrderBy(a => a.ConceptoCobro)
            .ThenBy(a => a.Matricula)
            .ToListAsync(cancellationToken);

        return rows.Select(a => ToDeudorFiltroDto(a, hoy)).ToList();
    }

    public async Task<List<DeudorFiltroResultadoDTO>> ConsultarDeudoresInscritosAsync(
        string? concepto,
        DateOnly? fecha,
        CancellationToken cancellationToken)
    {
        var hoy = DateOnly.FromDateTime(DateTime.UtcNow);
        var query = dbContext.Adeudos
            .AsNoTracking()
            .Include(a => a.Alumno)
            .Include(a => a.Periodo)
            .Where(a =>
                a.SaldoPendiente > 0
                && a.Estado != "LIQUIDADO"
                && a.Alumno != null
                && (a.Alumno.Estatus.ToUpper() == "ACTIVO" || a.Alumno.Estatus.ToUpper() == "INSCRITO"));

        if (!string.IsNullOrWhiteSpace(concepto))
        {
            var c = concepto.Trim().ToLower();
            query = query.Where(a => a.ConceptoCobro.ToLower().Contains(c));
        }

        if (fecha.HasValue)
        {
            var f = fecha.Value;
            query = query.Where(a => a.FechaLimite == null || a.FechaLimite <= f);
        }

        var rows = await query
            .OrderBy(a => a.Matricula)
            .ToListAsync(cancellationToken);

        return rows.Select(a => ToDeudorFiltroDto(a, hoy)).ToList();
    }

    public async Task<ResumenSaldosVencidosDTO> CalcularResumenSaldosVencidosAsync(
        int? periodoId,
        DateOnly? fechaReferencia,
        CancellationToken cancellationToken)
    {
        var refDate = fechaReferencia ?? DateOnly.FromDateTime(DateTime.UtcNow);
        var query = dbContext.Adeudos
            .AsNoTracking()
            .Where(a => a.SaldoPendiente > 0 && (a.Estado == "PENDIENTE" || a.Estado == "PARCIAL"));

        if (periodoId.HasValue)
        {
            query = query.Where(a => a.IdPeriodo == periodoId.Value);
        }

        var pendientes = await query.ToListAsync(cancellationToken);

        var vencidos = pendientes.Where(a => a.FechaLimite.HasValue && a.FechaLimite.Value < refDate).ToList();
        var porVencer = pendientes.Where(a => !a.FechaLimite.HasValue || a.FechaLimite.Value >= refDate).ToList();

        return new ResumenSaldosVencidosDTO(
            TotalAdeudosPendientes: pendientes.Count,
            TotalVencidos: vencidos.Count,
            TotalPorVencer: porVencer.Count,
            MontoOriginalTotal: pendientes.Sum(a => a.MontoOriginal),
            SaldoPendienteTotal: pendientes.Sum(a => a.SaldoPendiente),
            SaldoVencidoTotal: vencidos.Sum(a => a.SaldoPendiente),
            SaldoPorVencerTotal: porVencer.Sum(a => a.SaldoPendiente),
            FechaReferencia: refDate);
    }

    public async Task<AdeudoItemDTO> CrearAdeudoAsync(
        CrearAdeudoRequest request,
        CancellationToken cancellationToken)
    {
        var matricula = request.Matricula.Trim();
        var alumno = await dbContext.Alumnos
            .SingleOrDefaultAsync(a => a.Matricula == matricula, cancellationToken)
            ?? throw new KeyNotFoundException($"No se encontró el alumno con matrícula {matricula}.");

        var periodo = await dbContext.PeriodosAcademicos
            .SingleOrDefaultAsync(p => p.IdPeriodo == request.IdPeriodo, cancellationToken)
            ?? throw new KeyNotFoundException($"No se encontró el periodo académico {request.IdPeriodo}.");

        if (request.MontoOriginal <= 0)
        {
            throw new InvalidOperationException("El monto original del adeudo debe ser mayor a cero.");
        }

        var entity = new Adeudo
        {
            Matricula = alumno.Matricula,
            ConceptoCobro = request.ConceptoCobro.Trim().ToUpperInvariant(),
            IdPeriodo = periodo.IdPeriodo,
            MontoOriginal = request.MontoOriginal,
            SaldoPendiente = request.MontoOriginal,
            FechaLimite = request.FechaLimite,
            Estado = "PENDIENTE",
            CreatedAt = DateTimeOffset.UtcNow
        };

        dbContext.Adeudos.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);

        var hoy = DateOnly.FromDateTime(DateTime.UtcNow);
        var vencido = entity.FechaLimite.HasValue && entity.FechaLimite.Value < hoy;
        var dias = vencido ? hoy.DayNumber - entity.FechaLimite!.Value.DayNumber : 0;

        return new AdeudoItemDTO(
            entity.IdAdeudo,
            entity.Matricula,
            entity.ConceptoCobro,
            entity.IdPeriodo,
            periodo.Codigo,
            entity.MontoOriginal,
            entity.SaldoPendiente,
            entity.FechaLimite,
            entity.Estado,
            vencido,
            dias);
    }

    public async Task<AdeudoItemDTO> AbonarAdeudoAsync(
        long idAdeudo,
        AbonarAdeudoRequest request,
        CancellationToken cancellationToken)
    {
        if (request.MontoAbono <= 0)
        {
            throw new InvalidOperationException("El monto del abono debe ser mayor a cero.");
        }

        var adeudo = await dbContext.Adeudos
            .Include(a => a.Periodo)
            .SingleOrDefaultAsync(a => a.IdAdeudo == idAdeudo, cancellationToken)
            ?? throw new KeyNotFoundException($"No se encontró el adeudo {idAdeudo}.");

        adeudo.SaldoPendiente = Math.Max(0, adeudo.SaldoPendiente - request.MontoAbono);
        adeudo.Estado = adeudo.SaldoPendiente <= 0 ? "LIQUIDADO" : "PARCIAL";

        await dbContext.SaveChangesAsync(cancellationToken);

        var hoy = DateOnly.FromDateTime(DateTime.UtcNow);
        var vencido = (adeudo.Estado == "PENDIENTE" || adeudo.Estado == "PARCIAL")
            && adeudo.FechaLimite.HasValue
            && adeudo.FechaLimite.Value < hoy;
        var dias = vencido ? hoy.DayNumber - adeudo.FechaLimite!.Value.DayNumber : 0;

        return new AdeudoItemDTO(
            adeudo.IdAdeudo,
            adeudo.Matricula,
            adeudo.ConceptoCobro,
            adeudo.IdPeriodo,
            adeudo.Periodo?.Codigo ?? "VIGENTE",
            adeudo.MontoOriginal,
            adeudo.SaldoPendiente,
            adeudo.FechaLimite,
            adeudo.Estado,
            vencido,
            dias);
    }

    public async Task<List<BecaDescuentoDTO>> ListarBecasAsync(
        string? matricula,
        int? periodoId,
        bool soloActivas,
        CancellationToken cancellationToken)
    {
        var query = dbContext.BecasDescuentos
            .AsNoTracking()
            .Include(b => b.Alumno)
            .Include(b => b.Periodo)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(matricula))
        {
            var mat = matricula.Trim().ToLower();
            query = query.Where(b => b.Matricula.ToLower().Contains(mat));
        }

        if (periodoId.HasValue)
        {
            query = query.Where(b => b.IdPeriodo == periodoId.Value);
        }

        if (soloActivas)
        {
            query = query.Where(b => b.Activa);
        }

        var rows = await query
            .OrderByDescending(b => b.CreatedAt)
            .ToListAsync(cancellationToken);

        return rows.Select(ToBecaDto).ToList();
    }

    public async Task<AplicarBecaResponse> AplicarBecaAsync(
        AplicarBecaRequest request,
        CancellationToken cancellationToken)
    {
        var matricula = request.Matricula.Trim();
        var alumno = await dbContext.Alumnos
            .SingleOrDefaultAsync(a => a.Matricula == matricula, cancellationToken)
            ?? throw new KeyNotFoundException($"No se encontró el alumno con matrícula {matricula}.");

        var periodo = await dbContext.PeriodosAcademicos
            .SingleOrDefaultAsync(p => p.IdPeriodo == request.IdPeriodo, cancellationToken)
            ?? throw new KeyNotFoundException($"No se encontró el periodo académico {request.IdPeriodo}.");

        if (request.Porcentaje < 0 || request.Porcentaje > 100)
        {
            throw new InvalidOperationException("El porcentaje de beca debe estar entre 0 y 100.");
        }

        if (request.MontoFijo < 0)
        {
            throw new InvalidOperationException("El monto fijo de descuento no puede ser negativo.");
        }

        var beca = new BecaDescuento
        {
            Matricula = alumno.Matricula,
            IdPeriodo = periodo.IdPeriodo,
            TipoBeca = string.IsNullOrWhiteSpace(request.TipoBeca) ? "ACADEMICA" : request.TipoBeca.Trim().ToUpperInvariant(),
            Porcentaje = request.Porcentaje,
            MontoFijo = request.MontoFijo,
            Motivo = request.Motivo?.Trim(),
            Activa = true,
            CreatedAt = DateTimeOffset.UtcNow
        };

        dbContext.BecasDescuentos.Add(beca);

        // Sync student scholarship flags
        alumno.TieneBeca = true;
        if (request.Porcentaje > alumno.PorcentajeBeca)
        {
            alumno.PorcentajeBeca = request.Porcentaje;
        }

        var adeudosActualizados = 0;
        var descuentoTotal = 0m;

        if (request.RecalcularAdeudosPendientes)
        {
            var adeudosPendientes = await dbContext.Adeudos
                .Where(a => a.Matricula == alumno.Matricula
                    && a.IdPeriodo == periodo.IdPeriodo
                    && a.SaldoPendiente > 0
                    && (a.Estado == "PENDIENTE" || a.Estado == "PARCIAL"))
                .ToListAsync(cancellationToken);

            foreach (var adeudo in adeudosPendientes)
            {
                var descuentoPorc = request.Porcentaje > 0
                    ? Math.Round(adeudo.SaldoPendiente * (request.Porcentaje / 100m), 2, MidpointRounding.AwayFromZero)
                    : 0m;
                var descuento = Math.Min(adeudo.SaldoPendiente, descuentoPorc + request.MontoFijo);

                if (descuento > 0)
                {
                    adeudo.SaldoPendiente = Math.Max(0, adeudo.SaldoPendiente - descuento);
                    adeudo.Estado = adeudo.SaldoPendiente <= 0 ? "LIQUIDADO" : "PARCIAL";
                    descuentoTotal += descuento;
                    adeudosActualizados++;
                }
            }
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        beca.Alumno = alumno;
        beca.Periodo = periodo;

        return new AplicarBecaResponse(
            ToBecaDto(beca),
            adeudosActualizados,
            descuentoTotal);
    }

    public async Task<BecaDescuentoDTO> ToggleBecaAsync(long idBeca, CancellationToken cancellationToken)
    {
        var beca = await dbContext.BecasDescuentos
            .Include(b => b.Alumno)
            .Include(b => b.Periodo)
            .SingleOrDefaultAsync(b => b.IdBeca == idBeca, cancellationToken)
            ?? throw new KeyNotFoundException($"No se encontró la beca {idBeca}.");

        beca.Activa = !beca.Activa;

        if (beca.Alumno != null)
        {
            var otrasActivas = await dbContext.BecasDescuentos
                .Where(b => b.Matricula == beca.Matricula && b.IdBeca != beca.IdBeca && b.Activa)
                .ToListAsync(cancellationToken);

            var todasActivas = beca.Activa ? [.. otrasActivas, beca] : otrasActivas;
            beca.Alumno.TieneBeca = todasActivas.Count > 0;
            beca.Alumno.PorcentajeBeca = todasActivas.Count > 0 ? todasActivas.Max(x => x.Porcentaje) : 0m;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        return ToBecaDto(beca);
    }

    private static AdeudoDetalleDTO ToDetalleDto(Adeudo a, DateOnly hoy)
    {
        var esPendiente = a.Estado == "PENDIENTE" || a.Estado == "PARCIAL";
        var vencido = esPendiente && a.FechaLimite.HasValue && a.FechaLimite.Value < hoy;
        var dias = vencido ? hoy.DayNumber - a.FechaLimite!.Value.DayNumber : 0;

        return new AdeudoDetalleDTO(
            a.IdAdeudo,
            a.Matricula,
            a.Alumno?.NombreCompleto ?? "Sin Nombre",
            a.Alumno?.Carrera ?? "Sin Carrera",
            a.Alumno?.Estatus ?? "ACTIVO",
            a.ConceptoCobro,
            a.IdPeriodo,
            a.Periodo?.Codigo ?? "N/D",
            a.Periodo?.Anio ?? (short)hoy.Year,
            a.Periodo?.Ciclo ?? "PRIMAVERA",
            a.MontoOriginal,
            a.SaldoPendiente,
            a.FechaLimite,
            a.Estado,
            vencido,
            dias);
    }

    private static DeudorFiltroResultadoDTO ToDeudorFiltroDto(Adeudo a, DateOnly hoy)
    {
        var esPendiente = a.Estado == "PENDIENTE" || a.Estado == "PARCIAL";
        var vencido = esPendiente && a.FechaLimite.HasValue && a.FechaLimite.Value < hoy;

        return new DeudorFiltroResultadoDTO(
            a.IdAdeudo,
            a.Matricula,
            a.Alumno?.NombreCompleto ?? "Sin Nombre",
            a.Alumno?.Carrera ?? "Sin Carrera",
            a.ConceptoCobro,
            a.Periodo?.Codigo ?? "N/D",
            a.FechaLimite,
            a.MontoOriginal,
            a.SaldoPendiente,
            a.Estado,
            vencido);
    }

    private static BecaDescuentoDTO ToBecaDto(BecaDescuento b) =>
        new(
            b.IdBeca,
            b.Matricula,
            b.Alumno?.NombreCompleto ?? "Sin Nombre",
            b.IdPeriodo,
            b.Periodo?.Codigo ?? "VIGENTE",
            b.TipoBeca,
            b.Porcentaje,
            b.MontoFijo,
            b.Motivo,
            b.Activa);
}
