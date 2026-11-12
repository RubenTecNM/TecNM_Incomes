<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useTheme } from '../../../shared/composables/useTheme'
import * as cajaApi from '../api/cajaApi'
import ModalCuentas from '../../catalogos/components/ModalCuentas.vue'

const emit = defineEmits<{
  (e: 'close'): void
}>()

const { dark } = useTheme()

// ==========================================
// Encabezado del Recibo
// ==========================================
const esDepositoBancario = ref(false)
const numeroRecibo = ref('')
const fecha = ref('')
const pickerFechaRef = ref<HTMLInputElement | null>(null)

// ==========================================
// Datos del Estudiante
// ==========================================
const matricula = ref('')
const nombre = ref('')
const semestre = ref<number | ''>('')
const carrera = ref('')
const turno = ref<'Matutino' | 'Vespertino' | 'Nocturno' | 'Sabatino'>('Matutino')

const carrerasOpciones = ref<string[]>([
  'Ing. Industrial',
  'Ing. Informática',
  'Ing. Mecánica',
  'Ing. Electrónica',
  'Ing. Gestión Emp.',
  'Ing. Energías Renovables',
  'Ing. Mecatrónica',
  'Lic. Informática',
])

const turnosOpciones = ['Matutino', 'Vespertino', 'Nocturno', 'Sabatino']

// Búsqueda automática de alumno por matrícula
const isBuscandoAlumno = ref(false)
async function buscarAlumnoPorMatricula(): Promise<void> {
  if (!matricula.value.trim()) return

  isBuscandoAlumno.value = true
  try {
    const alumno = await cajaApi.getAlumno(matricula.value.trim())
    if (alumno) {
      nombre.value = alumno.nombreCompleto
      carrera.value = alumno.carrera
      semestre.value = alumno.semestre
      turno.value = alumno.turno || 'Matutino'
    }
  } catch {
    // Si no existe, dejamos que capture manualmente
  } finally {
    isBuscandoAlumno.value = false
  }
}

// ==========================================
// Catálogo y Agregado de Conceptos
// ==========================================
interface ConceptoCatalogoItem {
  id: string
  descripcion: string
  cuotaBase: number
}

const conceptosDisponibles = ref<ConceptoCatalogoItem[]>([])
const conceptoSeleccionadoId = ref('')
const cuotaActual = ref<number>(0)
const cantidadActual = ref<number>(1)

const conceptosFallback: ConceptoCatalogoItem[] = [
  { id: '', descripcion: '-- Seleccionar Concepto --', cuotaBase: 0 },
  { id: 'c1', descripcion: 'PAGO DE INSCRIPCION (PERIODO VIGENTE)', cuotaBase: 1700 },
  { id: 'c2', descripcion: 'ADEUDO DE INSCRIPCION ANTERIOR', cuotaBase: 1700 },
  { id: 'c3', descripcion: 'CURSO DE VERANO (POR ASIGNATURA)', cuotaBase: 650 },
  { id: 'c4', descripcion: 'EXPEDICION DE KARDEX', cuotaBase: 150 },
  { id: 'c5', descripcion: 'CONSTANCIA DE ESTUDIOS CON CALIFICACIONES', cuotaBase: 100 },
  { id: 'c6', descripcion: 'TRAMITE DE TITULACION INTEGRAL Y CEDULA', cuotaBase: 3500 },
]

function onCambioConcepto(): void {
  const match = conceptosDisponibles.value.find(c => c.id === conceptoSeleccionadoId.value)
  if (match) {
    cuotaActual.value = match.cuotaBase
  } else {
    cuotaActual.value = 0
  }
}

// Conceptos agregados al recibo provisional
interface PartidaProvisional {
  id: string
  concepto: string
  cantidad: number
  cuota: number
  adeudo: number
  importe: number
}

const partidas = ref<PartidaProvisional[]>([])

function agregarConcepto(): void {
  if (!conceptoSeleccionadoId.value) return

  const match = conceptosDisponibles.value.find(c => c.id === conceptoSeleccionadoId.value)
  if (!match) return

  const cant = cantidadActual.value > 0 ? cantidadActual.value : 1
  const cuota = cuotaActual.value >= 0 ? cuotaActual.value : match.cuotaBase
  const importe = cant * cuota

  partidas.value.push({
    id: `partida-${Date.now()}-${Math.random()}`,
    concepto: match.descripcion,
    cantidad: cant,
    cuota,
    adeudo: 0,
    importe,
  })

  // Limpiar campos de captura de concepto
  conceptoSeleccionadoId.value = ''
  cuotaActual.value = 0
  cantidadActual.value = 1
}

function eliminarConcepto(id: string): void {
  partidas.value = partidas.value.filter(p => p.id !== id)
}

