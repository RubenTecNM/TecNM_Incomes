using Microsoft.AspNetCore.Mvc;

namespace TecNM.Api.Modules.Caja;

[ApiController]
[Route("api/caja")]
public sealed class CajaController(CajaService cajaService) : ControllerBase
{
    // =========================================================================
    // 1. Alumnos and Control Escolar -> Decoupled to AlumnosController
    // 2. Adeudos and Becas -> Decoupled to AdeudosController
    // =========================================================================

    // =========================================================================
    // 3. Empleados/Cajeros (Cuentas -> Decoupled to CuentasController)
    // =========================================================================

    [HttpGet("empleados")]
    public async Task<ActionResult<List<EmpleadoDTO>>> ListarEmpleados(CancellationToken cancellationToken)
    {
        var empleados = await cajaService.ListarEmpleadosAsync(cancellationToken);
        return Ok(empleados);
    }

    [HttpPost("empleados")]
    public async Task<ActionResult<EmpleadoDTO>> CrearEmpleado(
        [FromBody] CrearEmpleadoRequest req,
        CancellationToken cancellationToken)
    {
        try
        {
            var empleado = await cajaService.CrearEmpleadoAsync(req, cancellationToken);
            return Created($"/api/caja/empleados/{empleado.Id}", empleado);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    // =========================================================================
    // 4. Catálogos Académicos (Carreras -> AlumnosController, Periodos y Conceptos)
    // =========================================================================

    [HttpGet("periodos")]
    public async Task<ActionResult<List<PeriodoDTO>>> GetPeriodos(CancellationToken cancellationToken)
    {
        var periodos = await cajaService.GetPeriodosAsync(cancellationToken);
        return Ok(periodos);
    }

    [HttpGet("conceptos")]
    public async Task<ActionResult<List<ConceptoDTO>>> GetConceptos(CancellationToken cancellationToken)
    {
        var conceptos = await cajaService.GetConceptosAsync(cancellationToken);
        return Ok(conceptos);
    }

    // =========================================================================
    // 5. Análisis y Desglose de Referencias Bancarias (5+5)
    // =========================================================================

    [HttpGet("referencias/desglosar")]
    public async Task<ActionResult<DesgloseReferenciaDTO>> DesglosarReferencia(
        [FromQuery] string referencia,
        CancellationToken cancellationToken)
    {
        var desglose = await cajaService.DesglosarReferenciaAsync(referencia, cancellationToken);
        return Ok(desglose);
    }

    // =========================================================================
    // 7. Corte Diario, Pólizas y Reportes (Para Modales del Frontend)
    // =========================================================================

    [HttpGet("corte")]
    public async Task<ActionResult<CorteCajaResponse>> GetCorteDiario(
        [FromQuery] DateOnly? fecha,
        CancellationToken cancellationToken)
    {
        var corte = await cajaService.GetCorteDiarioAsync(fecha, null, cancellationToken);
        return Ok(corte);
    }

    // =========================================================================
    // 7. Polizas and Detailed Ledgers -> Decoupled to PolizasController
    // =========================================================================

    [HttpGet("reportes/ingresos")]
    public async Task<ActionResult<ReporteIngresoResumenDTO>> GetReporteIngresos(
        [FromQuery] string? fecha,
        CancellationToken cancellationToken)
    {
        var reporte = await cajaService.GetReporteIngresosAsync(fecha, cancellationToken);
        return Ok(reporte);
    }

    [HttpGet("reportes/verano")]
    public async Task<ActionResult<ReporteVeranoResumenDTO>> GetReporteVerano(
        [FromQuery] string? inicio,
        [FromQuery] string? fin,
        [FromQuery] string? concepto,
        CancellationToken cancellationToken)
    {
        var reporte = await cajaService.GetReporteVeranoAsync(inicio, fin, concepto, cancellationToken);
        return Ok(reporte);
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    private (string usuario, string nombre) GetCajeroSesion()
    {
        var usuario = User.FindFirst("name")?.Value
            ?? User.Identity?.Name
            ?? "cajero1";

        var nombre = User.FindFirst("fullName")?.Value
            ?? "Cajero Turno Matutino";

        return (usuario, nombre);
    }
}
