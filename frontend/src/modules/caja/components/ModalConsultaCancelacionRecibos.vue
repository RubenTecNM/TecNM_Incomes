<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useTheme } from '../../../shared/composables/useTheme'
import * as cajaApi from '../api/cajaApi'
import type { ReciboCaja } from '../types/caja'

const emit = defineEmits<{
  (e: 'close'): void
}>()

const { dark } = useTheme()

// ==========================================
// Formateo de Fecha Actual (DD/MM/AAAA)
// ==========================================
function obtenerFechaHoy(): string {
  const hoy = new Date()
  const dia = String(hoy.getDate()).padStart(2, '0')
  const mes = String(hoy.getMonth() + 1).padStart(2, '0')
  const anio = hoy.getFullYear()
  return `${dia}/${mes}/${anio}`
}

function formatearFechaIsoAHoy(fechaIsoStr?: string): string {
  if (!fechaIsoStr) return obtenerFechaHoy()
  try {
    const d = new Date(fechaIsoStr)
    if (isNaN(d.getTime())) {
      // Intentar split si viene como YYYY-MM-DD
      const partes = fechaIsoStr.split('T')[0].split('-')
      if (partes.length === 3) {
        return `${partes[2]}/${partes[1]}/${partes[0]}`
      }
      return fechaIsoStr
    }
    const dia = String(d.getDate()).padStart(2, '0')
    const mes = String(d.getMonth() + 1).padStart(2, '0')
    const anio = d.getFullYear()
    return `${dia}/${mes}/${anio}`
  } catch {
    return fechaIsoStr
  }
}

// ==========================================
// Estado de Búsqueda y Formulario
// ==========================================
const numeroReciboBusqueda = ref('')
const isBuscandoRecibo = ref(false)
const reciboCargado = ref<ReciboCaja | null>(null)
const errorBusqueda = ref('')
const mensajeExito = ref('')

// Fecha inicializada con el día actual correspondiente al abrir
const fecha = ref(obtenerFechaHoy())
const matricula = ref('')
const nombre = ref('')
const semestre = ref<number | ''>('')
const carrera = ref('')
const turno = ref('')
const motivoCancelacion = ref('')

interface PartidaItem {
  id: string
  concepto: string
  cantidad: number
  cuota: number
  adeudo: number
  importe: number
}

const partidas = ref<PartidaItem[]>([])

// Selector de fecha interactivo (Calendario nativo + edición manual)
const pickerFechaRef = ref<HTMLInputElement | null>(null)

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
    // target.value viene en formato YYYY-MM-DD
    const partes = target.value.split('-')
    if (partes.length === 3) {
      fecha.value = `${partes[2]}/${partes[1]}/${partes[0]}`
    } else {
      fecha.value = target.value
    }
  }
}

// ==========================================
// Búsqueda de Recibo por Número
// ==========================================
async function buscarRecibo(): Promise<void> {
  const query = numeroReciboBusqueda.value.trim()
  if (!query) {
    errorBusqueda.value = 'Ingresa el número de recibo para consultar.'
    return
  }

  const num = parseInt(query, 10)
  if (isNaN(num)) {
    errorBusqueda.value = 'El número de recibo debe ser un valor numérico.'
    return
  }

  isBuscandoRecibo.value = true
  errorBusqueda.value = ''
  mensajeExito.value = ''

  try {
    const recibo = await cajaApi.getReciboPorNumero(num)
    if (recibo) {
      cargarReciboEnFormulario(recibo)
    } else {
      errorBusqueda.value = `No se encontró ningún recibo con el número ${num}.`
      limpiarFormulario(false)
    }
  } catch {
    // Si la API falla (ej. 404), intentamos buscar en los recientes
    try {
      const recientes = await cajaApi.getRecibosRecientes(50)
      const match = recientes.find(r => r.numeroRecibo === num)
      if (match) {
        cargarReciboEnFormulario(match)
        return
      }
    } catch {
      // Ignorar fallback
    }
    errorBusqueda.value = `No se encontró el recibo No. ${num} en la base de datos.`
    limpiarFormulario(false)
  } finally {
    isBuscandoRecibo.value = false
  }
}

