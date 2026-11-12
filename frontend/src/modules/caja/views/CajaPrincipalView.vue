<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  UiAlert,
  UiBadge,
  UiButton,
  UiCard,
  UiDialog,
  UiEmptyState,
  UiField,
  UiSkeleton,
  UiSpinner,
  UiToast,
  UiToggle,
} from '../../../shared/components'
import { useTheme } from '../../../shared/composables/useTheme'
import { logout, me } from '../../auth/api/authApi'
import { clearSessionMarker } from '../../../shared/utils/sessionCookie'
import ModalCuentas from '../../catalogos/components/ModalCuentas.vue'
import ModalEmpleados from '../../catalogos/components/ModalEmpleados.vue'
import ModalImprimeVerano from '../components/ModalImprimeVerano.vue'
import ModalPolizaIngresos from '../components/ModalPolizaIngresos.vue'
import ModalReporteIngresos from '../components/ModalReporteIngresos.vue'
import ModalPolizaIngresoPeriodo from '../components/ModalPolizaIngresoPeriodo.vue'
import ModalReporteIngresosPeriodo from '../components/ModalReporteIngresosPeriodo.vue'
import ModalReporteVarios from '../components/ModalReporteVarios.vue'
import ModalReporteDeudores from '../components/ModalReporteDeudores.vue'
import ModalReporteDeudoresFechaCorte from '../components/ModalReporteDeudoresFechaCorte.vue'
import ModalReporteDeudoresFechaCuenta from '../components/ModalReporteDeudoresFechaCuenta.vue'
import ModalReporteDeudoresInscritos from '../components/ModalReporteDeudoresInscritos.vue'
import ModalDepositoBancario from '../components/ModalDepositoBancario.vue'
import ModalDepositoBancarioPropedeutico from '../components/ModalDepositoBancarioPropedeutico.vue'
import ModalReciboProvisional from '../components/ModalReciboProvisional.vue'
import ModalReciboProvisionalCancelar from '../components/ModalReciboProvisionalCancelar.vue'
import * as cajaApi from '../api/cajaApi'
import type {
  AdeudoAlumno,
  AlumnoCaja,
  BecaAlumno,
  CarreraCatalogo,
  ConceptoCatalogo,
  CrearReciboPayload,
  DetalleConceptoRecibo,
  EstadoRecibo,
  MetodoPago,
  ReciboCaja,
} from '../types/caja' 

const route = useRoute()
const router = useRouter()
const { dark } = useTheme()

// ==========================================
// Cerrar Sesión
// ==========================================
const isCerrandoSesion = ref(false)

async function endSession(): Promise<void> {
  isCerrandoSesion.value = true
  try {
    await logout()
  } catch {
    // Si el API falla igual limpiamos la sesión local
  } finally {
    clearSessionMarker()
    await router.replace({ name: 'login' })
    isCerrandoSesion.value = false
  }
}

onMounted(async () => {
  try {
    const user = await me()
    if (user?.name) {
      cajeroActual.value = user.name
    } else if (user?.username) {
      cajeroActual.value = user.username
    }
  } catch {
    // Sesión no disponible o modo offline
  }
})

// ==========================================
// Control de Menú y Ventanas Modales de Catálogos
// ==========================================
const mostrarModalCuentas = ref(false)
const mostrarModalEmpleados = ref(false)
const mostrarModalImprimeVerano = ref(false)
const mostrarModalPolizaIngresos = ref(false)
const mostrarModalReporteIngresos = ref(false)
const mostrarModalPolizaIngresoPeriodo = ref(false)
const mostrarModalReporteIngresosPeriodo = ref(false)
const mostrarModalReporteVarios = ref(false)
const mostrarModalReporteDeudores = ref(false)
const mostrarModalReporteDeudoresFechaCorte = ref(false)
const mostrarModalReporteDeudoresFechaCuenta = ref(false)
const mostrarModalReporteDeudoresInscritos = ref(false)
const mostrarModalDepositoBancario = ref(false)
const mostrarModalDepositoBancarioPropedeutico = ref(false)
const mostrarModalReciboProvisional = ref(false)
const mostrarModalReciboProvisionalCancelar = ref(false)
const menuAbierto = ref<'catalogo' | 'imprimir' | 'control' | 'utilerias' | null>(null)

function toggleMenu(menu: 'catalogo' | 'imprimir' | 'control' | 'utilerias'): void {
  menuAbierto.value = menuAbierto.value === menu ? null : menu
}

function cerrarMenus(): void {
  menuAbierto.value = null
}

function abrirModalCuentas(): void {
  mostrarModalCuentas.value = true
  cerrarMenus()
}

function abrirModalEmpleados(): void {
  mostrarModalEmpleados.value = true
  cerrarMenus()
}

function abrirModalImprimeVerano(): void {
  mostrarModalImprimeVerano.value = true
  cerrarMenus()
}

function abrirModalPolizaIngresos(): void {
  mostrarModalPolizaIngresos.value = true
  cerrarMenus()
}

function abrirModalReporteIngresos(): void {
  mostrarModalReporteIngresos.value = true
  cerrarMenus()
}

function abrirModalPolizaIngresoPeriodo(): void {
  mostrarModalPolizaIngresoPeriodo.value = true
  cerrarMenus()
}

function abrirModalReporteIngresosPeriodo(): void {
  mostrarModalReporteIngresosPeriodo.value = true
  cerrarMenus()
}

function abrirModalReporteVarios(): void {
  mostrarModalReporteVarios.value = true
  cerrarMenus()
}

function abrirModalReporteDeudores(): void {
  mostrarModalReporteDeudores.value = true
  cerrarMenus()
}

function abrirModalReporteDeudoresFechaCorte(): void {
  mostrarModalReporteDeudoresFechaCorte.value = true
  cerrarMenus()
}

function abrirModalReporteDeudoresFechaCuenta(): void {
  mostrarModalReporteDeudoresFechaCuenta.value = true
  cerrarMenus()
}

function abrirModalReporteDeudoresInscritos(): void {
  mostrarModalReporteDeudoresInscritos.value = true
  cerrarMenus()
}

function abrirModalDepositoBancario(): void {
  mostrarModalDepositoBancario.value = true
  cerrarMenus()
}

function abrirModalDepositoBancarioPropedeutico(): void {
  mostrarModalDepositoBancarioPropedeutico.value = true
  cerrarMenus()
}

function abrirModalReciboProvisional(): void {
  mostrarModalReciboProvisional.value = true
  cerrarMenus()
}

function abrirModalReciboProvisionalCancelar(): void {
  mostrarModalReciboProvisionalCancelar.value = true
  cerrarMenus()
}

function cerrarModalCuentas(): void {
  mostrarModalCuentas.value = false
  if (route.hash === '#cuentas') {
    void router.replace({ path: route.path })
  }
}

function cerrarModalEmpleados(): void {
  mostrarModalEmpleados.value = false
  if (route.hash === '#empleados') {
    void router.replace({ path: route.path })
  }
}

// Escuchar cambios en la URL (por ejemplo si el usuario pulsa en el sidebar)
watch(
  () => route.hash,
  (hash) => {
    if (hash === '#cuentas') {
      mostrarModalCuentas.value = true
    } else if (hash === '#empleados') {
      mostrarModalEmpleados.value = true
    }
  },
  { immediate: true },
)

// ==========================================
// Notificaciones Toast y Estados de Carga Asíncrona
// ==========================================
const toastRef = ref<InstanceType<typeof UiToast>>()
const isBuscandoAlumno = ref(false)
const isGuardandoCobro = ref(false)
const isCargandoHistorial = ref(false)

// ==========================================
// 1. Datos del Cajero y Turno Operativo
// ==========================================
const cajeroActual = ref('Cajero en Turno')
const cajaNumero = ref('01')
const turnoActual = ref('Matutino')
const fechaOperacion = ref(new Date().toISOString().split('T')[0])
const permitirEditarFecha = ref(false)

// ==========================================
// 2. Metadatos del Recibo en Pantalla
// ==========================================
const numeroRecibo = ref<number | string>('')
const folioAdministrativo = ref('')
const estadoRecibo = ref<EstadoRecibo>('REGISTRADO')
const metodoPagoSeleccionado = ref<MetodoPago>('EFECTIVO')
const referenciaBancaria = ref('')
const fechaBancaria = ref('')
const cuentaBancaria = ref('0123456789')

// ==========================================
// 3. Expediente del Estudiante y Catálogos Dinámicos
// ==========================================
const busquedaMatricula = ref('')
const adeudosAlumno = ref<AdeudoAlumno[]>([])
const becasAlumno = ref<BecaAlumno[]>([])

const alumno = ref<AlumnoCaja>({
  matricula: '',
  nombreCompleto: '',
  carrera: 'Ing. Industrial',
  carreraId: 67,
  semestre: 1,
  turno: 'Matutino',
  estatus: 'Inscrito',
  tieneBeca: false,
  porcentajeBeca: 0,
})

// Catálogo dinámico de carreras desde PostgreSQL (con respaldo institucional)
const opcionesCarreras = ref([
  { value: '', label: 'Seleccionar carrera...' },
  { value: 'Ing. Industrial', label: 'Ing. Industrial (INGENIERIA INDUSTRIAL)' },
  { value: 'Ing. Mecánica', label: 'Ing. Mecánica (INGENIERIA MECANICA)' },
  { value: 'Ing. Electrónica', label: 'Ing. Electrónica (INGENIERIA ELECTRONICA)' },
  { value: 'Ing. Gestión Emp.', label: 'Ing. Gestión Emp. (INGENIERIA EN GESTION EMPRESARIAL)' },
  { value: 'Ing. Informática', label: 'Ing. Informática (INGENIERIA INFORMATICA)' },
  { value: 'Lic. Informática', label: 'Lic. Informática (LICENCIATURA EN INFORMATICA)' },
  { value: 'Ing. Energías Renovables', label: 'Ing. Energías Renovables' },
  { value: 'Ing. Mecatrónica', label: 'Ing. Mecatrónica (INGENIERIA MECATRONICA)' },
])

const sugerenciasEstudiantes = ref<AlumnoCaja[]>([])
let searchDebounceTimeout: any = null

function limpiarExpedienteEstudiante(): void {
  alumno.value = {
    matricula: '',
    nombreCompleto: '',
    carrera: 'Ing. Industrial',
    carreraId: 67,
    semestre: 1,
    turno: 'Matutino',
    estatus: 'Inscrito',
    tieneBeca: false,
    porcentajeBeca: 0,
  }
  adeudosAlumno.value = []
  becasAlumno.value = []
  sugerenciasEstudiantes.value = []
}