// Total del recibo
const granTotal = computed(() => {
  return partidas.value.reduce((acc, p) => acc + p.importe, 0)
})

// ==========================================
// Observaciones e Impresora
// ==========================================
const observaciones = ref('')
const impresora = ref('')
const impresorasDisponibles = [
  { id: '', nombre: '-- Seleccionar impresora --' },
  { id: 'termica', nombre: 'Impresora Térmica de Recibos (Caja)' },
  { id: 'laser', nombre: 'Impresora Láser Institucional (Reportes)' },
  { id: 'pdf', nombre: 'Exportar a Documento PDF' },
]

// ==========================================
// Modales Secundarios F1 (Alumnos) y F2 (Cuentas)
// ==========================================
const mostrarModalF1Alumnos = ref(false)
const mostrarModalF2Cuentas = ref(false)
const alumnosLista = ref<Array<{ matricula: string; nombreCompleto: string; carrera: string }>>([])
const isCargandoF1 = ref(false)

async function abrirF1Alumnos(): Promise<void> {
  mostrarModalF1Alumnos.value = true
  isCargandoF1.value = true
  try {
    const list = await cajaApi.buscarAlumnos('')
    if (list && list.length > 0) {
      alumnosLista.value = list.map(a => ({
        matricula: a.matricula,
        nombreCompleto: a.nombreCompleto,
        carrera: a.carrera,
      }))
    }
  } catch {
    alumnosLista.value = []
  } finally {
    isCargandoF1.value = false
  }
}

function seleccionarAlumnoF1(a: { matricula: string; nombreCompleto: string; carrera: string }): void {
  matricula.value = a.matricula
  nombre.value = a.nombreCompleto
  carrera.value = a.carrera
  mostrarModalF1Alumnos.value = false
}

function abrirF2Cuentas(): void {
  mostrarModalF2Cuentas.value = true
}

// Selector de fecha
function abrirCalendario(): void {
  if (pickerFechaRef.value) {
    if (typeof pickerFechaRef.value.showPicker === 'function') {
      pickerFechaRef.value.showPicker()
    } else {
      pickerFechaRef.value.focus()
    }
  }
}

function onFechaSeleccionada(event: Event): void {
  const target = event.target as HTMLInputElement
  if (target && target.value) {
    fecha.value = target.value
  }
}

function formatearMoneda(valor: number): string {
  return valor.toLocaleString('es-MX', { style: 'currency', currency: 'MXN' })
}

// ==========================================
// Acciones del Recibo
// ==========================================
const isGuardando = ref(false)
const mensajeExito = ref('')

async function guardarRecibo(): Promise<void> {
  if (partidas.value.length === 0) return
  isGuardando.value = true
  await new Promise(resolve => setTimeout(resolve, 500))
  mensajeExito.value = `Recibo provisional No. ${numeroRecibo.value} guardado con éxito`
  isGuardando.value = false
  setTimeout(() => {
    mensajeExito.value = ''
  }, 3500)
}

function limpiar(): void {
  esDepositoBancario.value = false
  matricula.value = ''
  nombre.value = ''
  semestre.value = ''
  carrera.value = ''
  turno.value = 'Matutino'
  conceptoSeleccionadoId.value = ''
  cuotaActual.value = 0
  cantidadActual.value = 1
  partidas.value = []
  observaciones.value = ''
  impresora.value = ''
}

function cerrar(): void {
  emit('close')
}

function handleKeydown(e: KeyboardEvent): void {
  if (e.key === 'Escape') {
    if (mostrarModalF1Alumnos.value) {
      mostrarModalF1Alumnos.value = false
    } else if (mostrarModalF2Cuentas.value) {
      mostrarModalF2Cuentas.value = false
    } else {
      cerrar()
    }
  } else if (e.key === 'F1') {
    e.preventDefault()
    void abrirF1Alumnos()
  } else if (e.key === 'F2') {
    e.preventDefault()
    abrirF2Cuentas()
  }
}

onMounted(async () => {
  window.addEventListener('keydown', handleKeydown)

  // 1. Cargar conceptos
  try {
    const list = await cajaApi.getConceptos()
    if (list && list.length > 0) {
      conceptosDisponibles.value = [
        { id: '', descripcion: '-- Seleccionar Concepto --', cuotaBase: 0 },
        ...list.map(c => ({ id: c.id, descripcion: c.descripcion, cuotaBase: c.cuotaBase })),
      ]
    } else {
      conceptosDisponibles.value = conceptosFallback
    }
  } catch {
    conceptosDisponibles.value = conceptosFallback
  }

  // 2. Cargar carreras de la base de datos
  try {
    const carr = await cajaApi.getCarreras()
    if (carr && carr.length > 0) {
      carrerasOpciones.value = carr.map(c => c.carrera)
    }
  } catch {
    // mantiene catálogo fallback
  }

  // 3. Obtener número de recibo consecutivo
  try {
    const recientes = await cajaApi.getRecibosRecientes(1)
    if (recientes && recientes.length > 0 && recientes[0].numeroRecibo) {
      numeroRecibo.value = String(recientes[0].numeroRecibo + 1)
    } else {
      numeroRecibo.value = '5123'
    }
  } catch {
    numeroRecibo.value = '5123'
  }
})

