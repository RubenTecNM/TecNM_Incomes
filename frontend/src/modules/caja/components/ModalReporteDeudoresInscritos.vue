<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { useTheme } from '../../../shared/composables/useTheme'
import * as cajaApi from '../api/cajaApi'

const emit = defineEmits<{
  (e: 'close'): void
}>()

const { dark } = useTheme()

// ==========================================
// Estado del formulario
// ==========================================
interface ConceptoItem {
  id: string
  descripcion: string
}

const conceptosDisponibles = ref<ConceptoItem[]>([])
const conceptoSeleccionado = ref('')
const fecha = ref('')
const isBuscando = ref(false)
const pickerFechaRef = ref<HTMLInputElement | null>(null)

// Fallback de conceptos
const conceptosFallback: ConceptoItem[] = [
  { id: '', descripcion: '-- Seleccionar Concepto --' },
  { id: 'c1', descripcion: 'PAGO DE INSCRIPCION (PERIODO VIGENTE)' },
  { id: 'c2', descripcion: 'ADEUDO DE INSCRIPCION ANTERIOR' },
  { id: 'c3', descripcion: 'CURSO DE VERANO (POR ASIGNATURA)' },
  { id: 'c4', descripcion: 'EXPEDICION DE KARDEX' },
  { id: 'c5', descripcion: 'CONSTANCIA DE ESTUDIOS CON CALIFICACIONES' },
  { id: 'c6', descripcion: 'TRAMITE DE TITULACION INTEGRAL Y CEDULA' },
]

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

// Resultados de la búsqueda
interface FilaDeudorInscrito {
  matricula: string
  estudiante: string
  carrera: string
  fecha: string
  abono: number
  costo: number
  adeudo: number
}

const resultados = ref<FilaDeudorInscrito[]>([])
const totalAdeudo = ref(0)

async function buscar(): Promise<void> {
  if (!conceptoSeleccionado.value) return

  isBuscando.value = true
  // TODO: Conectar con endpoint GET /api/caja/deudores/inscritos?concepto={concepto}&fecha={fecha}
  await new Promise(resolve => setTimeout(resolve, 400)) // simulación de consulta
  resultados.value = []
  totalAdeudo.value = 0
  isBuscando.value = false
}

function formatearMoneda(valor: number): string {
  return valor.toLocaleString('es-MX', { style: 'currency', currency: 'MXN' })
}

function limpiar(): void {
  conceptoSeleccionado.value = ''
  fecha.value = ''
  resultados.value = []
  totalAdeudo.value = 0
}

function cerrar(): void {
  emit('close')
}

function handleKeydown(e: KeyboardEvent): void {
  if (e.key === 'Escape') cerrar()
}

onMounted(async () => {
  window.addEventListener('keydown', handleKeydown)
  try {
    const list = await cajaApi.getConceptos()
    if (list && list.length > 0) {
      conceptosDisponibles.value = [
        { id: '', descripcion: '-- Seleccionar Concepto --' },
        ...list.map(c => ({ id: c.id, descripcion: c.descripcion })),
      ]
    } else {
      conceptosDisponibles.value = conceptosFallback
    }
  } catch {
    conceptosDisponibles.value = conceptosFallback
  }
})

onUnmounted(() => window.removeEventListener('keydown', handleKeydown))
</script>

