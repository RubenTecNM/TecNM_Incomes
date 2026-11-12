<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { useTheme } from '../../../shared/composables/useTheme'

const emit = defineEmits<{
  (e: 'close'): void
}>()

const { dark } = useTheme()

// ==========================================
// Filtros disponibles (con casillas de activación)
// ==========================================
// 1. Filtro Cliente
const activarCliente = ref(false)
const matricula = ref('')
const nombreCliente = ref('')

// 2. Filtro Cuenta
const activarCuenta = ref(false)
const conceptoSeleccionado = ref('')

// Catálogo de conceptos para el filtro de cuenta (preparado para PostgreSQL)
const conceptosCatalogo = [
  { id: '', nombre: '-- Seleccionar Concepto / Cuenta --' },
  { id: 'c1', nombre: 'KARDEX - EXPEDICION DE KARDEX' },
  { id: 'c2', nombre: 'PAGO DE INSCRIPCION (PERIODO VIGENTE)' },
  { id: 'c3', nombre: 'ADEUDO DE INSCRIPCION ANTERIOR' },
  { id: 'c4', nombre: 'CURSO DE VERANO (POR ASIGNATURA)' },
  { id: 'c5', nombre: 'CONSTANCIA DE ESTUDIOS CON CALIFICACIONES' },
  { id: 'c6', nombre: 'TRAMITE DE TITULACION INTEGRAL Y CEDULA' },
]

// 3. Filtro Fecha (Rango)
const activarFecha = ref(false)
const fechaInicio = ref('')
const fechaFin = ref('')

const pickerInicioRef = ref<HTMLInputElement | null>(null)
const pickerFinRef = ref<HTMLInputElement | null>(null)

function abrirCalendario(campo: 'inicio' | 'fin'): void {
  if (campo === 'inicio') {
    pickerInicioRef.value?.showPicker?.()
  } else {
    pickerFinRef.value?.showPicker?.()
  }
}

function onFechaSeleccionada(campo: 'inicio' | 'fin', event: Event): void {
  const target = event.target as HTMLInputElement
  if (target?.value) {
    if (campo === 'inicio') fechaInicio.value = target.value
    else fechaFin.value = target.value
  }
}

// ==========================================
// Impresoras y búsqueda
// ==========================================
const impresora = ref('')
const isBuscando = ref(false)

const impresorasDisponibles = [
  { id: '', nombre: '-- Seleccionar impresora --' },
  { id: 'termica', nombre: 'Impresora Térmica de Recibos (Caja)' },
  { id: 'laser', nombre: 'Impresora Láser Institucional (Reportes)' },
  { id: 'pdf', nombre: 'Exportar a Documento PDF' },
]

// Resultados de la búsqueda (vacío hasta conectar con PostgreSQL)
interface FilaReporteVarios {
  fecha: string
  folio: string
  concepto: string
  nombre: string
  total: number
  estatus: string
}

const resultados = ref<FilaReporteVarios[]>([])
const totalGeneral = ref(0)

async function buscar(): Promise<void> {
  isBuscando.value = true
  // TODO: Conectar con endpoint GET /api/reportes/varios con filtros activados
  // { matricula, nombre, concepto, fechaInicio, fechaFin }
  await new Promise(resolve => setTimeout(resolve, 400)) // simulación de consulta
  resultados.value = []
  totalGeneral.value = 0
  isBuscando.value = false
}

function formatearMoneda(valor: number): string {
  return valor.toLocaleString('es-MX', { style: 'currency', currency: 'MXN' })
}

function limpiar(): void {
  activarCliente.value = false
  matricula.value = ''
  nombreCliente.value = ''
  activarCuenta.value = false
  conceptoSeleccionado.value = ''
  activarFecha.value = false
  fechaInicio.value = ''
  fechaFin.value = ''
  impresora.value = ''
  resultados.value = []
  totalGeneral.value = 0
}

function cerrar(): void {
  emit('close')
}

function handleKeydown(e: KeyboardEvent): void {
  if (e.key === 'Escape') cerrar()
}

onMounted(() => window.addEventListener('keydown', handleKeydown))
onUnmounted(() => window.removeEventListener('keydown', handleKeydown))
</script>

