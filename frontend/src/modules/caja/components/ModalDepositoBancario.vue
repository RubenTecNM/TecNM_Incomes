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
// Catálogo de Conceptos
// ==========================================
interface ConceptoOpcion {
  id: string
  descripcion: string
  cuotaBase: number
}

const conceptosCatalogo = ref<ConceptoOpcion[]>([])

const conceptosFallback: ConceptoOpcion[] = [
  { id: '', descripcion: '-- Seleccionar Concepto --', cuotaBase: 0 },
  { id: 'c1', descripcion: 'PAGO DE INSCRIPCION (PERIODO VIGENTE)', cuotaBase: 1700 },
  { id: 'c2', descripcion: 'ADEUDO DE INSCRIPCION ANTERIOR', cuotaBase: 1700 },
  { id: 'c3', descripcion: 'CURSO DE VERANO (POR ASIGNATURA)', cuotaBase: 650 },
  { id: 'c4', descripcion: 'EXPEDICION DE KARDEX', cuotaBase: 150 },
  { id: 'c5', descripcion: 'CONSTANCIA DE ESTUDIOS CON CALIFICACIONES', cuotaBase: 100 },
  { id: 'c6', descripcion: 'TRAMITE DE TITULACION INTEGRAL Y CEDULA', cuotaBase: 3500 },
]

// ==========================================
// 3 Renglones de Conceptos (Cuota y Cantidad)
// ==========================================
interface RenglonConcepto {
  conceptoId: string
  cuota: number
  cantidad: number
}

const renglones = ref<RenglonConcepto[]>([
  { conceptoId: '', cuota: 0, cantidad: 1 },
  { conceptoId: '', cuota: 0, cantidad: 1 },
  { conceptoId: '', cuota: 0, cantidad: 1 },
])

function onCambioConcepto(idx: number): void {
  const item = renglones.value[idx]
  const match = conceptosCatalogo.value.find(c => c.id === item.conceptoId)
  if (match) {
    item.cuota = match.cuotaBase
  } else {
    item.cuota = 0
  }
}

// Total dinámico de los 3 conceptos
const granTotal = computed(() => {
  return renglones.value.reduce((acc, r) => acc + (r.cuota * (r.cantidad || 0)), 0)
})

// ==========================================
// Campos de Fecha, Recibo y Registros
// ==========================================
const fechaOperacion = ref('')
const numeroRecibo = ref('')
const totalRegistros = ref(0)
const fechaInicio = ref('')
const fechaFin = ref('')

// Referencias a inputs de archivos y calendarios
const fileInputRef = ref<HTMLInputElement | null>(null)
const pickerFechaRef = ref<HTMLInputElement | null>(null)
const pickerInicioRef = ref<HTMLInputElement | null>(null)
const pickerFinRef = ref<HTMLInputElement | null>(null)

// Modales secundarios de F1 (Alumnos) y F2 (Cuentas)
const mostrarModalF2Cuentas = ref(false)
const mostrarModalF1Alumnos = ref(false)

// Lista rápida para modal F1 Alumnos
interface AlumnoPreview {
  matricula: string
  nombreCompleto: string
  carrera: string
}
const alumnosLista = ref<AlumnoPreview[]>([])
const isBuscandoAlumnos = ref(false)

function abrirExploradorArchivos(): void {
  if (fileInputRef.value) {
    fileInputRef.value.click()
  }
}

function onArchivoSeleccionado(e: Event): void {
  const target = e.target as HTMLInputElement
  if (target.files && target.files.length > 0) {
    const file = target.files[0]
    totalRegistros.value = 1
    // Si es un archivo de texto o excel podríamos simular la cantidad de registros
    if (file.size > 0) {
      totalRegistros.value = Math.max(1, Math.min(500, Math.floor(file.size / 120)))
    }
  }
}

// Pickers de fechas
function abrirPicker(tipo: 'fecha' | 'inicio' | 'fin'): void {
  const refMap = {
    fecha: pickerFechaRef.value,
    inicio: pickerInicioRef.value,
    fin: pickerFinRef.value,
  }
  const el = refMap[tipo]
  if (el) {
    if (typeof el.showPicker === 'function') {
      el.showPicker()
    } else {
      el.focus()
    }
  }
}

function onFechaPick(tipo: 'fecha' | 'inicio' | 'fin', e: Event): void {
  const target = e.target as HTMLInputElement
  if (target && target.value) {
    if (tipo === 'fecha') fechaOperacion.value = target.value
    if (tipo === 'inicio') fechaInicio.value = target.value
    if (tipo === 'fin') fechaFin.value = target.value
  }
}

