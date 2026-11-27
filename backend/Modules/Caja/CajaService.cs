using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using TecNM.Api.Core.Entities;
using TecNM.Api.Data;

namespace TecNM.Api.Modules.Caja;

public sealed class CajaService(
    TecNMDbContext dbContext,
    PasswordHasher<User> passwordHasher)
{
    // =========================================================================
    // 1. GESTIÓN Y BÚSQUEDA DE ALUMNOS (INCLUYE HISTORIAL DE MATRÍCULAS)
    // =========================================================================

    public async Task<List<AlumnoDTO>> BuscarAlumnosAsync(string? query, CancellationToken cancellationToken)
    {
        var q = query?.Trim().ToLowerInvariant() ?? string.Empty;

        try
        {
            // 1. Buscar en alumnos activos
            var alumnos = await dbContext.Alumnos
                .Where(a => string.IsNullOrEmpty(q)
                    || a.Matricula.ToLower().Contains(q)
                    || a.NombreCompleto.ToLower().Contains(q)
                    || (a.NumeroFicha != null && a.NumeroFicha.ToLower().Contains(q)))
                .Take(20)
                .Select(a => ToAlumnoDTO(a, null))
                .ToListAsync(cancellationToken);

            // 2. Si la consulta es específica y no se encontró o se busca ampliar, buscar en historial de matrículas previas
            if (!string.IsNullOrEmpty(q))
            {
                var historicos = await dbContext.AlumnoMatriculasHistorial
                    .Include(h => h.Alumno)
                    .Where(h => h.MatriculaPrevia.ToLower().Contains(q))
                    .Take(10)
                    .ToListAsync(cancellationToken);

                foreach (var hist in historicos)
                {
                    if (hist.Alumno != null && alumnos.All(a => a.Matricula != hist.Alumno.Matricula))
                    {
                        alumnos.Add(ToAlumnoDTO(hist.Alumno, hist.MatriculaPrevia));
                    }
                }
            }

            if (alumnos.Count != 0 || !string.IsNullOrEmpty(q))
            {
                return alumnos;
            }
        }
        catch
        {
            // Fallback de contingencia con catálogo semilla
        }

        return GetAlumnosSemilla()
            .Where(a => string.IsNullOrEmpty(q)
                || a.Matricula.ToLower().Contains(q)
                || a.NombreCompleto.ToLower().Contains(q))
            .Take(20)
            .ToList();
    }

    public async Task<AlumnoDTO?> GetAlumnoAsync(string matricula, CancellationToken cancellationToken)
    {
        var normalized = matricula.Trim();

        try
        {
            // Buscar por matrícula actual
            var alumno = await dbContext.Alumnos
                .SingleOrDefaultAsync(a => a.Matricula == normalized, cancellationToken);

            if (alumno is not null)
            {
                return ToAlumnoDTO(alumno, null);
            }

            // Buscar si corresponde a una matrícula previa
            var hist = await dbContext.AlumnoMatriculasHistorial
                .Include(h => h.Alumno)
                .FirstOrDefaultAsync(h => h.MatriculaPrevia == normalized, cancellationToken);

            if (hist?.Alumno is not null)
            {
                return ToAlumnoDTO(hist.Alumno, hist.MatriculaPrevia);
            }
        }
        catch
        {
            // Contingencia
        }

        return GetAlumnosSemilla()
            .SingleOrDefault(a => a.Matricula.Equals(normalized, StringComparison.OrdinalIgnoreCase));
    }

    public async Task<List<AlumnoDTO>> ListarAlumnosAsync(
        string? carrera,
        int? semestre,
        string? estatus,
        CancellationToken cancellationToken)
    {
        try
        {
            var query = dbContext.Alumnos.AsQueryable();

            if (!string.IsNullOrWhiteSpace(carrera))
            {
                query = query.Where(a => a.Carrera == carrera.Trim());
            }

            if (semestre.HasValue)
            {
                query = query.Where(a => a.Semestre == semestre.Value);
            }

            if (!string.IsNullOrWhiteSpace(estatus))
            {
                query = query.Where(a => a.Estatus == estatus.Trim());
            }

            return await query
                .OrderBy(a => a.Carrera)
                .ThenBy(a => a.NombreCompleto)
                .Select(a => ToAlumnoDTO(a, null))
                .ToListAsync(cancellationToken);
        }
        catch
        {
            return GetAlumnosSemilla();
        }
    }

    // =========================================================================
    // 2. HISTORIAL DE MATRÍCULAS (CAMBIOS DE MATRÍCULA Y ANTECEDENTES)
    // =========================================================================

    public async Task<List<MatriculaHistorialDTO>> GetHistorialMatriculasAsync(
        string matricula,
        CancellationToken cancellationToken)
    {
        try
        {
            return await dbContext.AlumnoMatriculasHistorial
                .Include(h => h.Periodo)
                .Where(h => h.MatriculaAlumno == matricula.Trim() || h.MatriculaPrevia == matricula.Trim())
                .OrderByDescending(h => h.FechaRegistro)
                .Select(h => new MatriculaHistorialDTO(
                    h.IdHistorial,
                    h.MatriculaAlumno,
                    h.MatriculaPrevia,
                    h.Periodo != null ? h.Periodo.Codigo : null,
                    h.FechaRegistro,
                    h.MotivoCambio))
                .ToListAsync(cancellationToken);
        }
        catch
        {
            return [];
        }
    }

    public async Task<AlumnoDTO> CambiarMatriculaAsync(
        string matriculaActual,
        CambiarMatriculaRequest req,
        string usuarioResponsable,
        CancellationToken cancellationToken)
    {
        var actual = matriculaActual.Trim();
        var nueva = req.NuevaMatricula.Trim();

        if (string.Equals(actual, nueva, StringComparison.OrdinalIgnoreCase))
        {
            throw new ArgumentException("La nueva matrícula no puede ser idéntica a la matrícula actual.");
        }

        var alumno = await dbContext.Alumnos
            .SingleOrDefaultAsync(a => a.Matricula == actual, cancellationToken)
            ?? throw new KeyNotFoundException($"No se encontró al alumno con matrícula '{actual}'.");

        var existente = await dbContext.Alumnos
            .AnyAsync(a => a.Matricula == nueva, cancellationToken);
        if (existente)
        {
            throw new InvalidOperationException($"La matrícula '{nueva}' ya se encuentra registrada en el sistema.");
        }

        // Registrar en historial de matrículas
        var hist = new AlumnoMatriculaHistorial
        {
            MatriculaAlumno = nueva,
            MatriculaPrevia = actual,
            IdPeriodo = req.IdPeriodo,
            FechaRegistro = DateTimeOffset.UtcNow,
            MotivoCambio = $"{req.MotivoCambio} (Registrado por: {usuarioResponsable})"
        };

        // Crear nueva instancia de alumno con la nueva matrícula y transferir datos
        var nuevoAlumno = new Alumno
        {
            Matricula = nueva,
            NombreCompleto = alumno.NombreCompleto,
            Nombres = alumno.Nombres,
            Apellidos = alumno.Apellidos,
            Sexo = alumno.Sexo,
            IdCarrera = alumno.IdCarrera,
            Carrera = alumno.Carrera,
            Semestre = alumno.Semestre,
            Turno = alumno.Turno,
            NumeroFicha = alumno.NumeroFicha,
            CuentaA = alumno.CuentaA,
            Estatus = alumno.Estatus,
            TieneBeca = alumno.TieneBeca,
            PorcentajeBeca = alumno.PorcentajeBeca,
            CreatedAt = alumno.CreatedAt
        };

        dbContext.Alumnos.Add(nuevoAlumno);

        // Actualizar referencias en recibos, adeudos y becas
        var recibos = await dbContext.Recibos
            .Where(r => r.AlumnoMatricula == actual)
            .ToListAsync(cancellationToken);
        foreach (var r in recibos) r.AlumnoMatricula = nueva;

        var adeudos = await dbContext.Adeudos
            .Where(a => a.Matricula == actual)
            .ToListAsync(cancellationToken);
        foreach (var a in adeudos) a.Matricula = nueva;

        var becas = await dbContext.BecasDescuentos
            .Where(b => b.Matricula == actual)
            .ToListAsync(cancellationToken);
        foreach (var b in becas) b.Matricula = nueva;

        dbContext.Alumnos.Remove(alumno);
        dbContext.AlumnoMatriculasHistorial.Add(hist);

        await dbContext.SaveChangesAsync(cancellationToken);

        return ToAlumnoDTO(nuevoAlumno, actual);
    }

    // =========================================================================
    // 3. ADEUDOS Y BECAS -> Desacoplado a AdeudosService
    // =========================================================================

    // =========================================================================
    // 4. DISTINCIÓN: CUENTAS DE USUARIO (EMPLEADOS) VS CUENTAS/CONCEPTOS
    // =========================================================================

    public async Task<List<EmpleadoDTO>> ListarEmpleadosAsync(CancellationToken cancellationToken)
    {
        try
        {
            return await dbContext.Users
                .OrderBy(u => u.Name)
                .Select(u => new EmpleadoDTO(
                    u.Id,
                    u.Username,
                    u.Name,
                    u.Email,
                    u.Role,
                    u.IsActive))
                .ToListAsync(cancellationToken);
        }
        catch
        {
            return
            [
                new(Guid.Parse("10000000-0000-4000-8000-000000000001"), "admin", "Administrador General", "admin@tecnm.local", "Admin", true),
                new(Guid.Parse("10000000-0000-4000-8000-000000000002"), "cajero1", "Cajero Turno Matutino", "cajero1@tecnm.local", "Cajero", true),
                new(Guid.Parse("10000000-0000-4000-8000-000000000003"), "cajero2", "Cajero Turno Nocturno", "cajero2@tecnm.local", "Cajero", true),
            ];
        }
    }

    public async Task<EmpleadoDTO> CrearEmpleadoAsync(CrearEmpleadoRequest req, CancellationToken cancellationToken)
    {
        var username = req.Username.Trim();
        var email = req.Email.Trim();

        var existe = await dbContext.Users
            .AnyAsync(u => u.Username == username || u.Email == email, cancellationToken);
        if (existe)
        {
            throw new InvalidOperationException($"El usuario o correo electrónico ya existe.");
        }

        var user = new User
        {
            Username = username,
            Email = email,
            Name = req.Name.Trim(),
            Role = string.IsNullOrWhiteSpace(req.Role) ? "Cajero" : req.Role.Trim(),
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow,
            Password = string.Empty
        };

        user.Password = passwordHasher.HashPassword(user, string.IsNullOrWhiteSpace(req.Password) ? "Password123!" : req.Password);
        dbContext.Users.Add(user);
        await dbContext.SaveChangesAsync(cancellationToken);

        return new EmpleadoDTO(user.Id, user.Username, user.Name, user.Email, user.Role, user.IsActive);
    }

    public async Task<List<CuentaConceptoDTO>> ListarCuentasConceptosAsync(CancellationToken cancellationToken)
    {
        try
        {
            return await dbContext.ConceptosCobro
                .Where(c => c.IsActive)
                .OrderBy(c => c.Clave)
                .Select(c => new CuentaConceptoDTO(
                    c.Id,
                    c.Clave,
                    c.Descripcion,
                    c.CuotaBase,
                    c.Categoria,
                    c.AplicaBeca))
                .ToListAsync(cancellationToken);
        }
        catch
        {
            return GetConceptosSemilla().Select(c => new CuentaConceptoDTO(
                c.Id, c.Clave, c.Descripcion, c.CuotaBase, c.Categoria, c.AplicaBeca)).ToList();
        }
    }

    public async Task<CuentaConceptoDTO> CrearCuentaConceptoAsync(CrearCuentaConceptoRequest req, CancellationToken cancellationToken)
    {
        var clave = req.Cuenta.Trim();
        var existe = await dbContext.ConceptosCobro.AnyAsync(c => c.Clave == clave, cancellationToken);
        if (existe)
        {
            throw new InvalidOperationException($"La cuenta o concepto '{clave}' ya se encuentra registrada.");
        }

        var concepto = new ConceptoCobro
        {
            Clave = clave,
            Descripcion = req.Descripcion.Trim(),
            CuotaBase = req.Costo,
            Categoria = string.IsNullOrWhiteSpace(req.Categoria) ? "Inscripción" : req.Categoria.Trim(),
            AplicaBeca = false,
            IsActive = true
        };

        dbContext.ConceptosCobro.Add(concepto);
        await dbContext.SaveChangesAsync(cancellationToken);

        return new CuentaConceptoDTO(concepto.Id, concepto.Clave, concepto.Descripcion, concepto.CuotaBase, concepto.Categoria, concepto.AplicaBeca);
    }

    public async Task<CuentaConceptoDTO> ActualizarCuentaConceptoAsync(Guid id, ActualizarCuentaConceptoRequest req, CancellationToken cancellationToken)
    {
        var concepto = await dbContext.ConceptosCobro.FindAsync([id], cancellationToken)
            ?? throw new KeyNotFoundException("Concepto o cuenta no encontrada.");

        concepto.Descripcion = req.Descripcion.Trim();
        concepto.CuotaBase = req.Costo;
        if (!string.IsNullOrWhiteSpace(req.Categoria))
        {
            concepto.Categoria = req.Categoria.Trim();
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        return new CuentaConceptoDTO(concepto.Id, concepto.Clave, concepto.Descripcion, concepto.CuotaBase, concepto.Categoria, concepto.AplicaBeca);
    }

    // =========================================================================
    // 5. ANÁLISIS DE REFERENCIAS BANCARIAS (ESTRUCTURA 5+5 Y DETECCIÓN)
    // =========================================================================

    public async Task<DesgloseReferenciaDTO> DesglosarReferenciaAsync(string referencia, CancellationToken cancellationToken)
    {
        var refLimpia = (referencia ?? string.Empty).Trim().Replace("-", "").Replace(" ", "");

        if (string.IsNullOrWhiteSpace(refLimpia))
        {
            return new DesgloseReferenciaDTO(referencia ?? "", "", "", null, null, [], false, "Referencia vacía.");
        }

        string codigo5Alumno = refLimpia.Length >= 5 ? refLimpia[..5] : refLimpia;
        string codigo5Concepto = refLimpia.Length >= 10 ? refLimpia[^5..] : (refLimpia.Length > 5 ? refLimpia[5..] : "");

        AlumnoDTO? alumnoDetectado = null;
        ConceptoDTO? conceptoDetectado = null;

        try
        {
            // 1. Intentar localizar al alumno por los primeros 5 dígitos (cuenta_a o prefijo de matrícula)
            if (int.TryParse(codigo5Alumno, out var cuentaInt))
            {
                var al = await dbContext.Alumnos.FirstOrDefaultAsync(a => a.CuentaA == cuentaInt, cancellationToken);
                if (al != null) alumnoDetectado = ToAlumnoDTO(al, null);
            }

            if (alumnoDetectado == null)
            {
                var al = await dbContext.Alumnos.FirstOrDefaultAsync(a => a.Matricula.StartsWith(codigo5Alumno), cancellationToken);
                if (al != null) alumnoDetectado = ToAlumnoDTO(al, null);
            }

            // 2. Intentar localizar el concepto por los últimos 5 dígitos
            if (!string.IsNullOrEmpty(codigo5Concepto))
            {
                var conc = await dbContext.ConceptosCobro.FirstOrDefaultAsync(
                    c => c.Clave.EndsWith(codigo5Concepto) || c.Clave.Contains(codigo5Concepto), cancellationToken);
                if (conc != null)
                {
                    conceptoDetectado = new ConceptoDTO(conc.Id, conc.Clave, conc.Descripcion, conc.CuotaBase, conc.AplicaBeca, conc.Categoria, conc.CuentaReferencia, conc.Orden);
                }
            }

            // 3. Buscar si la referencia bancaria ya fue utilizada previamente en algún recibo
            var refTrimmed = (referencia ?? string.Empty).Trim();
            var recibosPrevios = await dbContext.Recibos
                .Include(r => r.Detalles)
                .Where(r => r.ReferenciaBancaria == refTrimmed || r.ReferenciaBancaria == refLimpia)
                .OrderByDescending(r => r.FechaOperacion)
                .Select(r => ToReciboResponse(r))
                .ToListAsync(cancellationToken);

            bool duplicada = recibosPrevios.Count > 0;
            string mensaje = duplicada
                ? $"Atención: Esta referencia bancaria ya tiene {recibosPrevios.Count} recibo(s) registrado(s) previamente."
                : (alumnoDetectado != null ? $"Referencia 5+5 identificada exitosamente para {alumnoDetectado.NombreCompleto}." : "Estructura 5+5 analizada. Verifique los datos del comprobante.");

            return new DesgloseReferenciaDTO(
                refTrimmed,
                codigo5Alumno,
                codigo5Concepto,
                alumnoDetectado,
                conceptoDetectado,
                recibosPrevios,
                duplicada,
                mensaje);
        }
        catch
        {
            return new DesgloseReferenciaDTO(referencia ?? string.Empty, codigo5Alumno, codigo5Concepto, null, null, [], false, "Error al consultar la base de datos.");
        }
    }

    // =========================================================================
    // 6. CATÁLOGOS ACADÉMICOS Y CONCEPTOS
    // =========================================================================

    public async Task<List<CarreraDTO>> GetCarrerasAsync(CancellationToken cancellationToken)
    {
        try
        {
            return await dbContext.Carreras
                .Where(c => c.Activo)
                .OrderBy(c => c.Abreviatura)
                .Select(c => new CarreraDTO(c.IdCarrera, c.Abreviatura, c.NombreCarrera, c.Titulo, c.Activo))
                .ToListAsync(cancellationToken);
        }
        catch
        {
            return
            [
                new(67, "Ing. Industrial", "INGENIERIA INDUSTRIAL", "INGENIERO INDUSTRIAL", true),
                new(65, "Ing. Mecánica", "INGENIERIA MECANICA", "INGENIERO MECANICO", true),
                new(68, "Ing. Electrónica", "INGENIERIA ELECTRONICA", "INGENIERO ELECTRONICO", true),
                new(69, "Ing. Informática", "INGENIERIA INFORMATICA", "INGENIERO INFORMATICO", true),
                new(70, "Ing. Gestión Emp.", "INGENIERIA EN GESTION EMPRESARIAL", "INGENIERO EN GESTION EMPRESARIAL", true),
                new(71, "Ing. Energías Renovables", "INGENIERIA EN ENERGIAS RENOVABLES", "INGENIERO EN ENERGIAS RENOVABLES", true),
                new(74, "Ing. Mecatrónica", "INGENIERIA MECATRONICA", "INGENIERO MECATRONICO", true),
                new(64, "Lic. Informática", "LICENCIATURA EN INFORMATICA", "LICENCIADO EN INFORMATICA", true)
            ];
        }
    }

    public async Task<List<PeriodoDTO>> GetPeriodosAsync(CancellationToken cancellationToken)
    {
        try
        {
            return await dbContext.PeriodosAcademicos
                .OrderByDescending(p => p.Anio)
                .ThenByDescending(p => p.IdPeriodo)
                .Select(p => new PeriodoDTO(p.IdPeriodo, p.Codigo, p.Descripcion, p.Anio, p.Ciclo, p.FechaInicio, p.FechaFin, p.Activo))
                .ToListAsync(cancellationToken);
        }
        catch
        {
            return
            [
                new(7, "2026-1", "SEMESTRE ENERO-JUNIO 2026", 2026, "PRIMAVERA", new DateOnly(2026, 1, 12), new DateOnly(2026, 6, 30), true),
                new(6, "2025-2", "SEMESTRE AGOSTO-DICIEMBRE 2025", 2025, "OTONO", new DateOnly(2025, 8, 11), new DateOnly(2025, 12, 19), false),
            ];
        }
    }

    public async Task<List<ConceptoDTO>> GetConceptosAsync(CancellationToken cancellationToken)
    {
        try
        {
            return await dbContext.ConceptosCobro
                .Where(c => c.IsActive)
                .OrderBy(c => c.Orden.HasValue ? c.Orden.Value : 999)
                .ThenBy(c => c.Clave)
                .Select(c => new ConceptoDTO(c.Id, c.Clave, c.Descripcion, c.CuotaBase, c.AplicaBeca, c.Categoria, c.CuentaReferencia, c.Orden))
                .ToListAsync(cancellationToken);
        }
        catch
        {
            return GetConceptosSemilla().Select(c => new ConceptoDTO(
                c.Id, c.Clave, c.Descripcion, c.CuotaBase, c.AplicaBeca, c.Categoria, c.CuentaReferencia, c.Orden)).ToList();
        }
    }

    // =========================================================================
    // 7. EMISIÓN Y CANCELACIÓN DE RECIBOS DE COBRO
    // =========================================================================

    public async Task<ReciboResponse> CrearReciboAsync(
        CrearReciboRequest request,
        string cajeroUsuario,
        string cajeroNombre,
        bool esPrevio,
        CancellationToken cancellationToken)
    {
        if (request.Detalles == null || request.Detalles.Count == 0)
        {
            throw new ArgumentException("El recibo debe contener al menos una partida de cobro.");
        }

        // Determinar fecha de operación (Automática por defecto, o manual justificada)
        var fechaOperacion = request.FechaOperacion ?? DateTimeOffset.UtcNow;

        var subtotal = request.Detalles.Sum(d => d.Cantidad * d.CuotaUnitario);
        var descuentoTotal = request.Detalles.Sum(d => d.DescuentoBeca);
        var total = request.Detalles.Sum(d => d.ImporteTotal);

        var numeroRecibo = await GenerarSiguienteNumeroReciboAsync(cancellationToken);
        var folioAdministrativo = $"FOL-{fechaOperacion:yyyy-MM}-{numeroRecibo}";

        var recibo = new Recibo
        {
            NumeroRecibo = numeroRecibo,
            FolioAdministrativo = folioAdministrativo,
            FechaOperacion = fechaOperacion,
            FechaEfectivaPago = fechaOperacion,
            AlumnoMatricula = request.Matricula.Trim(),
            AlumnoNombre = request.NombreCompleto.Trim(),
            AlumnoCarrera = request.Carrera.Trim(),
            AlumnoSemestre = request.Semestre,
            AlumnoTurno = request.Turno.Trim(),
            MetodoPago = request.MetodoPago.Trim().ToUpperInvariant(),
            ReferenciaBancaria = request.ReferenciaBancaria?.Trim(),
            CuentaBancaria = request.CuentaBancaria?.Trim(),
            FechaBancaria = request.FechaBancaria,
            Subtotal = subtotal,
            DescuentoTotal = descuentoTotal,
            Total = total,
            Status = 1,
            Estado = esPrevio ? "PREVIO" : "REGISTRADO",
            TipoRecibo = esPrevio ? "PREVIO" : "DEFINITIVO",
            CajeroUsuario = cajeroUsuario,
            CajeroNombre = cajeroNombre,
            MotivoCancelacion = !string.IsNullOrWhiteSpace(request.JustificacionFecha) ? $"[Fecha Justificada: {request.JustificacionFecha}]" : null
        };

        foreach (var item in request.Detalles)
        {
            recibo.Detalles.Add(new DetalleRecibo
            {
                ConceptoId = item.ConceptoId,
                Descripcion = item.Descripcion.Trim(),
                Cantidad = item.Cantidad,
                CuotaUnitario = item.CuotaUnitario,
                DescuentoBeca = item.DescuentoBeca,
                ImporteTotal = item.ImporteTotal,
                PeriodoAno = item.PeriodoAno ?? $"{fechaOperacion.Year}-1"
            });
        }

        // Generar movimiento contable
        recibo.Movimientos.Add(new MovimientoPago
        {
            FormaPago = recibo.MetodoPago,
            ReferenciaBancaria = recibo.ReferenciaBancaria ?? "0",
            Monto = recibo.Total,
            FechaMovimiento = fechaOperacion,
            CajeroUsuario = cajeroUsuario
        });

        dbContext.Recibos.Add(recibo);

        // Si es cobro definitivo, verificar y amortizar adeudos coincidentes del estudiante
        if (!esPrevio)
        {
            foreach (var detalle in request.Detalles)
            {
                var adeudo = await dbContext.Adeudos
                    .FirstOrDefaultAsync(a => a.Matricula == recibo.AlumnoMatricula
                        && a.ConceptoCobro.ToLower().Contains(detalle.Descripcion.ToLower())
                        && a.Estado != "LIQUIDADO", cancellationToken);

                if (adeudo != null)
                {
                    adeudo.SaldoPendiente = Math.Max(0, adeudo.SaldoPendiente - detalle.ImporteTotal);
                    if (adeudo.SaldoPendiente <= 0)
                    {
                        adeudo.Estado = "LIQUIDADO";
                    }
                    else
                    {
                        adeudo.Estado = "PARCIAL";
                    }
                }
            }
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        return ToReciboResponse(recibo);
    }

    public async Task<ReciboResponse> CancelarReciboAsync(
        Guid id,
        string motivo,
        string cajeroUsuario,
        CancellationToken cancellationToken)
    {
        var motivoLimpio = motivo?.Trim() ?? string.Empty;
        if (motivoLimpio.Length < 5)
        {
            throw new ArgumentException("El motivo de cancelación debe contener al menos 5 caracteres formales.");
        }

        var recibo = await dbContext.Recibos
            .Include(r => r.Detalles)
            .SingleOrDefaultAsync(r => r.Id == id, cancellationToken)
            ?? throw new KeyNotFoundException("No se encontró el recibo especificado.");

        if (recibo.Estado == "CANCELADO")
        {
            throw new InvalidOperationException("El recibo ya se encuentra cancelado.");
        }

        recibo.Estado = "CANCELADO";
        recibo.Status = 0;
        recibo.MotivoCancelacion = $"{motivoLimpio} (Cancelado por: {cajeroUsuario})";
        recibo.FechaCancelacion = DateTimeOffset.UtcNow;

        await dbContext.SaveChangesAsync(cancellationToken);

        return ToReciboResponse(recibo);
    }

    public async Task<ReciboResponse?> GetReciboByNumeroAsync(long numero, CancellationToken cancellationToken)
    {
        var recibo = await dbContext.Recibos
            .Include(r => r.Detalles)
            .SingleOrDefaultAsync(r => r.NumeroRecibo == numero, cancellationToken);

        return recibo is not null ? ToReciboResponse(recibo) : null;
    }

    public async Task<List<ReciboResponse>> GetRecibosRecientesAsync(int limite, CancellationToken cancellationToken)
    {
        try
        {
            return await dbContext.Recibos
                .Include(r => r.Detalles)
                .OrderByDescending(r => r.NumeroRecibo)
                .Take(limite)
                .Select(r => ToReciboResponse(r))
                .ToListAsync(cancellationToken);
        }
        catch
        {
            return [];
        }
    }

    // =========================================================================
    // 8. CORTE DIARIO, PÓLIZAS Y REPORTES PARA MODALES
    // =========================================================================

    public async Task<CorteCajaResponse> GetCorteDiarioAsync(
        DateOnly? fecha,
        string? cajeroUsuario,
        CancellationToken cancellationToken)
    {
        var fechaFiltro = fecha ?? DateOnly.FromDateTime(DateTime.UtcNow);
        var inicio = new DateTimeOffset(fechaFiltro.ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var fin = new DateTimeOffset(fechaFiltro.ToDateTime(TimeOnly.MaxValue), TimeSpan.Zero);

        try
        {
            var query = dbContext.Recibos
                .Include(r => r.Movimientos)
                .Where(r => r.FechaOperacion >= inicio && r.FechaOperacion <= fin);

            if (!string.IsNullOrWhiteSpace(cajeroUsuario))
            {
                query = query.Where(r => r.CajeroUsuario == cajeroUsuario);
            }

            var recibos = await query.ToListAsync(cancellationToken);

            var totalEfectivo = recibos
                .Where(r => r.Estado != "CANCELADO" && r.MetodoPago == "EFECTIVO")
                .Sum(r => r.Total);

            var totalBanco = recibos
                .Where(r => r.Estado != "CANCELADO" && r.MetodoPago != "EFECTIVO")
                .Sum(r => r.Total);

            return new CorteCajaResponse(
                fechaFiltro,
                totalEfectivo,
                totalBanco,
                totalEfectivo + totalBanco,
                recibos.Count,
                recibos.Count(r => r.Estado == "CANCELADO"));
        }
        catch
        {
            return new CorteCajaResponse(fechaFiltro, 0, 0, 0, 0, 0);
        }
    }

    public async Task<List<ReporteReciboDetalladoDTO>> GetReporteDetalladoAsync(CancellationToken cancellationToken)
    {
        try
        {
            var lista = await dbContext.Recibos
                .Include(r => r.Detalles)
                .OrderByDescending(r => r.FechaOperacion)
                .ToListAsync(cancellationToken);

            var resultado = new List<ReporteReciboDetalladoDTO>();
            foreach (var r in lista)
            {
                foreach (var d in r.Detalles)
                {
                    resultado.Add(new ReporteReciboDetalladoDTO(
                        r.Id,
                        r.NumeroRecibo,
                        r.FolioAdministrativo,
                        r.FechaOperacion,
                        r.AlumnoMatricula,
                        r.AlumnoNombre,
                        r.AlumnoCarrera,
                        r.AlumnoSemestre,
                        r.AlumnoTurno,
                        d.Descripcion,
                        d.Cantidad,
                        d.CuotaUnitario,
                        d.DescuentoBeca,
                        d.ImporteTotal,
                        r.Total,
                        r.MetodoPago,
                        r.ReferenciaBancaria,
                        r.Estado,
                        r.CajeroUsuario,
                        r.CajeroNombre));
                }
            }

            return resultado;
        }
        catch
        {
            return [];
        }
    }

    public async Task<PolizaIngresoResumenDTO> GetPolizaResumenAsync(string? fechaStr, CancellationToken cancellationToken)
    {
        DateOnly fecha = DateOnly.FromDateTime(DateTime.UtcNow);
        if (!string.IsNullOrWhiteSpace(fechaStr) && DateOnly.TryParse(fechaStr, out var parsed))
        {
            fecha = parsed;
        }

        var inicio = new DateTimeOffset(fecha.ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var fin = new DateTimeOffset(fecha.ToDateTime(TimeOnly.MaxValue), TimeSpan.Zero);

        try
        {
            var detalles = await dbContext.DetallesRecibo
                .Include(d => d.Recibo)
                .Include(d => d.Concepto)
                .Where(d => d.Recibo != null && d.Recibo.FechaOperacion >= inicio && d.Recibo.FechaOperacion <= fin && d.Recibo.Estado != "CANCELADO")
                .ToListAsync(cancellationToken);

            var agrupado = detalles
                .GroupBy(d => new
                {
                    Cuenta = d.Concepto != null ? d.Concepto.Clave : "5200-001-002",
                    Concepto = d.Descripcion
                })
                .Select(g => new PolizaIngresoFilaDTO(
                    g.Key.Cuenta,
                    g.Key.Concepto,
                    g.Sum(x => x.Cantidad),
                    g.Sum(x => x.ImporteTotal)))
                .OrderBy(f => f.Cuenta)
                .ToList();

            var total = agrupado.Sum(f => f.Total);
            return new PolizaIngresoResumenDTO(fecha.ToString("yyyy-MM-dd"), total, agrupado);
        }
        catch
        {
            return new PolizaIngresoResumenDTO(fecha.ToString("yyyy-MM-dd"), 0, []);
        }
    }

    public async Task<ReporteIngresoResumenDTO> GetReporteIngresosAsync(string? fechaStr, CancellationToken cancellationToken)
    {
        DateOnly fecha = DateOnly.FromDateTime(DateTime.UtcNow);
        if (!string.IsNullOrWhiteSpace(fechaStr) && DateOnly.TryParse(fechaStr, out var parsed))
        {
            fecha = parsed;
        }

        var inicio = new DateTimeOffset(fecha.ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var fin = new DateTimeOffset(fecha.ToDateTime(TimeOnly.MaxValue), TimeSpan.Zero);

        try
        {
            var recibos = await dbContext.Recibos
                .Include(r => r.Detalles)
                .Where(r => r.FechaOperacion >= inicio && r.FechaOperacion <= fin)
                .OrderBy(r => r.NumeroRecibo)
                .ToListAsync(cancellationToken);

            var filas = recibos.Select(r => new ReporteIngresoFilaDTO(
                r.FolioAdministrativo,
                r.Detalles.FirstOrDefault()?.Descripcion ?? "Pago de Servicios",
                r.AlumnoNombre,
                r.Total,
                r.Estado)).ToList();

            var total = filas.Where(f => f.Estatus != "CANCELADO").Sum(f => f.Total);
            return new ReporteIngresoResumenDTO(fecha.ToString("yyyy-MM-dd"), total, filas);
        }
        catch
        {
            return new ReporteIngresoResumenDTO(fecha.ToString("yyyy-MM-dd"), 0, []);
        }
    }

    public async Task<ReporteVeranoResumenDTO> GetReporteVeranoAsync(
        string? inicioStr,
        string? finStr,
        string? concepto,
        CancellationToken cancellationToken)
    {
        var conceptoFiltro = concepto?.Trim().ToLower() ?? "verano";

        try
        {
            var query = dbContext.DetallesRecibo
                .Include(d => d.Recibo)
                .Where(d => d.Recibo != null && (d.Descripcion.ToLower().Contains("verano") || d.Descripcion.ToLower().Contains(conceptoFiltro)));

            if (DateTimeOffset.TryParse(inicioStr, out var dInicio))
            {
                query = query.Where(d => d.Recibo!.FechaOperacion >= dInicio);
            }

            if (DateTimeOffset.TryParse(finStr, out var dFin))
            {
                query = query.Where(d => d.Recibo!.FechaOperacion <= dFin);
            }

            var items = await query
                .OrderBy(d => d.Recibo!.NumeroRecibo)
                .ToListAsync(cancellationToken);

            var registros = items.Select(d => new ReporteVeranoItemDTO(
                d.Recibo!.FolioAdministrativo,
                d.Recibo!.AlumnoMatricula,
                d.Recibo!.AlumnoNombre,
                d.Descripcion,
                d.ImporteTotal,
                d.Recibo!.FechaOperacion.ToString("yyyy-MM-dd"))).ToList();

            var cuota = items.FirstOrDefault()?.CuotaUnitario ?? 1200.00m;
            var totalRecaudado = registros.Sum(r => r.Cuota);

            return new ReporteVeranoResumenDTO(
                inicioStr ?? "",
                finStr ?? "",
                concepto ?? "Curso de Verano",
                cuota,
                registros.Count,
                totalRecaudado,
                registros);
        }
        catch
        {
            return new ReporteVeranoResumenDTO(inicioStr ?? "", finStr ?? "", concepto ?? "Curso de Verano", 1200, 0, 0, []);
        }
    }

    // =========================================================================
    // HELPERS INTERNOS
    // =========================================================================

    private async Task<long> GenerarSiguienteNumeroReciboAsync(CancellationToken cancellationToken)
    {
        try
        {
            var maxActual = await dbContext.Recibos.MaxAsync(r => (long?)r.NumeroRecibo, cancellationToken);
            return (maxActual ?? 128450) + 1;
        }
        catch
        {
            return 128451;
        }
    }

    private static AlumnoDTO ToAlumnoDTO(Alumno a, string? matriculaPrevia)
    {
        return new AlumnoDTO(
            a.Matricula,
            a.NombreCompleto,
            a.Carrera,
            a.Semestre,
            a.Turno,
            a.Estatus,
            a.TieneBeca,
            a.PorcentajeBeca,
            a.IdCarrera,
            a.NumeroFicha,
            a.CuentaA,
            matriculaPrevia);
    }

    private static ReciboResponse ToReciboResponse(Recibo r)
    {
        return new ReciboResponse(
            r.Id,
            r.NumeroRecibo,
            r.FolioAdministrativo,
            r.FechaOperacion,
            r.AlumnoMatricula,
            r.AlumnoNombre,
            r.AlumnoCarrera,
            r.AlumnoSemestre,
            r.AlumnoTurno,
            r.MetodoPago,
            r.ReferenciaBancaria,
            r.CuentaBancaria,
            r.FechaBancaria,
            r.Subtotal,
            r.DescuentoTotal,
            r.Total,
            r.Estado,
            r.MotivoCancelacion,
            r.FechaCancelacion,
            r.CajeroUsuario,
            r.CajeroNombre,
            r.Detalles.Select(d => new DetalleItemResponse(
                d.Id,
                d.ConceptoId,
                d.Descripcion,
                d.Cantidad,
                d.CuotaUnitario,
                d.DescuentoBeca,
                d.ImporteTotal,
                d.PeriodoAno)).ToList());
    }

    private static List<ConceptoCobro> GetConceptosSemilla()
    {
        return
        [
            new() { Id = Guid.Parse("6e7b3668-dac4-4791-bc05-e81ccf0dea9d"), Clave = "5200-001-002-004", Descripcion = "INSCRIPCION SEM. AGO 2012-ENERO 2013", CuotaBase = 1700.00m, AplicaBeca = true, Categoria = "Inscripción", Orden = 1, IsActive = true },
            new() { Id = Guid.Parse("230eaa2a-f8d5-41e9-adaf-f538585d9741"), Clave = "INSC-VIG", Descripcion = "Pago de Inscripción (Periodo Vigente 2026)", CuotaBase = 2600.00m, AplicaBeca = true, Categoria = "Inscripción", Orden = 6, IsActive = true },
            new() { Id = Guid.Parse("42ce4c37-f5ce-49dd-8fc8-a7276d3c12d8"), Clave = "KARD", Descripcion = "KARDEX OFICIAL", CuotaBase = 150.00m, AplicaBeca = false, Categoria = "Constancias", Orden = 30, IsActive = true },
            new() { Id = Guid.Parse("1efdec3b-4f6f-4aba-92d9-abeadeb76275"), Clave = "VERA", Descripcion = "Curso de Verano (Por Asignatura)", CuotaBase = 1200.00m, AplicaBeca = false, Categoria = "Cursos", Orden = 32, IsActive = true },
        ];
    }

    private static List<AlumnoDTO> GetAlumnosSemilla()
    {
        return
        [
            new("23050243", "ORTEGON HERNANDEZ KLEBER", "Ing. Industrial", 4, "Matutino", "Inscrito", false, 0.00m, 67, "F-2023-243", 23050),
            new("23050118", "GARCIA ZAVALA LUIS FERNANDO", "Ing. Mecatrónica", 3, "Matutino", "Inscrito", false, 0.00m, 74, "F-2023-118", 23051),
            new("22050890", "LOPEZ SANCHEZ MARIANA", "Ing. Gestión Emp.", 6, "Matutino", "Inscrito", true, 50.00m, 70, "F-2022-890", 22050),
            new("G2605048", "MARTINEZ SILVA MARIA JOSE", "Ing. Gestión Emp.", 1, "Matutino", "Inscrito", false, 0.00m, 70, "F-2026-001", 24468),
        ];
    }
}
