# Adeudos Module Specification

## Responsibility
Decouples student debts (`Adeudo`) and scholarship/discount management (`BecaDescuento`) from `CajaController` into an independent vertical slice.

## Endpoints
- `GET /api/adeudos` | `GET /api/caja/adeudos`: General debt query with filters (`matricula`, `concepto`, `periodoId`, `estado`, `fechaCorte`, `soloVencidos`).
- `GET /api/adeudos/resumen-vencidos`: Computes overdue and upcoming balances.
- `GET /api/adeudos/deudores/fecha-corte` | `GET /api/caja/deudores/fecha-corte`: Debtors filtered by cutoff date and payment status.
- `GET /api/adeudos/deudores/fecha-cuenta` | `GET /api/caja/deudores/fecha-cuenta`: Debtors filtered by date and concept list.
- `GET /api/adeudos/deudores/inscritos` | `GET /api/caja/deudores/inscritos`: Active enrolled students with pending balances.
- `POST /api/adeudos`: Registers a new debt for a student.
- `POST /api/adeudos/{idAdeudo}/abonar`: Applies a partial or full payment to an existing debt.
- `GET /api/adeudos/becas`: Lists scholarships/discounts.
- `POST /api/adeudos/becas`: Registers and optionally applies a percentage or fixed discount to pending debts in PostgreSQL.
- `PATCH /api/adeudos/becas/{idBeca}/toggle`: Activates/deactivates a scholarship and synchronizes `Alumno.TieneBeca` and `Alumno.PorcentajeBeca`.
