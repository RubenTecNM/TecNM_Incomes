using Microsoft.AspNetCore.Mvc;

namespace TecNM.Api.Modules.Adeudos;

/// <summary>
/// Vertical-slice controller for student debts (adeudos), debtors queries, and scholarships.
/// Dual-routed at /api/adeudos and /api/caja/adeudos for full frontend compatibility.
/// </summary>
[ApiController]
[Route("api/adeudos")]
[Route("api/caja/adeudos")]
public sealed class AdeudosController(AdeudosService adeudosService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<AdeudoDetalleDTO>>> ConsultarAdeudosGeneral(
        [FromQuery] string? matricula,
        [FromQuery] string? nombre,
        [FromQuery] string? concepto,
        [FromQuery] int? periodoId,
        [FromQuery] string? estado,
        [FromQuery] DateOnly? fechaCorte,
        [FromQuery] bool soloVencidos = false,
        CancellationToken cancellationToken = default)
    {
        var adeudos = await adeudosService.ConsultarAdeudosGeneralAsync(
            matricula, nombre, concepto, periodoId, estado, fechaCorte, soloVencidos, cancellationToken);
        return Ok(adeudos);
    }

    [HttpGet("resumen-vencidos")]
    public async Task<ActionResult<ResumenSaldosVencidosDTO>> CalcularResumenVencidos(
        [FromQuery] int? periodoId,
        [FromQuery] DateOnly? fechaReferencia,
        CancellationToken cancellationToken = default)
    {
        var resumen = await adeudosService.CalcularResumenSaldosVencidosAsync(
            periodoId, fechaReferencia, cancellationToken);
        return Ok(resumen);
    }

    [HttpGet("deudores/fecha-corte")]
    [HttpGet("/api/caja/deudores/fecha-corte")]
    public async Task<ActionResult<List<DeudorFiltroResultadoDTO>>> ConsultarDeudoresFechaCorte(
        [FromQuery] string? concepto,
        [FromQuery] DateOnly? fechaCorte,
        [FromQuery] bool quitarPagados = true,
        CancellationToken cancellationToken = default)
    {
        var resultado = await adeudosService.ConsultarDeudoresFechaCorteAsync(
            concepto, fechaCorte, quitarPagados, cancellationToken);
        return Ok(resultado);
    }

    [HttpGet("deudores/fecha-cuenta")]
    [HttpGet("/api/caja/deudores/fecha-cuenta")]
    public async Task<ActionResult<List<DeudorFiltroResultadoDTO>>> ConsultarDeudoresFechaCuenta(
        [FromQuery] DateOnly? fecha,
        [FromQuery] string? conceptos,
        CancellationToken cancellationToken = default)
    {
        var resultado = await adeudosService.ConsultarDeudoresFechaCuentaAsync(
            fecha, conceptos, cancellationToken);
        return Ok(resultado);
    }

    [HttpGet("deudores/inscritos")]
    [HttpGet("/api/caja/deudores/inscritos")]
    public async Task<ActionResult<List<DeudorFiltroResultadoDTO>>> ConsultarDeudoresInscritos(
        [FromQuery] string? concepto,
        [FromQuery] DateOnly? fecha,
        CancellationToken cancellationToken = default)
    {
        var resultado = await adeudosService.ConsultarDeudoresInscritosAsync(
            concepto, fecha, cancellationToken);
        return Ok(resultado);
    }

    [HttpPost]
    public async Task<ActionResult<AdeudoItemDTO>> CrearAdeudo(
        [FromBody] CrearAdeudoRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var adeudo = await adeudosService.CrearAdeudoAsync(request, cancellationToken);
            return Created($"/api/adeudos/{adeudo.IdAdeudo}", adeudo);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{idAdeudo:long}/abonar")]
    public async Task<ActionResult<AdeudoItemDTO>> AbonarAdeudo(
        [FromRoute] long idAdeudo,
        [FromBody] AbonarAdeudoRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var adeudo = await adeudosService.AbonarAdeudoAsync(idAdeudo, request, cancellationToken);
            return Ok(adeudo);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("becas")]
    public async Task<ActionResult<List<BecaDescuentoDTO>>> ListarBecas(
        [FromQuery] string? matricula,
        [FromQuery] int? periodoId,
        [FromQuery] bool soloActivas = true,
        CancellationToken cancellationToken = default)
    {
        var becas = await adeudosService.ListarBecasAsync(matricula, periodoId, soloActivas, cancellationToken);
        return Ok(becas);
    }

    [HttpPost("becas")]
    public async Task<ActionResult<AplicarBecaResponse>> AplicarBeca(
        [FromBody] AplicarBecaRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await adeudosService.AplicarBecaAsync(request, cancellationToken);
            return Ok(response);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPatch("becas/{idBeca:long}/toggle")]
    public async Task<ActionResult<BecaDescuentoDTO>> ToggleBeca(
        [FromRoute] long idBeca,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var beca = await adeudosService.ToggleBecaAsync(idBeca, cancellationToken);
            return Ok(beca);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }
}
