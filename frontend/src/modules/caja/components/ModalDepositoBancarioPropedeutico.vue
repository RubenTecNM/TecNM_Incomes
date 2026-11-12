<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { useTheme } from '../../../shared/composables/useTheme'
import * as cajaApi from '../api/cajaApi'
import ModalCuentas from '../../catalogos/components/ModalCuentas.vue'

const emit = defineEmits<{
  (e: 'close'): void
}>()

const { dark } = useTheme()

// ==========================================
// Campos del Formulario
// ==========================================
// "lo de no. de recibo eso dejalo en blanco eso se va allenar por default"
const numeroRecibo = ref('')
const totalRegistros = ref<number | ''>('')
const fechaInicio = ref('')
const fechaFin = ref('')
const nombreArchivoCargado = ref('')

// Mensajes y estados
const isImprimiendo = ref(false)
const mensajeExito = ref('')

// Referencias a inputs de archivos y calendarios
const fileInputRef = ref<HTMLInputElement | null>(null)
const pickerInicioRef = ref<HTMLInputElement | null>(null)
const pickerFinRef = ref<HTMLInputElement | null>(null)

// Modales secundarios de F1 (Alumnos) y F2 (Cuentas)
const mostrarModalF2Cuentas = ref(false)
const mostrarModalF1Alumnos = ref(false)

// Lista de alumnos para submodal F1
interface AlumnoPreview {
  matricula: string
  nombreCompleto: string
  carrera: string
}
const alumnosLista = ref<AlumnoPreview[]>([])
const isBuscandoAlumnos = ref(false)

// ==========================================
// Manejo del Archivo de Depósito Bancario
// ==========================================
function abrirExploradorArchivos(): void {
  if (fileInputRef.value) {
    fileInputRef.value.click()
  }
}

function onArchivoSeleccionado(e: Event): void {
  const target = e.target as HTMLInputElement
  if (target.files && target.files.length > 0) {
    const file = target.files[0]
    nombreArchivoCargado.value = file.name

    // Cálculo simulado de registros basado en el archivo
    if (file.size > 0) {
      totalRegistros.value = Math.max(1, Math.min(850, Math.floor(file.size / 110)))
    } else {
      totalRegistros.value = 1
    }
  }
}