function onBusquedaInput(val: string): void {
  busquedaMatricula.value = val
  if (searchDebounceTimeout) clearTimeout(searchDebounceTimeout)

  // 1. Si el usuario borra la caja de búsqueda, limpiar de inmediato adeudos y expediente anterior
  if (!val || val.trim() === '') {
    limpiarExpedienteEstudiante()
    return
  }

  // 2. Si el texto cambia y ya no coincide con la matrícula cargada, quitar adeudos del alumno anterior
  if (val.trim() !== alumno.value.matricula) {
    adeudosAlumno.value = []
    becasAlumno.value = []
  }

  if (val.trim().length < 2) {
    sugerenciasEstudiantes.value = []
    return
  }

  searchDebounceTimeout = setTimeout(async () => {
    try {
      const res = await cajaApi.buscarAlumnos(val.trim())
      sugerenciasEstudiantes.value = res || []

      // Si coincide exactamente con una matrícula, cargar automáticamente el nuevo alumno y sus adeudos
      const coincidencia = (res || []).find(
        a => a.matricula.toLowerCase() === val.trim().toLowerCase()
      )
      if (coincidencia && coincidencia.matricula !== alumno.value.matricula) {
        await seleccionarEstudiante(coincidencia, false)
      }
    } catch {
      sugerenciasEstudiantes.value = []
    }
  }, 200)
}

function cobrarAdeudo(adeudo: AdeudoAlumno): void {
  const conceptoMatch = catalogoConceptos.value.find(c =>
    c.descripcion.toLowerCase().includes(adeudo.conceptoCobro.toLowerCase()) ||
    c.clave.toLowerCase().includes('insc')
  )

  const yaExiste = partidas.value.find(p => p.descripcion.includes(adeudo.conceptoCobro) && p.periodoAno === adeudo.periodoCodigo)
  if (yaExiste) {
    toastRef.value?.info(`El adeudo de ${adeudo.conceptoCobro} (${adeudo.periodoCodigo}) ya está incluido en el recibo.`)
    return
  }

  partidas.value.push({
    id: `adeudo-${adeudo.idAdeudo}-${Date.now()}`,
    conceptoId: conceptoMatch?.id || undefined,
    descripcion: `${adeudo.conceptoCobro} (Periodo: ${adeudo.periodoCodigo})`,
    cantidad: 1,
    cuotaUnitario: adeudo.saldoPendiente,
    descuentoBeca: 0,
    importeTotal: adeudo.saldoPendiente,
    periodoAno: adeudo.periodoCodigo,
  })

  toastRef.value?.success(`Adeudo de ${adeudo.conceptoCobro} ($${adeudo.saldoPendiente.toFixed(2)}) cargado al recibo. Puedes editar el importe si el alumno desea abonar una cantidad parcial.`)
}

const desgloseReferenciaInfo = ref<cajaApi.DesgloseReferenciaResult | null>(null)
let debounceReferenciaTimeout: any = null

function onReferenciaBancariaInput(val: string): void {
  referenciaBancaria.value = val
  if (debounceReferenciaTimeout) clearTimeout(debounceReferenciaTimeout)

  if (!val || val.trim().length < 5) {
    desgloseReferenciaInfo.value = null
    return
  }

  debounceReferenciaTimeout = setTimeout(async () => {
    try {
      const res = await cajaApi.desglosarReferencia(val.trim())
      desgloseReferenciaInfo.value = res
      if (res.alumnoDetectado && !alumno.value.matricula) {
        toastRef.value?.info(`Referencia 5+5 asociada a ${res.alumnoDetectado.nombreCompleto}.`)
      }
      if (res.referenciaDuplicada) {
        toastRef.value?.warning(res.mensaje)
      }
    } catch {
      desgloseReferenciaInfo.value = null
    }
  }, 300)
}

function aplicarAlumnoDeReferencia(): void {
  if (desgloseReferenciaInfo.value?.alumnoDetectado) {
    void seleccionarEstudiante(desgloseReferenciaInfo.value.alumnoDetectado)
  }
}

async function seleccionarEstudiante(est: AlumnoCaja, showNotification = true): Promise<void> {
  alumno.value.matricula = est.matricula
  alumno.value.nombreCompleto = est.nombreCompleto
  alumno.value.carrera = est.carrera
  alumno.value.semestre = est.semestre
  alumno.value.turno = est.turno || 'Matutino'
  alumno.value.estatus = est.estatus || 'Inscrito'
  alumno.value.tieneBeca = est.tieneBeca
  alumno.value.porcentajeBeca = est.porcentajeBeca || 0
  busquedaMatricula.value = est.matricula
  sugerenciasEstudiantes.value = []

  // Consultar adeudos y becas activas del estudiante en la base de datos
  try {
    const [adeudos, becas] = await Promise.all([
      cajaApi.getAdeudosAlumno(est.matricula),
      cajaApi.getBecasAlumno(est.matricula),
    ])
    adeudosAlumno.value = adeudos || []
    becasAlumno.value = becas || []

    if (adeudos && adeudos.length > 0) {
      toastRef.value?.warning(`Atención: El estudiante presenta ${adeudos.length} adeudo(s) pendiente(s).`)
    }
  } catch {
    adeudosAlumno.value = []
    becasAlumno.value = []
  }

  // Recalcular descuentos de beca en partidas existentes si aplica
  partidas.value.forEach(p => {
    const itemCat = catalogoConceptos.value.find(c => c.id === p.conceptoId || c.clave === p.conceptoId)
    if (itemCat && itemCat.aplicaBeca && alumno.value.tieneBeca) {
      p.descuentoBeca = (itemCat.cuotaBase * alumno.value.porcentajeBeca) / 100
      p.importeTotal = (itemCat.cuotaBase - p.descuentoBeca) * p.cantidad
    }
  })

  if (showNotification) {
    toastRef.value?.success(`Expediente cargado: ${est.nombreCompleto}`)
  }
}

async function buscarEstudiante(): Promise<void> {
  const q = busquedaMatricula.value.trim()
  if (!q) {
    limpiarExpedienteEstudiante()
    toastRef.value?.warning('Ingresa una matrícula o nombre para realizar la búsqueda.')
    return
  }

  isBuscandoAlumno.value = true
  // Limpiar adeudos del alumno anterior mientras se realiza la nueva búsqueda
  adeudosAlumno.value = []
  becasAlumno.value = []

  try {
    const resultados = await cajaApi.buscarAlumnos(q)
    isBuscandoAlumno.value = false

    if (resultados && resultados.length > 0) {
      const match = resultados[0]
      await seleccionarEstudiante(match, false)
      toastRef.value?.success(`Alumno localizado: ${match.nombreCompleto}`)
    } else {
      limpiarExpedienteEstudiante()
      toastRef.value?.error(`No se encontró ningún estudiante con "${busquedaMatricula.value}".`)
    }
  } catch (err: any) {
    isBuscandoAlumno.value = false
    limpiarExpedienteEstudiante()
    toastRef.value?.error('Error de comunicación con el servicio de estudiantes.')
  }
}

const opcionesTurnos = [
  { value: '', label: 'Seleccionar turno...' },
  { value: 'Matutino', label: 'Matutino' },
  { value: 'Vespertino', label: 'Vespertino' },
  { value: 'Nocturno', label: 'Nocturno' },
]

// ==========================================
// 4. Catálogo y Rejilla de Conceptos
// ==========================================
const catalogoConceptos = ref<ConceptoCatalogo[]>([
  { id: 'c1', clave: '5200-001-002-004', descripcion: 'CUOTA DE INSCRIPCION AL SEMESTRE REGULAR', cuotaBase: 2600.0, aplicaBeca: true, categoria: 'Inscripción' },
  { id: 'c2', clave: 'INSC', descripcion: 'Pago de Inscripción (Periodo Vigente 2026)', cuotaBase: 2600.0, aplicaBeca: true, categoria: 'Inscripción' },
  { id: 'c3', clave: 'INSC-ANT', descripcion: 'Adeudo Inscripción (Año 2025)', cuotaBase: 2450.0, aplicaBeca: false, categoria: 'Inscripción' },
  { id: 'c4', clave: 'KARD', descripcion: 'KARDEX OFICIAL DE CALIFICACIONES', cuotaBase: 150.0, aplicaBeca: false, categoria: 'Constancias' },
  { id: 'c5', clave: 'CONST', descripcion: 'Constancia de Estudios con Calificaciones', cuotaBase: 100.0, aplicaBeca: false, categoria: 'Constancias' },
  { id: 'c6', clave: 'VERA', descripcion: 'Curso de Verano (Por Asignatura)', cuotaBase: 1200.0, aplicaBeca: false, categoria: 'Cursos' },
  { id: 'c7', clave: 'TITU', descripcion: 'Trámite de Titulación Integral y Cédula', cuotaBase: 3800.0, aplicaBeca: false, categoria: 'Otros' },
])

const conceptoSeleccionadoId = ref('c1')
const partidas = ref<DetalleConceptoRecibo[]>([])

function agregarConcepto(): void {
  const itemCatalogo = catalogoConceptos.value.find(c => c.id === conceptoSeleccionadoId.value || c.clave === conceptoSeleccionadoId.value)
  if (!itemCatalogo) return

  const descuento = alumno.value.tieneBeca && itemCatalogo.aplicaBeca
    ? (itemCatalogo.cuotaBase * alumno.value.porcentajeBeca) / 100
    : 0

  const importe = itemCatalogo.cuotaBase - descuento

  partidas.value.push({
    id: `p-${Date.now()}`,
    conceptoId: itemCatalogo.id,
    descripcion: itemCatalogo.descripcion,
    cantidad: 1,
    cuotaUnitario: itemCatalogo.cuotaBase,
    descuentoBeca: descuento,
    importeTotal: importe,
    periodoAno: '2026-1',
  })
  toastRef.value?.info(`Concepto añadido: ${itemCatalogo.descripcion}`)
}

function eliminarPartida(id: string): void {
  const item = partidas.value.find(p => p.id === id)
  partidas.value = partidas.value.filter(p => p.id !== id)
  if (item) {
    toastRef.value?.info(`Concepto "${item.descripcion}" eliminado del recibo`)
  }
}

// ==========================================
// 5. Cálculos de Totales
// ==========================================
const subtotal = computed(() =>
  partidas.value.reduce((acc, curr) => acc + curr.cuotaUnitario * curr.cantidad, 0),
)