<template>
  <div class="modal-backdrop" :class="{ 'dark-theme': dark }" @click.self="cerrar">
    <div class="tecnm-window" role="dialog" aria-modal="true" aria-labelledby="deudores-inscritos-title">

      <!-- Barra de título institucional -->
      <header class="window-title-bar">
        <div class="window-title-left">
          <svg class="window-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
            <circle cx="9" cy="7" r="4"/>
            <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
            <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
          </svg>
          <span id="deudores-inscritos-title" class="window-title-text">Reporte de Deudores Inscritos</span>
        </div>
        <button type="button" class="window-btn-close" title="Cerrar (ESC)" aria-label="Cerrar ventana" @click="cerrar">
          &times;
        </button>
      </header>

      <!-- Panel de contenido y búsqueda -->
      <section class="window-content-panel">

        <!-- Fila superior: Concepto + Fecha + Buscar -->
        <div class="filter-bar-container">
          <!-- 1. Concepto -->
          <div class="field-item item-concepto">
            <label for="select-deudor-ins-concepto" class="field-label">Concepto:</label>
            <select
              id="select-deudor-ins-concepto"
              v-model="conceptoSeleccionado"
              class="tecnm-input tecnm-select"
            >
              <option v-for="c in conceptosDisponibles" :key="c.id" :value="c.id">
                {{ c.descripcion }}
              </option>
            </select>
          </div>

          <!-- 2. Fecha -->
          <div class="field-item item-fecha">
            <label for="input-deudor-ins-fecha" class="field-label">Fecha:</label>
            <div class="date-input-combo">
              <input
                id="input-deudor-ins-fecha"
                v-model="fecha"
                type="text"
                class="tecnm-input input-date font-mono"
                placeholder="AAAA-MM-DD o escribir..."
                autocomplete="off"
                @keyup.enter="buscar"
              />
              <input
                ref="pickerFechaRef"
                type="date"
                class="hidden-date-picker"
                tabindex="-1"
                aria-hidden="true"
                @change="onFechaSeleccionada"
              />
              <button
                type="button"
                class="btn-calendar-trigger"
                title="Elegir fecha"
                aria-label="Abrir calendario fecha"
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

          <!-- 3. Botón Buscar -->
          <button
            type="button"
            class="btn-buscar"
            :disabled="!conceptoSeleccionado || isBuscando"
            @click="buscar"
          >
            <svg v-if="isBuscando" class="spin-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
            </svg>
            <svg v-else class="btn-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="11" cy="11" r="8"/>
              <line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            {{ isBuscando ? 'Buscando...' : 'Buscar' }}
          </button>
        </div>

        <!-- Tabla de resultados: Matrícula, Estudiante, Carrera, Fecha, Abono, Costo, Adeudo -->
        <div class="table-container">
          <table class="deudores-table">
            <thead>
              <tr>
                <th class="col-matricula">Matrícula</th>
                <th class="col-estudiante">Estudiante</th>
                <th class="col-carrera">Carrera</th>
                <th class="col-fecha">Fecha</th>
                <th class="col-monto">Abono</th>
                <th class="col-monto">Costo</th>
                <th class="col-monto">Adeudo</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="resultados.length === 0 && !isBuscando">
                <td colspan="7" class="empty-cell">
                  <div class="empty-state">
                    <svg class="empty-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                      <circle cx="9" cy="7" r="4"/>
                      <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                      <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                    </svg>
                    <span>{{ conceptoSeleccionado ? 'No se encontraron estudiantes inscritos con adeudo para los criterios seleccionados' : 'Selecciona un concepto y fecha para consultar el reporte de deudores inscritos' }}</span>
                  </div>
                </td>
              </tr>
              <tr v-else-if="isBuscando">
                <td colspan="7" class="empty-cell">
                  <div class="empty-state">
                    <span>Consultando alumnos inscritos con adeudos en la base de datos...</span>
                  </div>
                </td>
              </tr>
              <tr v-for="(fila, idx) in resultados" :key="idx" class="data-row">
                <td class="col-matricula font-mono font-bold">{{ fila.matricula }}</td>
                <td class="col-estudiante">{{ fila.estudiante }}</td>
                <td class="col-carrera">{{ fila.carrera }}</td>
                <td class="col-fecha font-mono">{{ fila.fecha }}</td>
                <td class="col-monto font-mono text-right">{{ formatearMoneda(fila.abono) }}</td>
                <td class="col-monto font-mono text-right">{{ formatearMoneda(fila.costo) }}</td>
                <td class="col-monto font-mono text-right font-bold text-danger">{{ formatearMoneda(fila.adeudo) }}</td>
              </tr>
            </tbody>
          </table>
        </div>

      </section>

      <!-- Barra de acciones inferior: Imprimir, Limpiar, Salir -->
      <footer class="window-footer-bar">
        <div class="footer-buttons-group">
          <button
            type="button"
            class="btn-action-primary"
            :disabled="resultados.length === 0"
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

      </footer>

    </div>
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

