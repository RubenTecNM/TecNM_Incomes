import { http } from '../../../shared/api/http'
import type {
  AdeudoAlumno,
  AlumnoCaja,
  BecaAlumno,
  CarreraCatalogo,
  ConceptoCatalogo,
  CrearReciboPayload,
  PeriodoAcademicoItem,
  ReciboCaja,
  ReporteDetalladoItem,
  ResumenCajaTurno,
} from '../types/caja'

// Backend Recibo Response shape (flat alumno properties)
interface BackendReciboResponse {
  id: string
  numeroRecibo: number
  folioAdministrativo: string
  fechaOperacion: string
  matricula?: string
  nombreCompleto?: string
  carrera?: string
  semestre?: number
  turno?: string
  alumnoMatricula?: string
  alumnoNombre?: string
  alumnoCarrera?: string
  alumnoSemestre?: number
  alumnoTurno?: string
  metodoPago: string
  referenciaBancaria?: string
  cuentaBancaria?: string
  fechaBancaria?: string
  fechaEfectivaPago?: string
  subtotal: number
  descuentoTotal: number
  total: number
  estado: string
  motivoCancelacion?: string
  fechaCancelacion?: string
  cajeroUsuario: string
  cajeroNombre: string
  detalles: Array<{
    id: string
    conceptoId?: string
    descripcion: string
    cantidad: number
    cuotaUnitario: number
    descuentoBeca: number
    importeTotal: number
    periodoAno?: string
  }>
}

function adaptReciboResponse(item: BackendReciboResponse): ReciboCaja {
  return {
    id: item.id,
    numeroRecibo: item.numeroRecibo,
    folioAdministrativo: item.folioAdministrativo,
    fechaOperacion: item.fechaOperacion?.split('T')[0] ?? new Date().toISOString().split('T')[0],
    fechaEfectivaPago: item.fechaEfectivaPago || item.fechaBancaria,
    alumno: {
      matricula: item.matricula || item.alumnoMatricula || '',
      nombreCompleto: item.nombreCompleto || item.alumnoNombre || 'Sin Nombre',
      carrera: item.carrera || item.alumnoCarrera || '',
      semestre: item.semestre ?? item.alumnoSemestre ?? 1,
      turno: (item.turno as any) || (item.alumnoTurno as any) || 'Matutino',
      estatus: 'Inscrito',
      tieneBeca: item.descuentoTotal > 0,
      porcentajeBeca: item.subtotal > 0 ? (item.descuentoTotal / item.subtotal) * 100 : 0,
    },
    detalles: item.detalles.map(d => ({
      id: d.id,
      conceptoId: d.conceptoId,
      descripcion: d.descripcion,
      cantidad: d.cantidad,
      cuotaUnitario: d.cuotaUnitario,
      descuentoBeca: d.descuentoBeca,
      importeTotal: d.importeTotal,
      periodoAno: d.periodoAno,
    })),
    metodoPago: (item.metodoPago as any) || 'EFECTIVO',
    referenciaBancaria: item.referenciaBancaria,
    fechaBancaria: item.fechaBancaria,
    cuentaBancaria: item.cuentaBancaria,
    subtotal: item.subtotal,
    descuentoTotal: item.descuentoTotal,
    total: item.total,
    estado: (item.estado as any) || 'REGISTRADO',
    motivoCancelacion: item.motivoCancelacion,
    fechaCancelacion: item.fechaCancelacion,
    cajeroUsuario: item.cajeroUsuario,
    cajeroNombre: item.cajeroNombre,
    cajaNumero: '01',
  }
}

// =============================================================================
// Catálogos Oficiales
// =============================================================================

export async function getConceptos(): Promise<ConceptoCatalogo[]> {
  const { data } = await http.get<ConceptoCatalogo[]>('/caja/conceptos')
  return data
}

export async function getCarreras(): Promise<CarreraCatalogo[]> {
  const { data } = await http.get<CarreraCatalogo[]>('/caja/carreras')
  return data
}

export async function getPeriodos(): Promise<PeriodoAcademicoItem[]> {
  const { data } = await http.get<PeriodoAcademicoItem[]>('/caja/periodos')
  return data
}

// =============================================================================
// Alumnos e Historial de Matrícula
// =============================================================================

export async function buscarAlumnos(query?: string): Promise<AlumnoCaja[]> {
  const { data } = await http.get<AlumnoCaja[]>('/caja/alumnos/buscar', {
    params: { q: query },
  })
  return data
}

export async function getAlumno(matricula: string): Promise<AlumnoCaja> {
  const { data } = await http.get<AlumnoCaja>(`/caja/alumnos/${encodeURIComponent(matricula)}`)
  return data
}

export async function getHistorialMatriculas(matricula: string): Promise<any[]> {
  const { data } = await http.get<any[]>(`/caja/alumnos/${encodeURIComponent(matricula)}/historial-matriculas`)
  return data
}

