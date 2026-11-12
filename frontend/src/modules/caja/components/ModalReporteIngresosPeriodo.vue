<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { useTheme } from '../../../shared/composables/useTheme'

const emit = defineEmits<{
  (e: 'close'): void
}>()

const { dark } = useTheme()

// ==========================================
// Estado del formulario (Rango de fechas)
// ==========================================
const fechaInicio = ref('')
const fechaFin = ref('')
const impresora = ref('')
const isBuscando = ref(false)

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

// Resultados de la búsqueda (vacío hasta conectar con PostgreSQL)
interface FilaReportePeriodo {
  folio: string
  concepto: string
  nombre: string
  total: number
  estatus: string
}

const resultados = ref<FilaReportePeriodo[]>([])
const totalGeneral = ref(0)

// Impresoras disponibles
const impresorasDisponibles = [
  { id: '', nombre: '-- Seleccionar impresora --' },
  { id: 'termica', nombre: 'Impresora Térmica de Recibos (Caja)' },
  { id: 'laser', nombre: 'Impresora Láser Institucional (Reportes)' },
  { id: 'pdf', nombre: 'Exportar a Documento PDF' },
]

// ==========================================
// Lógica de búsqueda por rango de fechas
// ==========================================
async function buscar(): Promise<void> {
  if (!fechaInicio.value && !fechaFin.value) return

  isBuscando.value = true
  // TODO: Conectar con endpoint GET /api/reporte-ingresos/periodo?inicio=YYYY-MM-DD&fin=YYYY-MM-DD
  // const data = await fetchReporteIngresoPeriodo(fechaInicio.value, fechaFin.value)
  // resultados.value = data.filas
  // totalGeneral.value = data.total
  await new Promise(resolve => setTimeout(resolve, 400)) // simulación de consulta
  resultados.value = []
  totalGeneral.value = 0
  isBuscando.value = false
}

function formatearMoneda(valor: number): string {
  return valor.toLocaleString('es-MX', { style: 'currency', currency: 'MXN' })
}