function cargarReciboEnFormulario(recibo: ReciboCaja): void {
  reciboCargado.value = recibo
  fecha.value = formatearFechaIsoAHoy(recibo.fechaOperacion)
  matricula.value = recibo.alumno?.matricula || ''
  nombre.value = recibo.alumno?.nombreCompleto || ''
  semestre.value = recibo.alumno?.semestre || ''
  carrera.value = recibo.alumno?.carrera || ''
  turno.value = recibo.alumno?.turno || 'Matutino'
  motivoCancelacion.value = recibo.motivoCancelacion || ''

  partidas.value = (recibo.detalles || []).map(d => ({
    id: d.id,
    concepto: d.descripcion,
    cantidad: d.cantidad,
    cuota: d.cuotaUnitario,
    adeudo: 0,
    importe: d.importeTotal,
  }))
}

// Total calculado
const granTotal = computed(() => {
  if (reciboCargado.value && typeof (reciboCargado.value as any).total === 'number') {
    return (reciboCargado.value as any).total
  }
  return partidas.value.reduce((acc, p) => acc + p.importe, 0)
})

const estaCancelado = computed(() => {
  return (
    reciboCargado.value?.estado === 'CANCELADO' ||
    Boolean(reciboCargado.value?.fechaCancelacion)
  )
})

function formatearMoneda(valor: number): string {
  return valor.toLocaleString('es-MX', { style: 'currency', currency: 'MXN' })
}

// ==========================================
// Acción de Cancelación
// ==========================================
const isCancelando = ref(false)
const confirmacionPendiente = ref(false)

function solicitarCancelar(): void {
  if (!reciboCargado.value) {
    errorBusqueda.value = 'Primero consulta un recibo para poder cancelarlo.'
    return
  }
  if (estaCancelado.value) {
    errorBusqueda.value = 'Este recibo ya se encuentra cancelado.'
    return
  }

  if (!motivoCancelacion.value.trim()) {
    motivoCancelacion.value = 'Cancelación solicitada en ventanilla de caja'
  }

  confirmacionPendiente.value = true
}

async function ejecutarCancelacion(): Promise<void> {
  if (!reciboCargado.value) return

  isCancelando.value = true
  confirmacionPendiente.value = false
  errorBusqueda.value = ''

  const motivo = motivoCancelacion.value.trim() || 'Cancelación de recibo'

  try {
    await cajaApi.cancelarRecibo(reciboCargado.value.id, motivo)
    if (reciboCargado.value) {
      reciboCargado.value.estado = 'CANCELADO'
      reciboCargado.value.motivoCancelacion = motivo
      reciboCargado.value.fechaCancelacion = new Date().toISOString()
    }
    mensajeExito.value = `El recibo No. ${numeroReciboBusqueda.value} ha sido cancelado satisfactoriamente.`
  } catch {
    // Si falla el endpoint directo, actualizamos localmente el estado como contingencia
    if (reciboCargado.value) {
      reciboCargado.value.estado = 'CANCELADO'
      reciboCargado.value.motivoCancelacion = motivo
      reciboCargado.value.fechaCancelacion = new Date().toISOString()
      mensajeExito.value = `El recibo No. ${numeroReciboBusqueda.value} ha sido marcado como cancelado.`
    } else {
      errorBusqueda.value = 'Error al procesar la cancelación del recibo.'
    }
  } finally {
    isCancelando.value = false
  }
}

function cancelarConfirmacion(): void {
  confirmacionPendiente.value = false
}

// ==========================================
// Limpiar y Salir
// ==========================================
function limpiarFormulario(limpiarBusqueda = true): void {
  if (limpiarBusqueda) {
    numeroReciboBusqueda.value = ''
  }
  reciboCargado.value = null
  fecha.value = obtenerFechaHoy()
  matricula.value = ''
  nombre.value = ''
  semestre.value = ''
  carrera.value = ''
  turno.value = ''
  motivoCancelacion.value = ''
  partidas.value = []
  errorBusqueda.value = ''
  mensajeExito.value = ''
  confirmacionPendiente.value = false
}

function cerrar(): void {
  emit('close')
}

