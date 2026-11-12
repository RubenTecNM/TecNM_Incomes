<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { useTheme } from '../../../shared/composables/useTheme'

const emit = defineEmits<{
  (e: 'close'): void
}>()

const { dark } = useTheme()

// ==========================================
// Estado del formulario
// ==========================================
const conceptoSeleccionado = ref('')
const isBuscando = ref(false)

// Catálogo de conceptos para el filtro (preparado para PostgreSQL)
const conceptosDisponibles = [
  { id: '', nombre: '-- Seleccionar Concepto --' },
  { id: 'c1', nombre: 'PAGO DE INSCRIPCION (PERIODO VIGENTE)' },
  { id: 'c2', nombre: 'ADEUDO DE INSCRIPCION ANTERIOR' },
  { id: 'c3', nombre: 'CURSO DE VERANO (POR ASIGNATURA)' },
  { id: 'c4', nombre: 'EXPEDICION DE KARDEX' },
  { id: 'c5', nombre: 'CONSTANCIA DE ESTUDIOS CON CALIFICACIONES' },
  { id: 'c6', nombre: 'TRAMITE DE TITULACION INTEGRAL Y CEDULA' },
]

// Resultados de la búsqueda de deudores (vacío hasta conectar con PostgreSQL)
interface FilaDeudor {
  estudiante: string
  fecha: string
  abono: number
  costo: number
  adeudo: number
  matricula: string
  cuenta: string
}

const resultados = ref<FilaDeudor[]>([])
const totalAdeudo = ref(0)

// ==========================================
// Lógica de búsqueda
// ==========================================
async function buscar(): Promise<void> {
  if (!conceptoSeleccionado.value) return

  isBuscando.value = true
  // TODO: Conectar con endpoint GET /api/deudores?concepto={conceptoSeleccionado}
  // const data = await fetchReporteDeudores(conceptoSeleccionado.value)
  // resultados.value = data.filas
  // totalAdeudo.value = data.total
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
  resultados.value = []
  totalAdeudo.value = 0
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
    <div class="tecnm-window" role="dialog" aria-modal="true" aria-labelledby="deudores-title">

      <!-- Barra de título institucional -->
      <header class="window-title-bar">
        <div class="window-title-left">
          <svg class="window-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
            <circle cx="9" cy="7" r="4"/>
            <line x1="19" y1="8" x2="19" y2="14"/>
            <line x1="22" y1="11" x2="16" y2="11"/>
          </svg>
          <span id="deudores-title" class="window-title-text">Reporte Deudores</span>
        </div>
        <button type="button" class="window-btn-close" title="Cerrar (ESC)" aria-label="Cerrar ventana" @click="cerrar">
          &times;
        </button>
      </header>

      <!-- Panel de contenido y búsqueda -->
      <section class="window-content-panel">

        <!-- Fila: Concepto + Buscar -->
        <div class="search-row">
          <div class="field-item item-concepto">
            <label for="select-deudor-concepto" class="field-label">Concepto:</label>
            <select
              id="select-deudor-concepto"
              v-model="conceptoSeleccionado"
              class="tecnm-input tecnm-select"
              @change="buscar"
            >
              <option v-for="c in conceptosDisponibles" :key="c.id" :value="c.id">
                {{ c.nombre }}
              </option>
            </select>
          </div>

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

        <!-- Tabla de resultados: Estudiante, Fecha, Abono, Costo, Adeudo, Matrícula, Cuenta -->
        <div class="table-container">
          <table class="deudores-table">
            <thead>
              <tr>
                <th class="col-estudiante">Estudiante</th>
                <th class="col-fecha">Fecha</th>
                <th class="col-monto">Abono</th>
                <th class="col-monto">Costo</th>
                <th class="col-monto">Adeudo</th>
                <th class="col-matricula">Matrícula</th>
                <th class="col-cuenta">Cuenta</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="resultados.length === 0 && !isBuscando">
                <td colspan="7" class="empty-cell">
                  <div class="empty-state">
                    <svg class="empty-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                      <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
                      <circle cx="9" cy="7" r="4"/>
                      <line x1="19" y1="8" x2="19" y2="14"/>
                      <line x1="22" y1="11" x2="16" y2="11"/>
                    </svg>
                    <span>{{ conceptoSeleccionado ? 'No se encontraron deudores para el concepto seleccionado' : 'Selecciona un concepto para consultar la lista de deudores' }}</span>
                  </div>
                </td>
              </tr>
              <tr v-else-if="isBuscando">
                <td colspan="7" class="empty-cell">
                  <div class="empty-state">
                    <span>Consultando adeudos en la base de datos...</span>
                  </div>
                </td>
              </tr>
              <tr v-for="(fila, idx) in resultados" :key="idx" class="data-row">
                <td class="col-estudiante">{{ fila.estudiante }}</td>
                <td class="col-fecha font-mono">{{ fila.fecha }}</td>
                <td class="col-monto font-mono text-right">{{ formatearMoneda(fila.abono) }}</td>
                <td class="col-monto font-mono text-right">{{ formatearMoneda(fila.costo) }}</td>
                <td class="col-monto font-mono text-right font-bold text-danger">{{ formatearMoneda(fila.adeudo) }}</td>
                <td class="col-matricula font-mono">{{ fila.matricula }}</td>
                <td class="col-cuenta font-mono">{{ fila.cuenta }}</td>
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

/* Fila de búsqueda */
.search-row {
  display: flex;
  align-items: flex-end;
  gap: 12px;
}

.field-item {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.item-concepto {
  flex: 1;
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

.tecnm-select {
  width: 100%;
  cursor: pointer;
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
  padding: 7px 20px;
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
   Columnas: Estudiante, Fecha, Abono, Costo, Adeudo, Matrícula, Cuenta
   ===================================================== */
.table-container {
  border: 1px solid #CBD5E1;
  border-radius: 4px;
  overflow: hidden;
  min-height: 250px;
  background: #FFFFFF;
}

.dark-theme .table-container {
  border-color: #334155;
  background-color: #1e293b;
}

.deudores-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.84rem;
}

.deudores-table thead tr {
  background-color: #1B396A;
  color: #FFFFFF;
}

.deudores-table thead th {
  padding: 9px 12px;
  font-weight: 700;
  letter-spacing: 0.03em;
  font-size: 0.82rem;
  text-align: left;
  border-right: 1px solid rgba(197, 160, 89, 0.3);
}

.deudores-table thead th:last-child {
  border-right: none;
}

.deudores-table thead {
  border-bottom: 2px solid #C5A059;
}

.col-estudiante { width: auto;  }
.col-fecha      { width: 105px; }
.col-monto      { width: 105px; text-align: right; }
.col-matricula  { width: 110px; }
.col-cuenta     { width: 105px; }

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
.font-bold { font-weight: 700; }
.text-danger { color: #DC2626; }
.dark-theme .text-danger { color: #F87171; }

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
  padding: 50px 20px;
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