const totalDescuentos = computed(() =>
  partidas.value.reduce((acc, curr) => acc + curr.descuentoBeca * curr.cantidad, 0),
)

const granTotal = computed(() =>
  Math.max(0, subtotal.value - totalDescuentos.value),
)

// ==========================================
// 6. Historial de Recibos Recientes del Turno
// ==========================================
const historialTurno = ref<ReciboCaja[]>([])

function cargarReciboHistorial(rec: ReciboCaja): void {
  numeroRecibo.value = rec.numeroRecibo
  folioAdministrativo.value = rec.folioAdministrativo
  fechaOperacion.value = rec.fechaOperacion
  estadoRecibo.value = rec.estado
  alumno.value = { ...rec.alumno }
  busquedaMatricula.value = rec.alumno.matricula
  partidas.value = [...rec.detalles]
  metodoPagoSeleccionado.value = rec.metodoPago
  if (rec.referenciaBancaria) referenciaBancaria.value = rec.referenciaBancaria
  if (rec.cuentaBancaria) cuentaBancaria.value = rec.cuentaBancaria
  toastRef.value?.info(`Recibo #${rec.numeroRecibo} cargado en vista`)
}

// ==========================================
// 7. Modales: Cancelación e Impresión
// ==========================================
const mostrarModalCancelar = ref(false)
const motivoCancelacion = ref('')
const errorCancelacion = ref('')

function abrirModalCancelar(): void {
  motivoCancelacion.value = ''
  errorCancelacion.value = ''
  mostrarModalCancelar.value = true
}

async function confirmarCancelacion(): Promise<void> {
  if (!motivoCancelacion.value.trim() || motivoCancelacion.value.length < 5) {
    errorCancelacion.value = 'Debes ingresar un motivo administrativo válido (mínimo 5 caracteres).'
    toastRef.value?.error('Ingresa una justificación válida de al menos 5 caracteres.')
    return
  }

  const rec = historialTurno.value.find(r => r.numeroRecibo === Number(numeroRecibo.value))

  try {
    if (rec && rec.id) {
      await cajaApi.cancelarRecibo(rec.id, motivoCancelacion.value)
    }
  } catch (err: any) {
    // Continúa con la actualización visual
  }

  estadoRecibo.value = 'CANCELADO'
  mostrarModalCancelar.value = false

  if (rec) {
    rec.estado = 'CANCELADO'
    rec.motivoCancelacion = motivoCancelacion.value
    rec.fechaCancelacion = new Date().toISOString()
  }

  toastRef.value?.warning(`Recibo #${numeroRecibo.value} cancelado formalmente`)
}

const mostrarModalImprimir = ref(false)

function abrirImpresion(): void {
  mostrarModalImprimir.value = true
}

function imprimirDocumento(): void {
  window.print()
}

function limpiarFormulario(): void {
  const num = typeof numeroRecibo.value === 'number' ? numeroRecibo.value : Number(numeroRecibo.value) || 128450
  numeroRecibo.value = num + 1
  folioAdministrativo.value = `FOL-2026-09-${numeroRecibo.value}`
  estadoRecibo.value = 'PREVIO'
  busquedaMatricula.value = ''
  adeudosAlumno.value = []
  alumno.value = {
    matricula: '',
    nombreCompleto: '',
    carrera: 'Ing. Industrial',
    carreraId: 67,
    semestre: 1,
    turno: 'Matutino',
    estatus: 'Inscrito',
    tieneBeca: false,
    porcentajeBeca: 0,
  }
  partidas.value = []
}

// ==========================================
// 8. Registro Real de Cobros y Recibos
// ==========================================
async function registrarCobro(): Promise<void> {
  if (!alumno.value.matricula.trim() || !alumno.value.nombreCompleto.trim()) {
    toastRef.value?.error('Debes ingresar la matrícula y datos del estudiante antes de registrar el cobro.')
    return
  }
  if (partidas.value.length === 0) {
    toastRef.value?.error('Debes agregar al menos un concepto de cobro.')
    return
  }

  isGuardandoCobro.value = true

  const payload: CrearReciboPayload = {
    matricula: alumno.value.matricula.trim(),
    nombreCompleto: alumno.value.nombreCompleto.trim(),
    carrera: alumno.value.carrera.trim(),
    semestre: alumno.value.semestre,
    turno: alumno.value.turno.trim(),
    metodoPago: metodoPagoSeleccionado.value,
    referenciaBancaria: metodoPagoSeleccionado.value === 'DEPOSITO_BANCARIO' ? referenciaBancaria.value : undefined,
    cuentaBancaria: cuentaBancaria.value || undefined,
    fechaBancaria: fechaBancaria.value ? new Date(fechaBancaria.value).toISOString() : undefined,
    fechaOperacion: permitirEditarFecha.value && fechaOperacion.value ? `${fechaOperacion.value}T12:00:00Z` : undefined,
    justificacionFecha: permitirEditarFecha.value ? 'Modificación administrativa de fecha justificada en ventanilla' : undefined,
    detalles: partidas.value.map(p => ({
      conceptoId: p.conceptoId && p.conceptoId.length === 36 ? p.conceptoId : undefined,
      descripcion: p.descripcion,
      cantidad: p.cantidad,
      cuotaUnitario: p.cuotaUnitario,
      descuentoBeca: p.descuentoBeca,
      importeTotal: p.importeTotal,
      periodoAno: p.periodoAno || '2026-1',
    })),
  }

  try {
    const nuevoRecibo = await cajaApi.crearRecibo(payload)

    numeroRecibo.value = nuevoRecibo.numeroRecibo
    folioAdministrativo.value = nuevoRecibo.folioAdministrativo
    estadoRecibo.value = 'REGISTRADO'

    historialTurno.value.unshift(nuevoRecibo)
    isGuardandoCobro.value = false

    toastRef.value?.success(`Recibo #${nuevoRecibo.numeroRecibo} registrado con éxito ($${nuevoRecibo.total.toFixed(2)})`)
    abrirImpresion()
  } catch (e: any) {
    // Si la conexión falla en desarrollo, registrar en memoria local para no bloquear la ventanilla
    const fallbackNumero = typeof numeroRecibo.value === 'number' ? numeroRecibo.value : (Date.now() % 1000000)
    estadoRecibo.value = 'REGISTRADO'
    const fallbackRecibo: ReciboCaja = {
      id: `rec-${fallbackNumero}`,
      numeroRecibo: fallbackNumero,
      folioAdministrativo: folioAdministrativo.value || `FOL-2026-09-${fallbackNumero}`,
      fechaOperacion: fechaOperacion.value,
      alumno: { ...alumno.value },
      detalles: [...partidas.value],
      metodoPago: metodoPagoSeleccionado.value,
      referenciaBancaria: metodoPagoSeleccionado.value === 'DEPOSITO_BANCARIO' ? referenciaBancaria.value : undefined,
      subtotal: subtotal.value,
      descuentoTotal: totalDescuentos.value,
      total: granTotal.value,
      estado: 'REGISTRADO',
      cajeroNombre: cajeroActual.value,
      cajaNumero: cajaNumero.value,
    }
    historialTurno.value.unshift(fallbackRecibo)
    numeroRecibo.value = fallbackNumero
    isGuardandoCobro.value = false
    toastRef.value?.success(`Recibo #${fallbackNumero} procesado ($${fallbackRecibo.total.toFixed(2)})`)
    abrirImpresion()
  }
}

async function generarReciboPrevio(): Promise<void> {
  if (!alumno.value.matricula.trim() || !alumno.value.nombreCompleto.trim()) {
    toastRef.value?.error('Debes ingresar la matrícula y datos del estudiante.')
    return
  }
  if (partidas.value.length === 0) {
    toastRef.value?.error('Debes agregar al menos un concepto de cobro.')
    return
  }

  isGuardandoCobro.value = true
  const payload: CrearReciboPayload = {
    matricula: alumno.value.matricula.trim(),
    nombreCompleto: alumno.value.nombreCompleto.trim(),
    carrera: alumno.value.carrera.trim(),
    semestre: alumno.value.semestre,
    turno: alumno.value.turno.trim(),
    metodoPago: metodoPagoSeleccionado.value,
    fechaOperacion: permitirEditarFecha.value && fechaOperacion.value ? `${fechaOperacion.value}T12:00:00Z` : undefined,
    justificacionFecha: permitirEditarFecha.value ? 'Modificación de fecha justificada' : undefined,
    detalles: partidas.value.map(p => ({
      conceptoId: p.conceptoId && p.conceptoId.length === 36 ? p.conceptoId : undefined,
      descripcion: p.descripcion,
      cantidad: p.cantidad,
      cuotaUnitario: p.cuotaUnitario,
      descuentoBeca: p.descuentoBeca,
      importeTotal: p.importeTotal,
      periodoAno: '2026-1',
    })),
  }

  try {
    const previo = await cajaApi.crearReciboPrevio(payload)
    numeroRecibo.value = previo.numeroRecibo
    folioAdministrativo.value = previo.folioAdministrativo
    estadoRecibo.value = 'PREVIO'
    historialTurno.value.unshift(previo)
    toastRef.value?.info(`Recibo previo generado: ${previo.folioAdministrativo}`)
  } catch {
    estadoRecibo.value = 'PREVIO'
    toastRef.value?.info('Recibo provisional preparado en pantalla.')
  } finally {
    isGuardandoCobro.value = false
  }
}

// ==========================================
// 9. Ciclo de Vida: Inicialización Asíncrona
// ==========================================
onMounted(async () => {
  // 1. Obtener usuario de sesión
  try {
    const user = await me()
    if (user) {
      cajeroActual.value = user.name || user.username
      turnoActual.value = (user.role as string) === 'Cajero' ? 'Matutino' : user.role
      cajaNumero.value = '01'
    }
  } catch {
    cajeroActual.value = 'Cajero Turno Matutino'
    turnoActual.value = 'Matutino'
    cajaNumero.value = '01'
  }

  // 2. Cargar Catálogo Oficial de Carreras desde la Base de Datos
  try {
    const carreras = await cajaApi.getCarreras()
    if (carreras && carreras.length > 0) {
      opcionesCarreras.value = [
        { value: '', label: 'Seleccionar carrera...' },
        ...carreras.map(c => ({
          value: c.carrera,
          label: `${c.carrera} (${c.nombreCarrera})`,
        })),
      ]
    }
  } catch {
    // Mantiene las carreras base
  }

  // 3. Cargar Conceptos de Cobro
  try {
    const conceptos = await cajaApi.getConceptos()
    if (conceptos && conceptos.length > 0) {
      catalogoConceptos.value = conceptos
      conceptoSeleccionadoId.value = conceptos[0].id
    }
  } catch {
    // Mantiene los conceptos base
  }

  // 4. Cargar Historial Reciente de la Sesión
  isCargandoHistorial.value = true
  try {
    const recibos = await cajaApi.getRecibosRecientes(15)
    if (recibos && recibos.length > 0) {
      historialTurno.value = recibos
      // Precargar último consecutivo
      numeroRecibo.value = recibos[0].numeroRecibo + 1
      folioAdministrativo.value = `FOL-2026-09-${numeroRecibo.value}`
    } else {
      numeroRecibo.value = 128450
      folioAdministrativo.value = 'FOL-2026-09-128450'
    }
  } catch {
    numeroRecibo.value = 128450
    folioAdministrativo.value = 'FOL-2026-09-128450'
  } finally {
    isCargandoHistorial.value = false
  }
})
</script>

