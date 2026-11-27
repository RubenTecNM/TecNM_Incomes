using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using TecNM.Api.Core.Entities;
using TecNM.Api.Data;
using TecNM.Api.Modules.Auth;
using TecNM.Api.Modules.Caja;
using TecNM.Api.Modules.ConceptosCobro;
using TecNM.Api.Modules.Recibos;
using TecNM.Api.Modules.Alumnos;
using TecNM.Api.Modules.Polizas;
using TecNM.Api.Modules.Dashboard;
using TecNM.Api.Modules.Reportes;
using TecNM.Api.Modules.Adeudos;

const string FrontendCors = "Frontend";

LoadDotEnv();

var builder = WebApplication.CreateBuilder(args);
var configuration = builder.Configuration;

var connectionString = configuration.GetConnectionString("DefaultConnection");
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException(
        "Falta ConnectionStrings__DefaultConnection en la configuración.");
}

var secret = configuration["Jwt:SecretKey"];
if (string.IsNullOrWhiteSpace(secret) || Encoding.UTF8.GetByteCount(secret) < 32)
{
    throw new InvalidOperationException(
        "Jwt__SecretKey es obligatorio y debe contener al menos 32 bytes UTF-8.");
}

var issuer = configuration["Jwt:Issuer"];
var audience = configuration["Jwt:Audience"];
var lifetimeHours = configuration.GetValue<int?>("Jwt:LifetimeHours");
if (string.IsNullOrWhiteSpace(issuer) || string.IsNullOrWhiteSpace(audience) || lifetimeHours != 8)
{
    throw new InvalidOperationException(
        "Jwt:Issuer, Jwt:Audience y Jwt:LifetimeHours=8 son obligatorios.");
}

var allowedOrigin = configuration["Cors:AllowedOrigin"]?.TrimEnd('/');
if (string.IsNullOrWhiteSpace(allowedOrigin)
    || !Uri.TryCreate(allowedOrigin, UriKind.Absolute, out var originUri)
    || (originUri.Scheme != Uri.UriSchemeHttps && originUri.Scheme != Uri.UriSchemeHttp))
{
    throw new InvalidOperationException(
        "Cors__AllowedOrigin debe ser un origen HTTP o HTTPS absoluto.");
}

var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
var jwtSettings = new JwtSettings(issuer, audience, lifetimeHours.Value, signingKey);

builder.Services.AddControllers();
builder.Services.AddDbContext<TecNMDbContext>(options => options.UseNpgsql(connectionString));
builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<CajaService>();
builder.Services.AddScoped<ConceptoCobroService>();
builder.Services.AddScoped<RecibosService>();
builder.Services.AddScoped<AlumnosService>();
builder.Services.AddScoped<PolizasService>();
builder.Services.AddScoped<DashboardService>();
builder.Services.AddScoped<ReportesService>();
builder.Services.AddScoped<AdeudosService>();
builder.Services.AddScoped<PasswordHasher<User>>();
builder.Services.AddSingleton(jwtSettings);
builder.Services.AddCors(options => options.AddPolicy(FrontendCors, policy =>
    policy.WithOrigins(allowedOrigin, "http://localhost:6030", "http://localhost:5173", "https://localhost:6030", "https://localhost:5173")
          .AllowAnyHeader()
          .AllowAnyMethod()
          .AllowCredentials()));
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = issuer,
            ValidateAudience = true,
            ValidAudience = audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = signingKey,
            ValidateLifetime = true,
            RequireExpirationTime = true,
            RequireSignedTokens = true,
            ValidAlgorithms = [SecurityAlgorithms.HmacSha256],
            NameClaimType = "name",
            RoleClaimType = "role",
            ClockSkew = TimeSpan.Zero
        };
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var token = context.Request.Cookies["auth_token"];
                if (string.IsNullOrEmpty(token))
                {
                    context.NoResult();
                }
                else
                {
                    context.Token = token;
                }

                return Task.CompletedTask;
            }
        };
    });
builder.Services.AddAuthorization();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}
app.UseCors(FrontendCors);
app.UseAuthentication();
app.UseAuthorization();
app.MapGet("/", () => Results.Ok(new
{
    sistema = "Sistema de Control de Caja Universitaria - TecNM Campus Monclova",
    estado = "Servidor Backend en línea y conectado a PostgreSQL 17",
    version = ".NET 10 Web API",
    endpointsDisponibles = new[]
    {
        "GET /api/health",
        "GET /api/caja/conceptos",
        "GET /api/caja/alumnos/buscar?q=23050243",
        "GET /api/caja/corte",
        "POST /api/caja/recibos"
    }
})).AllowAnonymous();

app.MapGet("/api/health", () => Results.Ok(new { status = "ok" })).AllowAnonymous();
app.MapControllers();

app.Run();

static void LoadDotEnv()
{
    var searchDir = new DirectoryInfo(Directory.GetCurrentDirectory());
    DirectoryInfo? backendDir = null;

    if (File.Exists(Path.Combine(searchDir.FullName, "TecNM.Api.csproj")))
    {
        backendDir = searchDir;
    }
    else if (Directory.Exists(Path.Combine(searchDir.FullName, "backend")))
    {
        backendDir = new DirectoryInfo(Path.Combine(searchDir.FullName, "backend"));
    }
    else
    {
        var baseDir = new DirectoryInfo(AppContext.BaseDirectory);
        while (baseDir != null)
        {
            if (File.Exists(Path.Combine(baseDir.FullName, "TecNM.Api.csproj")))
            {
                backendDir = baseDir;
                break;
            }

            baseDir = baseDir.Parent;
        }
    }

    if (backendDir == null)
    {
        return;
    }

    var envPath = Path.Combine(backendDir.FullName, ".env");
    if (!File.Exists(envPath))
    {
        return;
    }

    foreach (var rawLine in File.ReadAllLines(envPath))
    {
        var line = rawLine.Trim();
        if (string.IsNullOrWhiteSpace(line) || line.StartsWith('#'))
        {
            continue;
        }

        var separatorIndex = line.IndexOf('=');
        if (separatorIndex <= 0)
        {
            continue;
        }

        var key = line[..separatorIndex].Trim();
        var value = line[(separatorIndex + 1)..].Trim().Trim('"', '\'');

        if (string.IsNullOrEmpty(Environment.GetEnvironmentVariable(key)))
        {
            Environment.SetEnvironmentVariable(key, value);
        }
    }
}
