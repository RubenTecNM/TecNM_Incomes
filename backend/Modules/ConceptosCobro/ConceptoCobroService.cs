using Microsoft.EntityFrameworkCore;
using TecNM.Api.Core.Entities;
using TecNM.Api.Data;

namespace TecNM.Api.Modules.ConceptosCobro;

/// <summary>
/// Domain service encapsulating business rules, validations, and data persistence for payment concepts.
/// </summary>
public sealed class ConceptoCobroService(
    TecNMDbContext dbContext,
    ILogger<ConceptoCobroService> logger)
{
    /// <summary>
    /// Retrieves a paginated list of payment concepts filtered by optional search query, category, and active status.
    /// </summary>
    public async Task<PagedResult<ConceptoCobroResponseDTO>> GetPagedAsync(
        ConceptoCobroFilterParams filters,
        CancellationToken cancellationToken = default)
    {
        var query = dbContext.ConceptosCobro.AsNoTracking().AsQueryable();

        // 1. Filter by search query (Clave or Description)
        if (!string.IsNullOrWhiteSpace(filters.Search))
        {
            var searchPattern = filters.Search.Trim().ToLower();
            query = query.Where(c =>
                c.Clave.ToLower().Contains(searchPattern) ||
                c.Descripcion.ToLower().Contains(searchPattern) ||
                (c.CuentaReferencia != null && c.CuentaReferencia.ToLower().Contains(searchPattern)));
        }

        // 2. Filter by category
        if (!string.IsNullOrWhiteSpace(filters.Categoria))
        {
            var category = filters.Categoria.Trim();
            query = query.Where(c => c.Categoria == category);
        }

        // 3. Filter by active flag
        if (filters.IsActive.HasValue)
        {
            query = query.Where(c => c.IsActive == filters.IsActive.Value);
        }

        // 4. Calculate total count before pagination
        var totalCount = await query.CountAsync(cancellationToken);

        // 5. Order results consistently
        query = query
            .OrderBy(c => c.Orden.HasValue ? c.Orden.Value : 999)
            .ThenBy(c => c.Categoria)
            .ThenBy(c => c.Clave);

        // 6. Apply pagination
        var skip = (filters.Page - 1) * filters.PageSize;
        var items = await query
            .Skip(skip)
            .Take(filters.PageSize)
            .Select(c => MapToDTO(c))
            .ToListAsync(cancellationToken);

        var totalPages = (int)Math.Ceiling(totalCount / (double)filters.PageSize);

        return new PagedResult<ConceptoCobroResponseDTO>(
            items,
            totalCount,
            filters.Page,
            filters.PageSize,
            totalPages);
    }

    /// <summary>
    /// Retrieves all active concepts without pagination, optimized for cashier UI dropdowns and select pickers.
    /// </summary>
    public async Task<IReadOnlyList<ConceptoCobroResponseDTO>> GetAllActiveAsync(
        CancellationToken cancellationToken = default)
    {
        return await dbContext.ConceptosCobro
            .AsNoTracking()
            .Where(c => c.IsActive)
            .OrderBy(c => c.Orden.HasValue ? c.Orden.Value : 999)
            .ThenBy(c => c.Clave)
            .Select(c => MapToDTO(c))
            .ToListAsync(cancellationToken);
    }

    /// <summary>
    /// Retrieves a single payment concept by its unique identifier.
    /// </summary>
    public async Task<ConceptoCobroResponseDTO?> GetByIdAsync(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var concept = await dbContext.ConceptosCobro
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);

        return concept is null ? null : MapToDTO(concept);
    }

    /// <summary>
    /// Retrieves a payment concept by its institutional code (Clave).
    /// </summary>
    public async Task<ConceptoCobroResponseDTO?> GetByClaveAsync(
        string clave,
        CancellationToken cancellationToken = default)
    {
        var normalizedClave = clave.Trim();
        var concept = await dbContext.ConceptosCobro
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Clave == normalizedClave, cancellationToken);

        return concept is null ? null : MapToDTO(concept);
    }

    private static readonly string[] DefaultCategories =
    [
        "Inscripción",
        "Reinscripción",
        "Constancias",
        "Cursos",
        "Exámenes",
        "Titulación",
        "Servicios",
        "Varios",
        "Otros"
    ];

    /// <summary>
    /// Retrieves a distinct list of all categories currently registered in the catalog merged with standard institutional categories.
    /// </summary>
    public async Task<IReadOnlyList<string>> GetCategoriesAsync(
        CancellationToken cancellationToken = default)
    {
        var dbCategories = await dbContext.ConceptosCobro
            .AsNoTracking()
            .Where(c => !string.IsNullOrWhiteSpace(c.Categoria))
            .Select(c => c.Categoria.Trim())
            .Distinct()
            .ToListAsync(cancellationToken);

        return dbCategories
            .Concat(DefaultCategories)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(c => c)
            .ToList();
    }

    /// <summary>
    /// Creates a new payment concept enforcing uniqueness of Clave and validation rules.
    /// </summary>
    public async Task<ConceptoCobroResponseDTO> CreateAsync(
        CreateConceptoCobroRequest request,
        CancellationToken cancellationToken = default)
    {
        var normalizedClave = request.Clave.Trim();

        // 1. Validate uniqueness of Clave
        var exists = await dbContext.ConceptosCobro
            .AnyAsync(c => c.Clave.ToLower() == normalizedClave.ToLower(), cancellationToken);

        if (exists)
        {
            logger.LogWarning("Attempted to create concept with duplicate Clave: {Clave}", normalizedClave);
            throw new InvalidOperationException($"A payment concept with code '{normalizedClave}' already exists.");
        }

        // 2. Map and persist new entity
        var concept = new ConceptoCobro
        {
            Id = Guid.NewGuid(),
            Clave = normalizedClave,
            Descripcion = request.Descripcion.Trim(),
            CuotaBase = request.CuotaBase,
            Orden = request.Orden,
            CuentaReferencia = string.IsNullOrWhiteSpace(request.CuentaReferencia) ? null : request.CuentaReferencia.Trim(),
            AplicaBeca = request.AplicaBeca,
            Categoria = request.Categoria.Trim(),
            IsActive = true
        };

        dbContext.ConceptosCobro.Add(concept);
        await dbContext.SaveChangesAsync(cancellationToken);

        logger.LogInformation("Successfully created payment concept: {Clave} (ID: {Id})", concept.Clave, concept.Id);

        return MapToDTO(concept);
    }

    /// <summary>
    /// Updates details, pricing, and category of an existing payment concept.
    /// </summary>
    public async Task<ConceptoCobroResponseDTO> UpdateAsync(
        Guid id,
        UpdateConceptoCobroRequest request,
        CancellationToken cancellationToken = default)
    {
        var concept = await dbContext.ConceptosCobro
            .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);

        if (concept is null)
        {
            throw new KeyNotFoundException($"Payment concept with ID '{id}' was not found.");
        }

        concept.Descripcion = request.Descripcion.Trim();
        concept.CuotaBase = request.CuotaBase;
        concept.Orden = request.Orden;
        concept.CuentaReferencia = string.IsNullOrWhiteSpace(request.CuentaReferencia) ? null : request.CuentaReferencia.Trim();
        concept.AplicaBeca = request.AplicaBeca;
        concept.Categoria = request.Categoria.Trim();
        concept.IsActive = request.IsActive;

        await dbContext.SaveChangesAsync(cancellationToken);

        logger.LogInformation("Successfully updated payment concept: {Clave} (ID: {Id})", concept.Clave, concept.Id);

        return MapToDTO(concept);
    }

    /// <summary>
    /// Toggles the active/inactive state of a concept.
    /// </summary>
    public async Task<ConceptoCobroResponseDTO> ToggleStatusAsync(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var concept = await dbContext.ConceptosCobro
            .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);

        if (concept is null)
        {
            throw new KeyNotFoundException($"Payment concept with ID '{id}' was not found.");
        }

        concept.IsActive = !concept.IsActive;
        await dbContext.SaveChangesAsync(cancellationToken);

        logger.LogInformation("Toggled active status for concept: {Clave} to {Status}", concept.Clave, concept.IsActive);

        return MapToDTO(concept);
    }

    /// <summary>
    /// Deletes a payment concept, or performs a soft-delete if receipts already reference it.
    /// </summary>
    public async Task<bool> DeleteAsync(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var concept = await dbContext.ConceptosCobro
            .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);

        if (concept is null)
        {
            throw new KeyNotFoundException($"Payment concept with ID '{id}' was not found.");
        }

        // Check if there are receipts referencing this concept
        var isReferencedInReceipts = await dbContext.DetallesRecibo
            .AnyAsync(d => d.ConceptoId == id, cancellationToken);

        if (isReferencedInReceipts)
        {
            // Soft-delete to preserve foreign key historical integrity
            concept.IsActive = false;
            await dbContext.SaveChangesAsync(cancellationToken);
            logger.LogInformation("Payment concept {Clave} is referenced in receipts; soft-deleted (IsActive = false).", concept.Clave);
            return false;
        }

        dbContext.ConceptosCobro.Remove(concept);
        await dbContext.SaveChangesAsync(cancellationToken);
        logger.LogInformation("Hard-deleted payment concept {Clave} (ID: {Id}).", concept.Clave, id);
        return true;
    }

    private static ConceptoCobroResponseDTO MapToDTO(ConceptoCobro entity) =>
        new(
            entity.Id,
            entity.Clave,
            entity.Descripcion,
            entity.CuotaBase,
            entity.Orden,
            entity.CuentaReferencia,
            entity.AplicaBeca,
            entity.Categoria,
            entity.IsActive
        );
}