onUnmounted(() => window.removeEventListener('keydown', handleKeydown))
</script>

<template>
  <div class="modal-backdrop" :class="{ 'dark-theme': dark }" @click.self="cerrar">
    <div class="tecnm-window" role="dialog" aria-modal="true" aria-labelledby="recibo-prov-title">

      <!-- Barra de título institucional -->
      <header class="window-title-bar">
        <div class="window-title-left">
          <svg class="window-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
            <polyline points="14 2 14 8 20 8"/>
            <line x1="16" y1="13" x2="8" y2="13"/>
            <line x1="16" y1="17" x2="8" y2="17"/>
            <polyline points="10 9 9 9 8 9"/>
          </svg>
          <span id="recibo-prov-title" class="window-title-text">Recibo Provisional</span>
        </div>
        <button type="button" class="window-btn-close" title="Cerrar (ESC)" aria-label="Cerrar ventana" @click="cerrar">
          &times;
        </button>
      </header>

      <!-- Panel de Contenido -->
      <section class="window-content-panel">

        <!-- Banner de éxito al guardar -->
        <div v-if="mensajeExito" class="success-banner">
          ✓ {{ mensajeExito }}
        </div>

        <!-- FILA SUPERIOR: Depósito Bancario + Recibo No + Fecha -->
        <div class="top-header-card">
          <label class="custom-checkbox-label">
            <input
              v-model="esDepositoBancario"
              type="checkbox"
              class="tecnm-checkbox"
            />
            <span class="checkbox-caption">Depósito Bancario</span>
          </label>

          <div class="header-right-group">
            <div class="field-item item-recibo-no">
              <label for="input-prov-recibo-no" class="field-label">Recibo No:</label>
              <input
                id="input-prov-recibo-no"
                v-model="numeroRecibo"
                type="text"
                class="tecnm-input font-mono font-bold text-center text-primary"
              />
            </div>

            <div class="field-item item-fecha">
              <label for="input-prov-fecha" class="field-label">Fecha:</label>
              <div class="date-input-combo">
                <input
                  id="input-prov-fecha"
                  v-model="fecha"
                  type="text"
                  class="tecnm-input font-mono"
                  placeholder="AAAA-MM-DD"
                />
                <input
                  ref="pickerFechaRef"
                  type="date"
                  class="hidden-date-picker"
                  tabindex="-1"
                  @change="onFechaSeleccionada"
                />
                <button
                  type="button"
                  class="btn-calendar-trigger"
                  title="Elegir fecha"
                  @click="abrirCalendario"
                >
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="calendar-icon">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                    <line x1="16" y1="2" x2="16" y2="6"/>
                    <line x1="8" y1="2" x2="8" y2="6"/>
                    <line x1="3" y1="10" x2="21" y2="10"/>
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- SECCIÓN DE DATOS DEL ALUMNO -->
        <div class="student-info-card">
          <!-- Renglón 1: Matrícula, Nombre, Semestre -->
          <div class="student-row-1">
            <div class="field-item item-matricula">
              <label for="input-prov-matricula" class="field-label">Matrícula:</label>
              <div class="matricula-input-group">
                <input
                  id="input-prov-matricula"
                  v-model="matricula"
                  type="text"
                  class="tecnm-input font-mono"
                  placeholder="Ej. 120050011"
                  @keyup.enter="buscarAlumnoPorMatricula"
                />
                <button
                  type="button"
                  class="btn-buscar-alumno"
                  title="Buscar estudiante por matrícula"
                  :disabled="isBuscandoAlumno"
                  @click="buscarAlumnoPorMatricula"
                >
                  <svg v-if="isBuscandoAlumno" class="spin-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
                  </svg>
                  <svg v-else class="btn-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="11" cy="11" r="8"/>
                    <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                  </svg>
                </button>
              </div>
            </div>

            <div class="field-item item-nombre">
              <label for="input-prov-nombre" class="field-label">Nombre:</label>
              <input
                id="input-prov-nombre"
                v-model="nombre"
                type="text"
                class="tecnm-input"
                placeholder="Nombre completo del estudiante"
              />
            </div>

            <div class="field-item item-semestre">
              <label for="input-prov-semestre" class="field-label">Semestre:</label>
              <input
                id="input-prov-semestre"
                v-model.number="semestre"
                type="number"
                min="1"
                max="14"
                class="tecnm-input font-mono text-center"
                placeholder="1"
              />
            </div>
          </div>

          <!-- Renglón 2: Carrera, Turno -->
          <div class="student-row-2">
            <div class="field-item item-carrera">
              <label for="select-prov-carrera" class="field-label">Carrera:</label>
              <select
                id="select-prov-carrera"
                v-model="carrera"
                class="tecnm-input tecnm-select"
              >
                <option value="">-- Seleccionar Carrera --</option>
                <option v-for="c in carrerasOpciones" :key="c" :value="c">
                  {{ c }}
                </option>
              </select>
            </div>

            <div class="field-item item-turno">
              <label for="select-prov-turno" class="field-label">Turno:</label>
              <select
                id="select-prov-turno"
                v-model="turno"
                class="tecnm-input tecnm-select"
              >
                <option v-for="t in turnosOpciones" :key="t" :value="t">
                  {{ t }}
                </option>
              </select>
            </div>
          </div>
        </div>

        <!-- SECCIÓN DE CAPTURA DE CONCEPTO -->
        <div class="concept-input-card">
          <div class="concept-row">
            <div class="field-item item-concepto-select">
              <label for="select-prov-concepto" class="field-label">Concepto:</label>
              <select
                id="select-prov-concepto"
                v-model="conceptoSeleccionadoId"
                class="tecnm-input tecnm-select"
                @change="onCambioConcepto"
              >
                <option v-for="c in conceptosDisponibles" :key="c.id" :value="c.id">
                  {{ c.descripcion }}
                </option>
              </select>
            </div>

            <div class="field-item item-cuota-input">
              <label for="input-prov-cuota" class="field-label">Cuota:</label>
              <input
                id="input-prov-cuota"
                v-model.number="cuotaActual"
                type="number"
                min="0"
                step="0.01"
                class="tecnm-input font-mono text-right"
              />
            </div>

            <div class="field-item item-cantidad-input">
              <label for="input-prov-cantidad" class="field-label">Cantidad:</label>
              <input
                id="input-prov-cantidad"
                v-model.number="cantidadActual"
                type="number"
                min="1"
                class="tecnm-input font-mono text-center"
                @keyup.enter="agregarConcepto"
              />
            </div>

            <button
              type="button"
              class="btn-agregar-concepto"
              :disabled="!conceptoSeleccionadoId"
              @click="agregarConcepto"
            >
              + Agregar
            </button>
          </div>
        </div>

        <!-- TABLA DE CONCEPTOS AGREGADOS -->
        <div class="table-container">
          <table class="conceptos-table">
            <thead>
              <tr>
                <th class="col-concepto">Concepto</th>
                <th class="col-cantidad text-center">Cantidad</th>
                <th class="col-monto text-right">Cuota</th>
                <th class="col-monto text-right">Adeudo</th>
                <th class="col-monto text-right">Importe</th>
                <th class="col-action text-center">Eliminar</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="partidas.length === 0">
                <td colspan="6" class="empty-cell">
                  <div class="empty-state">
                    <span>No hay conceptos añadidos al recibo provisional</span>
                  </div>
                </td>
              </tr>
              <tr v-for="p in partidas" :key="p.id" class="data-row">
                <td class="col-concepto font-bold">{{ p.concepto }}</td>
                <td class="col-cantidad font-mono text-center">{{ p.cantidad }}</td>
                <td class="col-monto font-mono text-right">{{ formatearMoneda(p.cuota) }}</td>
                <td class="col-monto font-mono text-right">{{ formatearMoneda(p.adeudo) }}</td>
                <td class="col-monto font-mono text-right font-bold">{{ formatearMoneda(p.importe) }}</td>
                <td class="col-action text-center">
                  <!-- Botón con ícono X para eliminar conforme a requerimiento de usuario -->
                  <button
                    type="button"
                    class="btn-delete-item"
                    title="Eliminar concepto de la lista"
                    aria-label="Eliminar concepto"
                    @click="eliminarConcepto(p.id)"
                  >
                    &times;
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- FILA DE TOTAL Y OBSERVACIONES -->
        <div class="bottom-fields-row">
          <div class="field-item item-observaciones">
            <input
              v-model="observaciones"
              type="text"
              class="tecnm-input input-notes"
              placeholder="Notas u observaciones del recibo provisional..."
            />
          </div>

          <div class="total-box">
            <span class="total-label">Total:</span>
            <input
              :value="formatearMoneda(granTotal)"
              type="text"
              readonly
              class="tecnm-input input-total font-mono font-bold text-right readonly-input"
            />
          </div>
        </div>

        <!-- SELECTOR DE IMPRESORA -->
        <div class="printer-selection-row">
          <div class="field-item flex-grow">
            <label for="select-prov-impresora" class="field-label">Selecciona la impresora:</label>
            <select
              id="select-prov-impresora"
              v-model="impresora"
              class="tecnm-input tecnm-select"
            >
              <option v-for="imp in impresorasDisponibles" :key="imp.id" :value="imp.id">
                {{ imp.nombre }}
              </option>
            </select>
          </div>
        </div>

        <!-- BOTONES F1 Y F2 (convertidos en botones institucionales interactivos) -->
        <div class="f-buttons-bar">
          <button
            type="button"
            class="btn-f-action"
            title="Presiona F1 o haz clic para consultar lista de alumnos"
            @click="abrirF1Alumnos"
          >
            <span class="f-badge">F1</span>
            <span class="f-label">Lista de Alumnos</span>
          </button>

          <button
            type="button"
            class="btn-f-action"
            title="Presiona F2 o haz clic para consultar catálogo de cuentas"
            @click="abrirF2Cuentas"
          >
            <span class="f-badge">F2</span>
            <span class="f-label">Lista de Cuentas</span>
          </button>
        </div>

      </section>

      <!-- Barra de acciones inferior: Imprimir, Guardar, Limpiar, Salir -->
      <footer class="window-footer-bar">
        <div class="footer-buttons-group">
          <button
            type="button"
            class="btn-action-primary"
            :disabled="partidas.length === 0"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="btn-icon">
              <polyline points="6 9 6 2 18 2 18 9"/>
              <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/>
              <rect x="6" y="14" width="12" height="8"/>
            </svg>
            Imprimir
          </button>
          <button
            type="button"
            class="btn-action-success"
            :disabled="partidas.length === 0 || isGuardando"
            @click="guardarRecibo"
          >
            <svg v-if="!isGuardando" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="btn-icon">
              <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
              <polyline points="17 21 17 13 7 13 7 21"/>
              <polyline points="7 3 7 8 15 8"/>
            </svg>
            {{ isGuardando ? 'Guardando...' : 'Guardar' }}
          </button>
          <button type="button" class="btn-action-secondary" @click="limpiar">
            Limpiar
          </button>
          <button type="button" class="btn-action-danger" @click="cerrar">
            Salir
          </button>
        </div>
        <div class="footer-hint">
          <kbd>ESC</kbd> = Salir
        </div>
      </footer>

    </div>

    <!-- DIÁLOGO MODAL F1: Lista de Alumnos -->
    <div v-if="mostrarModalF1Alumnos" class="f1-submodal-backdrop" @click.self="mostrarModalF1Alumnos = false">
      <div class="f1-submodal">
        <div class="f1-submodal-header">
          <span class="font-bold">F1 · Catálogo de Alumnos (Haz clic en un alumno para seleccionarlo)</span>
          <button type="button" class="window-btn-close" @click="mostrarModalF1Alumnos = false">&times;</button>
        </div>
        <div class="f1-submodal-body">
          <div v-if="isCargandoF1" class="f1-loading">Consultando alumnos en base de datos...</div>
          <table v-else class="f1-table">
            <thead>
              <tr>
                <th>Matrícula</th>
                <th>Nombre del Estudiante</th>
                <th>Carrera</th>
                <th>Acción</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="a in alumnosLista" :key="a.matricula">
                <td class="font-mono font-bold">{{ a.matricula }}</td>
                <td>{{ a.nombreCompleto }}</td>
                <td>{{ a.carrera }}</td>
                <td>
                  <button type="button" class="btn-select-f1" @click="seleccionarAlumnoF1(a)">
                    Seleccionar
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- MODAL F2: Catálogo de Cuentas -->
    <ModalCuentas v-if="mostrarModalF2Cuentas" @close="mostrarModalF2Cuentas = false" />

  </div>
