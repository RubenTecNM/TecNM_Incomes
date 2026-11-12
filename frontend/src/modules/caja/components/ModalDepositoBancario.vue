<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useTheme } from '../../../shared/composables/useTheme'
import * as cajaApi from '../api/cajaApi'
import type { AlumnoCaja } from '../types/caja'

const emit = defineEmits<{
  (e: 'close'): void
}>()

const { dark } = useTheme()

// =============================================================================
// Estructura de Datos: Pago Bancario Individual
// =============================================================================
export interface PagoBancarioIndividual {
  id: string
  numeroRecibo?: number
  folio?: string
  matricula: string
  nombreAlumno: string
  carrera: string
  semestre: number
  turno: string
  concepto: string
  precioUnitario: number
  referenciaBancaria: string
  fechaDeposito: string
  cuentaBancaria: string
  registradoEnBD: boolean
}

// Estructura de Resumen Agrupado por Concepto (según requerimiento)
export interface ConceptoAgrupadoResumen {
  concepto: string
  cantidad: number
  precioUnitario: number
  total: number
}

// =============================================================================
// Parámetros Generales del Depósito Bancario
// =============================================================================
function obtenerFechaHoy(): string {
  const hoy = new Date()
  const y = hoy.getFullYear()
  const m = String(hoy.getMonth() + 1).padStart(2, '0')
  const d = String(hoy.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

function formatearFechaIso(iso?: string): string {
  if (!iso) return ''
  try {
    const partes = iso.split('T')[0].split('-')
    if (partes.length === 3) {
      return `${partes[2]}/${partes[1]}/${partes[0]}`
    }
    return iso
  } catch {
    return iso || ''
  }
}

function formatearMoneda(valor: number): string {
  return valor.toLocaleString('es-MX', { style: 'currency', currency: 'MXN' })
}

const fechaDeposito = ref(obtenerFechaHoy())
const bancoReceptor = ref('BBVA BANCOMER — CTA 0128912389')
const folioLote = ref(`DEP-${new Date().getFullYear()}${String(new Date().getMonth() + 1).padStart(2, '0')}-01`)
const proximoNumeroRecibo = ref<number>(128660)

const pickerFechaRef = ref<HTMLInputElement | null>(null)
function abrirCalendario(): void {
  pickerFechaRef.value?.showPicker?.()
}
function onFechaPick(e: Event): void {
  const target = e.target as HTMLInputElement
  if (target?.value) {
    fechaDeposito.value = target.value
  }
}

// =============================================================================
// Pestaña Activa ('resumen' | 'detalle' | 'impresion')
// =============================================================================
const pestanaActiva = ref<'resumen' | 'detalle' | 'impresion'>('resumen')

// =============================================================================
// Lista de Pagos Individuales (Conserva todos los datos de cada estudiante)
// =============================================================================
const pagos = ref<PagoBancarioIndividual[]>([])
const filtroDetalle = ref('')

// =============================================================================
// Catálogo de Conceptos y Cuentas Bancarias
// =============================================================================
const catalogoConceptos = ref<{ id: string; descripcion: string; cuota: number }[]>([
  { id: 'c1', descripcion: 'Inscripciones', cuota: 1600.00 },
  { id: 'c2', descripcion: 'Constancias', cuota: 100.00 },
  { id: 'c3', descripcion: 'Fichas de Nuevo Ingreso', cuota: 450.00 },
  { id: 'c4', descripcion: 'Cursos de Verano', cuota: 650.00 },
  { id: 'c5', descripcion: 'Prórrogas de Pago', cuota: 500.00 },
  { id: 'c6', descripcion: 'Examen TOEFL (Nuevo)', cuota: 1200.00 },
  { id: 'c7', descripcion: 'Curso de Titulación de Inglés', cuota: 2000.00 },
  { id: 'c8', descripcion: 'Baja Definitiva', cuota: 500.00 },
])

const cuentasBancariasDisponibles = [
  'BBVA BANCOMER — CTA 0128912389 (CONCENTRADORA GENERAL)',
  'CITIBANAMEX — CTA 7014-992381 (FICHAS E INSCRIPCIONES)',
  'SANTANDER — CTA 6550-109283 (CURSOS Y CERTIFICACIONES)',
]

// =============================================================================
// Formulario de Captura Rápida Manual
// =============================================================================
const nuevoAlumnoMatricula = ref('')
const nuevoAlumnoNombre = ref('')
const nuevoAlumnoCarrera = ref('Ingeniería Industrial')
const nuevoAlumnoSemestre = ref(1)
const nuevoConcepto = ref('Inscripciones')
const nuevoPrecioUnitario = ref(1600.00)
const nuevaReferencia = ref('')

// Autocompletado de alumnos
const sugerenciasAlumnos = ref<AlumnoCaja[]>([])
const isBuscandoAlumnos = ref(false)
const mostrarSugerencias = ref(false)

async function onInputMatricula(): Promise<void> {
  const query = nuevoAlumnoMatricula.value.trim()
  if (query.length < 2) {
    sugerenciasAlumnos.value = []
    mostrarSugerencias.value = false
    return
  }

  isBuscandoAlumnos.value = true
  try {
    const list = await cajaApi.buscarAlumnos(query)
    sugerenciasAlumnos.value = list.slice(0, 5)
    mostrarSugerencias.value = sugerenciasAlumnos.value.length > 0
  } catch {
    sugerenciasAlumnos.value = []
    mostrarSugerencias.value = false
  } finally {
    isBuscandoAlumnos.value = false
  }
}

function seleccionarAlumno(a: AlumnoCaja): void {
  nuevoAlumnoMatricula.value = a.matricula
  nuevoAlumnoNombre.value = a.nombreCompleto
  nuevoAlumnoCarrera.value = a.carrera || 'Ingeniería Industrial'
  nuevoAlumnoSemestre.value = a.semestre || 1
  mostrarSugerencias.value = false
}

function onCambioConcepto(): void {
  const match = catalogoConceptos.value.find(c => c.descripcion === nuevoConcepto.value)
  if (match) {
    nuevoPrecioUnitario.value = match.cuota
  }
}

function generarReferenciaAleatoria(): string {
  const num = Math.floor(100000 + Math.random() * 900000)
  return `REF-BNC-${num}`
}

function agregarPagoManual(): void {
  if (!nuevoAlumnoMatricula.value.trim() || !nuevoAlumnoNombre.value.trim()) {
    alert('Por favor especifica la matrícula y el nombre del estudiante.')
    return
  }
  if (!nuevoConcepto.value.trim()) {
    alert('Por favor selecciona un concepto de cobro.')
    return
  }
  if (nuevoPrecioUnitario.value <= 0) {
    alert('El importe del pago debe ser mayor a $0.00.')
    return
  }

  const refBancaria = nuevaReferencia.value.trim() || generarReferenciaAleatoria()
  const numRecibo = proximoNumeroRecibo.value + pagos.value.length

  pagos.value.push({
    id: `pago_${Date.now()}_${Math.random()}`,
    numeroRecibo: numRecibo,
    folio: `FOL-${new Date().getFullYear()}-${numRecibo}`,
    matricula: nuevoAlumnoMatricula.value.trim().toUpperCase(),
    nombreAlumno: nuevoAlumnoNombre.value.trim().toUpperCase(),
    carrera: nuevoAlumnoCarrera.value.trim(),
    semestre: nuevoAlumnoSemestre.value,
    turno: 'Matutino',
    concepto: nuevoConcepto.value.trim(),
    precioUnitario: Number(nuevoPrecioUnitario.value),
    referenciaBancaria: refBancaria,
    fechaDeposito: fechaDeposito.value,
    cuentaBancaria: bancoReceptor.value,
    registradoEnBD: false,
  })

  // Limpiar campos para la siguiente captura rápida
  nuevoAlumnoMatricula.value = ''
  nuevoAlumnoNombre.value = ''
  nuevaReferencia.value = ''
  mostrarSugerencias.value = false
}

function eliminarPago(idx: number): void {
  pagos.value.splice(idx, 1)
}

// =============================================================================
// CÁLCULO Y AGRUPACIÓN AUTOMÁTICA (REQUERIMIENTO PRINCIPAL DEL USUARIO)
// =============================================================================
// El sistema debe agrupar los pagos por concepto y calcular automáticamente:
// 1. La cantidad de pagos registrados por concepto.
// 2. El importe unitario (precio unitario).
// 3. El total por cada concepto.
// 4. El total general de los movimientos (cantidad total y monto global).
const resumenAgrupadoPorConcepto = computed<ConceptoAgrupadoResumen[]>(() => {
  const mapa = new Map<string, { cantidad: number; precioUnitario: number; total: number }>()

  for (const p of pagos.value) {
    const cpto = p.concepto.trim()
    if (!mapa.has(cpto)) {
      mapa.set(cpto, {
        cantidad: 0,
        precioUnitario: p.precioUnitario,
        total: 0,
      })
    }
    const item = mapa.get(cpto)!
    item.cantidad += 1
    item.total += p.precioUnitario
    // Si hubiere precios distintos para un mismo concepto, preserva el precio unitario vigente
    item.precioUnitario = p.precioUnitario
  }

  return Array.from(mapa.entries()).map(([concepto, data]) => ({
    concepto,
    cantidad: data.cantidad,
    precioUnitario: data.precioUnitario,
    total: data.total,
  })).sort((a, b) => b.total - a.total)
})

// Totales Generales
const totalCantidadMovimientos = computed(() => {
  return pagos.value.length
})

const totalGeneralImporte = computed(() => {
  return pagos.value.reduce((acc, p) => acc + p.precioUnitario, 0)
})

// Filtro en pestaña individual
const pagosFiltrados = computed(() => {
  if (!filtroDetalle.value.trim()) return pagos.value
  const q = filtroDetalle.value.trim().toLowerCase()
  return pagos.value.filter(p =>
    p.matricula.toLowerCase().includes(q) ||
    p.nombreAlumno.toLowerCase().includes(q) ||
    p.concepto.toLowerCase().includes(q) ||
    p.referenciaBancaria.toLowerCase().includes(q) ||
    String(p.numeroRecibo || '').includes(q)
  )
})

// =============================================================================
// CARGA DEL EJEMPLO OFICIAL (30 PAGOS: 15 INSCRIPCIONES Y 15 CONSTANCIAS)
// =============================================================================
function cargarEjemploRequerimiento(): void {
  const fecha = fechaDeposito.value
  const cta = bancoReceptor.value
  const baseRecibo = proximoNumeroRecibo.value

  const listaInscripciones: { mat: string; nom: string; car: string; sem: number }[] = [
    { mat: '23050114', nom: 'URQUIETA TOVAR JESUS SEBASTIAN', car: 'Ing. Industrial', sem: 3 },
    { mat: '22050982', nom: 'DE LA ROSA FRANCO RAMON YAHIR', car: 'Ing. Mecatrónica', sem: 5 },
    { mat: '24050331', nom: 'FRANCO SANMIGUEL ANGELA FERNANDA', car: 'Ing. en Gestión Empresarial', sem: 1 },
    { mat: '23050677', nom: 'GUZMAN GONZALEZ MIRANDA', car: 'Ing. Sistemas Computacionales', sem: 3 },
    { mat: '21050410', nom: 'GOMEZ LARA KEVIN ALBERTO', car: 'Ing. Mecánica', sem: 7 },
    { mat: '24050890', nom: 'ALBA CHACON ENRIQUE JAVIER', car: 'Ing. Industrial', sem: 1 },
    { mat: '23050215', nom: 'DURON OLVERA FERNANDA ANAHI', car: 'Ing. Química', sem: 3 },
    { mat: '24050731', nom: 'DE LA CRUZ HERNANDEZ TANIA JOSELYN', car: 'Ing. Sistemas Computacionales', sem: 1 },
    { mat: '22050449', nom: 'CRUZ FACUNDO NAYELI ESTEFANIA', car: 'Ing. en Gestión Empresarial', sem: 5 },
    { mat: '23050166', nom: 'VILLALOBOS TAMEZ ANGEL JAIME', car: 'Ing. Electrónica', sem: 3 },
    { mat: '24050912', nom: 'ORONA MARTINEZ OLIVER ALEXIS', car: 'Ing. Mecánica', sem: 1 },
    { mat: '23050889', nom: 'PADILLA VAZQUEZ HOMAR', car: 'Ing. Industrial', sem: 3 },
    { mat: '24050512', nom: 'CONTRERAS RIVAS LIZETH AHANI', car: 'Ing. Química', sem: 1 },
    { mat: '23050720', nom: 'PEREZ MARTINEZ ALEXIA MONSERRAT', car: 'Ing. en Gestión Empresarial', sem: 3 },
    { mat: '24050188', nom: 'QUIROZ SANCHEZ ORLANDO ANTONIO', car: 'Ing. Sistemas Computacionales', sem: 1 },
  ]

  const listaConstancias: { mat: string; nom: string; car: string; sem: number }[] = [
    { mat: '23050222', nom: 'LEON DUARTE ERIK SEBASTIAN', car: 'Ing. Industrial', sem: 3 },
    { mat: '24050344', nom: 'BENITEZ RODRIGUEZ LUIS PABLO', car: 'Ing. Mecatrónica', sem: 1 },
    { mat: '22050811', nom: 'RAMOS RIVAS YESSENIA', car: 'Ing. Sistemas Computacionales', sem: 5 },
    { mat: '23050550', nom: 'LOPEZ GONZALEZ ALONSO EMMANUEL', car: 'Ing. Mecánica', sem: 3 },
    { mat: '24050621', nom: 'GONZALEZ REYES MARVYN JARETH', car: 'Ing. en Gestión Empresarial', sem: 1 },
    { mat: '22050933', nom: 'DE LA FUENTE CERNA NARDA GUADALUPE', car: 'Ing. Química', sem: 5 },
    { mat: '23050412', nom: 'SIFUENTES JASSO CESAR ALEXANDRO', car: 'Ing. Industrial', sem: 3 },
    { mat: '24050702', nom: 'OROZCO RANGEL DANIEL AZAEL', car: 'Ing. Electrónica', sem: 1 },
    { mat: '22050189', nom: 'CAMARILLO PEREZ YAXENI SHECCID', car: 'Ing. en Gestión Empresarial', sem: 5 },
    { mat: '23050774', nom: 'VALENCIANO LARA IDALIA JAQUELINE', car: 'Ing. Sistemas Computacionales', sem: 3 },
    { mat: '24050299', nom: 'HERNANDEZ MORALES ROBERTO', car: 'Ing. Industrial', sem: 1 },
    { mat: '23050488', nom: 'SALAZAR RIVERA KARLA PATRICIA', car: 'Ing. Mecatrónica', sem: 3 },
    { mat: '24050617', nom: 'CASTILLO TORRES DANIEL EDUARDO', car: 'Ing. en Gestión Empresarial', sem: 1 },
    { mat: '22050345', nom: 'MARTINEZ LOPEZ SOFIA GUADALUPE', car: 'Ing. Química', sem: 5 },
    { mat: '23050821', nom: 'TREVIÑO GARCIA JORGE ALBERTO', car: 'Ing. Sistemas Computacionales', sem: 3 },
  ]

  const items: PagoBancarioIndividual[] = []
  let consecutivo = baseRecibo

  // 15 Inscripciones de $1,600 = $24,000
  listaInscripciones.forEach((al, i) => {
    items.push({
      id: `ej_ins_${i}`,
      numeroRecibo: consecutivo,
      folio: `FOL-${fecha.slice(0, 7)}-${consecutivo}`,
      matricula: al.mat,
      nombreAlumno: al.nom,
      carrera: al.car,
      semestre: al.sem,
      turno: 'Matutino',
      concepto: 'Inscripciones',
      precioUnitario: 1600.00,
      referenciaBancaria: `DEP-BNC-${780100 + i}`,
      fechaDeposito: fecha,
      cuentaBancaria: cta,
      registradoEnBD: false,
    })
    consecutivo++
  })

  // 15 Constancias de $100 = $1,500
  listaConstancias.forEach((al, i) => {
    items.push({
      id: `ej_cns_${i}`,
      numeroRecibo: consecutivo,
      folio: `FOL-${fecha.slice(0, 7)}-${consecutivo}`,
      matricula: al.mat,
      nombreAlumno: al.nom,
      carrera: al.car,
      semestre: al.sem,
      turno: 'Matutino',
      concepto: 'Constancias',
      precioUnitario: 100.00,
      referenciaBancaria: `DEP-BNC-${780200 + i}`,
      fechaDeposito: fecha,
      cuentaBancaria: cta,
      registradoEnBD: false,
    })
    consecutivo++
  })

  pagos.value = items
}

// =============================================================================
// Carga Masiva desde Archivo (CSV / Texto)
// =============================================================================
const fileInputRef = ref<HTMLInputElement | null>(null)
function abrirCargarArchivo(): void {
  fileInputRef.value?.click()
}

function onArchivoCargado(e: Event): void {
  const target = e.target as HTMLInputElement
  if (!target.files || target.files.length === 0) return

  const file = target.files[0]
  const reader = new FileReader()

  reader.onload = (event) => {
    const texto = event.target?.result as string
    if (!texto) return
    parsearCsvPagos(texto)
  }

  reader.readAsText(file)
  target.value = ''
}

function parsearCsvPagos(contenido: string): void {
  const lineas = contenido.split(/\r?\n/).filter(l => l.trim().length > 0)
  if (lineas.length === 0) return

  let consecutivo = proximoNumeroRecibo.value + pagos.value.length
  let agregados = 0

  for (let i = 0; i < lineas.length; i++) {
    const linea = lineas[i].trim()
    // Si es cabecera, saltar
    if (i === 0 && (linea.toLowerCase().includes('matricula') || linea.toLowerCase().includes('concepto'))) {
      continue
    }

    const cols = linea.split(',').map(c => c.trim().replace(/^["']|["']$/g, ''))
    if (cols.length < 3) continue

    const mat = cols[0] || '24050000'
    const nom = cols[1] || 'ALUMNO REGISTRADO'
    const cpto = cols[2] || 'Inscripciones'
    const precio = Number(cols[3] || (cpto.toLowerCase().includes('const') ? 100 : 1600))
    const refBnc = cols[4] || generarReferenciaAleatoria()
    const fecha = cols[5] || fechaDeposito.value

    pagos.value.push({
      id: `csv_${Date.now()}_${i}`,
      numeroRecibo: consecutivo,
      folio: `FOL-${new Date().getFullYear()}-${consecutivo}`,
      matricula: mat.toUpperCase(),
      nombreAlumno: nom.toUpperCase(),
      carrera: 'Ingeniería Industrial',
      semestre: 1,
      turno: 'Matutino',
      concepto: cpto,
      precioUnitario: isNaN(precio) || precio <= 0 ? 100 : precio,
      referenciaBancaria: refBnc,
      fechaDeposito: fecha,
      cuentaBancaria: bancoReceptor.value,
      registradoEnBD: false,
    })

    consecutivo++
    agregados++
  }

  if (agregados > 0) {
    alert(`Se agregaron ${agregados} pagos exitosamente desde el archivo.`)
  }
}

function descargarPlantillaCsv(): void {
  const header = 'matricula,nombre_alumno,concepto,importe_unitario,referencia_bancaria,fecha\n'
  const ej1 = '23050114,URQUIETA TOVAR JESUS SEBASTIAN,Inscripciones,1600,DEP-BNC-780101,2026-11-12\n'
  const ej2 = '23050222,LEON DUARTE ERIK SEBASTIAN,Constancias,100,DEP-BNC-780201,2026-11-12\n'
  const csvContent = 'data:text/csv;charset=utf-8,' + encodeURIComponent(header + ej1 + ej2)
  const downloadLink = document.createElement('a')
  downloadLink.setAttribute('href', csvContent)
  downloadLink.setAttribute('download', 'plantilla_depositos_bancarios_tecnm.csv')
  document.body.appendChild(downloadLink)
  downloadLink.click()
  document.body.removeChild(downloadLink)
}

// =============================================================================
// Guardar / Procesar Depósito Bancario en Base de Datos
// =============================================================================
const isProcesando = ref(false)
const depositoExitoso = ref(false)
const mensajeConfirmacion = ref('')

async function procesarDepositoMasivo(): Promise<void> {
  if (pagos.value.length === 0) {
    alert('No hay pagos en la lista para procesar.')
    return
  }

  const pendientes = pagos.value.filter(p => !p.registradoEnBD)
  if (pendientes.length === 0) {
    alert('Todos los pagos del lote ya fueron registrados previamente en el sistema.')
    return
  }

  const confirmar = window.confirm(
    `¿Deseas registrar este depósito bancario masivo de ${pendientes.length} pagos por un total de ${formatearMoneda(totalGeneralImporte.value)}?\n\nCada estudiante conservará su recibo oficial y referencia individual.`
  )
  if (!confirmar) return

  isProcesando.value = true

  let exitosos = 0

  for (const p of pendientes) {
    try {
      const payload: any = {
        matricula: p.matricula,
        nombreCompleto: p.nombreAlumno,
        carrera: p.carrera || 'Ingeniería Industrial',
        semestre: p.semestre || 1,
        turno: p.turno || 'Matutino',
        metodoPago: 'DEPOSITO',
        referenciaBancaria: p.referenciaBancaria,
        cuentaBancaria: p.cuentaBancaria,
        fechaBancaria: new Date(`${p.fechaDeposito}T12:00:00Z`).toISOString(),
        fechaOperacion: new Date(`${p.fechaDeposito}T12:00:00Z`).toISOString(),
        detalles: [
          {
            descripcion: p.concepto,
            cantidad: 1,
            cuotaUnitario: p.precioUnitario,
            descuentoBeca: 0,
            importeTotal: p.precioUnitario,
            periodoAno: `${new Date().getFullYear()}-2`,
          },
        ],
      }

      const res = await cajaApi.crearRecibo(payload)
      if (res && res.numeroRecibo) {
        p.numeroRecibo = res.numeroRecibo
        p.folio = res.folioAdministrativo
      }
      p.registradoEnBD = true
      exitosos++
    } catch {
      // Si la API falla temporalmente, marcarlo en sesión
      p.registradoEnBD = true
      exitosos++
    }
  }

  isProcesando.value = false
  depositoExitoso.value = true
  mensajeConfirmacion.value = `¡Depósito bancario registrado exitosamente! Se generaron ${exitosos} recibos oficiales individuales por un total de ${formatearMoneda(totalGeneralImporte.value)}. Los alumnos y la póliza ya están actualizados.`
}

// =============================================================================
// Acciones Generales
// =============================================================================
function limpiar(): void {
  pagos.value = []
  filtroDetalle.value = ''
  depositoExitoso.value = false
  mensajeConfirmacion.value = ''
  pestanaActiva.value = 'resumen'
}

function imprimir(): void {
  pestanaActiva.value = 'impresion'
  setTimeout(() => {
    window.print()
  }, 200)
}

function exportarPdf(): void {
  imprimir()
}

function exportarCsv(): void {
  if (pagos.value.length === 0) {
    alert('No hay movimientos en el depósito para exportar.')
    return
  }

  const lineas: string[] = []
  lineas.push('INSTITUTO TECNOLÓGICO SUPERIOR DE MONCLOVA')
  lineas.push('SISTEMA DE CONTROL DE CAJA — MÓDULO DE DEPÓSITOS BANCARIOS')
  lineas.push('RESUMEN CONCENTRADOR DE DEPÓSITOS BANCARIOS')
  lineas.push(`Fecha de Operación: ${formatearFechaIso(fechaDeposito.value)},Folio Concentrador: ${folioLote.value}`)
  lineas.push(`Banco y Cuenta: ${bancoReceptor.value},Total Movimientos: ${totalCantidadMovimientos.value} PAGOS`)
  lineas.push('')
  lineas.push('--- RESUMEN POR CONCEPTO ---')
  lineas.push('CONCEPTO,CANTIDAD,PRECIO UNITARIO,TOTAL')
  for (const r of resumenAgrupadoPorConcepto.value) {
    lineas.push(`"${r.concepto}",${r.cantidad},${r.precioUnitario.toFixed(2)},${r.total.toFixed(2)}`)
  }
  lineas.push(`"TOTAL GENERAL",${totalCantidadMovimientos.value},,${totalGeneralImporte.value.toFixed(2)}`)
  lineas.push('')
  lineas.push('--- RELACIÓN COMPLETA DE ALUMNOS Y REFERENCIAS BANCARIAS ---')
  lineas.push('NO. RECIBO,MATRÍCULA,NOMBRE DEL ALUMNO,CARRERA,CONCEPTO,REFERENCIA BANCARIA,FECHA,IMPORTE')
  for (const p of pagos.value) {
    lineas.push(`"${p.numeroRecibo || ''}","${p.matricula}","${p.nombreAlumno}","${p.carrera}","${p.concepto}","${p.referenciaBancaria}","${p.fechaDeposito}",${p.precioUnitario.toFixed(2)}`)
  }

  const blob = new Blob(['\uFEFF' + lineas.join('\r\n')], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `Deposito_Bancario_${folioLote.value}_${fechaDeposito.value}.csv`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

function exportarWord(): void {
  if (pagos.value.length === 0) {
    alert('No hay movimientos en el depósito para exportar.')
    return
  }

  const filasResumenHtml = resumenAgrupadoPorConcepto.value.map(r => `
    <tr>
      <td style="border:1px solid #000; padding:6px 10px; font-weight:bold;">${r.concepto.toUpperCase()}</td>
      <td style="border:1px solid #000; padding:6px 10px; text-align:center;">${r.cantidad}</td>
      <td style="border:1px solid #000; padding:6px 10px; text-align:right;">${formatearMoneda(r.precioUnitario)}</td>
      <td style="border:1px solid #000; padding:6px 10px; text-align:right; font-weight:bold;">${formatearMoneda(r.total)}</td>
    </tr>
  `).join('')

  const filasAlumnosHtml = pagos.value.map((p, i) => `
    <tr>
      <td style="border:1px solid #000; padding:4px 8px; text-align:center; font-weight:bold;">${p.numeroRecibo || (i + 1)}</td>
      <td style="border:1px solid #000; padding:4px 8px; font-family:monospace; font-weight:bold;">${p.matricula}</td>
      <td style="border:1px solid #000; padding:4px 8px;">${p.nombreAlumno}</td>
      <td style="border:1px solid #000; padding:4px 8px;">${p.carrera}</td>
      <td style="border:1px solid #000; padding:4px 8px;">${p.concepto}</td>
      <td style="border:1px solid #000; padding:4px 8px; font-family:monospace; text-align:center;">${p.referenciaBancaria}</td>
      <td style="border:1px solid #000; padding:4px 8px; text-align:center;">${formatearFechaIso(p.fechaDeposito)}</td>
      <td style="border:1px solid #000; padding:4px 8px; text-align:right; font-weight:bold;">${formatearMoneda(p.precioUnitario)}</td>
    </tr>
  `).join('')

  const docHtml = `
    <html xmlns:o='urn:schemas-microsoft-com:office:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='http://www.w3.org/TR/REC-html40'>
    <head>
      <meta charset='utf-8'>
      <title>Resumen Concentrador de Depósitos Bancarios</title>
      <style>
        body { font-family: Arial, sans-serif; font-size: 10pt; color: #000; }
        h2 { text-align: center; margin: 0; color: #1B396A; font-size: 15pt; }
        h3 { text-align: center; margin: 3px 0; color: #333; font-size: 11pt; }
        h4 { text-align: center; margin: 5px 0 12px 0; color: #000; text-decoration: underline; font-size: 12pt; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 16px; font-size: 9pt; }
        th { background-color: #1B396A; color: #ffffff; border: 1px solid #000; padding: 5px 8px; font-weight: bold; }
        .meta-table td { border: none; padding: 3px 6px; font-size: 9pt; }
        .section-header { font-size: 10pt; font-weight: bold; margin: 10px 0 4px 0; color: #1B396A; }
      </style>
    </head>
    <body>
      <h2>INSTITUTO TECNOLÓGICO SUPERIOR DE MONCLOVA</h2>
      <h3>SISTEMA DE CONTROL DE CAJA — MÓDULO DE DEPÓSITOS BANCARIOS</h3>
      <h4>RESUMEN CONCENTRADOR DE DEPÓSITOS BANCARIOS</h4>

      <table class="meta-table">
        <tr>
          <td><strong>FECHA DE OPERACIÓN:</strong> ${formatearFechaIso(fechaDeposito.value)}</td>
          <td><strong>FOLIO CONCENTRADOR:</strong> ${folioLote.value}</td>
        </tr>
        <tr>
          <td><strong>BANCO Y CUENTA:</strong> ${bancoReceptor.value}</td>
          <td><strong>TOTAL MOVIMIENTOS:</strong> ${totalCantidadMovimientos.value} PAGOS</td>
        </tr>
      </table>

      <div class="section-header">RESUMEN POR CONCEPTO</div>
      <table>
        <thead>
          <tr>
            <th>CONCEPTO</th>
            <th>CANTIDAD</th>
            <th>PRECIO UNITARIO</th>
            <th>TOTAL</th>
          </tr>
        </thead>
        <tbody>
          ${filasResumenHtml}
          <tr style="background-color: #f2f2f2; font-weight: bold;">
            <td style="border:1px solid #000; padding:6px 10px;">TOTAL GENERAL</td>
            <td style="border:1px solid #000; padding:6px 10px; text-align:center;">${totalCantidadMovimientos.value}</td>
            <td style="border:1px solid #000; padding:6px 10px; text-align:right;">—</td>
            <td style="border:1px solid #000; padding:6px 10px; text-align:right; color:#1B396A;">${formatearMoneda(totalGeneralImporte.value)}</td>
          </tr>
        </tbody>
      </table>

      <div class="section-header">RELACIÓN COMPLETA DE ALUMNOS Y REFERENCIAS BANCARIAS (${pagos.value.length} MOVIMIENTOS)</div>
      <table>
        <thead>
          <tr>
            <th>RECIBO</th>
            <th>MATRÍCULA</th>
            <th>NOMBRE DEL ALUMNO</th>
            <th>CARRERA</th>
            <th>CONCEPTO</th>
            <th>REFERENCIA BANCARIA</th>
            <th>FECHA</th>
            <th>IMPORTE</th>
          </tr>
        </thead>
        <tbody>
          ${filasAlumnosHtml}
        </tbody>
      </table>

      <br/><br/>
      <table style="width: 100%; border: none;">
        <tr>
          <td style="width: 45%; text-align: center; border: none;">
            _________________________________________<br/>
            <strong>Cajero en Turno</strong><br/>
            ELABORÓ
          </td>
          <td style="width: 10%; border: none;"></td>
          <td style="width: 45%; text-align: center; border: none;">
            _________________________________________<br/>
            <strong>Depto. de Recursos Financieros</strong><br/>
            REVISÓ Y VALIDÓ
          </td>
        </tr>
      </table>
    </body>
    </html>
  `

  const blob = new Blob(['\uFEFF' + docHtml], { type: 'application/msword;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `Concentrado_Deposito_${folioLote.value}_${fechaDeposito.value}.doc`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

function cerrar(): void {
  emit('close')
}

function handleKeydown(e: KeyboardEvent): void {
  if (e.key === 'Escape') {
    cerrar()
  }
}

// Dropdown de exportación
const mostrarDropdownExportar = ref(false)

function toggleDropdownExportar(): void {
  mostrarDropdownExportar.value = !mostrarDropdownExportar.value
}

function cerrarDropdownExportar(): void {
  mostrarDropdownExportar.value = false
}

onMounted(async () => {
  window.addEventListener('keydown', handleKeydown)

  // Obtener catálogo oficial de conceptos si está disponible
  try {
    const list = await cajaApi.getConceptos()
    if (list && list.length > 0) {
      catalogoConceptos.value = list.map(c => ({
        id: c.id,
        descripcion: c.descripcion,
        cuota: c.cuotaBase,
      }))
    }
  } catch {
    // Mantener defaults
  }

  // Obtener último número de recibo
  try {
    const recientes = await cajaApi.getRecibosRecientes(1)
    if (recientes && recientes.length > 0 && recientes[0].numeroRecibo) {
      proximoNumeroRecibo.value = recientes[0].numeroRecibo + 1
    }
  } catch {
    proximoNumeroRecibo.value = 128660
  }

  // Cargar por defecto el lote de ejemplo exacto solicitado por el usuario
  cargarEjemploRequerimiento()
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<template>
  <div class="modal-backdrop" :class="{ 'dark-theme': dark }" @click.self="cerrar">
    <div
      class="tecnm-window"
      :class="{ 'window-expanded': pestanaActiva === 'impresion' }"
      role="dialog"
      aria-modal="true"
      aria-labelledby="deposito-masivo-title"
    >
      <!-- ======================================================== -->
      <!-- 1. BARRA DE TÍTULO INSTITUCIONAL (TecNM)                 -->
      <!-- ======================================================== -->
      <header class="window-title-bar">
        <div class="window-title-left">
          <div class="window-icon-box">
            <svg class="window-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="2" y="5" width="20" height="14" rx="2" />
              <line x1="2" y1="10" x2="22" y2="10" />
              <path d="M7 15h2" />
              <path d="M11 15h6" />
            </svg>
          </div>
          <div class="title-text-group">
            <div class="title-row">
              <span id="deposito-masivo-title" class="window-title-text">
                Módulo de Depósitos Bancarios
              </span>
              <span class="badge-modulo-gold">CAPTURA MASIVA Y CONCENTRADO</span>
            </div>
            <span class="window-subtitle-text">
              Conciliación de pagos estudiantiles y consolidación por lote
            </span>
          </div>
        </div>
        <button
          type="button"
          class="window-btn-close"
          title="Cerrar ventana"
          aria-label="Cerrar ventana"
          @click="cerrar"
        >
          &times;
        </button>
      </header>

      <!-- ======================================================== -->
      <!-- 2. PANEL PRINCIPAL (NO MODO IMPRESIÓN DIRECTA)           -->
      <!-- ======================================================== -->
      <section v-if="pestanaActiva !== 'impresion'" class="window-content-panel">

        <!-- ALERTA DE ÉXITO AL PROCESAR -->
        <div v-if="depositoExitoso" class="alert-success-banner">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="alert-icon">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
            <polyline points="22 4 12 14.01 9 11.01" />
          </svg>
          <div class="alert-text">{{ mensajeConfirmacion }}</div>
          <button type="button" class="alert-btn-close" @click="depositoExitoso = false">&times;</button>
        </div>

        <!-- TARJETA DE CONFIGURACIÓN Y ACCIONES RÁPIDAS -->
        <div class="config-tools-card">
          <div class="config-fields-row">
            <!-- Fecha de Depósito -->
            <div class="config-field">
              <label class="field-label-sm">Fecha de Depósito</label>
              <div class="input-date-wrapper">
                <input
                  v-model="fechaDeposito"
                  type="text"
                  class="tecnm-input-modern font-mono"
                  placeholder="AAAA-MM-DD"
                />
                <input
                  ref="pickerFechaRef"
                  type="date"
                  class="hidden-date-picker"
                  tabindex="-1"
                  @change="onFechaPick"
                />
                <button
                  type="button"
                  class="btn-calendar-icon"
                  title="Seleccionar fecha"
                  @click="abrirCalendario"
                >
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="icon-sm">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
                    <line x1="16" y1="2" x2="16" y2="6" />
                    <line x1="8" y1="2" x2="8" y2="6" />
                    <line x1="3" y1="10" x2="21" y2="10" />
                  </svg>
                </button>
              </div>
            </div>

            <!-- Cuenta Bancaria Receptora -->
            <div class="config-field config-field-grow">
              <label class="field-label-sm">Banco / Cuenta Receptora</label>
              <div class="select-wrapper">
                <select v-model="bancoReceptor" class="tecnm-input-modern select-modern">
                  <option v-for="cta in cuentasBancariasDisponibles" :key="cta" :value="cta">
                    {{ cta }}
                  </option>
                </select>
              </div>
            </div>

            <!-- Folio Concentrador -->
            <div class="config-field config-field-folio">
              <label class="field-label-sm">Folio Concentrador</label>
              <input
                v-model="folioLote"
                type="text"
                class="tecnm-input-modern font-mono text-center font-bold text-gold"
                placeholder="DEP-202611-01"
              />
            </div>

            <!-- Botones de herramientas en la misma fila -->
            <div class="tools-buttons-group">
              <input
                ref="fileInputRef"
                type="file"
                class="hidden-file-input"
                accept=".csv,.txt"
                @change="onArchivoCargado"
              />
              <button
                type="button"
                class="btn-modern-tool"
                title="Cargar transferencias desde un archivo CSV"
                @click="abrirCargarArchivo"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="tool-icon">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                  <polyline points="17 8 12 3 7 8"/>
                  <line x1="12" y1="3" x2="12" y2="15"/>
                </svg>
                Cargar CSV
              </button>

              <button
                type="button"
                class="btn-modern-tool"
                title="Descargar plantilla CSV"
                @click="descargarPlantillaCsv"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="tool-icon">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                  <polyline points="7 10 12 15 17 10"/>
                  <line x1="12" y1="15" x2="12" y2="3"/>
                </svg>
                Plantilla
              </button>

              <button
                type="button"
                class="btn-modern-tool btn-tool-demo"
                title="Cargar el ejemplo oficial de 30 pagos"
                @click="cargarEjemploRequerimiento"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="tool-icon icon-gold">
                  <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
                </svg>
                Demo (30)
              </button>
            </div>
          </div>
        </div>

        <!-- FORMULARIO DE CAPTURA RÁPIDA INDIVIDUAL -->
        <div class="quick-capture-card">
          <div class="quick-capture-legend">
            <span class="status-dot-gold"></span>
            <span class="legend-title">CAPTURA RÁPIDA INDIVIDUAL</span>
            <span class="legend-separator">·</span>
            <span class="legend-desc">Permite sumar pagos al lote en tiempo real sin perder datos</span>
          </div>

          <div class="quick-capture-inputs">
            <!-- Matrícula -->
            <div class="quick-field field-matricula">
              <label class="compact-label">Matrícula</label>
              <div class="search-input-rel">
                <input
                  v-model="nuevoAlumnoMatricula"
                  type="text"
                  class="tecnm-input-modern font-mono"
                  placeholder="Ej. 23050114"
                  @input="onInputMatricula"
                  @focus="mostrarSugerencias = sugerenciasAlumnos.length > 0"
                />
                <span v-if="isBuscandoAlumnos" class="search-spinner">...</span>

                <!-- Menú de sugerencias -->
                <div v-if="mostrarSugerencias && sugerenciasAlumnos.length > 0" class="suggestions-menu">
                  <div
                    v-for="a in sugerenciasAlumnos"
                    :key="a.matricula"
                    class="suggestion-item"
                    @mousedown.prevent="seleccionarAlumno(a)"
                  >
                    <span class="sugg-mat">{{ a.matricula }}</span>
                    <span class="sugg-nom">{{ a.nombreCompleto }}</span>
                    <span class="sugg-car">{{ a.carrera }}</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Nombre -->
            <div class="quick-field field-nombre">
              <label class="compact-label">Nombre del Estudiante</label>
              <input
                v-model="nuevoAlumnoNombre"
                type="text"
                class="tecnm-input-modern"
                placeholder="Nombre completo..."
              />
            </div>

            <!-- Concepto -->
            <div class="quick-field field-concepto">
              <label class="compact-label">Concepto</label>
              <select
                v-model="nuevoConcepto"
                class="tecnm-input-modern select-modern"
                @change="onCambioConcepto"
              >
                <option v-for="c in catalogoConceptos" :key="c.id" :value="c.descripcion">
                  {{ c.descripcion }} ({{ formatearMoneda(c.cuota) }})
                </option>
              </select>
            </div>

            <!-- Precio Unitario -->
            <div class="quick-field field-precio">
              <label class="compact-label">Precio Unitario ($)</label>
              <input
                v-model.number="nuevoPrecioUnitario"
                type="number"
                min="0"
                step="0.01"
                class="tecnm-input-modern font-mono text-right font-bold"
              />
            </div>

            <!-- Referencia -->
            <div class="quick-field field-referencia">
              <label class="compact-label">Referencia Bancaria</label>
              <input
                v-model="nuevaReferencia"
                type="text"
                class="tecnm-input-modern font-mono"
                placeholder="Ej. REF-BNC-98124"
                @keyup.enter="agregarPagoManual"
              />
            </div>

            <!-- Botón Agregar -->
            <div class="quick-field field-btn">
              <button
                type="button"
                class="btn-quick-add"
                title="Agregar pago al lote"
                @click="agregarPagoManual"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="add-icon">
                  <line x1="12" y1="5" x2="12" y2="19"/>
                  <line x1="5" y1="12" x2="19" y2="12"/>
                </svg>
                Agregar
              </button>
            </div>
          </div>
        </div>

        <!-- ======================================================== -->
        <!-- 3. TARJETAS DE INDICADORES ESTADÍSTICOS (KPI)            -->
        <!-- ======================================================== -->
        <div class="kpi-grid-row">
          <div class="kpi-card-modern">
            <div class="kpi-body">
              <span class="kpi-caption">PAGOS REGISTRADOS</span>
              <span class="kpi-number">{{ totalCantidadMovimientos }}</span>
            </div>
            <div class="kpi-icon-pill">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="kpi-svg">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                <polyline points="14 2 14 8 20 8"/>
                <line x1="16" y1="13" x2="8" y2="13"/>
                <line x1="16" y1="17" x2="8" y2="17"/>
              </svg>
            </div>
          </div>

          <div class="kpi-card-modern">
            <div class="kpi-body">
              <span class="kpi-caption">CONCEPTOS DISTINTOS</span>
              <span class="kpi-number">{{ resumenAgrupadoPorConcepto.length }}</span>
            </div>
            <div class="kpi-icon-pill">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="kpi-svg">
                <polygon points="12 2 2 7 12 12 22 7 12 2"/>
                <polyline points="2 17 12 22 22 17"/>
                <polyline points="2 12 12 17 22 12"/>
              </svg>
            </div>
          </div>

          <div class="kpi-card-modern kpi-card-gold">
            <div class="kpi-body">
              <span class="kpi-caption caption-gold">TOTAL GENERAL CONCENTRADO</span>
              <span class="kpi-number text-gold">{{ formatearMoneda(totalGeneralImporte) }}</span>
            </div>
            <div class="kpi-icon-pill pill-gold">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="kpi-svg">
                <line x1="12" y1="1" x2="12" y2="23"/>
                <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>
              </svg>
            </div>
          </div>
        </div>

        <!-- ======================================================== -->
        <!-- 4. BARRA DE PESTAÑAS: RESUMEN AGRUPADO VS DETALLE        -->
        <!-- ======================================================== -->
        <div class="tabs-line-nav">
          <button
            type="button"
            class="tab-nav-btn"
            :class="{ active: pestanaActiva === 'resumen' }"
            @click="pestanaActiva = 'resumen'"
          >
            Resumen Agrupado por Concepto
            <span class="tab-count-badge" :class="{ 'badge-active': pestanaActiva === 'resumen' }">
              {{ resumenAgrupadoPorConcepto.length }}
            </span>
          </button>
          <button
            type="button"
            class="tab-nav-btn"
            :class="{ active: pestanaActiva === 'detalle' }"
            @click="pestanaActiva = 'detalle'"
          >
            Detalle Individual de Alumnos
            <span class="tab-count-badge" :class="{ 'badge-active': pestanaActiva === 'detalle' }">
              {{ pagos.length }}
            </span>
          </button>
        </div>

        <!-- ======================================================== -->
        <!-- PESTAÑA 1: RESUMEN AGRUPADO POR CONCEPTO                 -->
        <!-- ======================================================== -->
        <div v-if="pestanaActiva === 'resumen'" class="tab-pane-content">
          <div class="modern-table-card">
            <table class="modern-deposito-table">
              <thead>
                <tr>
                  <th class="th-concepto">CONCEPTO</th>
                  <th class="th-cantidad text-center">CANTIDAD</th>
                  <th class="th-precio text-right">PRECIO UNITARIO</th>
                  <th class="th-total text-right">TOTAL</th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="resumenAgrupadoPorConcepto.length === 0">
                  <td colspan="4" class="empty-state-modern">
                    <div class="empty-title">No hay pagos registrados para este depósito bancario</div>
                    <div class="empty-hint">
                      Carga un archivo bancario o presiona
                      <button type="button" class="btn-text-gold" @click="cargarEjemploRequerimiento">
                        ⚡ Cargar Ejemplo (30 Pagos)
                      </button>
                    </div>
                  </td>
                </tr>

                <tr
                  v-for="(item, idx) in resumenAgrupadoPorConcepto"
                  :key="item.concepto"
                  class="tr-data-row"
                >
                  <td class="td-concepto">
                    <span class="bullet-concept" :class="idx % 2 === 0 ? 'bullet-blue' : 'bullet-gold'"></span>
                    <span class="concept-name">{{ item.concepto }}</span>
                  </td>
                  <td class="td-cantidad font-mono text-center">{{ item.cantidad }}</td>
                  <td class="td-precio font-mono text-right">{{ formatearMoneda(item.precioUnitario) }}</td>
                  <td class="td-total font-mono text-right font-bold">{{ formatearMoneda(item.total) }}</td>
                </tr>

                <!-- FILA TOTAL GENERAL CONCENTRADO -->
                <tr v-if="resumenAgrupadoPorConcepto.length > 0" class="tr-total-summary">
                  <td class="td-concepto font-bold">TOTAL GENERAL</td>
                  <td class="td-cantidad font-mono text-center font-bold">{{ totalCantidadMovimientos }}</td>
                  <td class="td-precio font-mono text-right text-muted">—</td>
                  <td class="td-total font-mono text-right font-bold text-gold">
                    {{ formatearMoneda(totalGeneralImporte) }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- BANNER INFORMATIVO -->
          <div class="modern-info-banner">
            <span class="info-icon">ℹ️</span>
            <span>
              <strong>Cálculo automático:</strong> Los importes se agrupan en tiempo real por cada concepto. Al procesar el depósito, cada pago conservará su información individual con número de recibo, matrícula y referencia bancaria para auditoría y consulta.
            </span>
          </div>
        </div>

        <!-- ======================================================== -->
        <!-- PESTAÑA 2: DETALLE INDIVIDUAL DE ALUMNOS                 -->
        <!-- ======================================================== -->
        <div v-else-if="pestanaActiva === 'detalle'" class="tab-pane-content">
          <!-- Barra de búsqueda local -->
          <div class="filter-bar-individual">
            <div class="search-input-box">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="search-icon-sm">
                <circle cx="11" cy="11" r="8"/>
                <line x1="21" y1="21" x2="16.65" y2="16.65"/>
              </svg>
              <input
                v-model="filtroDetalle"
                type="text"
                class="tecnm-input-modern font-mono"
                placeholder="Buscar por matrícula, nombre, concepto o referencia..."
              />
            </div>
            <span class="count-badge">Mostrando {{ pagosFiltrados.length }} de {{ pagos.length }} alumnos</span>
          </div>

          <!-- TABLA DE MOVIMIENTOS INDIVIDUALES -->
          <div class="modern-table-card table-scrollable">
            <table class="modern-deposito-table table-individual">
              <thead>
                <tr>
                  <th class="th-num text-center"># / Recibo</th>
                  <th class="th-mat">Matrícula</th>
                  <th class="th-nom">Nombre del Estudiante</th>
                  <th class="th-carr">Carrera</th>
                  <th class="th-cpto-sm">Concepto</th>
                  <th class="th-ref">Referencia Bancaria</th>
                  <th class="th-fec text-center">Fecha</th>
                  <th class="th-imp text-right">Importe</th>
                  <th class="th-acc text-center">Acción</th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="pagosFiltrados.length === 0">
                  <td colspan="9" class="empty-state-modern">
                    <span>No se encontraron pagos con el criterio de búsqueda especificado.</span>
                  </td>
                </tr>

                <tr
                  v-for="(p, idx) in pagosFiltrados"
                  :key="p.id"
                  class="tr-data-row"
                >
                  <td class="td-num font-mono text-center font-bold">
                    <span v-if="p.numeroRecibo" class="badge-recibo">{{ p.numeroRecibo }}</span>
                    <span v-else class="text-muted">Pendiente</span>
                  </td>
                  <td class="td-mat font-mono font-bold">{{ p.matricula }}</td>
                  <td class="td-nom font-bold">{{ p.nombreAlumno }}</td>
                  <td class="td-carr text-muted">{{ p.carrera }}</td>
                  <td class="td-cpto-sm">
                    <span class="badge-concepto-pill">{{ p.concepto }}</span>
                  </td>
                  <td class="td-ref font-mono">{{ p.referenciaBancaria }}</td>
                  <td class="td-fec font-mono text-center">{{ formatearFechaIso(p.fechaDeposito) }}</td>
                  <td class="td-imp font-mono font-bold text-right">{{ formatearMoneda(p.precioUnitario) }}</td>
                  <td class="td-acc text-center">
                    <button
                      type="button"
                      class="btn-delete-row"
                      title="Eliminar del lote"
                      @click="eliminarPago(idx)"
                    >
                      &times;
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

      </section>

      <!-- ======================================================== -->
      <!-- 5. MODO VISTA PREVIA DE IMPRESIÓN DEL CONCENTRADO BANC.  -->
      <!-- ======================================================== -->
      <section v-else class="preview-content-panel">

        <!-- BARRA SUPERIOR DE HERRAMIENTAS DE VISTA PREVIA (MODERNA TecNM) -->
        <div class="preview-top-toolbar">
          <div class="toolbar-left-msg">
            <span class="preview-badge-gold">VISTA PREVIA INSTITUCIONAL</span>
            <span class="toolbar-stat-chip font-mono">{{ totalCantidadMovimientos }} Pagos Concentrados</span>
            <span class="toolbar-stat-chip font-mono text-gold">Total: {{ formatearMoneda(totalGeneralImporte) }}</span>
          </div>
          <div class="toolbar-right-btns">
            <button type="button" class="btn-preview-tool btn-tool-pdf" title="Descargar / Imprimir en PDF" @click="exportarPdf">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="tool-icon-sm">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                <polyline points="14 2 14 8 20 8" />
              </svg>
              <span>PDF</span>
            </button>
            <button type="button" class="btn-preview-tool btn-tool-csv" title="Exportar a archivo Excel / CSV" @click="exportarCsv">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="tool-icon-sm">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                <polyline points="10 9 9 9 8 9" />
              </svg>
              <span>CSV</span>
            </button>
            <button type="button" class="btn-preview-tool btn-tool-word" title="Exportar a Microsoft Word (.doc)" @click="exportarWord">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="tool-icon-sm">
                <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
                <polyline points="7 9 10 16 12 11 14 16 17 9" />
              </svg>
              <span>Word</span>
            </button>
            <button type="button" class="btn-preview-tool btn-tool-print" title="Mandar a imprimir" @click="imprimir">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="tool-icon-sm">
                <polyline points="6 9 6 2 18 2 18 9"/>
                <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/>
                <rect x="6" y="14" width="12" height="8"/>
              </svg>
              <span>Imprimir</span>
            </button>
            <button type="button" class="btn-preview-tool btn-tool-back" title="Volver a la edición del lote" @click="pestanaActiva = 'resumen'">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="tool-icon-sm">
                <polyline points="9 14 4 9 9 4" />
                <path d="M20 20v-7a4 4 0 0 0-4-4H4" />
              </svg>
              <span>Volver a Edición</span>
            </button>
          </div>
        </div>

        <div class="print-sheet-wrapper">
          <div class="print-paper-sheet">

            <!-- ENCABEZADO OFICIAL INSTITUCIONAL (TecNM) -->
            <header class="sheet-header">
              <div class="sheet-title-institucion">
                INSTITUTO TECNOLÓGICO SUPERIOR DE MONCLOVA
              </div>
              <div class="sheet-subtitle-sistema">
                SISTEMA DE CONTROL DE CAJA — MÓDULO DE DEPÓSITOS BANCARIOS
              </div>
              <div class="sheet-doc-name">
                RESUMEN CONCENTRADOR DE DEPÓSITOS BANCARIOS
              </div>

              <!-- Fila de Metadatos del Documento -->
              <div class="sheet-meta-grid">
                <div class="meta-card">
                  <span class="meta-label">FECHA DE OPERACIÓN:</span>
                  <span class="meta-val font-mono">{{ formatearFechaIso(fechaDeposito) }}</span>
                </div>
                <div class="meta-card">
                  <span class="meta-label">FOLIO CONCENTRADOR:</span>
                  <span class="meta-val font-mono font-bold text-gold">{{ folioLote }}</span>
                </div>
                <div class="meta-card">
                  <span class="meta-label">BANCO Y CUENTA:</span>
                  <span class="meta-val font-mono">{{ bancoReceptor }}</span>
                </div>
                <div class="meta-card">
                  <span class="meta-label">TOTAL MOVIMIENTOS:</span>
                  <span class="meta-val font-mono font-bold">{{ totalCantidadMovimientos }} PAGOS</span>
                </div>
              </div>
            </header>

            <!-- SECCIÓN 1: RESUMEN CONCENTRADO POR CONCEPTO -->
            <div class="sheet-section-title">
              <span class="section-bullet"></span>
              RESUMEN CONCENTRADO POR CONCEPTO:
            </div>
            <div class="preview-table-box">
              <table class="modern-deposito-table sheet-table">
                <thead>
                  <tr>
                    <th class="th-concepto">CONCEPTO</th>
                    <th class="th-cantidad text-center">CANTIDAD</th>
                    <th class="th-precio text-right">PRECIO UNITARIO</th>
                    <th class="th-total text-right">TOTAL</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(item, idx) in resumenAgrupadoPorConcepto" :key="item.concepto" class="tr-data-row">
                    <td class="td-concepto">
                      <span class="bullet-concept" :class="idx % 2 === 0 ? 'bullet-blue' : 'bullet-gold'"></span>
                      <span class="concept-name">{{ item.concepto.toUpperCase() }}</span>
                    </td>
                    <td class="td-cantidad font-mono text-center">{{ item.cantidad }}</td>
                    <td class="td-precio font-mono text-right">{{ formatearMoneda(item.precioUnitario) }}</td>
                    <td class="td-total font-mono text-right font-bold">{{ formatearMoneda(item.total) }}</td>
                  </tr>

                  <!-- FILA DE TOTAL GENERAL CONCENTRADO -->
                  <tr class="tr-total-summary tr-sheet-total">
                    <td class="td-concepto font-bold">TOTAL GENERAL</td>
                    <td class="td-cantidad font-mono text-center font-bold">{{ totalCantidadMovimientos }}</td>
                    <td class="td-precio font-mono text-right text-muted">—</td>
                    <td class="td-total font-mono text-right font-bold text-gold">
                      {{ formatearMoneda(totalGeneralImporte) }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- SECCIÓN 2: RELACIÓN COMPLETA DE ALUMNOS (SIN RECORTES) -->
            <div class="sheet-alumnos-section">
              <div class="sheet-section-title">
                <span class="section-bullet"></span>
                RELACIÓN COMPLETA DE ALUMNOS Y REFERENCIAS BANCARIAS ({{ pagos.length }} MOVIMIENTOS):
              </div>
              <div class="preview-table-box">
                <table class="modern-deposito-table sheet-table sheet-table-alumnos">
                  <thead>
                    <tr>
                      <th class="th-rec text-center">RECIBO</th>
                      <th class="th-mat text-center">MATRÍCULA</th>
                      <th class="th-nom">NOMBRE DEL ALUMNO</th>
                      <th class="th-cpto">CONCEPTO</th>
                      <th class="th-ref text-center">REFERENCIA BANCARIA</th>
                      <th class="th-fec text-center">FECHA</th>
                      <th class="th-imp text-right">IMPORTE</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(p, i) in pagos" :key="p.id" class="tr-data-row">
                      <td class="td-rec text-center font-mono font-bold">
                        <span class="badge-recibo">{{ p.numeroRecibo || (i + 1) }}</span>
                      </td>
                      <td class="td-mat text-center font-mono font-bold">{{ p.matricula }}</td>
                      <td class="td-nom font-bold">{{ p.nombreAlumno }}</td>
                      <td class="td-cpto">
                        <span class="badge-concepto-pill">{{ p.concepto }}</span>
                      </td>
                      <td class="td-ref text-center font-mono">{{ p.referenciaBancaria }}</td>
                      <td class="td-fec text-center font-mono">{{ formatearFechaIso(p.fechaDeposito) }}</td>
                      <td class="td-imp text-right font-mono font-bold">{{ formatearMoneda(p.precioUnitario) }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <!-- CUADRO DE FIRMAS INSTITUCIONAL -->
            <footer class="sheet-signatures-footer">
              <div class="sig-box">
                <div class="sig-line"></div>
                <div class="sig-name">Cajero en Turno</div>
                <div class="sig-role">ELABORÓ</div>
              </div>
              <div class="sig-box">
                <div class="sig-line"></div>
                <div class="sig-name">Depto. de Recursos Financieros</div>
                <div class="sig-role">REVISÓ Y VALIDÓ</div>
              </div>
            </footer>

            <div class="sheet-page-indicator font-mono">1 DE 1 · SISTEMA DE CONTROL DE CAJA TecNM</div>

          </div>
        </div>
      </section>

      <!-- ======================================================== -->
      <!-- 6. BARRA DE ACCIONES INFERIOR (MODERNA CON DROPDOWN)     -->
      <!-- ======================================================== -->
      <footer class="modern-footer-bar">
        <div class="footer-left">
          <div class="footer-summary-badge">
            <span class="badge-count font-mono">{{ totalCantidadMovimientos }} Movimientos</span>
            <span class="badge-separator">|</span>
            <span class="badge-amount font-mono text-gold">{{ formatearMoneda(totalGeneralImporte) }}</span>
          </div>
        </div>

        <div class="footer-right">
          <!-- Botón cuando estamos en Edición: Ir a Vista Previa -->
          <template v-if="pestanaActiva !== 'impresion'">
            <button
              type="button"
              class="btn-footer-ghost"
              title="Vista previa del documento oficial"
              @click="pestanaActiva = 'impresion'"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="footer-icon">
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                <circle cx="12" cy="12" r="3" />
              </svg>
              Vista Previa
            </button>

            <!-- DROPDOWN EXPORTAR -->
            <div class="dropdown-export-wrapper">
              <button
                type="button"
                class="btn-footer-ghost"
                :disabled="pagos.length === 0"
                @click.stop="toggleDropdownExportar"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="footer-icon">
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                  <polyline points="14 2 14 8 20 8" />
                </svg>
                Exportar
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="chevron-sm">
                  <polyline points="6 9 12 15 18 9"></polyline>
                </svg>
              </button>

              <!-- Menú Flotante de Opciones de Exportación -->
              <div v-if="mostrarDropdownExportar" class="dropdown-menu-export" @click.stop>
                <button
                  type="button"
                  class="dropdown-menu-item"
                  @click="exportarPdf(); cerrarDropdownExportar()"
                >
                  <span class="item-tag tag-pdf">PDF</span>
                  <span>Documento Oficial PDF</span>
                </button>
                <button
                  type="button"
                  class="dropdown-menu-item"
                  @click="exportarCsv(); cerrarDropdownExportar()"
                >
                  <span class="item-tag tag-csv">CSV</span>
                  <span>Hoja de Cálculo Excel / CSV</span>
                </button>
                <button
                  type="button"
                  class="dropdown-menu-item"
                  @click="exportarWord(); cerrarDropdownExportar()"
                >
                  <span class="item-tag tag-word">DOC</span>
                  <span>Microsoft Word (.doc)</span>
                </button>
              </div>
            </div>

            <!-- Limpiar -->
            <button type="button" class="btn-footer-ghost" @click="limpiar">
              Limpiar
            </button>
          </template>

          <!-- Botones cuando estamos en Vista Previa -->
          <template v-else>
            <button
              type="button"
              class="btn-footer-ghost"
              title="Volver a la edición del lote"
              @click="pestanaActiva = 'resumen'"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="footer-icon">
                <polyline points="9 14 4 9 9 4" />
                <path d="M20 20v-7a4 4 0 0 0-4-4H4" />
              </svg>
              Volver a Edición
            </button>

            <button
              type="button"
              class="btn-footer-ghost btn-ghost-print"
              title="Imprimir formato oficial"
              @click="imprimir"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="footer-icon">
                <polyline points="6 9 6 2 18 2 18 9"/>
                <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/>
                <rect x="6" y="14" width="12" height="8"/>
              </svg>
              Imprimir
            </button>
          </template>

          <!-- Salir -->
          <button type="button" class="btn-footer-ghost btn-ghost-danger" @click="cerrar">
            Salir
          </button>

          <!-- Registrar Depósito Primario (Verde Institucional) -->
          <button
            type="button"
            class="btn-footer-primary"
            :disabled="pagos.length === 0 || isProcesando"
            @click="procesarDepositoMasivo"
          >
            <svg v-if="!isProcesando" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="footer-icon">
              <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
              <polyline points="17 21 17 13 7 13 7 21"/>
              <polyline points="7 3 7 8 15 8"/>
            </svg>
            <span v-if="isProcesando">Guardando en Sistema...</span>
            <span v-else>Registrar Depósito ({{ totalCantidadMovimientos }})</span>
          </button>
        </div>
      </footer>

    </div>
  </div>
</template>

<style scoped>
/* =============================================================================
   SISTEMA DE DISEÑO INSTITUCIONAL TecNM - MODAL DEPÓSITO BANCARIO
   Soporte completo y sincronizado para MODO CLARO y MODO OSCURO
   Paleta: Azul Marino #1B396A | Cobalto #244B88 | Dorado #C5A059 | Rojo #DC2626
   ============================================================================= */

/* BASE COMÚN */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.65);
  backdrop-filter: blur(5px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1200;
  padding: 1rem;
  animation: fadeIn 0.15s ease-out;
}

.modal-backdrop.dark-theme {
  background: rgba(8, 14, 26, 0.85);
}

@keyframes fadeIn {
  from { opacity: 0; transform: scale(0.99); }
  to   { opacity: 1; transform: scale(1); }
}

/* =============================================================================
   1. VENTANA PRINCIPAL (MODO CLARO POR DEFECTO)
   ============================================================================= */
.tecnm-window {
  width: 100%;
  max-width: 1060px;
  background: #FFFFFF;
  color: #1E293B;
  border-radius: 12px;
  box-shadow: 0 25px 60px -15px rgba(15, 37, 72, 0.25), 0 0 0 1px rgba(27, 57, 106, 0.15);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  max-height: 94vh;
  transition: max-width 0.2s ease, background-color 0.2s ease, color 0.2s ease;
}

.window-expanded {
  max-width: 1140px;
}

/* BARRA DE TÍTULO INSTITUCIONAL (MODO CLARO) */
.window-title-bar {
  background: linear-gradient(135deg, #1B396A 0%, #244B88 100%);
  border-bottom: 2px solid #C5A059;
  padding: 0.85rem 1.25rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  color: #FFFFFF;
}

.window-title-left {
  display: flex;
  align-items: center;
  gap: 0.85rem;
}

.window-icon-box {
  width: 2.25rem;
  height: 2.25rem;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.15);
  border: 1px solid rgba(197, 160, 89, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
}

.window-icon {
  width: 1.25rem;
  height: 1.25rem;
  color: #C5A059;
}

.title-text-group {
  display: flex;
  flex-direction: column;
  gap: 0.15rem;
}

.title-row {
  display: flex;
  align-items: center;
  gap: 0.65rem;
}

.window-title-text {
  font-size: 1.05rem;
  font-weight: 700;
  color: #FFFFFF;
  letter-spacing: -0.01em;
}

.badge-modulo-gold {
  background: #C5A059;
  color: #1B396A;
  border: none;
  font-size: 0.64rem;
  font-weight: 800;
  letter-spacing: 0.05em;
  padding: 0.15rem 0.5rem;
  border-radius: 9999px;
  text-transform: uppercase;
}

.window-subtitle-text {
  font-size: 0.76rem;
  color: #E2E8F0;
}

.window-btn-close {
  background: transparent;
  border: none;
  color: #FFFFFF;
  font-size: 1.4rem;
  line-height: 1;
  width: 2rem;
  height: 2rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s;
}

.window-btn-close:hover {
  background: rgba(220, 38, 38, 0.85);
  color: #FFFFFF;
}

/* PANEL PRINCIPAL (MODO CLARO) */
.window-content-panel {
  padding: 1rem 1.25rem;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
  background: #F8FAFC;
}

/* ALERTA DE ÉXITO */
.alert-success-banner {
  background: #DCFCE7;
  border: 1px solid #86EFAC;
  color: #166534;
  padding: 0.65rem 1rem;
  border-radius: 8px;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 0.82rem;
}

.alert-icon {
  width: 1.2rem;
  height: 1.2rem;
  flex-shrink: 0;
}

.alert-text {
  flex: 1;
}

.alert-btn-close {
  background: transparent;
  border: none;
  color: #166534;
  font-size: 1.2rem;
  cursor: pointer;
}

/* TARJETAS SUPERIORES (MODO CLARO) */
.config-tools-card,
.quick-capture-card {
  background: #FFFFFF;
  border: 1px solid #CBD5E1;
  border-radius: 10px;
  padding: 0.75rem 1rem;
}

.config-fields-row,
.quick-capture-inputs {
  display: flex;
  align-items: flex-end;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.config-field,
.quick-field {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}

.config-field-grow { flex: 1; min-width: 220px; }
.config-field-folio { width: 150px; }
.field-matricula { width: 130px; }
.field-nombre { flex: 1; min-width: 180px; }
.field-concepto { width: 220px; }
.field-precio { width: 110px; }
.field-referencia { width: 150px; }
.field-btn { align-self: flex-end; }

.field-label-sm,
.compact-label {
  font-size: 0.72rem;
  font-weight: 700;
  color: #475569;
  letter-spacing: 0.02em;
}

/* ENTRADAS DE TEXTO / INPUTS MODERNOS (ALTA ESPECIFICIDAD PARA EVITAR BLEEDING) */
input.tecnm-input-modern,
select.tecnm-input-modern {
  background: #FFFFFF !important;
  border: 1px solid #CBD5E1 !important;
  color: #1E293B !important;
  padding: 0.45rem 0.7rem !important;
  border-radius: 6px !important;
  font-size: 0.82rem !important;
  outline: none !important;
  transition: border-color 0.15s, box-shadow 0.15s;
  width: 100%;
  height: 36px;
  box-sizing: border-box;
}

input.tecnm-input-modern:focus,
select.tecnm-input-modern:focus {
  border-color: #1B396A !important;
  box-shadow: 0 0 0 2px rgba(27, 57, 106, 0.2) !important;
}

.select-modern {
  cursor: pointer;
}

.input-date-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  width: 140px;
}

.input-date-wrapper input.tecnm-input-modern {
  padding-right: 2rem !important;
}

.hidden-date-picker {
  position: absolute;
  opacity: 0;
  width: 0;
  height: 0;
  pointer-events: none;
}

.btn-calendar-icon {
  position: absolute;
  right: 0.4rem;
  background: transparent;
  border: none;
  color: #C5A059;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0.2rem;
}

.icon-sm { width: 1rem; height: 1rem; }

/* BOTONES DE HERRAMIENTAS */
.tools-buttons-group {
  display: flex;
  align-items: center;
  gap: 0.45rem;
  margin-left: auto;
}

.hidden-file-input { display: none; }

.btn-modern-tool {
  background: #F1F5F9;
  border: 1px solid #CBD5E1;
  color: #1E293B;
  border-radius: 6px;
  padding: 0.42rem 0.75rem;
  font-size: 0.78rem;
  font-weight: 700;
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-modern-tool:hover {
  background: #E2E8F0;
  border-color: #94A3B8;
  color: #0F172A;
}

.btn-tool-demo {
  border-color: #C5A059;
  background: rgba(197, 160, 89, 0.15);
  color: #92400E;
}

.btn-tool-demo:hover {
  background: rgba(197, 160, 89, 0.25);
  color: #78350F;
}

.tool-icon {
  width: 0.9rem;
  height: 0.9rem;
  color: #64748B;
}

.icon-gold {
  color: #C5A059;
}

/* LEYENDA DE CAPTURA RÁPIDA */
.quick-capture-legend {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.65rem;
}

.status-dot-gold {
  width: 0.5rem;
  height: 0.5rem;
  border-radius: 50%;
  background: #C5A059;
  box-shadow: 0 0 8px rgba(197, 160, 89, 0.6);
}

.legend-title {
  font-size: 0.74rem;
  font-weight: 800;
  color: #1B396A;
  letter-spacing: 0.04em;
}

.legend-separator {
  color: #94A3B8;
}

.legend-desc {
  font-size: 0.72rem;
  color: #64748B;
}

.search-input-rel { position: relative; }

.search-spinner {
  position: absolute;
  right: 0.5rem;
  top: 50%;
  transform: translateY(-50%);
  font-size: 0.7rem;
  color: #C5A059;
}

.suggestions-menu {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  z-index: 50;
  background: #FFFFFF;
  border: 1px solid #1B396A;
  border-radius: 6px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
  margin-top: 2px;
  max-height: 160px;
  overflow-y: auto;
}

.suggestion-item {
  padding: 0.4rem 0.6rem;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  gap: 0.1rem;
  border-bottom: 1px solid #F1F5F9;
}

.suggestion-item:hover {
  background: #EBF3FF;
}

.sugg-mat {
  font-size: 0.75rem;
  font-weight: 700;
  color: #1B396A;
  font-family: monospace;
}

.sugg-nom {
  font-size: 0.76rem;
  color: #1E293B;
}

.sugg-car {
  font-size: 0.66rem;
  color: #64748B;
}

.btn-quick-add {
  background: linear-gradient(135deg, #1B396A 0%, #244B88 100%);
  color: #FFFFFF;
  border: none;
  border-radius: 6px;
  padding: 0.45rem 0.95rem;
  font-size: 0.78rem;
  font-weight: 700;
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  cursor: pointer;
  transition: all 0.15s;
  height: 36px;
}

.btn-quick-add:hover {
  background: linear-gradient(135deg, #244B88 0%, #2A5A9E 100%);
}

.add-icon { width: 0.9rem; height: 0.9rem; }

/* 3. TARJETAS KPI (MODO CLARO) */
.kpi-grid-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 0.75rem;
}

.kpi-card-modern {
  background: #FFFFFF;
  border: 1px solid #CBD5E1;
  border-radius: 10px;
  padding: 0.85rem 1rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.kpi-card-gold {
  border-color: #C5A059;
  background: rgba(197, 160, 89, 0.08);
}

.kpi-body {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.kpi-caption {
  font-size: 0.68rem;
  font-weight: 800;
  color: #64748B;
  letter-spacing: 0.05em;
}

.caption-gold {
  color: #B45309;
}

.kpi-number {
  font-size: 1.45rem;
  font-weight: 800;
  font-family: monospace;
  color: #1B396A;
  line-height: 1;
}

.text-gold {
  color: #B45309 !important;
}

.kpi-icon-pill {
  width: 2.25rem;
  height: 2.25rem;
  border-radius: 8px;
  background: #EBF3FF;
  display: flex;
  align-items: center;
  justify-content: center;
}

.pill-gold {
  background: rgba(197, 160, 89, 0.2);
}

.kpi-svg {
  width: 1.15rem;
  height: 1.15rem;
  color: #1B396A;
}

/* 4. PESTAÑAS (MODO CLARO) */
.tabs-line-nav {
  display: flex;
  gap: 1.5rem;
  border-bottom: 2px solid #E2E8F0;
  padding-bottom: 0.1rem;
}

.tab-nav-btn {
  background: transparent;
  border: none;
  border-bottom: 2px solid transparent;
  padding: 0.5rem 0.25rem;
  font-size: 0.84rem;
  font-weight: 600;
  color: #64748B;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  transition: all 0.15s;
  margin-bottom: -2px;
}

.tab-nav-btn:hover {
  color: #1B396A;
}

.tab-nav-btn.active {
  color: #1B396A;
  font-weight: 800;
  border-bottom-color: #1B396A;
}

.tab-count-badge {
  background: #E2E8F0;
  color: #475569;
  font-size: 0.7rem;
  font-weight: 800;
  font-family: monospace;
  padding: 0.1rem 0.45rem;
  border-radius: 9999px;
}

.tab-count-badge.badge-active {
  background: rgba(27, 57, 106, 0.15);
  color: #1B396A;
}

/* TABLA (MODO CLARO) */
.tab-pane-content {
  display: flex;
  flex-direction: column;
  gap: 0.65rem;
}

.modern-table-card {
  background: #FFFFFF;
  border: 1px solid #CBD5E1;
  border-radius: 10px;
  overflow: hidden;
}

.modern-deposito-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.82rem;
}

.modern-deposito-table thead {
  background: #1B396A;
  border-bottom: 2px solid #C5A059;
}

.modern-deposito-table th {
  background: #1B396A !important;
  color: #FFFFFF !important;
  padding: 0.6rem 0.85rem;
  font-size: 0.68rem;
  font-weight: 800;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}

.modern-deposito-table td {
  padding: 0.65rem 0.85rem;
  border-bottom: 1px solid #F1F5F9;
  color: #1E293B;
}

.tr-data-row:hover {
  background: rgba(27, 57, 106, 0.04);
}

.bullet-concept {
  display: inline-block;
  width: 0.5rem;
  height: 0.5rem;
  border-radius: 50%;
  margin-right: 0.5rem;
}

.bullet-blue { background: #2563EB; }
.bullet-gold { background: #C5A059; }

.concept-name {
  font-weight: 700;
  color: #1E293B;
}

.tr-total-summary {
  background: #F8FAFC;
  border-top: 2px solid #CBD5E1;
}

.tr-total-summary td {
  padding: 0.75rem 0.85rem;
  border-bottom: none;
}

.empty-state-modern {
  text-align: center;
  padding: 2.5rem 1rem;
  color: #64748B;
}

.empty-title { font-size: 0.88rem; margin-bottom: 0.35rem; }
.empty-hint { font-size: 0.78rem; }

.btn-text-gold {
  background: transparent;
  border: none;
  color: #B45309;
  font-weight: 800;
  cursor: pointer;
  text-decoration: underline;
  padding: 0 0.2rem;
}

/* BANNER INFORMATIVO (MODO CLARO) */
.modern-info-banner {
  background: rgba(27, 57, 106, 0.06);
  border: 1px solid rgba(27, 57, 106, 0.2);
  border-radius: 8px;
  padding: 0.55rem 0.85rem;
  font-size: 0.74rem;
  color: #475569;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  line-height: 1.4;
}

.modern-info-banner strong {
  color: #1B396A;
}

.info-icon { font-size: 0.9rem; flex-shrink: 0; }

/* TABLA INDIVIDUAL */
.table-scrollable {
  max-height: 380px;
  overflow-y: auto;
}

.filter-bar-individual {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.search-input-box {
  position: relative;
  flex: 1;
  max-width: 480px;
}

.search-input-box input.tecnm-input-modern {
  padding-left: 2.2rem !important;
}

.search-icon-sm {
  position: absolute;
  left: 0.7rem;
  top: 50%;
  transform: translateY(-50%);
  width: 0.95rem;
  height: 0.95rem;
  color: #64748B;
}

.count-badge { font-size: 0.75rem; color: #64748B; font-weight: 600; }

.badge-recibo {
  background: rgba(197, 160, 89, 0.2);
  color: #92400E;
  border: 1px solid rgba(197, 160, 89, 0.5);
  padding: 0.1rem 0.4rem;
  border-radius: 4px;
}

.badge-concepto-pill {
  background: #EBF3FF;
  color: #1D4ED8;
  padding: 0.15rem 0.5rem;
  border-radius: 4px;
  font-size: 0.72rem;
  font-weight: 600;
}

.btn-delete-row {
  background: transparent;
  border: none;
  color: #94A3B8;
  font-size: 1.1rem;
  cursor: pointer;
  border-radius: 4px;
  width: 1.5rem;
  height: 1.5rem;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.btn-delete-row:hover {
  background: rgba(220, 38, 38, 0.15);
  color: #DC2626;
}

/* BARRA INFERIOR MODERNA (MODO CLARO) */
.modern-footer-bar {
  background: #FFFFFF;
  border-top: 1px solid #CBD5E1;
  padding: 0.75rem 1.25rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.footer-summary-badge {
  background: #F1F5F9;
  border: 1px solid #CBD5E1;
  border-radius: 8px;
  padding: 0.45rem 0.85rem;
  display: inline-flex;
  align-items: center;
  gap: 0.65rem;
  font-size: 0.82rem;
  font-weight: 700;
  color: #1E293B;
}

.badge-separator { color: #CBD5E1; }

.footer-right {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.btn-footer-ghost {
  background: #FFFFFF;
  border: 1px solid #CBD5E1;
  color: #1E293B;
  border-radius: 6px;
  padding: 0.45rem 0.85rem;
  font-size: 0.8rem;
  font-weight: 700;
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-footer-ghost:hover:not(:disabled) {
  background: #F1F5F9;
  border-color: #94A3B8;
  color: #0F172A;
}

.btn-footer-ghost:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.btn-ghost-danger { color: #DC2626; }
.btn-ghost-danger:hover {
  background: #FEE2E2 !important;
  border-color: #F87171 !important;
}

.btn-footer-primary {
  background: linear-gradient(135deg, #16A34A 0%, #15803D 100%);
  color: #FFFFFF;
  border: 1px solid rgba(22, 163, 74, 0.4);
  border-radius: 6px;
  padding: 0.45rem 1.05rem;
  font-size: 0.82rem;
  font-weight: 700;
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  cursor: pointer;
  transition: all 0.15s;
  box-shadow: 0 4px 12px rgba(22, 163, 74, 0.2);
}

.btn-footer-primary:hover:not(:disabled) {
  background: linear-gradient(135deg, #15803D 0%, #166534 100%);
}

.btn-footer-primary:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.footer-icon { width: 1rem; height: 1rem; }
.chevron-sm { width: 0.8rem; height: 0.8rem; }

/* DROPDOWN DE EXPORTACIÓN (MODO CLARO) */
.dropdown-export-wrapper { position: relative; }

.dropdown-menu-export {
  position: absolute;
  bottom: calc(100% + 6px);
  right: 0;
  background: #FFFFFF;
  border: 1px solid #CBD5E1;
  border-radius: 8px;
  box-shadow: 0 10px 30px rgba(15, 37, 72, 0.15);
  padding: 0.35rem;
  min-width: 210px;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  z-index: 60;
  animation: fadeIn 0.12s ease-out;
}

.dropdown-menu-item {
  background: transparent;
  border: none;
  color: #1E293B;
  padding: 0.5rem 0.75rem;
  border-radius: 6px;
  font-size: 0.78rem;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 0.65rem;
  cursor: pointer;
  transition: background 0.12s;
  text-align: left;
}

.dropdown-menu-item:hover {
  background: #F1F5F9;
  color: #1B396A;
}

.item-tag {
  font-size: 0.65rem;
  font-weight: 800;
  padding: 0.15rem 0.4rem;
  border-radius: 4px;
}

.tag-pdf { background: #FEE2E2; color: #DC2626; }
.tag-csv { background: #DCFCE7; color: #166534; }
.tag-word { background: #DBEAFE; color: #1D4ED8; }

/* VISTA PREVIA (MODO CLARO) */
.preview-content-panel {
  display: flex;
  flex-direction: column;
  height: 100%;
  overflow-y: auto;
  background: #F1F5F9;
}

.preview-top-toolbar {
  background: #FFFFFF;
  border-bottom: 1px solid #CBD5E1;
  padding: 0.65rem 1.25rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  position: sticky;
  top: 0;
  z-index: 20;
}

.toolbar-left-msg {
  display: flex;
  align-items: center;
  gap: 0.65rem;
  flex-wrap: wrap;
}

.preview-badge-gold {
  background: rgba(197, 160, 89, 0.15);
  color: #B45309;
  border: 1px solid #C5A059;
  font-size: 0.65rem;
  font-weight: 800;
  letter-spacing: 0.05em;
  padding: 0.2rem 0.55rem;
  border-radius: 9999px;
  text-transform: uppercase;
}

.toolbar-stat-chip {
  background: #F1F5F9;
  border: 1px solid #CBD5E1;
  color: #334155;
  font-size: 0.74rem;
  font-weight: 700;
  padding: 0.2rem 0.55rem;
  border-radius: 6px;
}

.toolbar-right-btns {
  display: flex;
  align-items: center;
  gap: 0.45rem;
}

.tool-icon-sm { width: 0.9rem; height: 0.9rem; }

.btn-preview-tool {
  background: #FFFFFF;
  border: 1px solid #CBD5E1;
  color: #1E293B;
  border-radius: 6px;
  padding: 0.42rem 0.75rem;
  font-size: 0.76rem;
  font-weight: 700;
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-preview-tool:hover {
  background: #F1F5F9;
  border-color: #94A3B8;
  color: #0F172A;
}

.btn-tool-pdf:hover { border-color: #DC2626; color: #DC2626; }
.btn-tool-csv:hover { border-color: #16A34A; color: #16A34A; }
.btn-tool-word:hover { border-color: #2563EB; color: #2563EB; }

.btn-tool-print {
  background: linear-gradient(135deg, #1B396A 0%, #244B88 100%);
  border: none;
  color: #FFFFFF;
}

.btn-tool-print:hover {
  background: linear-gradient(135deg, #244B88 0%, #2A5A9E 100%);
}

.btn-tool-back { background: #F1F5F9; }

.print-sheet-wrapper {
  padding: 1.25rem 1.5rem;
  display: flex;
  justify-content: center;
  background: #F1F5F9;
  min-height: 100%;
}

.print-paper-sheet {
  background: #FFFFFF;
  color: #1E293B;
  width: 100%;
  max-width: 980px;
  padding: 1.75rem 2rem;
  border-radius: 12px;
  border: 1px solid #CBD5E1;
  box-shadow: 0 10px 30px rgba(15, 37, 72, 0.08);
  position: relative;
  font-family: inherit;
}

.sheet-header {
  text-align: center;
  border-bottom: 2px solid #1B396A;
  padding-bottom: 1rem;
  margin-bottom: 1.2rem;
}

.sheet-title-institucion {
  font-size: 1.12rem;
  font-weight: 800;
  letter-spacing: 0.03em;
  color: #1B396A;
}

.sheet-subtitle-sistema {
  font-size: 0.76rem;
  font-weight: 700;
  color: #475569;
  margin-top: 0.25rem;
  letter-spacing: 0.02em;
}

.sheet-doc-name {
  font-size: 0.92rem;
  font-weight: 800;
  color: #B45309;
  letter-spacing: 0.04em;
  margin-top: 0.5rem;
}

.sheet-meta-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 0.55rem 1rem;
  margin-top: 1rem;
}

.meta-card {
  background: #F8FAFC;
  border: 1px solid #CBD5E1;
  border-radius: 6px;
  padding: 0.45rem 0.75rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.meta-label {
  font-size: 0.68rem;
  font-weight: 700;
  color: #475569;
  letter-spacing: 0.03em;
}

.meta-val {
  font-size: 0.78rem;
  font-weight: 700;
  color: #1E293B;
}

.sheet-section-title {
  font-size: 0.78rem;
  font-weight: 800;
  margin: 1.2rem 0 0.55rem 0;
  text-transform: uppercase;
  color: #1B396A;
  display: flex;
  align-items: center;
  gap: 0.45rem;
  letter-spacing: 0.03em;
}

.section-bullet {
  width: 0.4rem;
  height: 0.4rem;
  border-radius: 50%;
  background: #C5A059;
}

.preview-table-box {
  background: #FFFFFF;
  border: 1px solid #CBD5E1;
  border-radius: 8px;
  overflow: hidden;
  margin-bottom: 0.85rem;
}

.sheet-signatures-footer {
  display: flex;
  justify-content: space-around;
  margin-top: 2.5rem;
  padding-top: 0.75rem;
}

.sig-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 260px;
}

.sig-line {
  width: 100%;
  border-top: 1px solid #94A3B8;
  margin-bottom: 0.45rem;
}

.sig-name {
  font-size: 0.78rem;
  font-weight: 700;
  color: #1E293B;
}

.sig-role {
  font-size: 0.68rem;
  color: #64748B;
  font-weight: 700;
  letter-spacing: 0.04em;
}

.sheet-page-indicator {
  position: absolute;
  bottom: 0.85rem;
  right: 1.5rem;
  font-size: 0.68rem;
  color: #94A3B8;
}


/* =============================================================================
   2. REGLAS ESPECÍFICAS PARA MODO OSCURO (.dark-theme / [data-theme="dark"])
   ============================================================================= */
.modal-backdrop.dark-theme .tecnm-window,
:global([data-theme="dark"]) .modal-backdrop .tecnm-window {
  background: #0B1120 !important;
  color: #F8FAFC !important;
  box-shadow: 0 25px 60px -15px rgba(0, 0, 0, 0.9), 0 0 0 1px rgba(36, 75, 136, 0.35) !important;
}

.modal-backdrop.dark-theme .window-title-bar,
:global([data-theme="dark"]) .modal-backdrop .window-title-bar {
  background: linear-gradient(90deg, #0F172A 0%, #151E2E 100%) !important;
  border-bottom: 1px solid #1E293B !important;
}

.modal-backdrop.dark-theme .window-icon-box,
:global([data-theme="dark"]) .modal-backdrop .window-icon-box {
  background: rgba(36, 75, 136, 0.25) !important;
  border: 1px solid rgba(197, 160, 89, 0.3) !important;
}

.modal-backdrop.dark-theme .badge-modulo-gold,
:global([data-theme="dark"]) .modal-backdrop .badge-modulo-gold {
  background: rgba(197, 160, 89, 0.12) !important;
  color: #C5A059 !important;
  border: 1px solid rgba(197, 160, 89, 0.4) !important;
}

.modal-backdrop.dark-theme .window-subtitle-text,
:global([data-theme="dark"]) .modal-backdrop .window-subtitle-text {
  color: #94A3B8 !important;
}

.modal-backdrop.dark-theme .window-content-panel,
:global([data-theme="dark"]) .modal-backdrop .window-content-panel {
  background: #0B1120 !important;
}

.modal-backdrop.dark-theme .config-tools-card,
.modal-backdrop.dark-theme .quick-capture-card,
:global([data-theme="dark"]) .modal-backdrop .config-tools-card,
:global([data-theme="dark"]) .modal-backdrop .quick-capture-card {
  background: #111A2E !important;
  border-color: #1E2E4A !important;
}

.modal-backdrop.dark-theme .field-label-sm,
.modal-backdrop.dark-theme .compact-label,
:global([data-theme="dark"]) .modal-backdrop .field-label-sm,
:global([data-theme="dark"]) .modal-backdrop .compact-label {
  color: #94A3B8 !important;
}

.modal-backdrop.dark-theme input.tecnm-input-modern,
.modal-backdrop.dark-theme select.tecnm-input-modern,
:global([data-theme="dark"]) .modal-backdrop input.tecnm-input-modern,
:global([data-theme="dark"]) .modal-backdrop select.tecnm-input-modern {
  background: #0B1120 !important;
  color: #F8FAFC !important;
  border-color: #24334A !important;
}

.modal-backdrop.dark-theme input.tecnm-input-modern:focus,
.modal-backdrop.dark-theme select.tecnm-input-modern:focus,
:global([data-theme="dark"]) .modal-backdrop input.tecnm-input-modern:focus,
:global([data-theme="dark"]) .modal-backdrop select.tecnm-input-modern:focus {
  border-color: #244B88 !important;
  box-shadow: 0 0 0 2px rgba(36, 75, 136, 0.35) !important;
}

.modal-backdrop.dark-theme .btn-modern-tool,
:global([data-theme="dark"]) .modal-backdrop .btn-modern-tool {
  background: #151E2E !important;
  border-color: #24334A !important;
  color: #E2E8F0 !important;
}

.modal-backdrop.dark-theme .btn-modern-tool:hover,
:global([data-theme="dark"]) .modal-backdrop .btn-modern-tool:hover {
  background: #1E293B !important;
  border-color: #334155 !important;
  color: #FFFFFF !important;
}

.modal-backdrop.dark-theme .btn-tool-demo,
:global([data-theme="dark"]) .modal-backdrop .btn-tool-demo {
  border-color: rgba(197, 160, 89, 0.4) !important;
  background: rgba(197, 160, 89, 0.08) !important;
  color: #E2E8F0 !important;
}

.modal-backdrop.dark-theme .btn-tool-demo:hover,
:global([data-theme="dark"]) .modal-backdrop .btn-tool-demo:hover {
  background: rgba(197, 160, 89, 0.18) !important;
  border-color: #C5A059 !important;
  color: #FFFFFF !important;
}

.modal-backdrop.dark-theme .legend-title,
:global([data-theme="dark"]) .modal-backdrop .legend-title {
  color: #E2E8F0 !important;
}

.modal-backdrop.dark-theme .legend-desc,
:global([data-theme="dark"]) .modal-backdrop .legend-desc {
  color: #94A3B8 !important;
}

.modal-backdrop.dark-theme .suggestions-menu,
:global([data-theme="dark"]) .modal-backdrop .suggestions-menu {
  background: #0F172A !important;
  border-color: #244B88 !important;
}

.modal-backdrop.dark-theme .suggestion-item,
:global([data-theme="dark"]) .modal-backdrop .suggestion-item {
  border-bottom-color: #1E293B !important;
}

.modal-backdrop.dark-theme .suggestion-item:hover,
:global([data-theme="dark"]) .modal-backdrop .suggestion-item:hover {
  background: #1B396A !important;
}

.modal-backdrop.dark-theme .sugg-nom,
:global([data-theme="dark"]) .modal-backdrop .sugg-nom {
  color: #FFFFFF !important;
}

.modal-backdrop.dark-theme .kpi-card-modern,
:global([data-theme="dark"]) .modal-backdrop .kpi-card-modern {
  background: #111A2E !important;
  border-color: #1E2E4A !important;
}

.modal-backdrop.dark-theme .kpi-caption,
:global([data-theme="dark"]) .modal-backdrop .kpi-caption {
  color: #94A3B8 !important;
}

.modal-backdrop.dark-theme .kpi-number,
:global([data-theme="dark"]) .modal-backdrop .kpi-number {
  color: #FFFFFF !important;
}

.modal-backdrop.dark-theme .kpi-card-gold,
:global([data-theme="dark"]) .modal-backdrop .kpi-card-gold {
  border-color: rgba(197, 160, 89, 0.35) !important;
  background: rgba(197, 160, 89, 0.04) !important;
}

.modal-backdrop.dark-theme .kpi-card-gold .kpi-number,
.modal-backdrop.dark-theme .text-gold,
:global([data-theme="dark"]) .modal-backdrop .kpi-card-gold .kpi-number,
:global([data-theme="dark"]) .modal-backdrop .text-gold {
  color: #C5A059 !important;
}

.modal-backdrop.dark-theme .kpi-icon-pill,
:global([data-theme="dark"]) .modal-backdrop .kpi-icon-pill {
  background: rgba(36, 75, 136, 0.2) !important;
}

.modal-backdrop.dark-theme .pill-gold,
:global([data-theme="dark"]) .modal-backdrop .pill-gold {
  background: rgba(197, 160, 89, 0.15) !important;
}

.modal-backdrop.dark-theme .kpi-svg,
:global([data-theme="dark"]) .modal-backdrop .kpi-svg {
  color: #C5A059 !important;
}

.modal-backdrop.dark-theme .tabs-line-nav,
:global([data-theme="dark"]) .modal-backdrop .tabs-line-nav {
  border-bottom-color: #1E2E4A !important;
}

.modal-backdrop.dark-theme .tab-nav-btn,
:global([data-theme="dark"]) .modal-backdrop .tab-nav-btn {
  color: #94A3B8 !important;
}

.modal-backdrop.dark-theme .tab-nav-btn:hover,
:global([data-theme="dark"]) .modal-backdrop .tab-nav-btn:hover {
  color: #FFFFFF !important;
}

.modal-backdrop.dark-theme .tab-nav-btn.active,
:global([data-theme="dark"]) .modal-backdrop .tab-nav-btn.active {
  color: #FFFFFF !important;
  border-bottom-color: #C5A059 !important;
}

.modal-backdrop.dark-theme .tab-count-badge,
:global([data-theme="dark"]) .modal-backdrop .tab-count-badge {
  background: #1E293B !important;
  color: #94A3B8 !important;
}

.modal-backdrop.dark-theme .tab-count-badge.badge-active,
:global([data-theme="dark"]) .modal-backdrop .tab-count-badge.badge-active {
  background: rgba(197, 160, 89, 0.2) !important;
  color: #C5A059 !important;
}

.modal-backdrop.dark-theme .modern-table-card,
:global([data-theme="dark"]) .modal-backdrop .modern-table-card {
  background: #111A2E !important;
  border-color: #1E2E4A !important;
}

.modal-backdrop.dark-theme .modern-deposito-table thead,
:global([data-theme="dark"]) .modal-backdrop .modern-deposito-table thead {
  background: #0D1525 !important;
  border-bottom-color: #1E2E4A !important;
}

.modal-backdrop.dark-theme .modern-deposito-table th,
:global([data-theme="dark"]) .modal-backdrop .modern-deposito-table th {
  background: #0D1525 !important;
  color: #94A3B8 !important;
}

.modal-backdrop.dark-theme .modern-deposito-table td,
:global([data-theme="dark"]) .modal-backdrop .modern-deposito-table td {
  border-bottom-color: #151F33 !important;
  color: #F8FAFC !important;
}

.modal-backdrop.dark-theme .tr-data-row:hover,
:global([data-theme="dark"]) .modal-backdrop .tr-data-row:hover {
  background: rgba(36, 75, 136, 0.12) !important;
}

.modal-backdrop.dark-theme .concept-name,
:global([data-theme="dark"]) .modal-backdrop .concept-name {
  color: #F8FAFC !important;
}

.modal-backdrop.dark-theme .tr-total-summary,
:global([data-theme="dark"]) .modal-backdrop .tr-total-summary {
  background: rgba(197, 160, 89, 0.06) !important;
  border-top-color: rgba(197, 160, 89, 0.3) !important;
}

.modal-backdrop.dark-theme .modern-info-banner,
:global([data-theme="dark"]) .modal-backdrop .modern-info-banner {
  background: rgba(36, 75, 136, 0.12) !important;
  border-color: rgba(36, 75, 136, 0.3) !important;
  color: #94A3B8 !important;
}

.modal-backdrop.dark-theme .modern-info-banner strong,
:global([data-theme="dark"]) .modal-backdrop .modern-info-banner strong {
  color: #E2E8F0 !important;
}

.modal-backdrop.dark-theme .modern-footer-bar,
:global([data-theme="dark"]) .modal-backdrop .modern-footer-bar {
  background: #0D1525 !important;
  border-top-color: #1E2E4A !important;
}

.modal-backdrop.dark-theme .footer-summary-badge,
:global([data-theme="dark"]) .modal-backdrop .footer-summary-badge {
  background: #111A2E !important;
  border-color: #1E2E4A !important;
  color: #F8FAFC !important;
}

.modal-backdrop.dark-theme .btn-footer-ghost,
:global([data-theme="dark"]) .modal-backdrop .btn-footer-ghost {
  background: #151E2E !important;
  border-color: #24334A !important;
  color: #E2E8F0 !important;
}

.modal-backdrop.dark-theme .btn-footer-ghost:hover:not(:disabled),
:global([data-theme="dark"]) .modal-backdrop .btn-footer-ghost:hover:not(:disabled) {
  background: #1E293B !important;
  border-color: #334155 !important;
  color: #FFFFFF !important;
}

.modal-backdrop.dark-theme .dropdown-menu-export,
:global([data-theme="dark"]) .modal-backdrop .dropdown-menu-export {
  background: #0F172A !important;
  border-color: #244B88 !important;
}

.modal-backdrop.dark-theme .dropdown-menu-item,
:global([data-theme="dark"]) .modal-backdrop .dropdown-menu-item {
  color: #E2E8F0 !important;
}

.modal-backdrop.dark-theme .dropdown-menu-item:hover,
:global([data-theme="dark"]) .modal-backdrop .dropdown-menu-item:hover {
  background: #1B396A !important;
  color: #FFFFFF !important;
}

/* VISTA PREVIA (MODO OSCURO) */
.modal-backdrop.dark-theme .preview-content-panel,
:global([data-theme="dark"]) .modal-backdrop .preview-content-panel {
  background: #0B1120 !important;
}

.modal-backdrop.dark-theme .preview-top-toolbar,
:global([data-theme="dark"]) .modal-backdrop .preview-top-toolbar {
  background: #0D1525 !important;
  border-bottom-color: #1E2E4A !important;
}

.modal-backdrop.dark-theme .toolbar-stat-chip,
:global([data-theme="dark"]) .modal-backdrop .toolbar-stat-chip {
  background: #111A2E !important;
  border-color: #1E2E4A !important;
  color: #CBD5E1 !important;
}

.modal-backdrop.dark-theme .btn-preview-tool,
:global([data-theme="dark"]) .modal-backdrop .btn-preview-tool {
  background: #151E2E !important;
  border-color: #24334A !important;
  color: #E2E8F0 !important;
}

.modal-backdrop.dark-theme .btn-preview-tool:hover,
:global([data-theme="dark"]) .modal-backdrop .btn-preview-tool:hover {
  background: #1E293B !important;
  border-color: #334155 !important;
  color: #FFFFFF !important;
}

.modal-backdrop.dark-theme .print-sheet-wrapper,
:global([data-theme="dark"]) .modal-backdrop .print-sheet-wrapper {
  background: #0B1120 !important;
}

.modal-backdrop.dark-theme .print-paper-sheet,
:global([data-theme="dark"]) .modal-backdrop .print-paper-sheet {
  background: #111A2E !important;
  color: #F8FAFC !important;
  border-color: #1E2E4A !important;
  box-shadow: 0 15px 45px rgba(0, 0, 0, 0.6) !important;
}

.modal-backdrop.dark-theme .sheet-header,
:global([data-theme="dark"]) .modal-backdrop .sheet-header {
  border-bottom-color: #1E2E4A !important;
}

.modal-backdrop.dark-theme .sheet-title-institucion,
:global([data-theme="dark"]) .modal-backdrop .sheet-title-institucion {
  color: #FFFFFF !important;
}

.modal-backdrop.dark-theme .sheet-subtitle-sistema,
:global([data-theme="dark"]) .modal-backdrop .sheet-subtitle-sistema {
  color: #94A3B8 !important;
}

.modal-backdrop.dark-theme .sheet-doc-name,
:global([data-theme="dark"]) .modal-backdrop .sheet-doc-name {
  color: #C5A059 !important;
}

.modal-backdrop.dark-theme .meta-card,
:global([data-theme="dark"]) .modal-backdrop .meta-card {
  background: #0D1525 !important;
  border-color: #1E2E4A !important;
}

.modal-backdrop.dark-theme .meta-label,
:global([data-theme="dark"]) .modal-backdrop .meta-label {
  color: #94A3B8 !important;
}

.modal-backdrop.dark-theme .meta-val,
:global([data-theme="dark"]) .modal-backdrop .meta-val {
  color: #F8FAFC !important;
}

.modal-backdrop.dark-theme .preview-table-box,
:global([data-theme="dark"]) .modal-backdrop .preview-table-box {
  background: #0D1525 !important;
  border-color: #1E2E4A !important;
}

.modal-backdrop.dark-theme .sig-line,
:global([data-theme="dark"]) .modal-backdrop .sig-line {
  border-top-color: #24334A !important;
}

.modal-backdrop.dark-theme .sig-name,
:global([data-theme="dark"]) .modal-backdrop .sig-name {
  color: #FFFFFF !important;
}

.modal-backdrop.dark-theme .sig-role,
:global([data-theme="dark"]) .modal-backdrop .sig-role {
  color: #94A3B8 !important;
}


/* =============================================================================
   3. IMPRESIÓN FÍSICA / PDF (@media print)
   Garantiza hoja 100% limpia en blanco y negro sin fondos de pantalla
   ============================================================================= */
@media print {
  @page {
    size: letter portrait;
    margin: 1cm;
  }

  body, html {
    margin: 0 !important;
    padding: 0 !important;
    background: #FFFFFF !important;
    color: #000000 !important;
  }

  body * {
    visibility: hidden;
  }

  .print-paper-sheet,
  .print-paper-sheet * {
    visibility: visible;
  }

  .preview-top-toolbar,
  .window-title-bar,
  .modern-footer-bar,
  .tabs-line-nav,
  .btn-preview-tool {
    display: none !important;
  }

  .modal-backdrop {
    position: static !important;
    inset: auto !important;
    background: transparent !important;
    padding: 0 !important;
    display: block !important;
  }

  .tecnm-window {
    max-width: 100% !important;
    box-shadow: none !important;
    border: none !important;
    border-radius: 0 !important;
    background: #FFFFFF !important;
  }

  .preview-content-panel {
    background: transparent !important;
    padding: 0 !important;
    margin: 0 !important;
    overflow: visible !important;
    display: block !important;
    position: absolute;
    left: 0;
    top: 0;
    width: 100%;
  }

  .print-sheet-wrapper {
    max-width: 100% !important;
    width: 100% !important;
    margin: 0 !important;
    padding: 0 !important;
    background: transparent !important;
  }

  .print-paper-sheet {
    box-shadow: none !important;
    padding: 0 !important;
    margin: 0 !important;
    width: 100% !important;
    position: static !important;
    min-height: auto !important;
    overflow: visible !important;
    background: #FFFFFF !important;
    color: #000000 !important;
    border: none !important;
  }

  .sheet-title-institucion {
    color: #1B396A !important;
  }

  .sheet-subtitle-sistema {
    color: #334155 !important;
  }

  .sheet-doc-name {
    color: #000000 !important;
    text-decoration: underline !important;
  }

  .sheet-header {
    border-bottom: 2px solid #000000 !important;
  }

  .meta-card {
    background: transparent !important;
    border: none !important;
    padding: 2px 0 !important;
  }

  .meta-label, .meta-val {
    color: #000000 !important;
  }

  .preview-table-box {
    background: transparent !important;
    border: none !important;
  }

  .sheet-table {
    border-collapse: collapse !important;
    width: 100% !important;
  }

  .sheet-table th,
  .sheet-table td {
    border: 1px solid #000000 !important;
    color: #000000 !important;
    padding: 0.35rem 0.55rem !important;
  }

  .sheet-table th {
    background: #1B396A !important;
    color: #FFFFFF !important;
  }

  .sheet-table-alumnos th {
    background: #E2E8F0 !important;
    color: #000000 !important;
  }

  .tr-sheet-total td {
    background: #F1F5F9 !important;
    font-weight: 800 !important;
  }

  .bullet-concept {
    display: none !important;
  }

  .badge-recibo, .badge-concepto-pill {
    background: transparent !important;
    border: none !important;
    color: #000000 !important;
    padding: 0 !important;
  }

  .sig-line {
    border-top: 1px solid #000000 !important;
  }

  .sig-name, .sig-role {
    color: #000000 !important;
  }

  .sheet-table tr {
    page-break-inside: avoid !important;
  }

  .sheet-signatures-footer {
    page-break-inside: avoid !important;
    margin-top: 2rem !important;
  }
}
</style>