// ==========================================
// Selectores de Fecha (Inicio y Fin)
// ==========================================
function abrirPicker(tipo: 'inicio' | 'fin'): void {
  const refMap = {
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

function onFechaSeleccionada(tipo: 'inicio' | 'fin', event: Event): void {
  const target = event.target as HTMLInputElement
  if (target && target.value) {
    if (tipo === 'inicio') fechaInicio.value = target.value
    if (tipo === 'fin') fechaFin.value = target.value
  }
}

// ==========================================
// Modales F1 (Alumnos) y F2 (Cuentas)
// ==========================================
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

function abrirF2Cuentas(): void {
  mostrarModalF2Cuentas.value = true
}

// ==========================================
// Acciones: Imprimir, Limpiar, Salir
// ==========================================
async function imprimir(): Promise<void> {
  isImprimiendo.value = true
  await new Promise(resolve => setTimeout(resolve, 600))
  mensajeExito.value = `Generando impresión para Recibo Propedéutico No. ${numeroRecibo.value || '128710'}`
  isImprimiendo.value = false
  setTimeout(() => {
    mensajeExito.value = ''
  }, 4000)
}

function limpiar(): void {
  totalRegistros.value = ''
  fechaInicio.value = ''
  fechaFin.value = ''
  nombreArchivoCargado.value = ''
  mensajeExito.value = ''
  if (fileInputRef.value) {
    fileInputRef.value.value = ''
  }
}

function cerrar(): void {
  emit('close')
}

// Atajos de teclado
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

  // Autollenado por default del número de recibo consecutivo
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

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<template>
  <div class="modal-backdrop" :class="{ 'dark-theme': dark }" @click.self="cerrar">
    <div class="tecnm-window" role="dialog" aria-modal="true" aria-labelledby="dep-prop-title">

      <!-- 1. Barra de título institucional TecNM -->
      <header class="window-title-bar">
        <div class="window-title-left">
          <svg class="window-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="2" y="5" width="20" height="14" rx="2"/>
            <line x1="2" y1="10" x2="22" y2="10"/>
          </svg>
          <span id="dep-prop-title" class="window-title-text">Imprime Recibo Propedéutico</span>
          <span class="badge-subtitle">Curso Propedéutico</span>
        </div>
        <button
          type="button"
          class="window-btn-close"
          title="Cerrar (ESC)"
          aria-label="Cerrar ventana"
          @click="cerrar"
        >
          &times;
        </button>
      </header>

      <!-- 2. Panel de Contenido -->
      <section class="window-content-panel">

        <!-- Banner de éxito -->
        <div v-if="mensajeExito" class="alert-success">
          <svg class="alert-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="20 6 9 17 4 12"/>
          </svg>
          <span>{{ mensajeExito }}</span>
        </div>

        <!-- Input de archivo oculto para el botón Abrir -->
        <input
          ref="fileInputRef"
          type="file"
          class="hidden-file-input"
          accept=".txt,.csv,.xlsx,.xls,.dat"
          @change="onArchivoSeleccionado"
        />

        <!-- FILA SUPERIOR: Recibo No + Botón Abrir + Total de Registros -->
        <div class="section-card top-controls-card">
          <div class="field-item item-recibo-no">
            <label for="input-prop-recibo-no" class="field-label">Recibo No:</label>
            <input
              id="input-prop-recibo-no"
              v-model="numeroRecibo"
              type="text"
              class="tecnm-input font-mono font-bold text-center input-recibo-number"
              placeholder="128710"
            />
          </div>

          <div class="abrir-group">
            <button
              type="button"
              class="btn-abrir-archivo"
              title="Seleccionar archivo de depósito bancario"
              @click="abrirExploradorArchivos"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="btn-icon">
                <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>
              </svg>
              <span>Abrir</span>
            </button>
            <span v-if="nombreArchivoCargado" class="loaded-file-name" :title="nombreArchivoCargado">
              📁 {{ nombreArchivoCargado }}
            </span>
          </div>

          <div class="field-item item-total-registros">
            <label for="input-prop-total-registros" class="field-label">Total de Registros:</label>
            <input
              id="input-prop-total-registros"
              :value="totalRegistros !== '' ? totalRegistros : ''"
              type="text"
              readonly
              class="tecnm-input font-mono text-center readonly-input"
              placeholder="0"
            />
          </div>
        </div>

        <!-- FILA INTERMEDIA: Fechas (Inicio / Fin) y Botón Imprimir Centrado -->
        <div class="section-card dates-print-card">
          <div class="dates-subgroup">
            <!-- Fecha Inicio -->
            <div class="field-item item-date">
              <label for="input-prop-fecha-inicio" class="field-label">Inicio:</label>
              <div class="date-input-combo">
                <input
                  id="input-prop-fecha-inicio"
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
                  @change="(e) => onFechaSeleccionada('inicio', e)"
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

            <!-- Fecha Fin -->
            <div class="field-item item-date">
              <label for="input-prop-fecha-fin" class="field-label">Fin:</label>
              <div class="date-input-combo">
                <input
                  id="input-prop-fecha-fin"
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
                  @change="(e) => onFechaSeleccionada('fin', e)"
                />
                <button
                  type="button"
                  class="btn-calendar-trigger"
                  title="Elegir fecha de fin"
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

          <!-- Botón Imprimir Destacado -->
          <div class="print-center-action">
            <button
              type="button"
              class="btn-imprimir-main"
              :disabled="isImprimiendo"
              @click="imprimir"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="btn-icon-lg">
                <polyline points="6 9 6 2 18 2 18 9"/>
                <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/>
                <rect x="6" y="14" width="12" height="8"/>
              </svg>
              <span>{{ isImprimiendo ? 'Imprimiendo...' : 'Imprimir' }}</span>
            </button>
          </div>
        </div>

        <!-- FILA DE BOTONES F1 Y F2 (convertidos en botones institucionales interactivos) -->
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

      <!-- 3. Barra de acciones inferior: Limpiar, Salir -->
      <footer class="window-footer-bar">
        <div class="footer-buttons-group">
          <button
            type="button"
            class="btn-action-secondary"
            title="Limpiar los campos de captura"
            @click="limpiar"
          >
            Limpiar
          </button>

          <button
            type="button"
            class="btn-action-danger"
            title="Cerrar la ventana (ESC)"
            @click="cerrar"
          >
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
      <div class="f1-submodal-window" role="dialog" aria-modal="true" aria-label="Consulta F1 Alumnos">
        <header class="f1-submodal-header">
          <div class="f1-submodal-title">
            <span class="f-badge">F1</span>
            <span>Lista de Alumnos (Base de Datos)</span>
          </div>
          <button type="button" class="window-btn-close" @click="mostrarModalF1Alumnos = false">&times;</button>
        </header>

        <div class="f1-submodal-body">
          <div v-if="isBuscandoAlumnos" class="f1-loading-state">
            <span>Cargando estudiantes de PostgreSQL...</span>
          </div>
          <div v-else-if="alumnosLista.length === 0" class="f1-empty-state">
            <span>No se encontraron estudiantes registrados.</span>
          </div>
          <div v-else class="f1-table-wrap">
            <table class="f1-table">
              <thead>
                <tr>
                  <th>Matrícula</th>
                  <th>Nombre Completo</th>
                  <th>Carrera</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="a in alumnosLista" :key="a.matricula" class="f1-row">
                  <td class="font-mono font-bold">{{ a.matricula }}</td>
                  <td>{{ a.nombreCompleto }}</td>
                  <td>{{ a.carrera }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <footer class="f1-submodal-footer">
          <button type="button" class="btn-action-secondary" @click="mostrarModalF1Alumnos = false">Cerrar</button>
        </footer>
      </div>
    </div>

    <!-- DIÁLOGO MODAL F2: Catálogo de Cuentas -->
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
  max-width: 820px;
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

.badge-subtitle {
  background: rgba(197, 160, 89, 0.25);
  color: #F8FAFC;
  border: 1px solid #C5A059;
  border-radius: 4px;
  padding: 0.15rem 0.5rem;
  font-size: 0.75rem;
  font-weight: 600;
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
  padding: 1.5rem 1.75rem;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.alert-success {
  background: #ECFDF5;
  color: #065F46;
  border: 1px solid #A7F3D0;
  padding: 0.75rem 1rem;
  border-radius: 6px;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 0.875rem;
  font-weight: 500;
}

.modal-backdrop.dark-theme .alert-success {
  background: rgba(6, 95, 70, 0.25);
  color: #6EE7B7;
  border-color: #065F46;
}

.alert-icon {
  width: 18px;
  height: 18px;
  flex-shrink: 0;
}

.hidden-file-input {
  display: none;
}

/* Tarjetas de sección */
.section-card {
  background: #F8FAFC;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  padding: 1.25rem 1.5rem;
}

.modal-backdrop.dark-theme .section-card {
  background: #1E293B;
  border-color: #334155;
}

/* Fila Superior: Recibo No + Abrir + Total de Registros */
.top-controls-card {
  display: grid;
  grid-template-columns: 180px 1fr 180px;
  gap: 1.25rem;
  align-items: center;
}

.abrir-group {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.35rem;
}

.btn-abrir-archivo {
  height: 40px;
  padding: 0 1.5rem;
  background: #1B396A;
  color: #ffffff;
  border: 1px solid #244B88;
  border-radius: 6px;
  font-weight: 600;
  font-size: 0.875rem;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  transition: background 0.15s, border-color 0.15s, transform 0.1s;
}

.btn-abrir-archivo:hover {
  background: #244B88;
  border-color: #C5A059;
  transform: translateY(-1px);
}

.loaded-file-name {
  font-size: 0.75rem;
  color: #244B88;
  max-width: 220px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-weight: 600;
}

.modal-backdrop.dark-theme .loaded-file-name {
  color: #C5A059;
}

/* Fila de Fechas y Botón Imprimir */
.dates-print-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 2rem;
}

.dates-subgroup {
  display: flex;
  gap: 1.5rem;
}

.item-date {
  width: 170px;
}

.date-input-combo {
  position: relative;
  display: flex;
  align-items: center;
}

.date-input-combo .tecnm-input {
  width: 100%;
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
  cursor: pointer;
  color: #1B396A;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition: color 0.15s, background 0.15s;
}

.modal-backdrop.dark-theme .btn-calendar-trigger {
  color: #C5A059;
}

.btn-calendar-trigger:hover {
  background: rgba(27, 57, 106, 0.1);
}

.calendar-icon {
  width: 18px;
  height: 18px;
}

/* Botón Imprimir Destacado */
.print-center-action {
  display: flex;
  align-items: center;
}

.btn-imprimir-main {
  height: 48px;
  padding: 0 2rem;
  background: linear-gradient(135deg, #1B396A 0%, #244B88 100%);
  color: #ffffff;
  border: 1px solid #C5A059;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 0.65rem;
  box-shadow: 0 4px 12px rgba(27, 57, 106, 0.25);
  transition: all 0.15s ease;
}

.btn-imprimir-main:hover:not(:disabled) {
  background: linear-gradient(135deg, #244B88 0%, #1B396A 100%);
  box-shadow: 0 6px 16px rgba(27, 57, 106, 0.35);
  transform: translateY(-1px);
}

.btn-imprimir-main:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-icon-lg {
  width: 20px;
  height: 20px;
  color: #C5A059;
}

/* Campos comunes */
.field-item {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}

.field-label {
  font-size: 0.8rem;
  font-weight: 600;
  color: #1B396A;
  letter-spacing: 0.2px;
}

.modal-backdrop.dark-theme .field-label {
  color: #E2E8F0;
}

.tecnm-input {
  height: 38px;
  padding: 0 0.75rem;
  border: 1px solid #CBD5E1;
  border-radius: 6px;
  font-size: 0.9rem;
  color: #1E293B;
  background: #FFFFFF;
  transition: border-color 0.15s, box-shadow 0.15s;
  box-sizing: border-box;
}

.modal-backdrop.dark-theme .tecnm-input {
  background: #1E293B;
  border-color: #334155;
  color: #F1F5F9;
}

.tecnm-input:focus {
  outline: none;
  border-color: #1B396A;
  box-shadow: 0 0 0 3px rgba(27, 57, 106, 0.15);
}

.modal-backdrop.dark-theme .tecnm-input:focus {
  border-color: #C5A059;
  box-shadow: 0 0 0 3px rgba(197, 160, 89, 0.2);
}

.input-recibo-number {
  color: #1B396A;
}

.modal-backdrop.dark-theme .input-recibo-number {
  color: #C5A059;
}

.readonly-input {
  background: #F1F5F9 !important;
  color: #475569;
  border-color: #E2E8F0;
}

.modal-backdrop.dark-theme .readonly-input {
  background: #0F172A !important;
  color: #94A3B8;
  border-color: #1E293B;
}

/* Botones F1 y F2 */
.f-buttons-bar {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1.25rem;
  padding-top: 0.5rem;
}

.btn-f-action {
  display: inline-flex;
  align-items: center;
  gap: 0.55rem;
  padding: 0.5rem 1rem;
  background: #F1F5F9;
  border: 1px solid #CBD5E1;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
  color: #1B396A;
  font-size: 0.85rem;
  font-weight: 600;
}

.modal-backdrop.dark-theme .btn-f-action {
  background: #1E293B;
  border-color: #334155;
  color: #E2E8F0;
}

.btn-f-action:hover {
  background: #E2E8F0;
  border-color: #1B396A;
  transform: translateY(-1px);
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
  font-weight: 700;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}

.modal-backdrop.dark-theme .f-badge {
  background: #C5A059;
  color: #0F172A;
}

.f-label {
  font-weight: 600;
}

/* Barra inferior de acciones */
.window-footer-bar {
  background: #F8FAFC;
  border-top: 1px solid #E2E8F0;
  padding: 0.85rem 1.5rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.modal-backdrop.dark-theme .window-footer-bar {
  background: #0F172A;
  border-color: #1E293B;
}

.footer-buttons-group {
  display: flex;
  gap: 0.75rem;
}

.btn-action-secondary {
  height: 38px;
  padding: 0 1.25rem;
  background: #FFFFFF;
  color: #1B396A;
  border: 1px solid #CBD5E1;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s, border-color 0.15s;
}

.modal-backdrop.dark-theme .btn-action-secondary {
  background: #1E293B;
  color: #F1F5F9;
  border-color: #334155;
}

.btn-action-secondary:hover {
  background: #F1F5F9;
  border-color: #94A3B8;
}

.btn-action-danger {
  height: 38px;
  padding: 0 1.25rem;
  background: #DC2626;
  color: #ffffff;
  border: none;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s;
}

.btn-action-danger:hover {
  background: #B91C1C;
}

.btn-icon {
  width: 16px;
  height: 16px;
}

.footer-hint {
  font-size: 0.75rem;
  color: #94A3B8;
}

.footer-hint kbd {
  background: #E2E8F0;
  color: #334155;
  padding: 0.15rem 0.4rem;
  border-radius: 4px;
  font-size: 0.7rem;
  font-weight: 700;
}

.modal-backdrop.dark-theme .footer-hint kbd {
  background: #334155;
  color: #CBD5E1;
}

/* Estilos de submodal F1 */
.f1-submodal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1300;
  padding: 1rem;
}

.f1-submodal-window {
  width: 100%;
  max-width: 640px;
  background: #FFFFFF;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 15px 35px rgba(0, 0, 0, 0.4);
}

.modal-backdrop.dark-theme .f1-submodal-window {
  background: #1E293B;
  color: #F1F5F9;
}

.f1-submodal-header {
  background: #1B396A;
  color: #FFFFFF;
  padding: 0.65rem 1rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.f1-submodal-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 700;
  font-size: 0.9rem;
}

.f1-submodal-body {
  padding: 1rem;
  max-height: 320px;
  overflow-y: auto;
}

.f1-table-wrap {
  border: 1px solid #E2E8F0;
  border-radius: 6px;
  overflow: hidden;
}

.modal-backdrop.dark-theme .f1-table-wrap {
  border-color: #334155;
}

.f1-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.85rem;
}

.f1-table th {
  background: #F1F5F9;
  padding: 0.5rem 0.75rem;
  text-align: left;
  font-weight: 600;
  color: #1B396A;
}

.modal-backdrop.dark-theme .f1-table th {
  background: #0F172A;
  color: #C5A059;
}

.f1-table td {
  padding: 0.5rem 0.75rem;
  border-bottom: 1px solid #E2E8F0;
}

.modal-backdrop.dark-theme .f1-table td {
  border-bottom-color: #334155;
}

.f1-submodal-footer {
  padding: 0.75rem 1rem;
  background: #F8FAFC;
  display: flex;
  justify-content: flex-end;
  border-top: 1px solid #E2E8F0;
}

.modal-backdrop.dark-theme .f1-submodal-footer {
  background: #0F172A;
  border-color: #334155;
}

.f1-loading-state, .f1-empty-state {
  padding: 2rem;
  text-align: center;
  color: #94A3B8;
  font-size: 0.9rem;
}

/* Utilidades */
.font-mono {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}

.font-bold {
  font-weight: 700;
}

.text-center {
  text-align: center;
}
</style>