export async function cambiarMatricula(matricula: string, payload: { nuevaMatricula: string; motivoCambio: string; idPeriodo?: number }): Promise<AlumnoCaja> {
  const { data } = await http.post<AlumnoCaja>(`/caja/alumnos/${encodeURIComponent(matricula)}/cambiar-matricula`, payload)
  return data
}

// =============================================================================
// Adeudos y Becas
// =============================================================================

export async function getAdeudosAlumno(matricula: string): Promise<AdeudoAlumno[]> {
  const { data } = await http.get<AdeudoAlumno[]>(`/caja/alumnos/${encodeURIComponent(matricula)}/adeudos`)
  return data
}

export async function getBecasAlumno(matricula: string): Promise<BecaAlumno[]> {
  const { data } = await http.get<BecaAlumno[]>(`/caja/alumnos/${encodeURIComponent(matricula)}/becas`)
  return data
}

export async function getAdeudosGeneral(filtros?: { matricula?: string; concepto?: string; periodoId?: number; estado?: string }): Promise<any[]> {
  const { data } = await http.get<any[]>('/caja/adeudos', { params: filtros })
  return data
}

// =============================================================================
// Desglose de Referencias Bancarias (5+5)
// =============================================================================

export interface DesgloseReferenciaResult {
  referenciaOriginal: string
  codigoEstudiante5: string
  codigoConcepto5: string
  alumnoDetectado: AlumnoCaja | null
  conceptoDetectado: ConceptoCatalogo | null
  recibosPrevios: ReciboCaja[]
  referenciaDuplicada: boolean
  mensaje: string
}

export async function desglosarReferencia(referencia: string): Promise<DesgloseReferenciaResult> {
  const { data } = await http.get<any>('/caja/referencias/desglosar', {
    params: { referencia },
  })
  return {
    ...data,
    recibosPrevios: (data.recibosPrevios || []).map(adaptReciboResponse),
  }
}

// =============================================================================
// Empleados y Cuentas (Para Modales de Catálogos)
// =============================================================================

export interface EmpleadoItem {
  id: string
  username: string
  name: string
  email: string
  role: string
  isActive: boolean
}

export async function getEmpleados(): Promise<EmpleadoItem[]> {
  const { data } = await http.get<EmpleadoItem[]>('/caja/empleados')
  return data
}

export async function crearEmpleado(payload: { username: string; name: string; email: string; role: string; password?: string }): Promise<EmpleadoItem> {
  const { data } = await http.post<EmpleadoItem>('/caja/empleados', payload)
  return data
}

export interface CuentaItem {
  id: string
  cuenta: string
  descripcion: string
  costo: number
  categoria: string
  aplicaBeca: boolean
}

export async function getCuentas(): Promise<CuentaItem[]> {
  const { data } = await http.get<CuentaItem[]>('/caja/cuentas')
  return data
}

export async function crearCuenta(payload: { cuenta: string; descripcion: string; costo: number; categoria?: string }): Promise<CuentaItem> {
  const { data } = await http.post<CuentaItem>('/caja/cuentas', payload)
  return data
}

export async function actualizarCuenta(id: string, payload: { descripcion: string; costo: number; categoria?: string }): Promise<CuentaItem> {
  const { data } = await http.put<CuentaItem>(`/caja/cuentas/${id}`, payload)
  return data
}

// =============================================================================
// Pólizas y Reportes Especializados (Para Modales)
// =============================================================================

export interface PolizaResumenItem {
  cuenta: string
  concepto: string
  cantidad: number
  total: number
}

export interface PolizaResumenResponse {
  fecha: string
  totalGeneral: number
  filas: PolizaResumenItem[]
}

export async function getPolizaResumen(fecha?: string): Promise<PolizaResumenResponse> {
  const { data } = await http.get<PolizaResumenResponse>('/caja/polizas/resumen', {
    params: { fecha },
  })
  return data
}

export interface ReporteIngresoItem {
  folio: string
  concepto: string
  nombre: string
  total: number
  estatus: string
}

export interface ReporteIngresoResponse {
  fecha: string
  totalGeneral: number
  filas: ReporteIngresoItem[]
}

export async function getReporteIngresos(fecha?: string): Promise<ReporteIngresoResponse> {
  const { data } = await http.get<ReporteIngresoResponse>('/caja/reportes/ingresos', {
    params: { fecha },
  })
  return data
}

export interface ReporteVeranoItem {
  reciboNo: string
  matricula: string
  alumno: string
  concepto: string
  cuota: number
  fecha: string
}

export interface ReporteVeranoResponse {
  fechaInicio: string
  fechaFin: string
  concepto: string
  cuotaUnitario: number
  totalRegistros: number
  totalRecaudado: number
  registros: ReporteVeranoItem[]
}

export async function getReporteVerano(inicio?: string, fin?: string, concepto?: string): Promise<ReporteVeranoResponse> {
  const { data } = await http.get<ReporteVeranoResponse>('/caja/reportes/verano', {
    params: { inicio, fin, concepto },
  })
  return data
}

// =============================================================================
// Recibos, Cobros y Corte Diario
// =============================================================================