function limpiar(): void {
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
    <div class="tecnm-window" role="dialog" aria-modal="true" aria-labelledby="reporte-periodo-title">

      <!-- Barra de título institucional -->
      <header class="window-title-bar">
        <div class="window-title-left">
          <svg class="window-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="18" y1="20" x2="18" y2="10"/>
            <line x1="12" y1="20" x2="12" y2="4"/>
            <line x1="6" y1="20" x2="6" y2="14"/>
          </svg>
          <span id="reporte-periodo-title" class="window-title-text">Reporte de Ingresos por Período</span>
        </div>
        <button type="button" class="window-btn-close" title="Cerrar (ESC)" aria-label="Cerrar ventana" @click="cerrar">
          &times;
        </button>
      </header>

      <!-- Panel de contenido y búsqueda -->
      <section class="window-content-panel">

        <!-- Fila: Fecha Inicio + Y + Fecha Fin + Buscar -->
        <div class="search-row">
          <div class="field-item">
            <label for="input-rep-fecha-inicio" class="field-label">Fecha Inicial:</label>
            <div class="date-input-combo">
              <input
                id="input-rep-fecha-inicio"
                v-model="fechaInicio"
                type="text"
                class="tecnm-input input-date-code font-mono"
                placeholder="AAAA-MM-DD o escribir..."
                autocomplete="off"
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
                title="Elegir fecha de inicio del calendario"
                aria-label="Abrir calendario para Fecha Inicial"
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

          <div class="field-item">
            <label for="input-rep-fecha-fin" class="field-label">Fecha Final:</label>
            <div class="date-input-combo">
              <input
                id="input-rep-fecha-fin"
                v-model="fechaFin"
                type="text"
                class="tecnm-input input-date-code font-mono"
                placeholder="AAAA-MM-DD o escribir..."
                autocomplete="off"
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
                title="Elegir fecha final del calendario"
                aria-label="Abrir calendario para Fecha Final"
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

          <button
            type="button"
            class="btn-buscar"
            :disabled="(!fechaInicio && !fechaFin) || isBuscando"
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

        <!-- Tabla de resultados: Folio, Concepto, Nombre, Total, Estatus -->
        <div class="table-container">
          <table class="reporte-table">
            <thead>
              <tr>
                <th class="col-folio">Folio</th>
                <th class="col-concepto">Concepto</th>
                <th class="col-nombre">Nombre</th>
                <th class="col-total">Total</th>
                <th class="col-estatus">Estatus</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="resultados.length === 0 && !isBuscando">
                <td colspan="5" class="empty-cell">
                  <div class="empty-state">
                    <svg class="empty-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                      <line x1="18" y1="20" x2="18" y2="10"/>
                      <line x1="12" y1="20" x2="12" y2="4"/>
                      <line x1="6" y1="20" x2="6" y2="14"/>
                    </svg>
                    <span>{{ (fechaInicio || fechaFin) ? 'Sin movimientos registrados para el periodo seleccionado' : 'Selecciona o escribe el rango de fechas y presiona Buscar' }}</span>
                  </div>
                </td>
              </tr>
              <tr v-else-if="isBuscando">
                <td colspan="5" class="empty-cell">
                  <div class="empty-state">
                    <span>Consultando base de datos para el periodo...</span>
                  </div>
                </td>
              </tr>
              <tr v-for="(fila, idx) in resultados" :key="idx" class="data-row">
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
            <label for="select-impresora-rep-periodo" class="field-label">Selecciona la impresora</label>
            <select id="select-impresora-rep-periodo" v-model="impresora" class="tecnm-input tecnm-select">
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
  max-width: 820px;
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
   CONTENIDO
   ===================================================== */
.window-content-panel {
  padding: 20px 24px 16px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  background-color: #F8FAFC;
  flex: 1;
}

.dark-theme .window-content-panel {
  background-color: #0f172a;
}

/* Fila de búsqueda: Fecha Inicio + Y + Fecha Fin + Buscar */
.search-row {
  display: flex;
  align-items: flex-end;
  gap: 12px;
  flex-wrap: wrap;
}

.range-separator {
  font-size: 0.85rem;
  font-weight: 800;
  color: #1B396A;
  padding-bottom: 8px;
}

.dark-theme .range-separator {
  color: #C5A059;
}

.field-item {
  display: flex;
  flex-direction: column;
  gap: 5px;
  flex: 1;
  min-width: 180px;
}

.field-label {
  font-size: 0.82rem;
  font-weight: 700;
  color: #1E293B;
  letter-spacing: 0.02em;
}

.dark-theme .field-label {
  color: #cbd5e1;
}

.date-input-combo {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
}

.date-input-combo .input-date-code {
  width: 100%;
  padding-right: 36px;
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
  right: 6px;
  background: none;
  border: none;
  color: #C5A059;
  padding: 4px;
  border-radius: 4px;
  cursor: pointer;
  display: grid;
  place-items: center;
  transition: all 0.15s ease;
}

.btn-calendar-trigger:hover {
  background-color: #EBF3FF;
  color: #1B396A;
}

.dark-theme .btn-calendar-trigger:hover {
  background-color: rgba(197, 160, 89, 0.2);
  color: #C5A059;
}

.calendar-icon {
  width: 17px;
  height: 17px;
}

.tecnm-input {
  padding: 7px 11px;
  border: 1px solid #CBD5E1;
  border-radius: 4px;
  font-size: 0.88rem;
  font-weight: 600;
  background-color: #FFFFFF;
  color: #1E293B;
  outline: none;
  transition: border-color 0.15s, box-shadow 0.15s;
}

.dark-theme .tecnm-input {
  background-color: #1e293b;
  border-color: #334155;
  color: #e2e8f0;
}

.tecnm-input:focus {
  border-color: #C5A059;
  box-shadow: 0 0 0 3px rgba(197, 160, 89, 0.3);
}

/* Botón Buscar */
.btn-buscar {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #244B88;
  color: #FFFFFF;
  border: 1px solid #1B396A;
  padding: 7px 18px;
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.15s;
  white-space: nowrap;
  height: 35px;
}

.btn-buscar:hover:not(:disabled) {
  background-color: #1B396A;
  box-shadow: 0 2px 6px rgba(27, 57, 106, 0.3);
}

.btn-buscar:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.btn-icon {
  width: 15px;
  height: 15px;
}

.spin-icon {
  width: 15px;
  height: 15px;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to   { transform: rotate(360deg); }
}

/* =====================================================
   TABLA DE RESULTADOS
   Columnas: Folio, Concepto, Nombre, Total, Estatus
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

/* Línea dorada bajo encabezado */
.reporte-table thead {
  border-bottom: 2px solid #C5A059;
}

.col-folio    { width: 110px; }
.col-concepto { width: 220px; }
.col-nombre   { width: auto;  }
.col-total    { width: 120px; text-align: right; }
.col-estatus  { width: 100px; text-align: center; }

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