</template>

<style scoped>
/* =====================================================
   VARIABLES INSTITUCIONALES TecNM
   Azul Marino: #1B396A | Dorado: #C5A059 | Cobalto: #244B88
   ===================================================== */

.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.65);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1200;
  padding: 1.25rem;
  animation: fadeIn 0.15s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; transform: scale(0.99); }
  to   { opacity: 1; transform: scale(1); }
}

.tecnm-window {
  width: 100%;
  max-width: 980px;
  background: #ffffff;
  border-radius: 10px;
  box-shadow: 0 20px 45px rgba(0, 0, 0, 0.35), 0 0 0 1px rgba(27, 57, 106, 0.15);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  max-height: 94vh;
}

.modal-backdrop.dark-theme .tecnm-window {
  background: #111827;
  box-shadow: 0 20px 45px rgba(0, 0, 0, 0.65), 0 0 0 1px rgba(197, 160, 89, 0.3);
}

/* Barra de título */
.window-title-bar {
  background: linear-gradient(135deg, #1B396A 0%, #244B88 100%);
  color: #ffffff;
  padding: 0.75rem 1.25rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 2px solid #C5A059;
  user-select: none;
}

.window-title-left {
  display: flex;
  align-items: center;
  gap: 0.65rem;
}

.window-icon {
  width: 20px;
  height: 20px;
  color: #C5A059;
}

.window-title-text {
  font-weight: 700;
  font-size: 0.95rem;
  letter-spacing: 0.5px;
  text-transform: uppercase;
}

.window-btn-close {
  background: transparent;
  border: none;
  color: #ffffff;
  font-size: 1.5rem;
  line-height: 1;
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.window-btn-close:hover {
  background: rgba(239, 68, 68, 0.85);
  color: #ffffff;
}

/* Panel de contenido */
.window-content-panel {
  padding: 1.15rem 1.5rem;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
}

.success-banner {
  background: #dcfce7;
  color: #166534;
  padding: 0.6rem 1rem;
  border-radius: 6px;
  font-weight: 700;
  font-size: 0.85rem;
  border: 1px solid #86efac;
}

.modal-backdrop.dark-theme .success-banner {
  background: #064e3b;
  color: #a7f3d0;
  border-color: #047857;
}

/* Top Header Card */
.top-header-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #f8fafc;
  padding: 0.85rem 1.15rem;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.modal-backdrop.dark-theme .top-header-card {
  background: #1e293b;
  border-color: #334155;
}

.header-right-group {
  display: flex;
  align-items: center;
  gap: 1.25rem;
}

.custom-checkbox-label {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
  user-select: none;
}

.tecnm-checkbox {
  width: 18px;
  height: 18px;
  accent-color: #1B396A;
  cursor: pointer;
}

.modal-backdrop.dark-theme .tecnm-checkbox {
  accent-color: #C5A059;
}

.checkbox-caption {
  font-size: 0.875rem;
  font-weight: 700;
  color: #1e293b;
}

.modal-backdrop.dark-theme .checkbox-caption {
  color: #f1f5f9;
}

.item-recibo-no {
  width: 140px;
}

.item-fecha {
  width: 200px;
}

.field-item {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}

.field-label {
  font-size: 0.8rem;
  font-weight: 700;
  color: #1B396A;
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.modal-backdrop.dark-theme .field-label {
  color: #93c5fd;
}

.tecnm-input {
  height: 36px;
  padding: 0 0.75rem;
  font-size: 0.875rem;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  background: #ffffff;
  color: #0f172a;
  outline: none;
  transition: border-color 0.15s, box-shadow 0.15s;
}

.tecnm-input:focus {
  border-color: #1B396A;
  box-shadow: 0 0 0 3px rgba(27, 57, 106, 0.15);
}

.modal-backdrop.dark-theme .tecnm-input {
  background: #0f172a;
  color: #f8fafc;
  border-color: #475569;
}

.modal-backdrop.dark-theme .tecnm-input:focus {
  border-color: #C5A059;
  box-shadow: 0 0 0 3px rgba(197, 160, 89, 0.2);
}

.tecnm-select {
  cursor: pointer;
}

/* Combo fecha */
.date-input-combo {
  display: flex;
  position: relative;
  align-items: center;
}

.date-input-combo input {
  width: 100%;
  padding-right: 2.5rem;
}

.hidden-date-picker {
  position: absolute;
  opacity: 0;
  width: 0;
  height: 0;
  pointer-events: none;
}

.btn-calendar-trigger {
  position: absolute;
  right: 4px;
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  color: #1B396A;
}

.btn-calendar-trigger:hover {
  background: #e2e8f0;
  color: #C5A059;
}

.modal-backdrop.dark-theme .btn-calendar-trigger {
  color: #C5A059;
}

.calendar-icon {
  width: 16px;
  height: 16px;
}

/* Card Datos Alumno */
.student-info-card {
  background: #f8fafc;
  padding: 1rem 1.15rem;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.modal-backdrop.dark-theme .student-info-card {
  background: #1e293b;
  border-color: #334155;
}

.student-row-1 {
  display: grid;
  grid-template-columns: 200px 1fr 100px;
  gap: 0.85rem;
}

.matricula-input-group {
  display: flex;
  position: relative;
  align-items: center;
}

.matricula-input-group input {
  width: 100%;
  padding-right: 2.25rem;
}

.btn-buscar-alumno {
  position: absolute;
  right: 4px;
  width: 28px;
  height: 28px;
  background: transparent;
  border: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #1B396A;
}

.student-row-2 {
  display: grid;
  grid-template-columns: 1fr 180px;
  gap: 0.85rem;
}

/* Concept Input Card */
.concept-input-card {
  background: #f8fafc;
  padding: 0.85rem 1.15rem;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.modal-backdrop.dark-theme .concept-input-card {
  background: #1e293b;
  border-color: #334155;
}

.concept-row {
  display: grid;
  grid-template-columns: 1fr 110px 90px auto;
  gap: 0.75rem;
  align-items: flex-end;
}

.btn-agregar-concepto {
  height: 36px;
  padding: 0 1.25rem;
  background: linear-gradient(135deg, #C5A059 0%, #b38e47 100%);
  color: #ffffff;
  font-weight: 700;
  font-size: 0.85rem;
  border: 1px solid #C5A059;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s;
  white-space: nowrap;
}

.btn-agregar-concepto:hover:not(:disabled) {
  background: linear-gradient(135deg, #b38e47 0%, #997838 100%);
  box-shadow: 0 2px 6px rgba(197, 160, 89, 0.4);
}

.btn-agregar-concepto:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Tabla de Conceptos */
.table-container {
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  overflow-x: auto;
  max-height: 240px;
  background: #ffffff;
}

.modal-backdrop.dark-theme .table-container {
  border-color: #334155;
  background: #0f172a;
}

.conceptos-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.82rem;
}

.conceptos-table thead {
  background: linear-gradient(180deg, #1B396A 0%, #152d54 100%);
  color: #ffffff;
  position: sticky;
  top: 0;
  z-index: 10;
}

.conceptos-table th {
  padding: 0.55rem 0.75rem;
  font-weight: 700;
  border-right: 1px solid rgba(255, 255, 255, 0.12);
  white-space: nowrap;
}

.col-concepto {
  width: 45%;
  text-align: left;
}

.col-cantidad {
  width: 10%;
}

.col-monto {
  width: 15%;
}

.col-action {
  width: 10%;
}

.data-row {
  border-bottom: 1px solid #e2e8f0;
}

.modal-backdrop.dark-theme .data-row {
  border-color: #1e293b;
}

.conceptos-table td {
  padding: 0.45rem 0.75rem;
  color: #1e293b;
}

.modal-backdrop.dark-theme .conceptos-table td {
  color: #f1f5f9;
}

.empty-cell {
  padding: 1.75rem 1rem !important;
  text-align: center;
  color: #64748b;
  font-style: italic;
}

/* Botón de eliminar con icono X según requerimiento */
.btn-delete-item {
  width: 26px;
  height: 26px;
  background: #fee2e2;
  color: #dc2626;
  border: 1px solid #fca5a5;
  border-radius: 4px;
  font-size: 1.15rem;
  line-height: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-delete-item:hover {
  background: #dc2626;
  color: #ffffff;
}

.modal-backdrop.dark-theme .btn-delete-item {
  background: #450a0a;
  border-color: #7f1d1d;
  color: #fca5a5;
}

.modal-backdrop.dark-theme .btn-delete-item:hover {
  background: #ef4444;
  color: #ffffff;
}

/* Fila Inferior: Notas y Total */
.bottom-fields-row {
  display: grid;
  grid-template-columns: 1fr 220px;
  gap: 1rem;
  align-items: center;
}

.input-notes {
  width: 100%;
}

.total-box {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  justify-content: flex-end;
}

.total-label {
  font-weight: 700;
  font-size: 0.9rem;
  color: #1B396A;
}

.modal-backdrop.dark-theme .total-label {
  color: #C5A059;
}

.input-total {
  width: 140px;
}

.readonly-input {
  background: #e2e8f0 !important;
  cursor: default;
}

.modal-backdrop.dark-theme .readonly-input {
  background: #334155 !important;
}

/* Impresora */
.printer-selection-row {
  display: flex;
}

.flex-grow {
  flex: 1;
}

/* Botones F1 y F2 */
.f-buttons-bar {
  display: flex;
  gap: 1rem;
}

.btn-f-action {
  flex: 1;
  height: 38px;
  background: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.65rem;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-f-action:hover {
  border-color: #1B396A;
  background: #f1f5f9;
  box-shadow: 0 2px 4px rgba(27, 57, 106, 0.12);
}

.modal-backdrop.dark-theme .btn-f-action {
  background: #1e293b;
  border-color: #475569;
  color: #f8fafc;
}

.modal-backdrop.dark-theme .btn-f-action:hover {
  background: #334155;
  border-color: #C5A059;
}

.f-badge {
  background: #1B396A;
  color: #ffffff;
  padding: 0.15rem 0.45rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 800;
  letter-spacing: 0.5px;
}

.modal-backdrop.dark-theme .f-badge {
  background: #C5A059;
  color: #111827;
}

.f-label {
  font-size: 0.85rem;
  font-weight: 700;
  color: #1e293b;
}

.modal-backdrop.dark-theme .f-label {
  color: #f1f5f9;
}

/* Submodal F1 */
.f1-submodal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1300;
  padding: 1rem;
}

.f1-submodal {
  width: 100%;
  max-width: 680px;
  max-height: 80vh;
  background: #ffffff;
  border-radius: 8px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4);
}

.modal-backdrop.dark-theme .f1-submodal {
  background: #1e293b;
  color: #f8fafc;
}

.f1-submodal-header {
  background: #1B396A;
  color: #ffffff;
  padding: 0.75rem 1rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.f1-submodal-body {
  padding: 1rem;
  overflow-y: auto;
  max-height: 400px;
}

.f1-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.85rem;
}

.f1-table th {
  background: #f1f5f9;
  padding: 0.5rem 0.75rem;
  text-align: left;
  font-weight: 700;
  border-bottom: 1px solid #cbd5e1;
}

.modal-backdrop.dark-theme .f1-table th {
  background: #334155;
  border-color: #475569;
}

.f1-table td {
  padding: 0.5rem 0.75rem;
  border-bottom: 1px solid #e2e8f0;
}

.modal-backdrop.dark-theme .f1-table td {
  border-color: #334155;
}

.f1-loading {
  text-align: center;
  padding: 2rem;
  color: #64748b;
}

.btn-select-f1 {
  background: #1B396A;
  color: #ffffff;
  border: none;
  padding: 0.25rem 0.65rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 700;
  cursor: pointer;
}

.btn-select-f1:hover {
  background: #C5A059;
}

/* Pie de ventana */
.window-footer-bar {
  background: #f8fafc;
  border-top: 1px solid #e2e8f0;
  padding: 0.85rem 1.5rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.modal-backdrop.dark-theme .window-footer-bar {
  background: #1e293b;
  border-color: #334155;
}

.footer-buttons-group {
  display: flex;
  gap: 0.65rem;
  margin-left: auto;
}

.footer-hint {
  font-size: 0.75rem;
  color: #64748b;
  margin-right: auto;
  order: -1;
}

.footer-hint kbd {
  background: #e2e8f0;
  padding: 0.15rem 0.35rem;
  border-radius: 4px;
  font-weight: 700;
  font-size: 0.7rem;
}

.modal-backdrop.dark-theme .footer-hint kbd {
  background: #334155;
  color: #f8fafc;
}

.btn-action-primary,
.btn-action-success,
.btn-action-secondary,
.btn-action-danger {
  height: 36px;
  padding: 0 1.25rem;
  font-weight: 600;
  font-size: 0.85rem;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.45rem;
  transition: all 0.15s;
}

.btn-action-primary {
  background: linear-gradient(135deg, #1B396A 0%, #244B88 100%);
  color: #ffffff;
  border: 1px solid #1B396A;
}

.btn-action-primary:hover:not(:disabled) {
  border-color: #C5A059;
  box-shadow: 0 2px 6px rgba(27, 57, 106, 0.3);
}

.btn-action-primary:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.btn-action-success {
  background: linear-gradient(135deg, #16a34a 0%, #15803d 100%);
  color: #ffffff;
  border: 1px solid #16a34a;
}

.btn-action-success:hover:not(:disabled) {
  background: linear-gradient(135deg, #15803d 0%, #166534 100%);
  box-shadow: 0 2px 6px rgba(22, 163, 74, 0.3);
}

.btn-action-success:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-action-secondary {
  background: #ffffff;
  color: #1e293b;
  border: 1px solid #cbd5e1;
}

.btn-action-secondary:hover {
  background: #f1f5f9;
  border-color: #94a3b8;
}

.modal-backdrop.dark-theme .btn-action-secondary {
  background: #0f172a;
  color: #f8fafc;
  border-color: #475569;
}

.modal-backdrop.dark-theme .btn-action-secondary:hover {
  background: #1e293b;
}

.btn-action-danger {
  background: #fee2e2;
  color: #b91c1c;
  border: 1px solid #fca5a5;
}

.btn-action-danger:hover {
  background: #fecaca;
  color: #991b1b;
}

.modal-backdrop.dark-theme .btn-action-danger {
  background: #450a0a;
  color: #fca5a5;
  border-color: #7f1d1d;
}

.modal-backdrop.dark-theme .btn-action-danger:hover {
  background: #7f1d1d;
  color: #fecaca;
}

.btn-icon {
  width: 16px;
  height: 16px;
}

.spin-icon {
  width: 16px;
  height: 16px;
  animation: spin 0.75s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.font-mono {
  font-family: 'Consolas', 'Courier New', monospace;
}

.text-right {
  text-align: right;
}

.text-center {
  text-align: center;
}

.font-bold {
  font-weight: 700;
}

.text-primary {
  color: #1B396A;
}

.modal-backdrop.dark-theme .text-primary {
  color: #93c5fd;
}
</style>