export async function getRecibosRecientes(limite = 15): Promise<ReciboCaja[]> {
  const { data } = await http.get<BackendReciboResponse[]>('/caja/recibos/recientes', {
    params: { limite },
  })
  return data.map(adaptReciboResponse)
}

export async function getReciboPorNumero(numero: number): Promise<ReciboCaja> {
  const { data } = await http.get<BackendReciboResponse>(`/caja/recibos/${numero}`)
  return adaptReciboResponse(data)
}

export async function crearRecibo(payload: CrearReciboPayload): Promise<ReciboCaja> {
  const { data } = await http.post<BackendReciboResponse>('/caja/recibos', payload)
  return adaptReciboResponse(data)
}

export async function crearReciboPrevio(payload: CrearReciboPayload): Promise<ReciboCaja> {
  const { data } = await http.post<BackendReciboResponse>('/caja/recibos/previo', payload)
  return adaptReciboResponse(data)
}

export async function cancelarRecibo(id: string, motivo: string): Promise<ReciboCaja> {
  const { data } = await http.post<BackendReciboResponse>(`/caja/recibos/${id}/cancelar`, { motivo })
  return adaptReciboResponse(data)
}

export async function getCorteCaja(fecha?: string): Promise<ResumenCajaTurno> {
  const { data } = await http.get<ResumenCajaTurno>('/caja/corte', {
    params: { fecha },
  })
  return data
}

export async function getReporteDetallado(): Promise<ReporteDetalladoItem[]> {
  const { data } = await http.get<ReporteDetalladoItem[]>('/caja/reportes/detallado')
  return data
}

export interface DashboardIndicadoresResponse {
  usuarioActual: string
  rolActual: string
  scopeLabel: string
  periodo: string
  fechaReferencia: string
  recaudacionTotal: number
  metaObjetivo: number
  totalRecibosEmitidos: number
  ultimoFolio: string
  promedioPorRecibo: number
  totalAlumnosAtendidos: number
  porcentajeAlCorriente: number
  porcentajeConAdeudo: number
  adeudosRecuperadosMonto: number
  alumnosAdeudoRecuperado: number
  metodosPago: Array<{
    key: string
    nombre: string
    monto: number
    porcentaje: number
    color: string
  }>
  tendenciaSemanal: Array<{
    dia: string
    diaCorto: string
    monto: number
    etiquetaK: string
    porcentajeAltura: number
    esDestacado: boolean
  }>
  promedioSemanal: number
  conceptosTop: Array<{
    nombre: string
    monto: number
    porcentaje: number
  }>
  ultimosRecibos: Array<{
    id: string
    folio: string
    matricula: string
    alumno: string
    metodoPago: string
    monto: number
    estado: string
    fechaOperacion: string
    cajeroUsuario: string
  }>
}

export async function getDashboardIndicadores(
  periodo: 'hoy' | 'semana' | 'mes' = 'hoy',
): Promise<DashboardIndicadoresResponse> {
  const { data } = await http.get<DashboardIndicadoresResponse>('/dashboard/indicadores', {
    params: { periodo },
  })
  return data
}

export async function exportarDashboardPdf(
  periodo: 'hoy' | 'semana' | 'mes' = 'hoy',
): Promise<Blob> {
  const response = await http.get('/dashboard/exportar-pdf', {
    params: { periodo },
    responseType: 'blob',
  })
  return response.data
}

// ==========================================
// Módulo de Reportes & Exportaciones Multiformato (PDF, CSV, Word)
// ==========================================
export async function exportarReportePoliza(params: {
  fechaInicio?: string
  fechaFin?: string
  formaPago?: string
  cuentaContable?: string
  modo?: 'cuentas' | 'detalle'
  formato: 'pdf' | 'csv' | 'word'
}): Promise<Blob> {
  const response = await http.get('/reportes/poliza/exportar', {
    params,
    responseType: 'blob',
  })
  return response.data
}

export async function exportarReporteDeudores(params: {
  periodo?: string
  carreraId?: number
  fechaCorte?: string
  soloInscritos?: boolean
  formato: 'pdf' | 'csv' | 'word'
}): Promise<Blob> {
  const response = await http.get('/reportes/deudores/exportar', {
    params,
    responseType: 'blob',
  })
  return response.data
}

export async function exportarReporteIngresos(params: {
  fechaInicio?: string
  fechaFin?: string
  categoria?: string
  cajero?: string
  formato: 'pdf' | 'csv' | 'word'
}): Promise<Blob> {
  const response = await http.get('/reportes/ingresos/exportar', {
    params,
    responseType: 'blob',
  })
  return response.data
}

export async function exportarRecibo(
  folio: number | string,
  formato: 'pdf' | 'csv' | 'word' = 'pdf',
): Promise<Blob> {
  const response = await http.get(`/reportes/recibos/${folio}/exportar`, {
    params: { formato },
    responseType: 'blob',
  })
  return response.data
}

export function descargarBlob(blob: Blob, nombreArchivo: string): void {
  const url = window.URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = nombreArchivo
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  window.URL.revokeObjectURL(url)
}