<template>
  <div class="modal-backdrop" :class="{ 'dark-theme': dark }" @click.self="cerrar">
    <div class="tecnm-window" role="dialog" aria-modal="true" aria-labelledby="varios-title">

      <!-- Barra de título institucional -->
      <header class="window-title-bar">
        <div class="window-title-left">
          <svg class="window-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polygon points="12 2 2 7 12 12 22 7 12 2"/>
            <polyline points="2 17 12 22 22 17"/>
            <polyline points="2 12 12 17 22 12"/>
          </svg>
          <span id="varios-title" class="window-title-text">Reporte Varios</span>
        </div>
        <button type="button" class="window-btn-close" title="Cerrar (ESC)" aria-label="Cerrar ventana" @click="cerrar">
          &times;
        </button>
      </header>

      <!-- Panel de contenido y filtros -->
      <section class="window-content-panel">

        <div class="top-filters-wrapper">
          <div class="filters-column">

            <!-- 1. Filtro Cliente -->
            <div class="filter-group-row">
              <label class="checkbox-container">
                <input v-model="activarCliente" type="checkbox" class="filter-checkbox" />
                <span class="custom-checkbox"></span>
              </label>

              <fieldset class="filter-fieldset" :disabled="!activarCliente" :class="{ active: activarCliente }">
                <legend class="fieldset-legend">Cliente</legend>
                <div class="fieldset-body client-body">
                  <div class="field-item item-matricula">
                    <label for="input-var-matricula" class="field-label">Matrícula</label>
                    <input
                      id="input-var-matricula"
                      v-model="matricula"
                      type="text"
                      class="tecnm-input font-mono"
                      placeholder="Ej. 23050..."
                      autocomplete="off"
                    />
                  </div>

                  <div class="field-item item-nombre">
                    <label for="input-var-nombre" class="field-label">Nombre:</label>
                    <input
                      id="input-var-nombre"
                      v-model="nombreCliente"
                      type="text"
                      class="tecnm-input"
                      placeholder="Nombre del estudiante o cliente..."
                      autocomplete="off"
                    />
                  </div>
                </div>
              </fieldset>
            </div>

            <!-- 2. Filtro Cuenta -->
            <div class="filter-group-row">
              <label class="checkbox-container">
                <input v-model="activarCuenta" type="checkbox" class="filter-checkbox" />
                <span class="custom-checkbox"></span>
              </label>

              <fieldset class="filter-fieldset" :disabled="!activarCuenta" :class="{ active: activarCuenta }">
                <legend class="fieldset-legend">Cuenta</legend>
                <div class="fieldset-body">
                  <div class="field-item item-concepto-full">
                    <label for="select-var-concepto" class="field-label">Concepto:</label>
                    <select
                      id="select-var-concepto"
                      v-model="conceptoSeleccionado"
                      class="tecnm-input tecnm-select"
                    >
                      <option v-for="c in conceptosCatalogo" :key="c.id" :value="c.id">
                        {{ c.nombre }}
                      </option>
                    </select>
                  </div>
                </div>
              </fieldset>
            </div>

            <!-- 3. Filtro Fecha -->
            <div class="filter-group-row">
              <label class="checkbox-container">
                <input v-model="activarFecha" type="checkbox" class="filter-checkbox" />
                <span class="custom-checkbox"></span>
              </label>

              <fieldset class="filter-fieldset" :disabled="!activarFecha" :class="{ active: activarFecha }">
                <legend class="fieldset-legend">Fecha:</legend>
                <div class="fieldset-body date-body">
                  <div class="field-item item-fecha-sub">
                    <div class="date-input-combo">
                      <input
                        id="input-var-fecha-inicio"
                        v-model="fechaInicio"
                        type="text"
                        class="tecnm-input input-date-code font-mono"
                        placeholder="AAAA-MM-DD o escribir..."
                        autocomplete="off"
                        :disabled="!activarFecha"
                        @keyup.enter="buscar"
                      />
                      <input
                        ref="pickerInicioRef"
                        type="date"
                        class="hidden-date-picker"
                        tabindex="-1"
                        aria-hidden="true"
                        @change="onFechaSeleccionada('inicio', $event)"
                      />
                      <button
                        type="button"
                        class="btn-calendar-trigger"
                        title="Elegir fecha de inicio"
                        aria-label="Abrir calendario fecha inicial"
                        :disabled="!activarFecha"
                        @click="abrirCalendario('inicio')"
                      >
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="calendar-icon">
                          <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
                          <line x1="16" y1="2" x2="16" y2="6" />
                          <line x1="8" y1="2" x2="8" y2="6" />
                          <line x1="3" y1="10" x2="21" y2="10" />
                        </svg>
                      </button>
                    </div>
                  </div>

                  <span class="range-separator">Y</span>

                  <div class="field-item item-fecha-sub">
                    <div class="date-input-combo">
                      <input
                        id="input-var-fecha-fin"
                        v-model="fechaFin"
                        type="text"
                        class="tecnm-input input-date-code font-mono"
                        placeholder="AAAA-MM-DD o escribir..."
                        autocomplete="off"
                        :disabled="!activarFecha"
                        @keyup.enter="buscar"
                      />
                      <input
                        ref="pickerFinRef"
                        type="date"
                        class="hidden-date-picker"
                        tabindex="-1"
                        aria-hidden="true"
                        @change="onFechaSeleccionada('fin', $event)"
                      />
                      <button
                        type="button"
                        class="btn-calendar-trigger"
                        title="Elegir fecha final"
                        aria-label="Abrir calendario fecha final"
                        :disabled="!activarFecha"
                        @click="abrirCalendario('fin')"
                      >
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="calendar-icon">
                          <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
                          <line x1="16" y1="2" x2="16" y2="6" />
                          <line x1="8" y1="2" x2="8" y2="6" />
                          <line x1="3" y1="10" x2="21" y2="10" />
                        </svg>
                      </button>
                    </div>
                  </div>
                </div>
              </fieldset>
            </div>

          </div>

          <!-- Botón Buscar en el lateral derecho como en la imagen -->
          <div class="search-btn-wrapper">
            <button
              type="button"
              class="btn-buscar-large"
              :disabled="isBuscando"
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
        </div>

        <!-- Rejilla con columnas: Fecha, Folio, Concepto, Nombre, Total, Satus -->
        <div class="table-container">
          <table class="reporte-table">
            <thead>
              <tr>
                <th class="col-fecha">Fecha</th>
                <th class="col-folio">Folio</th>
                <th class="col-concepto">Concepto</th>
                <th class="col-nombre">Nombre</th>
                <th class="col-total">Total</th>
                <th class="col-estatus">Estatus</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="resultados.length === 0 && !isBuscando">
                <td colspan="6" class="empty-cell">
                  <div class="empty-state">
                    <svg class="empty-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                      <polygon points="12 2 2 7 12 12 22 7 12 2"/>
                      <polyline points="2 17 12 22 22 17"/>
                      <polyline points="2 12 12 17 22 12"/>
                    </svg>
                    <span>Activa los filtros deseados (Cliente, Cuenta y/o Fecha) y presiona Buscar</span>
                  </div>
                </td>
              </tr>
              <tr v-else-if="isBuscando">
                <td colspan="6" class="empty-cell">
                  <div class="empty-state">
                    <span>Consultando movimientos en la base de datos...</span>
                  </div>
                </td>
              </tr>
              <tr v-for="(fila, idx) in resultados" :key="idx" class="data-row">
                <td class="col-fecha font-mono">{{ fila.fecha }}</td>
                <td class="col-folio font-mono">{{ fila.folio }}</td>
                <td class="col-concepto">{{ fila.concepto }}</td>
                <td class="col-nombre">{{ fila.nombre }}</td>
                <td class="col-total font-mono text-right">{{ formatearMoneda(fila.total) }}</td>
                <td class="col-estatus">
                  <span class="estatus-tag">{{ fila.estatus }}</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Fila inferior: Impresora + Total -->
        <div class="bottom-row">
          <div class="field-item item-impresora">
            <label for="select-impresora-rep-varios" class="field-label">Selecciona la impresora</label>
            <select id="select-impresora-rep-varios" v-model="impresora" class="tecnm-input tecnm-select">
              <option v-for="imp in impresorasDisponibles" :key="imp.id" :value="imp.id">
                {{ imp.nombre }}
              </option>
            </select>
          </div>

          <div class="field-item item-total">
            <span class="field-label">Total:</span>
            <div class="total-badge font-mono">
              {{ formatearMoneda(totalGeneral) }}
            </div>
          </div>
        </div>

      </section>

      <!-- Barra de acciones -->
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
        <div class="footer-hint">
          <kbd>ESC</kbd> = Salir
        </div>
      </footer>

    </div>
  </div>