// F1: Lista de Alumnos
async function abrirF1Alumnos(): Promise<void> {
  mostrarModalF1Alumnos.value = true
  isBuscandoAlumnos.value = true
  try {
    const res = await cajaApi.buscarAlumnos('')
    if (res && res.length > 0) {
      alumnosLista.value = res.map(a => ({
        matricula: a.matricula,
        nombreCompleto: a.nombreCompleto,
        carrera: a.carrera,
      }))
    }
  } catch {
    alumnosLista.value = []
  } finally {
    isBuscandoAlumnos.value = false
  }
}

// F2: Lista de Cuentas
function abrirF2Cuentas(): void {
  mostrarModalF2Cuentas.value = true
}

// Acciones principales
function limpiar(): void {
  renglones.value = [
    { conceptoId: '', cuota: 0, cantidad: 1 },
    { conceptoId: '', cuota: 0, cantidad: 1 },
    { conceptoId: '', cuota: 0, cantidad: 1 },
  ]
  fechaOperacion.value = ''
  totalRegistros.value = 0
  fechaInicio.value = ''
  fechaFin.value = ''
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

  // 1. Cargar conceptos de la base de datos
  try {
    const list = await cajaApi.getConceptos()
    if (list && list.length > 0) {
      conceptosCatalogo.value = [
        { id: '', descripcion: '-- Seleccionar Concepto --', cuotaBase: 0 },
        ...list.map(c => ({ id: c.id, descripcion: c.descripcion, cuotaBase: c.cuotaBase })),
      ]
    } else {
      conceptosCatalogo.value = conceptosFallback
    }
  } catch {
    conceptosCatalogo.value = conceptosFallback
  }

  // 2. Obtener el número de recibo correspondiente de la BD
  try {
    const recientes = await cajaApi.getRecibosRecientes(1)
    if (recientes && recientes.length > 0 && recientes[0].numeroRecibo) {
      numeroRecibo.value = String(recientes[0].numeroRecibo + 1)
    } else {
      numeroRecibo.value = '128710'
    }
  } catch {
    numeroRecibo.value = '128710'
  }
})

onUnmounted(() => window.removeEventListener('keydown', handleKeydown))
</script>