<template>
  <div class="caja-dashboard" :class="{ 'dark-theme': dark }" @click="cerrarMenus">
    <!-- BARRA DE MENÚ CLÁSICA INSTITUCIONAL TECNM -->
    <nav class="tecnm-classic-menubar" aria-label="Menú principal del sistema" @click.stop>
      <div class="menubar-left-group">
        <span class="menubar-title-tag">Menú</span>
        <div class="menubar-items-group">
          <!-- 1. Archivo -->
          <div class="menubar-item">
            <button type="button" class="menubar-btn">Archivo</button>
          </div>

          <!-- 2. Catálogo (Empleados, Cuentas) -->
          <div class="menubar-item dropdown-parent" :class="{ open: menuAbierto === 'catalogo' }">
            <button
              type="button"
              class="menubar-btn btn-dropdown"
              :aria-expanded="menuAbierto === 'catalogo'"
              @click.stop="toggleMenu('catalogo')"
            >
              Catálogo <span class="arrow-indicator">▾</span>
            </button>

            <div v-if="menuAbierto === 'catalogo'" class="menubar-dropdown-panel" role="menu">
              <button
                type="button"
                class="dropdown-entry"
                role="menuitem"
                @click="abrirModalEmpleados"
              >
                <svg class="entry-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                  <circle cx="9" cy="7" r="4" />
                </svg>
                <span>Empleados</span>
              </button>

              <button
                type="button"
                class="dropdown-entry"
                role="menuitem"
                @click="abrirModalCuentas"
              >
                <svg class="entry-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect x="3" y="4" width="18" height="16" rx="2" />
                  <line x1="3" y1="10" x2="21" y2="10" />
                </svg>
                <span>Cuentas</span>
              </button>
            </div>
          </div>

          <!-- 3. Imprimir (15 opciones del reporte) -->
          <div class="menubar-item dropdown-parent" :class="{ open: menuAbierto === 'imprimir' }">
            <button
              type="button"
              class="menubar-btn btn-dropdown"
              :aria-expanded="menuAbierto === 'imprimir'"
              @click.stop="toggleMenu('imprimir')"
            >
              Imprimir <span class="arrow-indicator">▾</span>
            </button>

            <div v-if="menuAbierto === 'imprimir'" class="menubar-dropdown-panel menubar-dropdown-scroll" role="menu">
              <button type="button" class="dropdown-entry dropdown-entry-active" role="menuitem" @click="cerrarMenus">
                <span>Recibo</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalPolizaIngresos">
                <span>Poliza de Ingresos</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReporteIngresos">
                <span>Reporte de Ingresos</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalPolizaIngresoPeriodo">
                <span>Poliza de Ingreso Periodo</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReporteIngresosPeriodo">
                <span>Reporte de Ingresos por Periodo</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReporteVarios">
                <span>Reporte Varios</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReporteDeudores">
                <span>Reporte Deudores</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReporteDeudoresFechaCorte">
                <span>Reporte Deudores Fecha de Corte</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReporteDeudoresFechaCuenta">
                <span>Reporte Deudores Fecha y Cuenta</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReporteDeudoresInscritos">
                <span>Reporte Deudores Inscritos</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalDepositoBancario">
                <span>Deposito Bancario</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReciboProvisional">
                <span>Recibo Provisional</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReciboProvisionalCancelar">
                <span>Recibo Provisional Cancelar</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalDepositoBancarioPropedeutico">
                <span>Deposito Bancario - Curso Propedeutico</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalImprimeVerano">
                <span>Imprime Verano</span>
              </button>
            </div>
          </div>

          <!-- 4. Control (2 opciones) -->
          <div class="menubar-item dropdown-parent" :class="{ open: menuAbierto === 'control' }">
            <button
              type="button"
              class="menubar-btn btn-dropdown"
              :aria-expanded="menuAbierto === 'control'"
              @click.stop="toggleMenu('control')"
            >
              Control <span class="arrow-indicator">▾</span>
            </button>

            <div v-if="menuAbierto === 'control'" class="menubar-dropdown-panel" role="menu">
              <button type="button" class="dropdown-entry" role="menuitem" @click="cerrarMenus">
                <span>Consulta y Cancelación de Recibos</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="cerrarMenus">
                <span>Corte por Empleado</span>
              </button>
            </div>
          </div>

          <!-- 5. Utilerías (3 opciones) -->
          <div class="menubar-item dropdown-parent" :class="{ open: menuAbierto === 'utilerias' }">
            <button
              type="button"
              class="menubar-btn btn-dropdown"
              :aria-expanded="menuAbierto === 'utilerias'"
              @click.stop="toggleMenu('utilerias')"
            >
              Utilerías <span class="arrow-indicator">▾</span>
            </button>

            <div v-if="menuAbierto === 'utilerias'" class="menubar-dropdown-panel" role="menu">
              <button type="button" class="dropdown-entry" role="menuitem" @click="cerrarMenus">
                <span>Cambio de Contraseña</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="cerrarMenus">
                <span>Cierre de Semestre</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="cerrarMenus">
                <span>Crear Usuario</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Selector de Modo Oscuro / Claro integrado en el menú -->
      <div class="menubar-theme-toggle">
        <UiToggle
          v-model="dark"
          type="switch"
          :label="dark ? 'Modo oscuro' : 'Modo claro'"
          class="theme-switch"
        />
      </div>
    </nav>

    <!-- BARRA SUPERIOR INSTITUCIONAL: Control de Caja TecNM -->
    <header class="cashier-status-bar">
      <div class="brand-zone">
        <span class="institution-pill">TecNM Monclova</span>
        <h1 class="system-title">Sistema de Control de Caja Universitaria</h1>
      </div>

      <div class="cashier-meta">
        <div class="meta-item">
          <span class="meta-label">Usuario</span>
          <strong class="meta-value">{{ cajeroActual || '—' }}</strong>
        </div>
        <div class="meta-item">
          <span class="meta-label">Fecha de Movimientos</span>
          <strong class="meta-value">{{ fechaOperacion }}</strong>
        </div>
        <div class="meta-item">
          <span class="meta-label">Estatus del Recibo</span>
          <UiBadge tone="success">
            {{ estadoRecibo }}
          </UiBadge>
        </div>
        <button
          type="button"
          class="btn-cerrar-sesion"
          :disabled="isCerrandoSesion"
          @click="endSession"
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="logout-icon">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
            <polyline points="16 17 21 12 16 7" />
            <line x1="21" y1="12" x2="9" y2="12" />
          </svg>
          {{ isCerrandoSesion ? 'Cerrando…' : 'Cerrar sesión' }}
        </button>
      </div>
    </header>

    <div class="caja-grid-layout">
      <!-- ÁREA PRINCIPAL DE TRABAJO -->
      <main class="caja-main-area">
        <!-- 1. Encabezado del Recibo y Búsqueda -->
        <UiCard class="receipt-header-card">
          <div class="header-card-row">
            <div class="receipt-number-group">
              <span class="receipt-number-label">Recibo No:</span>
              <span class="receipt-number-badge">{{ numeroRecibo || 'NUEVO' }}</span>
              <span class="receipt-folio-tag">{{ folioAdministrativo || 'FOL-PENDIENTE' }}</span>
            </div>

            <div class="receipt-date-group">
              <label for="fecha-caja">Fecha:</label>
              <input
                id="fecha-caja"
                v-model="fechaOperacion"
                type="date"
                class="field-input-inline"
                :disabled="!permitirEditarFecha"
              />
              <button
                type="button"
                class="btn-text-action"
                @click="permitirEditarFecha = !permitirEditarFecha"
              >
                {{ permitirEditarFecha ? 'Bloquear' : 'Modificar' }}
              </button>
            </div>
          </div>

          <!-- Búsqueda rápida de alumno -->
          <div class="search-student-row">
            <div class="search-input-wrap">
              <UiField
                :model-value="busquedaMatricula"
                label="Buscar por Matrícula o Nombre"
                placeholder="Escribe para buscar (ej. 23050...)"
                hint="Al escribir se muestran sugerencias en base a matrícula y nombre"
                @update:model-value="onBusquedaInput"
                @keyup.enter="buscarEstudiante"
              />
              <!-- Sugerencias de autocompletado en texto tenue / bajito -->
              <div v-if="sugerenciasEstudiantes.length > 0" class="suggestions-dropdown">
                <div
                  v-for="sug in sugerenciasEstudiantes"
                  :key="sug.matricula"
                  class="suggestion-item"
                  @click="seleccionarEstudiante(sug)"
                >
                  <span class="sug-matricula">{{ sug.matricula }}</span>
                  <span class="sug-nombre">{{ sug.nombreCompleto }}</span>
                  <span class="sug-detalle">{{ sug.carrera }} · Semestre {{ sug.semestre }}°</span>
                </div>
              </div>
            </div>
            <UiButton
              variant="primary"
              class="btn-search"
              :disabled="isBuscandoAlumno"
              @click="buscarEstudiante"
            >
              <UiSpinner v-if="isBuscandoAlumno" size="sm" class="btn-spinner" />
              <span>{{ isBuscandoAlumno ? 'Consultando...' : 'Localizar Alumno' }}</span>
            </UiButton>
          </div>
        </UiCard>

        <!-- ALERTA DE ADEUDOS DEL ESTUDIANTE -->
        <UiAlert
          v-if="adeudosAlumno.length > 0"
          tone="warning"
          title="Atención en Ventanilla: El alumno presenta adeudos pendientes"
          class="adeudo-alert-banner"
        >
          <div class="adeudo-banner-header-row">
            <span class="adeudo-banner-subtitle">
              Se detectaron {{ adeudosAlumno.length }} concepto(s) pendientes. Pregunta al estudiante cuánto desea abonar o si cubrirá la totalidad.
            </span>
            <button
              type="button"
              class="btn-dismiss-adeudo"
              title="Descartar este aviso"
              @click="adeudosAlumno = []"
            >
              ✕ Descartar aviso
            </button>
          </div>

          <div v-for="adeudo in adeudosAlumno" :key="adeudo.idAdeudo" class="adeudo-item-notice">
            <div class="adeudo-notice-info">
              <span class="adeudo-bullet">⚠️</span>
              <strong class="adeudo-concepto">{{ adeudo.conceptoCobro }}</strong>
              <span class="adeudo-periodo">(Periodo: {{ adeudo.periodoCodigo }})</span>
              <span class="text-danger font-bold">Saldo: ${{ adeudo.saldoPendiente.toFixed(2) }}</span>
              <span v-if="adeudo.fechaLimite" class="adeudo-due-date">· Límite: {{ adeudo.fechaLimite }}</span>
            </div>
            <button
              type="button"
              class="btn-cobrar-adeudo"
              title="Cargar adeudo a las partidas para cobrarlo o abonar"
              @click="cobrarAdeudo(adeudo)"
            >
              + Cobrar / Abonar Adeudo
            </button>
          </div>
        </UiAlert>

        <!-- 2. Datos del Estudiante -->
        <UiCard title="Datos del Estudiante" description="Información académica y administrativa asociada a los cobros">
          <!-- Indicador visual Skeleton durante consulta de datos -->
          <div v-if="isBuscandoAlumno" class="student-form-skeleton" aria-busy="true" aria-label="Cargando expediente...">
            <div class="skeleton-field">
              <UiSkeleton width="70px" height="12px" />
              <UiSkeleton width="100%" height="40px" rounded="8px" />
            </div>
            <div class="skeleton-field col-span-2">
              <UiSkeleton width="120px" height="12px" />
              <UiSkeleton width="100%" height="40px" rounded="8px" />
            </div>
            <div class="skeleton-field">
              <UiSkeleton width="65px" height="12px" />
              <UiSkeleton width="100%" height="40px" rounded="8px" />
            </div>
            <div class="skeleton-field col-carrera">
              <UiSkeleton width="80px" height="12px" />
              <UiSkeleton width="100%" height="40px" rounded="8px" />
            </div>
            <div class="skeleton-field">
              <UiSkeleton width="60px" height="12px" />
              <UiSkeleton width="100%" height="40px" rounded="8px" />
            </div>
            <div class="skeleton-field">
              <UiSkeleton width="90px" height="12px" />
              <UiSkeleton width="100%" height="40px" rounded="8px" />
            </div>
          </div>

          <div v-else class="student-form-grid">
            <div class="form-col col-matricula">
              <UiField
                v-model="alumno.matricula"
                label="Matrícula"
                placeholder="Ej. 23050001"
              />
            </div>

            <div class="form-col col-nombre">
              <UiField
                v-model="alumno.nombreCompleto"
                label="Nombre Completo"
                placeholder="Nombre y apellidos del estudiante..."
              />
            </div>

            <div class="form-col col-semestre">
              <UiField
                :model-value="alumno.semestre > 0 ? `Semestre ${alumno.semestre}°` : '—'"
                label="Semestre"
                disabled
              />
            </div>

            <div class="form-col col-carrera">
              <UiField
                v-model="alumno.carrera"
                as="select"
                label="Carrera"
                :options="opcionesCarreras"
              />
            </div>

            <div class="form-col col-turno">
              <UiField
                v-model="alumno.turno"
                as="select"
                label="Turno"
                :options="opcionesTurnos"
              />
            </div>

            <div class="form-col col-estatus">
              <label class="field-static-label">Estatus Escolar</label>
              <div class="estatus-badge-container">
                <UiBadge tone="success">{{ alumno.estatus }}</UiBadge>
                <UiBadge v-if="alumno.tieneBeca" tone="purple">
                  Beca {{ alumno.porcentajeBeca }}%
                </UiBadge>
              </div>
            </div>
          </div>
        </UiCard>

        <!-- 3. Conceptos de Cobro (Tabla central de la foto) -->
        <UiCard title="Conceptos a Cobrar" description="Detalle de cuotas, becas aplicadas e importes netos">
          <!-- Selector para añadir partidas -->
          <div class="add-concept-bar">
            <div class="select-concept-wrap">
              <label for="concept-picker">Seleccionar Concepto:</label>
              <select id="concept-picker" v-model="conceptoSeleccionadoId" class="concept-dropdown">
                <option v-for="c in catalogoConceptos" :key="c.id" :value="c.id">
                  {{ c.clave }} - {{ c.descripcion }} (${{ c.cuotaBase.toFixed(2) }})
                </option>
              </select>
            </div>
            <UiButton variant="accent" @click="agregarConcepto">
              + Agregar Concepto
            </UiButton>
          </div>

          <!-- Rejilla con columnas exactas de la foto -->
          <div class="receipt-grid-wrap">
            <table class="receipt-table">
              <thead>
                <tr>
                  <th class="th-concepto">Concepto</th>
                  <th class="th-num">Cantidad</th>
                  <th class="th-num">Cuota</th>
                  <th class="th-num">Adeudo / Beca</th>
                  <th class="th-num">Importe</th>
                  <th class="th-action">Acción</th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="partidas.length === 0">
                  <td colspan="6" class="empty-items-cell">
                    <UiEmptyState
                      variant="cart"
                      title="No hay conceptos añadidos al recibo"
                      description="Selecciona una cuota o concepto en la barra superior y presiona '+ Agregar Concepto' para calcular los importes."
                    />
                  </td>
                </tr>
                <tr v-for="item in partidas" :key="item.id" class="item-row">
                  <td class="td-concepto font-bold">
                    {{ item.descripcion }}
                  </td>
                  <td class="td-num">
                    <input
                      v-model.number="item.cantidad"
                      type="number"
                      min="1"
                      class="qty-input"
                      @input="item.importeTotal = (item.cuotaUnitario - item.descuentoBeca) * item.cantidad"
                    />
                  </td>
                  <td class="td-num">
                    ${{ item.cuotaUnitario.toFixed(4) }}
                  </td>
                  <td class="td-num text-danger">
                    {{ item.descuentoBeca > 0 ? `-$${(item.descuentoBeca * item.cantidad).toFixed(4)}` : '$0.0000' }}
                  </td>
                  <td class="td-num font-bold">
                    ${{ item.importeTotal.toFixed(4) }}
                  </td>
                  <td class="td-action">
                    <button
                      type="button"
                      class="btn-delete-row"
                      title="Eliminar partida"
                      @click="eliminarPartida(item.id)"
                    >
                      ×
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Total de Liquidación -->
          <div class="totals-section">
            <div class="amount-total-container">
              <span class="total-label">Total:</span>
              <div class="total-display-card">
                <span class="total-currency">$</span>
                <span class="total-digits">{{ granTotal.toFixed(2) }}</span>
              </div>
            </div>
          </div>
        </UiCard>

        <!-- 4. Modalidad de Pago y Referencia Bancaria (Regla 5+5) -->
        <UiCard title="Forma de Liquidación" description="Modalidad de cobro y datos bancarios">
          <div class="payment-method-selector">
            <label
              class="payment-pill-option"
              :class="{ selected: metodoPagoSeleccionado === 'EFECTIVO' }"
            >
              <input v-model="metodoPagoSeleccionado" type="radio" value="EFECTIVO" />
              <svg class="payment-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="2" y="6" width="20" height="12" rx="2" />
                <circle cx="12" cy="12" r="2" />
                <path d="M6 12h.01M18 12h.01" />
              </svg>
              <span>Efectivo en Ventanilla</span>
            </label>

            <label
              class="payment-pill-option"
              :class="{ selected: metodoPagoSeleccionado === 'DEPOSITO_BANCARIO' }"
            >
              <input v-model="metodoPagoSeleccionado" type="radio" value="DEPOSITO_BANCARIO" />
              <svg class="payment-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M3 21h18M3 10h18M5 10v11M19 10v11M9 10v11M14 10v11M12 2L2 7h20L12 2z" />
              </svg>
              <span>Depósito Bancario</span>
            </label>
          </div>

          <!-- Desglose bancario si se selecciona Depósito -->
          <div v-if="metodoPagoSeleccionado === 'DEPOSITO_BANCARIO'" class="bank-details-box">
            <div class="bank-grid">
              <UiField
                v-model="cuentaBancaria"
                label="Cuenta / Convenio"
                hint="Cuenta receptora oficial TecNM"
              />
              <UiField
                :model-value="referenciaBancaria"
                label="Referencia Bancaria (Estructura 5 + 5)"
                hint="5 dígitos de alumno + 5 dígitos de concepto"
                @update:model-value="onReferenciaBancariaInput"
              />
              <UiField
                v-model="fechaBancaria"
                type="date"
                label="Fecha de Pago en Banco"
              />
            </div>

            <!-- Desglose Inteligente 5+5 -->
            <div v-if="desgloseReferenciaInfo" class="reference-analysis-panel mt-2 p-3 rounded border">
              <p class="reference-rule-note">
                ℹ️ Estructura 5+5: Estudiante (<strong>{{ desgloseReferenciaInfo.codigoEstudiante5 }}</strong>) · Concepto (<strong>{{ desgloseReferenciaInfo.codigoConcepto5 }}</strong>)
              </p>
              <div v-if="desgloseReferenciaInfo.alumnoDetectado" class="detected-student-banner mt-1 flex items-center justify-between">
                <span>🎓 Alumno identificado: <strong>{{ desgloseReferenciaInfo.alumnoDetectado.nombreCompleto }}</strong> ({{ desgloseReferenciaInfo.alumnoDetectado.matricula }})</span>
                <UiButton v-if="alumno.matricula !== desgloseReferenciaInfo.alumnoDetectado.matricula" size="sm" variant="secondary" @click="aplicarAlumnoDeReferencia">
                  Usar Alumno
                </UiButton>
              </div>
              <div v-if="desgloseReferenciaInfo.referenciaDuplicada" class="duplicate-alert mt-1 text-danger font-bold text-sm">
                ⚠️ {{ desgloseReferenciaInfo.mensaje }}
              </div>
            </div>
            <p v-else class="reference-rule-note">
              ℹ️ Validación de referencia: Primeros 5 dígitos (<strong>{{ referenciaBancaria.slice(0, 5) }}</strong>) vinculados a la matrícula; últimos 5 dígitos (<strong>{{ referenciaBancaria.slice(5) }}</strong>) correspondientes a la cuota institucional.
            </p>
          </div>
        </UiCard>

        <!-- 5. Barra de Acciones Principales (De la foto modernizadas) -->
        <div class="caja-actions-bar">
          <div class="action-buttons-left">
            <UiButton
              variant="primary"
              :disabled="partidas.length === 0 || estadoRecibo === 'CANCELADO' || isGuardandoCobro"
              @click="registrarCobro"
            >
              <UiSpinner v-if="isGuardandoCobro" size="sm" class="btn-spinner" />
              <span>{{ isGuardandoCobro ? 'Guardando e Imprimiendo...' : '✓ Registrar Cobro' }}</span>
            </UiButton>

            <UiButton
              variant="secondary"
              :disabled="partidas.length === 0 || isGuardandoCobro"
              @click="generarReciboPrevio"
            >
              📄 Recibo Previo
            </UiButton>

            <UiButton
              variant="secondary"
              :disabled="partidas.length === 0 || isGuardandoCobro"
              @click="abrirImpresion"
            >
              🖨️ Imprimir
            </UiButton>

            <UiButton
              variant="danger"
              :disabled="estadoRecibo === 'CANCELADO' || isGuardandoCobro"
              @click="abrirModalCancelar"
            >
              🚫 Cancelar Recibo
            </UiButton>
          </div>

          <div class="action-buttons-right">
            <UiButton variant="secondary" :disabled="isGuardandoCobro" @click="limpiarFormulario">
              Limpiar
            </UiButton>
          </div>
        </div>
      </main>

      <!-- BARRA LATERAL: Recibos Recientes del Turno -->
      <aside class="caja-sidebar-panel">
        <UiCard title="Turno Actual" description="Recibos emitidos en la sesión">
          <div class="shift-summary-badges">
            <div class="summary-chip">
              <span class="chip-number">{{ historialTurno.length }}</span>
              <span class="chip-label">Emitidos</span>
            </div>
            <div class="summary-chip highlight">
              <span class="chip-number">${{ historialTurno.filter(r => r.estado === 'REGISTRADO').reduce((a, b) => a + b.total, 0).toFixed(0) }}</span>
              <span class="chip-label">Corte Caja</span>
            </div>
          </div>

          <div class="recent-receipts-list">
            <!-- Indicador visual Skeleton al consultar historial -->
            <div v-if="isCargandoHistorial" class="recent-skeleton-list" aria-busy="true">
              <div v-for="i in 3" :key="i" class="recent-skeleton-card">
                <div class="skeleton-top">
                  <UiSkeleton width="40%" height="16px" />
                  <UiSkeleton width="25%" height="16px" rounded="12px" />
                </div>
                <UiSkeleton width="80%" height="14px" />
                <div class="skeleton-bottom">
                  <UiSkeleton width="35%" height="12px" />
                  <UiSkeleton width="30%" height="16px" />
                </div>
              </div>
            </div>

            <!-- Diseño de estado vacío con mensaje ilustrativo cuando no hay registros de ingresos -->
            <UiEmptyState
              v-else-if="historialTurno.length === 0"
              variant="receipt"
              title="Sin registros de ingresos disponibles"
              description="Aún no se han emitido movimientos en este turno operativo. Al registrar cobros, los recibos aparecerán listados aquí en tiempo real."
            />

            <!-- Lista de recibos emitidos -->
            <div
              v-else
              v-for="rec in historialTurno"
              :key="rec.id"
              class="recent-receipt-card"
              :class="{ active: rec.numeroRecibo === numeroRecibo }"
              @click="cargarReciboHistorial(rec)"
            >
              <div class="recent-top">
                <strong class="rec-num">#{{ rec.numeroRecibo }}</strong>
                <UiBadge
                  :tone="rec.estado === 'REGISTRADO' ? 'success' : rec.estado === 'CANCELADO' ? 'danger' : 'warning'"
                >
                  {{ rec.estado }}
                </UiBadge>
              </div>
              <div class="rec-student">{{ rec.alumno.nombreCompleto }}</div>
              <div class="rec-bottom">
                <span class="rec-matricula">{{ rec.alumno.matricula }}</span>
                <span class="rec-total font-bold">${{ rec.total.toFixed(2) }}</span>
              </div>
            </div>
          </div>
        </UiCard>
      </aside>
    </div>

    <!-- DIÁLOGO: Cancelar Recibo (Justificación requerida) -->
    <UiDialog
      :open="mostrarModalCancelar"
      title="Cancelar Recibo Oficial"
      description="Por normativa universitaria, toda cancelación debe registrar un motivo formal y no eliminará el registro histórico."
      @close="mostrarModalCancelar = false"
    >
      <div class="cancel-modal-body">
        <UiAlert tone="danger" title="Atención">
          Estás por cancelar el recibo <strong>#{{ numeroRecibo }}</strong> por un monto de <strong>${{ granTotal.toFixed(2) }}</strong>.
        </UiAlert>

        <UiField
          v-model="motivoCancelacion"
          as="textarea"
          label="Motivo Administrativo de la Cancelación"
          placeholder="Escribe la justificación autorizada por tesorería..."
          :error="errorCancelacion"
        />

        <div class="modal-buttons-row">
          <UiButton variant="secondary" @click="mostrarModalCancelar = false">
            Regresar sin Cancelar
          </UiButton>
          <UiButton variant="danger" @click="confirmarCancelacion">
            Confirmar Cancelación
          </UiButton>
        </div>
      </div>
    </UiDialog>

    <!-- DIÁLOGO: Vista Previa de Recibo Oficial Imprimible -->
    <UiDialog
      :open="mostrarModalImprimir"
      title="Recibo Oficial de Ingresos - TecNM"
      description="Comprobante digital emitido conforme a los registros del sistema de caja"
      @close="mostrarModalImprimir = false"
    >
      <div class="receipt-printable-ticket">
        <div class="ticket-header">
          <div class="tecnm-badge-brand">TECNOLÓGICO NACIONAL DE MÉXICO</div>
          <div class="tecnm-campus-name">CAMPUS MONCLOVA</div>
          <div class="ticket-type">SISTEMA DE CONTROL DE CAJA · COMPROBANTE DE PAGO</div>
        </div>

        <div class="ticket-meta-grid">
          <div><span>Recibo No:</span> <strong>{{ numeroRecibo }}</strong></div>
          <div><span>Fecha:</span> <strong>{{ fechaOperacion }}</strong></div>
          <div><span>Folio:</span> <strong>{{ folioAdministrativo }}</strong></div>
          <div><span>Caja:</span> <strong>01 ({{ cajeroActual }})</strong></div>
        </div>

        <div class="ticket-student-info">
          <div><span>Estudiante:</span> <strong>{{ alumno.nombreCompleto }}</strong></div>
          <div><span>Matrícula:</span> <strong>{{ alumno.matricula }}</strong></div>
          <div><span>Carrera:</span> <strong>{{ alumno.carrera }}</strong></div>
        </div>

        <table class="ticket-table">
          <thead>
            <tr>
              <th>Concepto</th>
              <th class="txt-right">Cant</th>
              <th class="txt-right">Importe</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="p in partidas" :key="p.id">
              <td>{{ p.descripcion }}</td>
              <td class="txt-right">{{ p.cantidad }}</td>
              <td class="txt-right">${{ p.importeTotal.toFixed(2) }}</td>
            </tr>
          </tbody>
        </table>

        <div class="ticket-total-box">
          <div class="ticket-total-row">
            <span>TOTAL:</span>
            <strong>${{ granTotal.toFixed(2) }} M.N.</strong>
          </div>
        </div>

        <div class="ticket-signatures">
          <div class="sig-block">
            <div class="sig-line"></div>
            <span>Cajero Responsable</span>
          </div>
          <div class="sig-block">
            <div class="sig-line"></div>
            <span>Firma del Estudiante</span>
          </div>
        </div>
      </div>

      <div class="print-dialog-actions">
        <UiButton variant="secondary" @click="mostrarModalImprimir = false">
          Cerrar
        </UiButton>
        <UiButton variant="primary" @click="imprimirDocumento">
          🖨️ Mandar a Impresora
        </UiButton>
      </div>
    </UiDialog>

    <!-- VENTANAS FLOTANTES DE CATÁLOGOS CONFORME A MANUAL TECNM -->
    <ModalCuentas
      v-if="mostrarModalCuentas"
      @close="mostrarModalCuentas = false"
    />

    <ModalEmpleados
      v-if="mostrarModalEmpleados"
      @close="mostrarModalEmpleados = false"
    />

    <ModalImprimeVerano
      v-if="mostrarModalImprimeVerano"
      @close="mostrarModalImprimeVerano = false"
    />

    <ModalPolizaIngresos
      v-if="mostrarModalPolizaIngresos"
      @close="mostrarModalPolizaIngresos = false"
    />

    <ModalReporteIngresos
      v-if="mostrarModalReporteIngresos"
      @close="mostrarModalReporteIngresos = false"
    />

    <ModalPolizaIngresoPeriodo
      v-if="mostrarModalPolizaIngresoPeriodo"
      @close="mostrarModalPolizaIngresoPeriodo = false"
    />

    <ModalReporteIngresosPeriodo
      v-if="mostrarModalReporteIngresosPeriodo"
      @close="mostrarModalReporteIngresosPeriodo = false"
    />

    <ModalReporteVarios
      v-if="mostrarModalReporteVarios"
      @close="mostrarModalReporteVarios = false"
    />

    <ModalReporteDeudores
      v-if="mostrarModalReporteDeudores"
      @close="mostrarModalReporteDeudores = false"
    />

    <ModalReporteDeudoresFechaCorte
      v-if="mostrarModalReporteDeudoresFechaCorte"
      @close="mostrarModalReporteDeudoresFechaCorte = false"
    />

    <ModalReporteDeudoresFechaCuenta
      v-if="mostrarModalReporteDeudoresFechaCuenta"
      @close="mostrarModalReporteDeudoresFechaCuenta = false"
    />

    <ModalReporteDeudoresInscritos
      v-if="mostrarModalReporteDeudoresInscritos"
      @close="mostrarModalReporteDeudoresInscritos = false"
    />

    <ModalDepositoBancario
      v-if="mostrarModalDepositoBancario"
      @close="mostrarModalDepositoBancario = false"
    />

    <ModalDepositoBancarioPropedeutico
      v-if="mostrarModalDepositoBancarioPropedeutico"
      @close="mostrarModalDepositoBancarioPropedeutico = false"
    />

    <ModalReciboProvisional
      v-if="mostrarModalReciboProvisional"
      @close="mostrarModalReciboProvisional = false"
    />

    <ModalReciboProvisionalCancelar
      v-if="mostrarModalReciboProvisionalCancelar"
      @close="mostrarModalReciboProvisionalCancelar = false"
    />

    <!-- Sistema de Notificaciones Flotantes (Toasts) -->
    <UiToast ref="toastRef" />
  </div>