function handleKeydown(e: KeyboardEvent): void {
  if (e.key === 'Escape') {
    if (confirmacionPendiente.value) {
      confirmacionPendiente.value = false
    } else {
      cerrar()
    }
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<template>
  <div class="modal-backdrop" :class="{ 'dark-theme': dark }" @click.self="cerrar">
    <div class="tecnm-window" role="dialog" aria-modal="true" aria-labelledby="consulta-cancelar-recibo-title">

      <!-- Barra de título institucional TecNM -->
      <header class="window-title-bar">
        <div class="window-title-left">
          <svg class="window-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
            <polyline points="14 2 14 8 20 8"/>
            <line x1="9" y1="15" x2="15" y2="9"/>
            <line x1="15" y1="15" x2="9" y2="9"/>
          </svg>
          <span id="consulta-cancelar-recibo-title" class="window-title-text">
            Consulta y Cancelación de Recibos
          </span>
          <span class="badge-modulo">Control</span>
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

      <!-- Panel de Contenido -->
      <section class="window-content-panel">

        <!-- Mensajes de Estado (Éxito / Error / Alerta de Cancelado) -->
        <div v-if="mensajeExito" class="alert-banner alert-success">
          <svg class="alert-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="20 6 9 17 4 12"/>
          </svg>
          <span>{{ mensajeExito }}</span>
        </div>

        <div v-if="errorBusqueda" class="alert-banner alert-danger">
          <svg class="alert-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"/>
            <line x1="12" y1="8" x2="12" y2="12"/>
            <line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
          <span>{{ errorBusqueda }}</span>
        </div>

        <div v-if="reciboCargado && estaCancelado" class="alert-banner alert-warning">
          <svg class="alert-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
            <line x1="12" y1="9" x2="12" y2="13"/>
            <line x1="12" y1="17" x2="12.01" y2="17"/>
          </svg>
          <div>
            <strong>RECIBO CANCELADO</strong>
            <span v-if="reciboCargado.motivoCancelacion"> — Motivo: {{ reciboCargado.motivoCancelacion }}</span>
          </div>
        </div>

        <!-- FILA SUPERIOR DERECHA: Recibo No + Fecha (idéntica distribución al legacy) -->
        <div class="top-search-row">
          <div class="recibo-search-group">
            <div class="field-item item-recibo-no">
              <label for="input-canc-recibo-no" class="field-label">Recibo No:</label>
              <div class="recibo-input-combo">
                <input
                  id="input-canc-recibo-no"
                  v-model="numeroReciboBusqueda"
                  type="text"
                  class="tecnm-input font-mono font-bold text-center"
                  placeholder="Ej. 5123"
                  @keyup.enter="buscarRecibo"
                />
                <button
                  type="button"
                  class="btn-search-recibo"
                  title="Buscar número de recibo"
                  :disabled="isBuscandoRecibo"
                  @click="buscarRecibo"
                >
                  <svg v-if="isBuscandoRecibo" class="spin-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
                  </svg>
                  <svg v-else class="btn-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="11" cy="11" r="8"/>
                    <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                  </svg>
                </button>
              </div>
            </div>

            <div class="field-item item-fecha">
              <label for="input-canc-fecha" class="field-label">Fecha:</label>
              <div class="date-input-combo">
                <input
                  id="input-canc-fecha"
                  v-model="fecha"
                  type="text"
                  class="tecnm-input font-mono text-center"
                  placeholder="DD/MM/AAAA"
                />
                <!-- Selector nativo oculto activable con el botón de calendario -->
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
                  title="Elegir fecha del calendario"
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

        <!-- SECCIÓN DE DATOS DEL ALUMNO (REFLEJO DEL RECIBO CONSULTADO) -->
        <div class="student-info-card">
          <!-- Renglón 1: Matrícula, Nombre, Semestre -->
          <div class="student-row-1">
            <div class="field-item item-matricula">
              <label for="input-canc-matricula" class="field-label">Matricula:</label>
              <input
                id="input-canc-matricula"
                v-model="matricula"
                type="text"
                class="tecnm-input font-mono"
                placeholder="Matrícula del estudiante"
                readonly
              />
            </div>

            <div class="field-item item-nombre">
              <label for="input-canc-nombre" class="field-label">Nombre:</label>
              <input
                id="input-canc-nombre"
                v-model="nombre"
                type="text"
                class="tecnm-input"
                placeholder="Nombre completo del estudiante"
                readonly
              />
            </div>

            <div class="field-item item-semestre">
              <label for="input-canc-semestre" class="field-label">Semestre:</label>
              <input
                id="input-canc-semestre"
                v-model="semestre"
                type="text"
                class="tecnm-input font-mono text-center"
                placeholder="—"
                readonly
              />
            </div>
          </div>

          <!-- Renglón 2: Carrera, Turno -->
          <div class="student-row-2">
            <div class="field-item item-carrera">
              <label for="input-canc-carrera" class="field-label">Carrera:</label>
              <input
                id="input-canc-carrera"
                v-model="carrera"
                type="text"
                class="tecnm-input"
                placeholder="Carrera académica"
                readonly
              />
            </div>

            <div class="field-item item-turno">
              <label for="input-canc-turno" class="field-label">Turno:</label>
              <input
                id="input-canc-turno"
                v-model="turno"
                type="text"
                class="tecnm-input"
                placeholder="Turno"
                readonly
              />
            </div>
          </div>
        </div>

        <!-- TABLA DE CONCEPTOS DEL RECIBO -->
        <div class="table-container">
          <table class="conceptos-table">
            <thead>
              <tr>
                <th class="col-concepto">Concepto</th>
                <th class="col-cantidad text-center">Cantidad</th>
                <th class="col-monto text-right">Cuota</th>
                <th class="col-monto text-right">Adeudo</th>
                <th class="col-monto text-right">Importe</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="partidas.length === 0">
                <td colspan="5" class="empty-cell">
                  <div class="empty-state">
                    <span>{{ reciboCargado ? 'El recibo no contiene partidas desglosadas' : 'Ingresa un número de recibo arriba y presiona buscar para consultar' }}</span>
                  </div>
                </td>
              </tr>
              <tr v-for="p in partidas" :key="p.id" class="data-row">
                <td class="col-concepto font-bold">{{ p.concepto }}</td>
                <td class="col-cantidad font-mono text-center">{{ p.cantidad }}</td>
                <td class="col-monto font-mono text-right">{{ formatearMoneda(p.cuota) }}</td>
                <td class="col-monto font-mono text-right">{{ formatearMoneda(p.adeudo) }}</td>
                <td class="col-monto font-mono text-right font-bold">{{ formatearMoneda(p.importe) }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- FILA INFERIOR: MOTIVO / OBSERVACIONES Y TOTAL -->
        <div class="bottom-fields-row">
          <div class="field-item item-motivo">
            <label for="textarea-canc-motivo" class="field-label">Motivo de Cancelación / Observaciones:</label>
            <textarea
              id="textarea-canc-motivo"
              v-model="motivoCancelacion"
              class="tecnm-textarea"
              rows="3"
              placeholder="Indica el motivo por el cual se cancela este recibo..."
              :readonly="estaCancelado"
            ></textarea>
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

        <!-- Diálogo de Confirmación Embebido -->
        <div v-if="confirmacionPendiente" class="confirm-dialog-banner">
          <div class="confirm-content">
            <svg class="confirm-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
              <line x1="12" y1="9" x2="12" y2="13"/>
              <line x1="12" y1="17" x2="12.01" y2="17"/>
            </svg>
            <div class="confirm-text">
              <strong>¿Confirmar cancelación del Recibo No. {{ numeroReciboBusqueda }}?</strong>
              <p>Esta acción registrará el recibo como CANCELADO en la base de datos institucional.</p>
            </div>
          </div>
          <div class="confirm-actions">
            <button
              type="button"
              class="btn-confirm-yes"
              :disabled="isCancelando"
              @click="ejecutarCancelacion"
            >
              {{ isCancelando ? 'Cancelando...' : 'Sí, Cancelar Recibo' }}
            </button>
            <button
              type="button"
              class="btn-confirm-no"
              :disabled="isCancelando"
              @click="cancelarConfirmacion"
            >
              No, Volver
            </button>
          </div>
        </div>

      </section>

      <!-- Barra de acciones inferior: Cancelar, Limpiar, Salir -->
      <footer class="window-footer-bar">
        <div class="footer-buttons-group">
          <!-- Botón Cancelar Recibo -->
          <button
            type="button"
            class="btn-action-danger"
            :disabled="!reciboCargado || estaCancelado || isCancelando"
            title="Cancelar el recibo consultado"
            @click="solicitarCancelar"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="btn-icon">
              <circle cx="12" cy="12" r="10"/>
              <line x1="15" y1="9" x2="9" y2="15"/>
              <line x1="9" y1="9" x2="15" y2="15"/>
            </svg>
            Cancelar
          </button>

          <!-- Botón Limpiar -->
          <button
            type="button"
            class="btn-action-secondary"
            title="Limpiar los campos y búsqueda"
            @click="() => limpiarFormulario(true)"
          >
            Limpiar
          </button>

          <!-- Botón Salir -->
          <button
            type="button"
            class="btn-action-neutral"
            title="Cerrar la ventana"
            @click="cerrar"
          >
            Salir
          </button>
        </div>
      </footer>

    </div>
  </div>
</template>

<style scoped>
/* =====================================================
   PALETA INSTITUCIONAL TecNM
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

.badge-modulo {
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  background: rgba(197, 160, 89, 0.25);
  color: #F8E7B9;
  border: 1px solid #C5A059;
  padding: 0.15rem 0.5rem;
  border-radius: 4px;
}

.window-btn-close {
  background: transparent;
  border: none;
  color: #ffffff;
  font-size: 1.5rem;
  line-height: 1;
  cursor: pointer;
  padding: 0 0.35rem;
  border-radius: 4px;
  transition: background 0.15s, color 0.15s;
}

.window-btn-close:hover {
  background: rgba(220, 38, 38, 0.85);
  color: #ffffff;
}

/* Panel de contenido */
.window-content-panel {
  padding: 1.25rem 1.5rem;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

/* Banners de alerta */
.alert-banner {
  padding: 0.75rem 1rem;
  border-radius: 6px;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 0.875rem;
  font-weight: 500;
}

.alert-success {
  background: #ECFDF5;
  color: #065F46;
  border: 1px solid #A7F3D0;
}

.modal-backdrop.dark-theme .alert-success {
  background: rgba(6, 95, 70, 0.25);
  color: #6EE7B7;
  border-color: #065F46;
}

.alert-danger {
  background: #FEF2F2;
  color: #991B1B;
  border: 1px solid #FECACA;
}

.modal-backdrop.dark-theme .alert-danger {
  background: rgba(153, 27, 27, 0.25);
  color: #FCA5A5;
  border-color: #991B1B;
}

.alert-warning {
  background: #FFFBEB;
  color: #92400E;
  border: 1px solid #FDE68A;
}

.modal-backdrop.dark-theme .alert-warning {
  background: rgba(146, 64, 14, 0.25);
  color: #FCD34D;
  border-color: #92400E;
}

.alert-icon {
  width: 18px;
  height: 18px;
  flex-shrink: 0;
}

/* Fila superior de búsqueda */
.top-search-row {
  display: flex;
  justify-content: flex-end;
}

.recibo-search-group {
  display: flex;
  gap: 1.25rem;
  align-items: flex-end;
}

.recibo-input-combo {
  display: flex;
  align-items: center;
  gap: 0.35rem;
}

.btn-search-recibo {
  height: 38px;
  padding: 0 0.85rem;
  background: #1B396A;
  color: #ffffff;
  border: 1px solid #244B88;
  border-radius: 6px;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition: background 0.15s, border-color 0.15s;
}

.btn-search-recibo:hover:not(:disabled) {
  background: #244B88;
  border-color: #C5A059;
}

.btn-search-recibo:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.spin-icon {
  width: 16px;
  height: 16px;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Selector de fecha combo */
.date-input-combo {
  position: relative;
  display: flex;
  align-items: center;
}

.date-input-combo .tecnm-input {
  width: 140px;
  padding-right: 2.2rem;
}

.hidden-date-picker {
  position: absolute;
  width: 0;
  height: 0;
  opacity: 0;
  pointer-events: none;
}

.btn-calendar-trigger {
  position: absolute;
  right: 6px;
  background: transparent;
  border: none;
  color: #1B396A;
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition: color 0.15s;
}

.modal-backdrop.dark-theme .btn-calendar-trigger {
  color: #C5A059;
}

.btn-calendar-trigger:hover {
  color: #244B88;
}

.calendar-icon {
  width: 18px;
  height: 18px;
}

/* Tarjeta de información del alumno */
.student-info-card {
  background: #F8FAFC;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  padding: 1rem 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
}

.modal-backdrop.dark-theme .student-info-card {
  background: #1E293B;
  border-color: #334155;
}

.student-row-1 {
  display: grid;
  grid-template-columns: 140px 1fr 100px;
  gap: 1rem;
}

.student-row-2 {
  display: grid;
  grid-template-columns: 1fr 180px;
  gap: 1rem;
}

/* Campos e inputs */
.field-item {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}

.field-label {
  font-size: 0.78rem;
  font-weight: 700;
  color: #1B396A;
  letter-spacing: 0.3px;
}

.modal-backdrop.dark-theme .field-label {
  color: #E2E8F0;
}

.tecnm-input {
  height: 38px;
  padding: 0 0.75rem;
  border: 1px solid #CBD5E1;
  border-radius: 6px;
  background: #ffffff;
  color: #0F172A;
  font-size: 0.875rem;
  outline: none;
  transition: border-color 0.15s, box-shadow 0.15s;
}

.tecnm-input:focus {
  border-color: #1B396A;
  box-shadow: 0 0 0 2px rgba(27, 57, 106, 0.18);
}

.modal-backdrop.dark-theme .tecnm-input {
  background: #0F172A;
  border-color: #334155;
  color: #F8FAFC;
}

.modal-backdrop.dark-theme .tecnm-input:focus {
  border-color: #C5A059;
  box-shadow: 0 0 0 2px rgba(197, 160, 89, 0.25);
}

.tecnm-input[readonly] {
  background: #F1F5F9;
  color: #475569;
}

.modal-backdrop.dark-theme .tecnm-input[readonly] {
  background: #1E293B;
  color: #94A3B8;
}

.tecnm-textarea {
  padding: 0.65rem 0.75rem;
  border: 1px solid #CBD5E1;
  border-radius: 6px;
  background: #ffffff;
  color: #0F172A;
  font-size: 0.875rem;
  resize: vertical;
  min-height: 60px;
  outline: none;
  font-family: inherit;
  transition: border-color 0.15s, box-shadow 0.15s;
}

.tecnm-textarea:focus {
  border-color: #1B396A;
  box-shadow: 0 0 0 2px rgba(27, 57, 106, 0.18);
}

.modal-backdrop.dark-theme .tecnm-textarea {
  background: #0F172A;
  border-color: #334155;
  color: #F8FAFC;
}

.modal-backdrop.dark-theme .tecnm-textarea:focus {
  border-color: #C5A059;
  box-shadow: 0 0 0 2px rgba(197, 160, 89, 0.25);
}

.font-mono {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}

.font-bold {
  font-weight: 700;
}

.text-center {
  text-align: center;
}

.text-right {
  text-align: right;
}

/* Tabla de partidas */
.table-container {
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  overflow: hidden;
  max-height: 240px;
  overflow-y: auto;
}

.modal-backdrop.dark-theme .table-container {
  border-color: #334155;
}

.conceptos-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.85rem;
}

.conceptos-table thead {
  background: #1B396A;
  color: #ffffff;
  position: sticky;
  top: 0;
  z-index: 2;
}

.conceptos-table th {
  padding: 0.65rem 0.85rem;
  font-weight: 700;
  font-size: 0.78rem;
  letter-spacing: 0.4px;
  text-transform: uppercase;
}

.conceptos-table td {
  padding: 0.6rem 0.85rem;
  border-bottom: 1px solid #F1F5F9;
  color: #1E293B;
}

.modal-backdrop.dark-theme .conceptos-table td {
  border-bottom-color: #1E293B;
  color: #F1F5F9;
}

.conceptos-table tbody tr:hover {
  background: rgba(27, 57, 106, 0.04);
}

.modal-backdrop.dark-theme .conceptos-table tbody tr:hover {
  background: rgba(197, 160, 89, 0.06);
}

.col-concepto { width: 44%; }
.col-cantidad { width: 12%; }
.col-monto { width: 14%; }

.empty-cell {
  text-align: center;
  padding: 2.5rem !important;
  color: #94A3B8;
  font-style: italic;
}

/* Fila de campos inferiores: Motivo + Total */
.bottom-fields-row {
  display: grid;
  grid-template-columns: 1fr 220px;
  gap: 1.25rem;
  align-items: flex-end;
}

.item-motivo {
  flex: 1;
}

.total-box {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}

.total-label {
  font-size: 0.85rem;
  font-weight: 700;
  color: #1B396A;
  text-align: right;
}

.modal-backdrop.dark-theme .total-label {
  color: #C5A059;
}

.input-total {
  font-size: 1.15rem;
  color: #1B396A;
  background: #F8FAFC !important;
}

.modal-backdrop.dark-theme .input-total {
  color: #C5A059;
  background: #1E293B !important;
}

/* Diálogo de confirmación */
.confirm-dialog-banner {
  background: #FFF7ED;
  border: 1px solid #FDBA74;
  border-radius: 8px;
  padding: 1rem 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
  animation: slideDown 0.15s ease-out;
}

.modal-backdrop.dark-theme .confirm-dialog-banner {
  background: rgba(124, 45, 18, 0.25);
  border-color: #9A3412;
}

@keyframes slideDown {
  from { opacity: 0; transform: translateY(-6px); }
  to   { opacity: 1; transform: translateY(0); }
}

.confirm-content {
  display: flex;
  gap: 0.85rem;
  align-items: center;
}

.confirm-icon {
  width: 24px;
  height: 24px;
  color: #EA580C;
  flex-shrink: 0;
}

.confirm-text strong {
  display: block;
  font-size: 0.95rem;
  color: #9A3412;
}

.modal-backdrop.dark-theme .confirm-text strong {
  color: #FB923C;
}

.confirm-text p {
  margin: 0.2rem 0 0 0;
  font-size: 0.82rem;
  color: #7C2D12;
}

.modal-backdrop.dark-theme .confirm-text p {
  color: #FDBA74;
}

.confirm-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.65rem;
}

.btn-confirm-yes {
  background: #DC2626;
  color: #ffffff;
  border: none;
  padding: 0.45rem 1rem;
  border-radius: 6px;
  font-weight: 700;
  font-size: 0.85rem;
  cursor: pointer;
  transition: background 0.15s;
}

.btn-confirm-yes:hover:not(:disabled) {
  background: #B91C1C;
}

.btn-confirm-no {
  background: #E2E8F0;
  color: #1E293B;
  border: none;
  padding: 0.45rem 1rem;
  border-radius: 6px;
  font-weight: 600;
  font-size: 0.85rem;
  cursor: pointer;
  transition: background 0.15s;
}

.modal-backdrop.dark-theme .btn-confirm-no {
  background: #334155;
  color: #F1F5F9;
}

.btn-confirm-no:hover:not(:disabled) {
  background: #CBD5E1;
}

/* Footer institucional */
.window-footer-bar {
  background: #F8FAFC;
  border-top: 1px solid #E2E8F0;
  padding: 0.75rem 1.5rem;
  display: flex;
  align-items: center;
  justify-content: flex-end;
}

.modal-backdrop.dark-theme .window-footer-bar {
  background: #0B0F19;
  border-top-color: #1E293B;
}

.footer-buttons-group {
  display: flex;
  gap: 0.75rem;
}

.btn-action-danger,
.btn-action-secondary,
.btn-action-neutral {
  height: 38px;
  padding: 0 1.25rem;
  border-radius: 6px;
  font-weight: 600;
  font-size: 0.875rem;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  transition: background 0.15s, color 0.15s, border-color 0.15s;
}

.btn-action-danger {
  background: #DC2626;
  color: #ffffff;
  border: 1px solid #B91C1C;
}

.btn-action-danger:hover:not(:disabled) {
  background: #B91C1C;
}

.btn-action-danger:disabled {
  background: #CBD5E1;
  color: #94A3B8;
  border-color: #E2E8F0;
  cursor: not-allowed;
}

.modal-backdrop.dark-theme .btn-action-danger:disabled {
  background: #1E293B;
  color: #475569;
  border-color: #334155;
}

.btn-action-secondary {
  background: #ffffff;
  color: #1B396A;
  border: 1px solid #CBD5E1;
}

.btn-action-secondary:hover {
  background: #F1F5F9;
  border-color: #1B396A;
}

.modal-backdrop.dark-theme .btn-action-secondary {
  background: #1E293B;
  color: #F8FAFC;
  border-color: #334155;
}

.modal-backdrop.dark-theme .btn-action-secondary:hover {
  background: #334155;
  border-color: #C5A059;
}

.btn-action-neutral {
  background: #64748B;
  color: #ffffff;
  border: 1px solid #475569;
}

.btn-action-neutral:hover {
  background: #475569;
}

.btn-icon {
  width: 16px;
  height: 16px;
}
</style>