<template>
  <div class="modal-backdrop" :class="{ 'dark-theme': dark }" @click.self="cerrar">
    <div class="tecnm-window" role="dialog" aria-modal="true" aria-labelledby="deposito-title">

      <!-- Barra de título institucional -->
      <header class="window-title-bar">
        <div class="window-title-left">
          <svg class="window-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="2" y="5" width="20" height="14" rx="2"/>
            <line x1="2" y1="10" x2="22" y2="10"/>
          </svg>
          <span id="deposito-title" class="window-title-text">Depósito Bancario</span>
        </div>
        <button type="button" class="window-btn-close" title="Cerrar (ESC)" aria-label="Cerrar ventana" @click="cerrar">
          &times;
        </button>
      </header>

      <!-- Panel de Contenido -->
      <section class="window-content-panel">

        <!-- Input de archivo oculto para el botón "Abrir" -->
        <input
          ref="fileInputRef"
          type="file"
          class="hidden-file-input"
          accept=".txt,.csv,.xlsx,.xls,.dat"
          @change="onArchivoSeleccionado"
        />

        <!-- SECCIÓN 1: 3 Renglones de Conceptos con Cuota y Cantidad -->
        <div class="conceptos-grid-box">
          <div class="conceptos-left-column">
            <div
              v-for="(renglon, idx) in renglones"
              :key="idx"
              class="concepto-row"
            >
              <!-- Selector de Concepto -->
              <div class="field-item item-concepto">
                <label :for="`select-dep-concepto-${idx}`" class="field-label">Concepto:</label>
                <select
                  :id="`select-dep-concepto-${idx}`"
                  v-model="renglon.conceptoId"
                  class="tecnm-input tecnm-select"
                  @change="onCambioConcepto(idx)"
                >
                  <option v-for="c in conceptosCatalogo" :key="c.id" :value="c.id">
                    {{ c.descripcion }}
                  </option>
                </select>
              </div>

              <!-- Cuota -->
              <div class="field-item item-cuota">
                <label :for="`input-dep-cuota-${idx}`" class="field-label">Cuota:</label>
                <input
                  :id="`input-dep-cuota-${idx}`"
                  v-model.number="renglon.cuota"
                  type="number"
                  min="0"
                  step="0.01"
                  class="tecnm-input input-number font-mono text-right"
                />
              </div>

              <!-- Cantidad -->
              <div class="field-item item-cantidad">
                <label :for="`input-dep-cantidad-${idx}`" class="field-label">Cantidad:</label>
                <input
                  :id="`input-dep-cantidad-${idx}`"
                  v-model.number="renglon.cantidad"
                  type="number"
                  min="1"
                  class="tecnm-input input-number font-mono text-center"
                />
              </div>
            </div>
          </div>

          <!-- Total a la derecha -->
          <div class="total-display-card">
            <span class="total-title">Total</span>
            <span class="total-amount font-mono">${{ granTotal.toFixed(2) }}</span>
          </div>
        </div>

        <!-- SECCIÓN 2: Fecha, Recibo No, Abrir y Total Registros -->
        <div class="middle-controls-card">
          <!-- Fecha Operación -->
          <div class="field-item item-fecha-op">
            <label for="input-dep-fecha-op" class="field-label">Fecha:</label>
            <div class="date-input-combo">
              <input
                id="input-dep-fecha-op"
                v-model="fechaOperacion"
                type="text"
                class="tecnm-input font-mono"
                placeholder="AAAA-MM-DD"
              />
              <input
                ref="pickerFechaRef"
                type="date"
                class="hidden-date-picker"
                tabindex="-1"
                @change="onFechaPick('fecha', $event)"
              />
              <button
                type="button"
                class="btn-calendar-trigger"
                title="Elegir fecha"
                @click="abrirPicker('fecha')"
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

          <!-- Recibo No (tomado de la BD) -->
          <div class="field-item item-recibo-no">
            <label for="input-dep-recibo-no" class="field-label">Recibo No:</label>
            <input
              id="input-dep-recibo-no"
              v-model="numeroRecibo"
              type="text"
              class="tecnm-input font-mono font-bold text-center text-primary"
              placeholder="Número de Recibo"
            />
          </div>

          <!-- Botón Abrir (explorador de carpetas/archivos) -->
          <div class="item-btn-abrir">
            <button
              type="button"
              class="btn-abrir-archivo"
              title="Abrir archivo o carpeta"
              @click="abrirExploradorArchivos"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="btn-icon">
                <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>
              </svg>
              Abrir
            </button>
          </div>

          <!-- Total de Registros -->
          <div class="field-item item-total-reg">
            <label for="input-dep-total-reg" class="field-label">Total de Registros:</label>
            <input
              id="input-dep-total-reg"
              v-model.number="totalRegistros"
              type="number"
              readonly
              class="tecnm-input font-mono text-center readonly-input"
            />
          </div>
        </div>

        <!-- SECCIÓN 3: Rango de Fechas (Inicio y Fin) -->
        <div class="range-dates-card">
          <div class="field-item item-range">
            <label for="input-dep-inicio" class="field-label">Inicio:</label>
            <div class="date-input-combo">
              <input
                id="input-dep-inicio"
                v-model="fechaInicio"
                type="text"
                class="tecnm-input font-mono"
                placeholder="AAAA-MM-DD"
              />
              <input
                ref="pickerInicioRef"
                type="date"
                class="hidden-date-picker"
                tabindex="-1"
                @change="onFechaPick('inicio', $event)"
              />
              <button
                type="button"
                class="btn-calendar-trigger"
                title="Elegir fecha de inicio"
                @click="abrirPicker('inicio')"
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

          <div class="field-item item-range">
            <label for="input-dep-fin" class="field-label">Fin:</label>
            <div class="date-input-combo">
              <input
                id="input-dep-fin"
                v-model="fechaFin"
                type="text"
                class="tecnm-input font-mono"
                placeholder="AAAA-MM-DD"
              />
              <input
                ref="pickerFinRef"
                type="date"
                class="hidden-date-picker"
                tabindex="-1"
                @change="onFechaPick('fin', $event)"
              />
              <button
                type="button"
                class="btn-calendar-trigger"
                title="Elegir fecha final"
                @click="abrirPicker('fin')"
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

        <!-- SECCIÓN 4: BOTONES F1 Y F2 (convertidos en botones institucionales) -->
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

      <!-- Barra de acciones inferior: Imprimir, Limpiar, Salir -->
      <footer class="window-footer-bar">
        <div class="footer-buttons-group">
          <button
            type="button"
            class="btn-action-primary"
            :disabled="granTotal === 0 && totalRegistros === 0"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="btn-icon">
              <polyline points="6 9 6 2 18 2 18 9"/>
              <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/>
              <rect x="6" y="14" width="12" height="8"/>
            </svg>
            Imprimir
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
          <span class="font-bold">F1 · Catálogo de Alumnos Registrados</span>
          <button type="button" class="window-btn-close" @click="mostrarModalF1Alumnos = false">&times;</button>
        </div>
        <div class="f1-submodal-body">
          <div v-if="isBuscandoAlumnos" class="f1-loading">Consultando alumnos en base de datos...</div>
          <table v-else class="f1-table">
            <thead>
              <tr>
                <th>Matrícula</th>
                <th>Nombre del Estudiante</th>
                <th>Carrera</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="a in alumnosLista" :key="a.matricula">
                <td class="font-mono font-bold">{{ a.matricula }}</td>
                <td>{{ a.nombreCompleto }}</td>
                <td>{{ a.carrera }}</td>
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
  max-width: 960px;
  background: #ffffff;
  border-radius: 10px;
  box-shadow: 0 20px 45px rgba(0, 0, 0, 0.35), 0 0 0 1px rgba(27, 57, 106, 0.15);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  max-height: 92vh;
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
  padding: 1.25rem 1.5rem;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 1.1rem;
}

