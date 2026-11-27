# Documentación del Proyecto - TecNM Campus Monclova
## Sistema de Control de Caja Universitaria e Ingresos Propios

Bienvenido a la carpeta oficial de documentación técnica y académica (`/docs`) para la liberación del repositorio institucional.

---

### Índice de Entregables por Asignatura

1. **[Fundamentos de Gestión de Servicios de TI (IFE-1014)](./3.1_Fundamentos_Gestion_Servicios_TI.md)**
   - **3.1.1.** Modelado del Proyecto como Servicio de TI Institucional (ITIL v4 SVS y Valor Cuantificable).
   - **3.1.2.** Catálogo de Servicios y Acuerdos de Nivel de Servicio (SLA: Disponibilidad 99%, Latencia ≤ 2s, RTO ≤ 2h, RPO ≤ 15m).
   - **3.1.3.** Modelado BPM (Diagrama de Procesos BPMN, Roles, Compuertas de Decisión y Entrega de Valor).
   - **3.1.4.** Estrategia y Gestión del Servicio (Procedimiento de Incidentes P1-P4 y Plan de Gestión de Cambios Zero-Downtime).

---

### Arquitectura Técnica del Repositorio
* **Frontend:** Vue 3 + TypeScript + Vite (`/frontend`).
* **Backend:** ASP.NET Core Web API en C# sobre .NET 10 (`/backend`).
* **Base de Datos:** PostgreSQL 17 relacional con esquemas canónicos y vistas de compatibilidad (`/scripts`).
* **Contenerización y Despliegue:** Docker Compose multi-contenedor con red bridge y volúmenes persistentes.
