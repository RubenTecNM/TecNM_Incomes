using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace TecNM.Api.Modules.ConceptosCobro;

/// <summary>
/// RESTful Controller providing HTTP endpoints for Payment Concepts (Conceptos de Cobro) management.
/// Follows the Thin Controller design pattern, delegating domain logic to ConceptoCobroService.
/// </summary>
[ApiController]
[Route("api/conceptos-cobro")]
[Produces("application/json")]
public sealed class ConceptoCobroController(ConceptoCobroService conceptoService) : ControllerBase
{
    /// <summary>
    /// Retrieves a paginated list of payment concepts with optional text search, category filtering, and status filters.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(PagedResult<ConceptoCobroResponseDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<ConceptoCobroResponseDTO>>> GetPaged(
        [FromQuery] ConceptoCobroFilterParams filters,
        CancellationToken cancellationToken)
    {
        var result = await conceptoService.GetPagedAsync(filters, cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Retrieves all active concepts in an unpaginated list, optimized for cashier UI pickers and selectors.
    /// </summary>
    [HttpGet("all")]
    [ProducesResponseType(typeof(IReadOnlyList<ConceptoCobroResponseDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<ConceptoCobroResponseDTO>>> GetAllActive(
        CancellationToken cancellationToken)
    {
        var result = await conceptoService.GetAllActiveAsync(cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Retrieves the list of all distinct category names existing in the system.
    /// </summary>
    [HttpGet("categories")]
    [ProducesResponseType(typeof(IReadOnlyList<string>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<string>>> GetCategories(
        CancellationToken cancellationToken)
    {
        var categories = await conceptoService.GetCategoriesAsync(cancellationToken);
        return Ok(categories);
    }

    /// <summary>
    /// Retrieves a single concept by its unique identifier (UUID).
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ConceptoCobroResponseDTO), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ConceptoCobroResponseDTO>> GetById(
        [FromRoute] Guid id,
        CancellationToken cancellationToken)
    {
        var concept = await conceptoService.GetByIdAsync(id, cancellationToken);
        if (concept is null)
        {
            return NotFound(new { message = $"Payment concept with ID '{id}' was not found." });
        }

        return Ok(concept);
    }

    /// <summary>
    /// Creates a new payment concept.
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(ConceptoCobroResponseDTO), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ConceptoCobroResponseDTO>> Create(
        [FromBody] CreateConceptoCobroRequest request,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        try
        {
            var created = await conceptoService.CreateAsync(request, cancellationToken);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Updates an existing payment concept's description, base fee, order, and flags.
    /// </summary>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ConceptoCobroResponseDTO), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ConceptoCobroResponseDTO>> Update(
        [FromRoute] Guid id,
        [FromBody] UpdateConceptoCobroRequest request,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        try
        {
            var updated = await conceptoService.UpdateAsync(id, request, cancellationToken);
            return Ok(updated);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Toggles the active/inactive state of a concept.
    /// </summary>
    [HttpPatch("{id:guid}/toggle-status")]
    [ProducesResponseType(typeof(ConceptoCobroResponseDTO), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ConceptoCobroResponseDTO>> ToggleStatus(
        [FromRoute] Guid id,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await conceptoService.ToggleStatusAsync(id, cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Deletes a payment concept. If the concept is already linked to receipt history, it is automatically soft-deleted.
    /// </summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(
        [FromRoute] Guid id,
        CancellationToken cancellationToken)
    {
        try
        {
            var wasHardDeleted = await conceptoService.DeleteAsync(id, cancellationToken);
            if (!wasHardDeleted)
            {
                return Ok(new
                {
                    message = "The concept has existing receipt history and was safely deactivated (soft-deleted) rather than permanently removed."
                });
            }

            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    // Compatibility alias for /api/caja/cuentas consolidated into ConceptosCobro
    [HttpGet("/api/caja/cuentas")]
    public async Task<IActionResult> GetCuentasAlias(CancellationToken cancellationToken)
    {
        var items = await conceptoService.GetAllActiveAsync(cancellationToken);
        return Ok(items.Select(c => new
        {
            id = c.Id,
            cuenta = c.Clave,
            descripcion = c.Descripcion,
            costo = c.CuotaBase,
            categoria = c.Categoria,
            aplicaBeca = c.AplicaBeca
        }));
    }
}