.hidden-file-input {
  display: none;
}

/* SECCIÓN 1: Cuadrícula de Conceptos */
.conceptos-grid-box {
  display: grid;
  grid-template-columns: 1fr 180px;
  gap: 1.25rem;
  background: #f8fafc;
  padding: 1.15rem;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.modal-backdrop.dark-theme .conceptos-grid-box {
  background: #1e293b;
  border-color: #334155;
}

.conceptos-left-column {
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
}

.concepto-row {
  display: grid;
  grid-template-columns: 1fr 110px 90px;
  gap: 0.75rem;
  align-items: flex-end;
}

.field-item {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}

.field-label {
  font-size: 0.82rem;
  font-weight: 700;
  color: #1B396A;
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.modal-backdrop.dark-theme .field-label {
  color: #93c5fd;
}

.tecnm-input {
  height: 38px;
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

/* Card Total */
.total-display-card {
  background: linear-gradient(135deg, #1B396A 0%, #244B88 100%);
  color: #ffffff;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  border: 2px solid #C5A059;
  box-shadow: 0 4px 12px rgba(27, 57, 106, 0.25);
}

.total-title {
  font-size: 0.85rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: #C5A059;
}

.total-amount {
  font-size: 1.45rem;
  font-weight: 800;
  margin-top: 0.25rem;
}

/* SECCIÓN 2: Controles Medios */
.middle-controls-card {
  display: grid;
  grid-template-columns: 200px 160px auto 160px;
  align-items: flex-end;
  gap: 1rem;
  background: #f8fafc;
  padding: 1rem 1.15rem;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.modal-backdrop.dark-theme .middle-controls-card {
  background: #1e293b;
  border-color: #334155;
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
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  color: #1B396A;
  transition: all 0.15s;
}

.btn-calendar-trigger:hover {
  background: #e2e8f0;
  color: #C5A059;
}

.modal-backdrop.dark-theme .btn-calendar-trigger {
  color: #C5A059;
}

.modal-backdrop.dark-theme .btn-calendar-trigger:hover {
  background: #334155;
}

.calendar-icon {
  width: 17px;
  height: 17px;
}

/* Botón Abrir */
.btn-abrir-archivo {
  height: 38px;
  padding: 0 1.5rem;
  background: linear-gradient(135deg, #C5A059 0%, #b38e47 100%);
  color: #ffffff;
  font-weight: 700;
  font-size: 0.875rem;
  border: 1px solid #C5A059;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  transition: all 0.15s;
  white-space: nowrap;
}

.btn-abrir-archivo:hover {
  background: linear-gradient(135deg, #b38e47 0%, #997838 100%);
  box-shadow: 0 2px 6px rgba(197, 160, 89, 0.4);
}

.readonly-input {
  background: #e2e8f0 !important;
  cursor: default;
}

.modal-backdrop.dark-theme .readonly-input {
  background: #334155 !important;
}

/* SECCIÓN 3: Rango de Fechas */
.range-dates-card {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.25rem;
  background: #f8fafc;
  padding: 1rem 1.15rem;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.modal-backdrop.dark-theme .range-dates-card {
  background: #1e293b;
  border-color: #334155;
}

/* SECCIÓN 4: Botones F1 y F2 */
.f-buttons-bar {
  display: flex;
  gap: 1rem;
  padding: 0.25rem 0;
}

.btn-f-action {
  flex: 1;
  height: 40px;
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

/* Submodal F1 Alumnos */
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
  max-width: 650px;
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