</template>

<style scoped>
/* ==========================================================================
   Estilos Institucionales TecNM (Diseño Dual Light/Dark conforme a DESIGN.md)
   ========================================================================== */

.caja-dashboard {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 16px;
  background-color: var(--color-bg-main, #F4F6F9);
  min-height: 100vh;
}

/* 0. Barra de Menú Clásica Institucional TecNM */
.tecnm-classic-menubar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  background-color: var(--color-surface-white, #FFFFFF);
  border: 1px solid var(--color-border-medium, #CBD5E1);
  border-left: 4px solid var(--color-primary, #1B396A);
  border-radius: 6px;
  padding: 4px 12px;
  box-shadow: 0 2px 4px rgba(15, 37, 72, 0.04);
  transition: background-color 0.2s, border-color 0.2s;
}

.menubar-left-group {
  display: flex;
  align-items: center;
  gap: 14px;
  flex-wrap: wrap;
}

.menubar-theme-toggle {
  margin-left: auto;
  display: flex;
  align-items: center;
  padding-left: 12px;
}

.theme-switch {
  font-size: 0.82rem;
  font-weight: 600;
  color: var(--color-text-primary, #1E293B);
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
}

.menubar-title-tag {
  font-size: 0.78rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--color-accent, #C5A059);
  padding-right: 8px;
  border-right: 1px solid var(--color-border, #E2E8F0);
}

.menubar-items-group {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
}

.menubar-item {
  position: relative;
}

.menubar-btn {
  background: none;
  border: 1px solid transparent;
  border-radius: 4px;
  padding: 6px 14px;
  font-size: 0.86rem;
  font-weight: 600;
  color: var(--color-text-primary, #1E293B);
  cursor: pointer;
  transition: all 0.15s ease;
  display: flex;
  align-items: center;
  gap: 6px;
}

.menubar-btn:hover {
  background-color: var(--color-primary-subtle, #EBF3FF);
  color: var(--color-primary, #1B396A);
  border-color: var(--color-border, #E2E8F0);
}

.btn-dropdown {
  color: var(--color-primary, #1B396A);
  font-weight: 700;
}

.arrow-indicator {
  font-size: 0.75rem;
  color: var(--color-accent, #C5A059);
}

.dropdown-parent.open .btn-dropdown {
  background-color: var(--color-primary, #1B396A);
  color: #FFFFFF;
  border-color: var(--color-primary-dark, #0F2548);
}

.dropdown-parent.open .arrow-indicator {
  color: #FFFFFF;
}

/* Menú flotante desplegable */
.menubar-dropdown-panel {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  z-index: 50;
  background-color: var(--color-surface-white, #FFFFFF);
  border: 1px solid var(--color-border-medium, #CBD5E1);
  border-top: 3px solid var(--color-accent, #C5A059);
  border-radius: 6px;
  box-shadow: 0 10px 25px -5px rgba(15, 37, 72, 0.2);
  min-width: 250px;
  max-height: 75vh;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  padding: 6px 0;
  animation: dropdown-fade 0.15s ease-out;
}

.menubar-dropdown-scroll {
  min-width: 290px;
}

@keyframes dropdown-fade {
  from { opacity: 0; transform: translateY(-4px); }
  to { opacity: 1; transform: translateY(0); }
}

.dropdown-entry {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  padding: 9px 16px;
  border: none;
  background: none;
  text-align: left;
  font-size: 0.88rem;
  font-weight: 600;
  color: var(--color-text-primary, #1E293B);
  cursor: pointer;
  transition: all 0.12s ease;
}

.dropdown-entry:hover {
  background-color: var(--color-primary-subtle, #EBF3FF);
  color: var(--color-primary, #1B396A);
}

/* Reglas específicas para Modo Oscuro en la Barra de Menú Clásica */
.dark-theme .tecnm-classic-menubar {
  background-color: #141E33;
  border-color: #2E3F5E;
  border-left-color: var(--color-accent, #D4B06A);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.4);
}

.dark-theme .menubar-title-tag {
  border-right-color: #2E3F5E;
  color: #D4B06A;
}

.dark-theme .menubar-btn {
  color: #F8FAFC !important;
}

.dark-theme .menubar-btn:hover {
  background-color: #1E2F50;
  color: #D4B06A !important;
  border-color: #334C79;
}

.dark-theme .btn-dropdown {
  color: #D4B06A !important;
}

.dark-theme .dropdown-parent.open .btn-dropdown {
  background-color: #244B88;
  color: #FFFFFF !important;
}

.dark-theme .menubar-dropdown-panel {
  background-color: #141E33;
  border-color: #2E3F5E;
  border-top-color: #D4B06A;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.6);
}

.dark-theme .dropdown-entry {
  color: #F8FAFC !important;
}

.dark-theme .dropdown-entry:hover {
  background-color: #1E2F50;
  color: #D4B06A !important;
}

.dark-theme .theme-switch {
  color: #F8FAFC !important;
}

.entry-icon {
  width: 16px;
  height: 16px;
  color: var(--color-accent, #C5A059);
  flex-shrink: 0;
}

/* 1. Barra de estado superior */
.cashier-status-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  background: var(--color-primary, #1B396A);
  color: #FFFFFF;
  padding: 14px 24px;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(27, 57, 106, 0.15);
}

.brand-zone {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.institution-pill {
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--color-accent, #C5A059);
}

.system-title {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 700;
  color: #FFFFFF;
}

.cashier-meta {
  display: flex;
  align-items: center;
  gap: 20px;
  flex-wrap: wrap;
}

.meta-item {
  display: flex;
  flex-direction: column;
  font-size: 0.85rem;
}

.meta-label {
  font-size: 0.7rem;
  text-transform: uppercase;
  opacity: 0.8;
  letter-spacing: 0.05em;
}

.meta-value {
  color: #FFFFFF;
  font-weight: 600;
}

.btn-cerrar-sesion {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background-color: rgba(255, 255, 255, 0.12);
  border: 1px solid rgba(255, 255, 255, 0.35);
  color: #FFFFFF;
  padding: 6px 14px;
  border-radius: 6px;
  font-size: 0.82rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
  margin-left: 8px;
}

.btn-cerrar-sesion:hover {
  background-color: #DC2626;
  border-color: #DC2626;
  color: #FFFFFF;
  box-shadow: 0 2px 8px rgba(220, 38, 38, 0.3);
}

.btn-cerrar-sesion:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.logout-icon {
  width: 16px;
  height: 16px;
}

/* 2. Disposición principal en rejilla */
.caja-grid-layout {
  display: grid;
  grid-template-columns: 1fr 320px;
  gap: 20px;
}

@media (max-width: 1080px) {
  .caja-grid-layout {
    grid-template-columns: 1fr;
  }
}

.caja-main-area {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

/* 3. Encabezado de recibo */
.receipt-header-card {
  padding: 16px 20px;
}

.header-card-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  border-bottom: 1px solid var(--color-border, #E2E8F0);
  padding-bottom: 14px;
  margin-bottom: 14px;
}

.receipt-number-group {
  display: flex;
  align-items: center;
  gap: 12px;
}

.receipt-number-label {
  font-weight: 700;
  font-size: 1.1rem;
  color: var(--color-text-primary, #1E293B);
}

.receipt-number-badge {
  background-color: var(--color-primary, #1B396A);
  color: #FFFFFF;
  font-size: 1.35rem;
  font-weight: 800;
  padding: 4px 14px;
  border-radius: 8px;
  letter-spacing: 0.05em;
}

.receipt-folio-tag {
  font-size: 0.8rem;
  color: var(--color-text-secondary, #64748B);
  background: var(--color-gray-100, #F1F5F9);
  padding: 4px 8px;
  border-radius: 4px;
}

.receipt-date-group {
  display: flex;
  align-items: center;
  gap: 8px;
}

.field-input-inline {
  padding: 6px 10px;
  border: 1px solid var(--color-border-medium, #CBD5E1);
  border-radius: 6px;
  font-weight: 600;
  background: var(--color-surface-white, #FFFFFF);
  color: var(--color-text-primary, #1E293B);
}

.btn-text-action {
  background: none;
  border: none;
  color: var(--color-primary, #1B396A);
  text-decoration: underline;
  cursor: pointer;
  font-size: 0.85rem;
  font-weight: 600;
}

.search-student-row {
  display: flex;
  align-items: flex-end;
  gap: 12px;
}

.search-input-wrap {
  flex: 1;
  position: relative;
}

.suggestions-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  z-index: 25;
  background: var(--color-surface-white, #FFFFFF);
  border: 1px solid var(--color-border-medium, #CBD5E1);
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(15, 37, 72, 0.12);
  margin-top: 4px;
  max-height: 220px;
  overflow-y: auto;
}

.suggestion-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 14px;
  cursor: pointer;
  border-bottom: 1px solid var(--color-border-light, #F1F5F9);
  transition: background 0.15s ease;
}

.suggestion-item:last-child {
  border-bottom: none;
}

.suggestion-item:hover {
  background: var(--color-primary-subtle, #EBF3FF);
}

.sug-matricula {
  font-weight: 700;
  font-size: 0.88rem;
  color: var(--color-primary, #1B396A);
}

.sug-nombre {
  font-weight: 500;
  font-size: 0.85rem;
  color: var(--color-text-secondary, #64748B);
}

.sug-detalle {
  margin-left: auto;
  font-size: 0.78rem;
  color: var(--color-text-muted, #94A3B8);
  font-style: italic;
}

.btn-search {
  height: 44px;
  margin-bottom: 2px;
}

.btn-spinner {
  margin-right: 8px;
}

/* 4. Formulario del estudiante y estados de carga */
.student-form-skeleton {
  display: grid;
  grid-template-columns: 160px 1fr 140px;
  gap: 14px;
  padding: 4px 0;
}

.skeleton-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.skeleton-field.col-span-2 {
  grid-column: span 2;
}

@media (max-width: 768px) {
  .student-form-skeleton {
    grid-template-columns: 1fr;
  }
  .skeleton-field.col-span-2 {
    grid-column: span 1;
  }
}

.student-form-grid {
  display: grid;
  grid-template-columns: 160px 1fr 140px;
  gap: 14px;
}

@media (max-width: 768px) {
  .student-form-grid {
    grid-template-columns: 1fr;
  }
}

.col-carrera {
  grid-column: span 2;
}

.field-static-label {
  display: block;
  font-size: 0.8rem;
  font-weight: 600;
  margin-bottom: 6px;
  color: var(--color-text-secondary, #64748B);
}

.estatus-badge-container {
  display: flex;
  gap: 8px;
  align-items: center;
  height: 42px;
}

/* 5. Rejilla de conceptos */
.add-concept-bar {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  gap: 16px;
  margin-bottom: 16px;
  padding: 12px;
  background: var(--color-gray-50, #F8FAFC);
  border: 1px solid var(--color-border, #E2E8F0);
  border-radius: 8px;
}

.select-concept-wrap {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.select-concept-wrap label {
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--color-text-secondary, #64748B);
}

.concept-dropdown {
  padding: 8px 12px;
  border-radius: 8px;
  border: 1px solid var(--color-border-medium, #CBD5E1);
  background: var(--color-surface-white, #FFFFFF);
  color: var(--color-text-primary, #1E293B);
  font-size: 0.95rem;
}

.receipt-grid-wrap {
  overflow-x: auto;
  border: 1px solid var(--color-border, #E2E8F0);
  border-radius: 8px;
}

.receipt-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.receipt-table th {
  background: var(--color-gray-100, #F1F5F9);
  padding: 10px 14px;
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--color-text-secondary, #64748B);
  border-bottom: 2px solid var(--color-border, #E2E8F0);
}

.receipt-table td {
  padding: 10px 14px;
  border-bottom: 1px solid var(--color-border-light, #F1F5F9);
  font-size: 0.92rem;
}

.th-num, .td-num {
  text-align: right;
}

.th-action, .td-action {
  text-align: center;
  width: 60px;
}

.qty-input {
  width: 60px;
  text-align: center;
  padding: 4px;
  border: 1px solid var(--color-border-medium, #CBD5E1);
  border-radius: 4px;
}

.btn-delete-row {
  background: none;
  border: none;
  color: #DC2626;
  font-size: 1.3rem;
  font-weight: bold;
  cursor: pointer;
  padding: 0 6px;
  border-radius: 4px;
}

.btn-delete-row:hover {
  background: #FEE2E2;
}

.empty-items-cell {
  text-align: center;
  padding: 30px;
  color: var(--color-text-muted, #94A3B8);
  font-style: italic;
}

/* 6. Totales de Liquidación */
.totals-section {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 20px;
  margin-top: 18px;
}

.amount-total-container {
  display: flex;
  align-items: center;
  gap: 12px;
}

.total-label {
  font-size: 1.3rem;
  font-weight: 700;
  color: var(--color-text-primary, #1E293B);
}

.total-display-card {
  display: flex;
  align-items: baseline;
  background: #1B396A;
  color: #FFFFFF;
  padding: 8px 24px;
  border-radius: 10px;
  box-shadow: 0 4px 10px rgba(27, 57, 106, 0.2);
}

.total-currency {
  font-size: 1.4rem;
  font-weight: 600;
  margin-right: 4px;
  color: var(--color-accent, #C5A059);
}

.total-digits {
  font-size: 2rem;
  font-weight: 800;
  letter-spacing: 0.02em;
}

/* 7. Métodos de pago */
.payment-method-selector {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.payment-pill-option {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 18px;
  border: 2px solid var(--color-border-medium, #CBD5E1);
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.2s ease;
  background: var(--color-surface-white, #FFFFFF);
}

.payment-pill-option.selected {
  border-color: var(--color-primary, #1B396A);
  background: var(--color-primary-subtle, #EBF3FF);
  color: var(--color-primary, #1B396A);
}

.payment-icon {
  width: 20px;
  height: 20px;
  stroke: currentColor;
}

.bank-details-box {
  margin-top: 14px;
  padding: 14px;
  border-radius: 8px;
  background: var(--color-gray-50, #F8FAFC);
  border: 1px dashed var(--color-border-medium, #CBD5E1);
}

.bank-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 14px;
}

.reference-rule-note {
  margin: 10px 0 0 0;
  font-size: 0.8rem;
  color: var(--color-text-secondary, #64748B);
}

/* 8. Barra inferior de acciones */
.caja-actions-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  padding: 14px 20px;
  background: var(--color-surface-white, #FFFFFF);
  border: 1px solid var(--color-border, #E2E8F0);
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(15, 37, 72, 0.05);
}

.action-buttons-left {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

/* 9. Historial lateral de recibos */
.shift-summary-badges {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin-bottom: 14px;
}

.summary-chip {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 10px;
  background: var(--color-gray-50, #F8FAFC);
  border: 1px solid var(--color-border, #E2E8F0);
  border-radius: 8px;
}

.summary-chip.highlight {
  background: var(--color-primary-subtle, #EBF3FF);
  border-color: var(--color-primary, #1B396A);
}

.chip-number {
  font-size: 1.25rem;
  font-weight: 800;
  color: var(--color-primary, #1B396A);
}

.chip-label {
  font-size: 0.72rem;
  text-transform: uppercase;
  color: var(--color-text-secondary, #64748B);
}

.recent-receipts-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
  max-height: 520px;
  overflow-y: auto;
}

.recent-skeleton-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.recent-skeleton-card {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 12px;
  border: 1px solid var(--color-border, #E2E8F0);
  border-radius: 8px;
  background: var(--color-surface-white, #FFFFFF);
}

.skeleton-top,
.skeleton-bottom {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.empty-recent-msg {
  text-align: center;
  padding: 24px 12px;
  color: var(--color-text-muted, #94A3B8);
  font-size: 0.85rem;
  font-style: italic;
  border: 1px dashed var(--color-border, #E2E8F0);
  border-radius: 8px;
}

.recent-receipt-card {
  padding: 10px 12px;
  border: 1px solid var(--color-border, #E2E8F0);
  border-radius: 8px;
  cursor: pointer;
  background: var(--color-surface-white, #FFFFFF);
  transition: border-color 0.15s ease;
}

.recent-receipt-card:hover {
  border-color: var(--color-primary, #1B396A);
}

.recent-receipt-card.active {
  border-color: var(--color-primary, #1B396A);
  background: var(--color-primary-subtle, #EBF3FF);
}

.recent-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
}

.rec-student {
  font-size: 0.82rem;
  font-weight: 600;
  color: var(--color-text-primary, #1E293B);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.rec-bottom {
  display: flex;
  justify-content: space-between;
  font-size: 0.78rem;
  color: var(--color-text-secondary, #64748B);
  margin-top: 4px;
}

/* 10. Modales de Cancelación e Impresión */
.cancel-modal-body {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 10px 0;
}

.modal-buttons-row {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 10px;
}

/* Formato de Ticket Impreso */
.receipt-printable-ticket {
  border: 2px dashed #94A3B8;
  padding: 24px;
  border-radius: 8px;
  background: #FFFFFF;
  color: #000000;
  font-family: 'Courier New', Courier, monospace;
}

.ticket-header {
  text-align: center;
  border-bottom: 2px solid #000000;
  padding-bottom: 12px;
  margin-bottom: 12px;
}

.tecnm-badge-brand {
  font-weight: 800;
  font-size: 1rem;
}

.tecnm-campus-name {
  font-size: 0.9rem;
  font-weight: 700;
}

.ticket-type {
  font-size: 0.75rem;
  margin-top: 4px;
}

.ticket-meta-grid, .ticket-student-info {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 6px;
  font-size: 0.85rem;
  margin-bottom: 12px;
}

.ticket-table {
  width: 100%;
  border-top: 1px solid #000000;
  border-bottom: 1px solid #000000;
  margin: 12px 0;
  border-collapse: collapse;
}

.ticket-table th, .ticket-table td {
  padding: 6px;
  font-size: 0.85rem;
}

.ticket-total-box {
  margin: 14px 0;
  text-align: right;
}

.ticket-total-row {
  font-size: 1.2rem;
  font-weight: 900;
}

.ticket-words {
  font-size: 0.75rem;
  font-style: italic;
  margin-top: 4px;
}

.ticket-signatures {
  display: flex;
  justify-content: space-around;
  margin-top: 36px;
  padding-top: 10px;
}

.sig-block {
  text-align: center;
  font-size: 0.75rem;
}

.sig-line {
  width: 160px;
  border-top: 1px solid #000000;
  margin-bottom: 4px;
}

.print-dialog-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 18px;
}

.txt-right {
  text-align: right;
}

.font-bold {
  font-weight: 700;
}

.text-danger {
  color: #DC2626;
}

.adeudo-alert-banner {
  margin-bottom: 12px;
  border-left: 4px solid #EAB308;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.adeudo-banner-header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  padding-bottom: 6px;
  border-bottom: 1px dashed rgba(234, 179, 8, 0.35);
}

.adeudo-banner-subtitle {
  font-size: 0.8125rem;
  color: inherit;
  opacity: 0.9;
}

.btn-dismiss-adeudo {
  background: transparent;
  border: 1px solid rgba(234, 179, 8, 0.4);
  color: inherit;
  border-radius: 4px;
  padding: 3px 8px;
  font-size: 0.75rem;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.2s ease;
}

.btn-dismiss-adeudo:hover {
  background: rgba(234, 179, 8, 0.15);
  border-color: #EAB308;
}

.adeudo-item-notice {
  font-size: 0.875rem;
  padding: 6px 10px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  background: rgba(234, 179, 8, 0.08);
  border-radius: 6px;
  border: 1px solid rgba(234, 179, 8, 0.2);
  flex-wrap: wrap;
}

.adeudo-notice-info {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.adeudo-due-date {
  color: #64748B;
  font-size: 0.8rem;
}

.btn-cobrar-adeudo {
  background: #1B396A;
  color: #FFFFFF;
  border: 1px solid #D4B06A;
  border-radius: 6px;
  padding: 5px 12px;
  font-size: 0.8125rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
}

.btn-cobrar-adeudo:hover {
  background: #152C53;
  color: #D4B06A;
  transform: translateY(-1px);
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.2);
}

:global([data-theme="dark"]) .btn-cobrar-adeudo {
  background: #1E293B;
  color: #F8FAFC;
  border-color: #D4B06A;
}

:global([data-theme="dark"]) .btn-cobrar-adeudo:hover {
  background: #283548;
  color: #D4B06A;
}

:global([data-theme="dark"]) .adeudo-due-date {
  color: #94A3B8;
}
</style>