</template>

<style scoped>
/* =====================================================
   BACKDROP Y VENTANA
   ===================================================== */
.modal-backdrop {
  position: fixed;
  inset: 0;
  z-index: 1000;
  background-color: rgba(15, 37, 72, 0.65);
  backdrop-filter: blur(2px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

.tecnm-window {
  width: 100%;
  max-width: 860px;
  background-color: #FFFFFF;
  border: 2px solid #1B396A;
  border-radius: 8px;
  box-shadow: 0 25px 50px -12px rgba(15, 37, 72, 0.35);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  animation: window-appear 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}

.dark-theme .tecnm-window {
  background-color: #1e293b;
  border-color: #334155;
}

@keyframes window-appear {
  from { opacity: 0; transform: scale(0.97) translateY(8px); }
  to   { opacity: 1; transform: scale(1)    translateY(0);  }
}

/* =====================================================
   BARRA DE TÍTULO
   ===================================================== */
.window-title-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: #1B396A;
  color: #FFFFFF;
  padding: 8px 16px;
  border-bottom: 3px solid #C5A059;
}

.window-title-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.window-icon {
  width: 18px;
  height: 18px;
  color: #C5A059;
}

.window-title-text {
  font-size: 0.88rem;
  font-weight: 700;
  letter-spacing: 0.03em;
  text-transform: uppercase;
  color: #FFFFFF;
}

.window-btn-close {
  background-color: #DC2626;
  border: none;
  color: #FFFFFF;
  width: 26px;
  height: 24px;
  border-radius: 4px;
  font-size: 1.15rem;
  font-weight: bold;
  cursor: pointer;
  display: grid;
  place-items: center;
  transition: background-color 0.15s;
}
.window-btn-close:hover { background-color: #B91C1C; }

/* =====================================================
   PANEL DE CONTENIDO Y FILTROS
   ===================================================== */
.window-content-panel {
  padding: 18px 24px 16px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  background-color: #F8FAFC;
  flex: 1;
}

.dark-theme .window-content-panel {
  background-color: #0f172a;
}

.top-filters-wrapper {
  display: flex;
  align-items: flex-start;
  gap: 16px;
}

.filters-column {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.filter-group-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* Checkbox estilizado */
.checkbox-container {
  display: flex;
  align-items: center;
  cursor: pointer;
  user-select: none;
}

.filter-checkbox {
  position: absolute;
  opacity: 0;
  cursor: pointer;
  height: 0;
  width: 0;
}

.custom-checkbox {
  width: 18px;
  height: 18px;
  background-color: #FFFFFF;
  border: 2px solid #CBD5E1;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
}

.dark-theme .custom-checkbox {
  background-color: #1e293b;
  border-color: #475569;
}

.filter-checkbox:checked ~ .custom-checkbox {
  background-color: #1B396A;
  border-color: #1B396A;
}

.dark-theme .filter-checkbox:checked ~ .custom-checkbox {
  background-color: #C5A059;
  border-color: #C5A059;
}

.filter-checkbox:checked ~ .custom-checkbox::after {
  content: '';
  width: 5px;
  height: 9px;
  border: solid #FFFFFF;
  border-width: 0 2px 2px 0;
  transform: rotate(45deg);
  margin-bottom: 2px;
}

.dark-theme .filter-checkbox:checked ~ .custom-checkbox::after {
  border-color: #1B396A;
}

/* Fieldset para enmarcar cada filtro */
.filter-fieldset {
  flex: 1;
  border: 1px solid #CBD5E1;
  border-radius: 6px;
  padding: 6px 12px 10px;
  background-color: #FFFFFF;
  transition: all 0.15s ease;
}

.dark-theme .filter-fieldset {
  background-color: #1e293b;
  border-color: #334155;
}

.filter-fieldset:disabled {
  opacity: 0.55;
  background-color: #F1F5F9;
  border-color: #E2E8F0;
}

.dark-theme .filter-fieldset:disabled {
  background-color: #0f172a;
  border-color: #1e293b;
  opacity: 0.45;
}

.filter-fieldset.active {
  border-color: #244B88;
  box-shadow: 0 1px 4px rgba(27, 57, 106, 0.08);
}

.dark-theme .filter-fieldset.active {
  border-color: #C5A059;
}

.fieldset-legend {
  font-size: 0.78rem;
  font-weight: 700;
  color: #1B396A;
  padding: 0 6px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.dark-theme .fieldset-legend {
  color: #C5A059;
}

.fieldset-body {
  display: flex;
  align-items: center;
  gap: 12px;
}

.client-body {
  display: flex;
  align-items: center;
  gap: 12px;
}

.item-matricula {
  width: 140px;
}

.item-nombre {
  flex: 1;
}

.item-concepto-full {
  width: 100%;
}

.date-body {
  display: flex;
  align-items: center;
  gap: 10px;
}

.item-fecha-sub {
  flex: 1;
}

.range-separator {
  font-size: 0.85rem;
  font-weight: 800;
  color: #1B396A;
}

.dark-theme .range-separator {
  color: #C5A059;
}

.field-item {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.field-label {
  font-size: 0.76rem;
  font-weight: 700;
  color: #1E293B;
  letter-spacing: 0.02em;
}

.dark-theme .field-label {
  color: #cbd5e1;
}

.tecnm-input {
  padding: 6px 10px;
  border: 1px solid #CBD5E1;
  border-radius: 4px;
  font-size: 0.84rem;
  font-weight: 600;
  background-color: #FFFFFF;
  color: #1E293B;
  outline: none;
  transition: border-color 0.15s, box-shadow 0.15s;
}

.dark-theme .tecnm-input {
  background-color: #0f172a;
  border-color: #334155;
  color: #e2e8f0;
}

.tecnm-input:focus:not(:disabled) {
  border-color: #C5A059;
  box-shadow: 0 0 0 3px rgba(197, 160, 89, 0.3);
}

.date-input-combo {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
}

.date-input-combo .input-date-code {
  width: 100%;
  padding-right: 34px;
}

.hidden-date-picker {
  position: absolute;
  opacity: 0;
  width: 0;
  height: 0;
  pointer-events: none;
  visibility: hidden;
}

.btn-calendar-trigger {
  position: absolute;
  right: 5px;
  background: none;
  border: none;
  color: #C5A059;
  padding: 3px;
  border-radius: 4px;
  cursor: pointer;
  display: grid;
  place-items: center;
  transition: all 0.15s ease;
}

.btn-calendar-trigger:hover:not(:disabled) {
  background-color: #EBF3FF;
  color: #1B396A;
}

.dark-theme .btn-calendar-trigger:hover:not(:disabled) {
  background-color: rgba(197, 160, 89, 0.2);
  color: #C5A059;
}

.calendar-icon {
  width: 16px;
  height: 16px;
}

/* Botón Buscar en lateral */
.search-btn-wrapper {
  padding-top: 6px;
}

.btn-buscar-large {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  background-color: #1B396A;
  color: #FFFFFF;
  border: 1px solid #0F2548;
  padding: 10px 22px;
  border-radius: 6px;
  font-size: 0.88rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.15s;
  white-space: nowrap;
  box-shadow: 0 2px 6px rgba(27, 57, 106, 0.2);
}

.btn-buscar-large:hover:not(:disabled) {
  background-color: #244B88;
  box-shadow: 0 4px 10px rgba(27, 57, 106, 0.35);
  transform: translateY(-1px);
}

.btn-buscar-large:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

.btn-icon {
  width: 16px;
  height: 16px;
}

.spin-icon {
  width: 16px;
  height: 16px;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to   { transform: rotate(360deg); }
}

/* =====================================================
   TABLA DE RESULTADOS
   Columnas: Fecha, Folio, Concepto, Nombre, Total, Estatus
   ===================================================== */
.table-container {
  border: 1px solid #CBD5E1;
  border-radius: 4px;
  overflow: hidden;
  min-height: 220px;
  background: #FFFFFF;
}

.dark-theme .table-container {
  border-color: #334155;
  background-color: #1e293b;
}

.reporte-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.84rem;
}

.reporte-table thead tr {
  background-color: #1B396A;
  color: #FFFFFF;
}

.reporte-table thead th {
  padding: 9px 12px;
  font-weight: 700;
  letter-spacing: 0.03em;
  font-size: 0.82rem;
  text-align: left;
  border-right: 1px solid rgba(197, 160, 89, 0.3);
}

.reporte-table thead th:last-child {
  border-right: none;
}

.reporte-table thead {
  border-bottom: 2px solid #C5A059;
}

.col-fecha    { width: 105px; }
.col-folio    { width: 105px; }
.col-concepto { width: 220px; }
.col-nombre   { width: auto;  }
.col-total    { width: 115px; text-align: right; }
.col-estatus  { width: 95px; text-align: center; }

.data-row td {
  padding: 8px 12px;
  border-bottom: 1px solid #F1F5F9;
  color: #1E293B;
}

.dark-theme .data-row td {
  border-bottom-color: #334155;
  color: #e2e8f0;
}

.data-row:nth-child(even) td {
  background-color: #F8FAFC;
}

.dark-theme .data-row:nth-child(even) td {
  background-color: rgba(255, 255, 255, 0.02);
}

.data-row:hover td {
  background-color: #EBF3FF;
}

.dark-theme .data-row:hover td {
  background-color: rgba(36, 75, 136, 0.2);
}

.text-right { text-align: right; }

.estatus-tag {
  display: inline-block;
  padding: 2px 8px;
  font-size: 0.75rem;
  font-weight: 700;
  border-radius: 4px;
  background-color: #DCFCE7;
  color: #166534;
}

.dark-theme .estatus-tag {
  background-color: rgba(34, 197, 94, 0.2);
  color: #86efac;
}

/* Estado vacío */
.empty-cell {
  padding: 0;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 40px 20px;
  color: #94A3B8;
  font-size: 0.84rem;
  font-weight: 500;
}

.empty-icon {
  width: 36px;
  height: 36px;
  opacity: 0.4;
  stroke: #1B396A;
}

.dark-theme .empty-icon {
  stroke: #C5A059;
}

/* =====================================================
   FILA INFERIOR: Impresora + Total
   ===================================================== */
.bottom-row {
  display: flex;
  align-items: flex-end;
  gap: 16px;
  flex-wrap: wrap;
}

.item-impresora {
  flex: 1;
  min-width: 220px;
}

.tecnm-select {
  width: 100%;
  cursor: pointer;
}

.item-total {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 5px;
}

.total-badge {
  padding: 7px 18px;
  background-color: #FFFFFF;
  border: 2px solid #1B396A;
  border-radius: 4px;
  font-size: 1rem;
  font-weight: 700;
  color: #1B396A;
  min-width: 140px;
  text-align: right;
}

.dark-theme .total-badge {
  background-color: #0f172a;
  border-color: #C5A059;
  color: #C5A059;
}

/* =====================================================
   BARRA DE ACCIONES (FOOTER)
   ===================================================== */
.window-footer-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 24px;
  background-color: #FFFFFF;
  border-top: 1px solid #CBD5E1;
}

.dark-theme .window-footer-bar {
  background-color: #1e293b;
  border-color: #334155;
}

.footer-buttons-group {
  display: flex;
  align-items: center;
  gap: 10px;
}

.btn-action-primary {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #1B396A;
  color: #FFFFFF;
  border: 1px solid #0F2548;
  padding: 7px 18px;
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-action-primary:hover:not(:disabled) {
  background-color: #244B88;
  box-shadow: 0 2px 6px rgba(27, 57, 106, 0.25);
}

.btn-action-primary:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.btn-action-secondary {
  padding: 7px 18px;
  background-color: #FFFFFF;
  border: 1px solid #CBD5E1;
  color: #1E293B;
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-action-secondary:hover {
  background-color: #F8FAFC;
  border-color: #1B396A;
}

.dark-theme .btn-action-secondary {
  background-color: #0f172a;
  border-color: #334155;
  color: #e2e8f0;
}

.dark-theme .btn-action-secondary:hover {
  background-color: #1e293b;
  border-color: #C5A059;
}

.btn-action-danger {
  padding: 7px 20px;
  background-color: #DC2626;
  border: 1px solid #B91C1C;
  color: #FFFFFF;
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-action-danger:hover {
  background-color: #B91C1C;
  box-shadow: 0 2px 6px rgba(220, 38, 38, 0.3);
}

.footer-hint {
  font-size: 0.78rem;
  font-weight: 700;
  color: #64748B;
}

.footer-hint kbd {
  background-color: #F1F5F9;
  border: 1px solid #CBD5E1;
  border-radius: 3px;
  padding: 2px 6px;
  font-family: inherit;
  font-size: 0.75rem;
  font-weight: 800;
  color: #1E293B;
}

.dark-theme .footer-hint kbd {
  background-color: #0f172a;
  border-color: #334155;
  color: #e2e8f0;
}

/* =====================================================
   UTILIDADES
   ===================================================== */
.font-mono {
  font-family: 'Consolas', 'Courier New', monospace;
}
</style>