/* Ventana principal */
.tecnm-window {
  width: 100%;
  max-width: 1020px;
  background: #ffffff;
  border-radius: 10px;
  box-shadow: 0 20px 45px rgba(0, 0, 0, 0.35), 0 0 0 1px rgba(27, 57, 106, 0.15);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  max-height: 90vh;
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
  gap: 1rem;
}

/* Fila de filtros principal */
.filter-bar-container {
  display: grid;
  grid-template-columns: 1fr auto auto;
  align-items: flex-end;
  gap: 1rem;
  background: #f8fafc;
  padding: 1rem 1.25rem;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.modal-backdrop.dark-theme .filter-bar-container {
  background: #1e293b;
  border-color: #334155;
}

.field-item {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}

.item-concepto {
  min-width: 280px;
}

.item-fecha {
  min-width: 210px;
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

/* Combo fecha (texto + botón calendario) */
.date-input-combo {
  display: flex;
  position: relative;
  align-items: center;
}

.input-date {
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

/* Botón Buscar */
.btn-buscar {
  height: 38px;
  padding: 0 1.5rem;
  background: linear-gradient(135deg, #1B396A 0%, #244B88 100%);
  color: #ffffff;
  font-weight: 700;
  font-size: 0.875rem;
  border: 1px solid #1B396A;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  transition: all 0.15s;
  white-space: nowrap;
}

.btn-buscar:hover:not(:disabled) {
  background: linear-gradient(135deg, #244B88 0%, #1B396A 100%);
  border-color: #C5A059;
  box-shadow: 0 2px 6px rgba(27, 57, 106, 0.3);
}

.btn-buscar:disabled {
  opacity: 0.5;
  cursor: not-allowed;
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

/* Contenedor de la tabla */
.table-container {
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  overflow-x: auto;
  max-height: 400px;
  background: #ffffff;
}

.modal-backdrop.dark-theme .table-container {
  border-color: #334155;
  background: #0f172a;
}

.deudores-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.85rem;
}

.deudores-table thead {
  background: linear-gradient(180deg, #1B396A 0%, #152d54 100%);
  color: #ffffff;
  position: sticky;
  top: 0;
  z-index: 10;
}

.deudores-table th {
  padding: 0.65rem 0.85rem;
  font-weight: 700;
  font-size: 0.8rem;
  letter-spacing: 0.3px;
  text-align: left;
  border-right: 1px solid rgba(255, 255, 255, 0.12);
  white-space: nowrap;
}

.deudores-table th:last-child {
  border-right: none;
}

.col-matricula {
  width: 120px;
}

.col-estudiante {
  min-width: 220px;
}

.col-carrera {
  min-width: 180px;
}

.col-fecha {
  width: 110px;
}

.col-monto {
  width: 110px;
  text-align: right;
}

.data-row {
  border-bottom: 1px solid #e2e8f0;
  transition: background 0.1s;
}

.modal-backdrop.dark-theme .data-row {
  border-color: #1e293b;
}

.data-row:hover {
  background: #f1f5f9;
}

.modal-backdrop.dark-theme .data-row:hover {
  background: #1e293b;
}

.deudores-table td {
  padding: 0.55rem 0.85rem;
  color: #1e293b;
}

.modal-backdrop.dark-theme .deudores-table td {
  color: #f1f5f9;
}

.empty-cell {
  padding: 3rem 1rem !important;
  text-align: center;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
  color: #64748b;
  font-size: 0.875rem;
}

.empty-icon {
  width: 36px;
  height: 36px;
  opacity: 0.5;
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

.font-mono {
  font-family: 'Consolas', 'Courier New', monospace;
}

.text-right {
  text-align: right;
}

.font-bold {
  font-weight: 700;
}

.text-danger {
  color: #dc2626 !important;
}

.modal-backdrop.dark-theme .text-danger {
  color: #f87171 !important;
}
</style>

