<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { getReporteVerano } from '../api/cajaApi'

const emit = defineEmits<{
  (e: 'close'): void
}>()

const form = ref({
  reciboNo: '',
  totalRegistros: 0,
  concepto: '',
  cuota: '',
  inicio: '',
  fin: '',
})

const isCargando = ref(false)
const mensajeReporte = ref('')

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
    form.value[campo] = target.value
  }
}

// Opciones de conceptos de verano (preparado para conexión con PostgreSQL)
const conceptosDisponibles = [
  { id: 1, nombre: 'CURSO DE VERANO - MATERIA NORMAL', cuota: 1500.00 },
  { id: 2, nombre: 'CURSO DE VERANO - ASIGNATURA ESPECIAL', cuota: 1800.00 },
  { id: 3, nombre: 'CURSO DE VERANO - LABORATORIO', cuota: 600.00 },
  { id: 4, nombre: 'CURSO DE VERANO - IDIOMAS / INGLES', cuota: 850.00 },
]

async function alCambiarConcepto(): Promise<void> {
  const seleccionado = conceptosDisponibles.find(c => c.nombre === form.value.concepto)
  if (seleccionado) {
    form.value.cuota = seleccionado.cuota.toFixed(2)
  }
  await ejecutarConsultaVerano()
}

async function ejecutarConsultaVerano(): Promise<void> {
  isCargando.value = true
  try {
    const data = await getReporteVerano(form.value.inicio, form.value.fin, form.value.concepto)
    form.value.totalRegistros = data.totalRegistros || 0
    if (data.registros && data.registros.length > 0) {
      form.value.reciboNo = data.registros[0].reciboNo
    }
    mensajeReporte.value = `Encontrados ${data.totalRegistros} registro(s) en PostgreSQL. Total recaudado: $${data.totalRecaudado.toFixed(2)}`
  } catch {
    mensajeReporte.value = 'Error al consultar datos de verano.'
  } finally {
    isCargando.value = false
  }
}

function limpiar(): void {
  form.value = {
    reciboNo: '',
    totalRegistros: 0,
    concepto: '',
    cuota: '',
    inicio: '',
    fin: '',
  }
}

function cerrar(): void {
  emit('close')
}

function handleKeydown(e: KeyboardEvent): void {
  if (e.key === 'Escape') {
    cerrar()
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
  <div class="modal-backdrop" @click.self="cerrar">
    <div class="tecnm-window" role="dialog" aria-modal="true" aria-labelledby="verano-title">
      <!-- 1. Barra de título institucional TecNM -->
      <header class="window-title-bar">
        <div class="window-title-left">
          <svg class="window-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="6 9 6 2 18 2 18 9" />
            <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2" />
            <rect x="6" y="14" width="12" height="8" />
          </svg>
          <span id="verano-title" class="window-title-text">Imprime Verano</span>
        </div>
        <button type="button" class="window-btn-close" title="Cerrar (ESC)" aria-label="Cerrar ventana" @click="cerrar">
          &times;
        </button>
      </header>

      <!-- 2. Panel de captura de Imprime Verano -->
      <section class="window-content-panel">
        <!-- Fila 1: Recibo No, Abrir y Total de Registros -->
        <div class="form-row-group row-top">
          <div class="field-item">
            <label for="input-recibo-no" class="field-label">Recibo No:</label>
            <div class="recibo-input-wrap">
              <input
                id="input-recibo-no"
                v-model="form.reciboNo"
                type="text"
                class="tecnm-input input-recibo font-mono"
                placeholder="Último en BD"
                autocomplete="off"
              />
              <button type="button" class="btn-action-primary btn-sm">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="btn-icon">
                  <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
                  <polyline points="15 3 21 3 21 9" />
                  <line x1="10" y1="14" x2="21" y2="3" />
                </svg>
                Abrir
              </button>
            </div>
          </div>

          <div class="field-item item-total">
            <label class="field-label">Total de Registros:</label>
            <div class="total-badge font-mono">
              {{ form.totalRegistros }}
            </div>
          </div>
        </div>

        <!-- Fila 2: Concepto y Cuota -->
        <div class="form-row-group row-middle">
          <div class="field-item item-concepto">
            <label for="select-concepto" class="field-label">Concepto:</label>
            <div class="select-wrap">
              <select
                id="select-concepto"
                v-model="form.concepto"
                class="tecnm-input tecnm-select"
                @change="alCambiarConcepto"
              >
                <option value="">-- Seleccionar Concepto de Verano --</option>
                <option v-for="c in conceptosDisponibles" :key="c.id" :value="c.nombre">
                  {{ c.nombre }}
                </option>
              </select>
            </div>
          </div>

          <div class="field-item item-cuota">
            <label for="input-cuota" class="field-label">Cuota:</label>
            <div class="currency-input-wrap">
              <span class="currency-sign">$</span>
              <input
                id="input-cuota"
                v-model="form.cuota"
                type="text"
                class="tecnm-input input-cuota font-mono"
                placeholder="0.00"
                autocomplete="off"
              />
            </div>
          </div>
        </div>

        <!-- Fila 3: Rango de Inicio, Fin e Imprimir -->
        <div class="form-row-group row-bottom">
          <div class="field-item item-date">
            <label for="input-inicio" class="field-label">Inicio:</label>
            <div class="date-input-combo">
              <input
                id="input-inicio"
                v-model="form.inicio"
                type="text"
                class="tecnm-input input-date-code font-mono"
                placeholder="AAAA-MM-DD o escribir..."
                autocomplete="off"
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
                title="Elegir fecha del calendario"
                aria-label="Abrir calendario para Inicio"
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

          <div class="field-item item-date">
            <label for="input-fin" class="field-label">Fin:</label>
            <div class="date-input-combo">
              <input
                id="input-fin"
                v-model="form.fin"
                type="text"
                class="tecnm-input input-date-code font-mono"
                placeholder="AAAA-MM-DD o escribir..."
                autocomplete="off"
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
                title="Elegir fecha del calendario"
                aria-label="Abrir calendario para Fin"
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

          <div class="field-item item-btn-imprimir">
            <button type="button" class="btn-action-primary btn-imprimir" :disabled="isCargando" @click="ejecutarConsultaVerano">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="btn-icon">
                <polyline points="6 9 6 2 18 2 18 9" />
                <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2" />
                <rect x="6" y="14" width="12" height="8" />
              </svg>
              Imprimir
            </button>
          </div>
        </div>
        <p v-if="mensajeReporte" class="reporte-hint-text font-bold text-center mt-2">{{ mensajeReporte }}</p>
      </section>

      <!-- 3. Barra inferior de acciones (Manual TecNM) -->
      <footer class="window-footer-bar">
        <div class="footer-buttons-group">
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
  font-family: var(--font-family-base, 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif);
}

.tecnm-window {
  width: 100%;
  max-width: 680px;
  background-color: var(--color-surface-white, #FFFFFF);
  border: 2px solid var(--color-primary, #1B396A);
  border-radius: 8px;
  box-shadow: 0 25px 50px -12px rgba(15, 37, 72, 0.35);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  animation: window-appear 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes window-appear {
  from { opacity: 0; transform: scale(0.97) translateY(8px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}

/* 1. Barra de título institucional */
.window-title-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: var(--color-primary, #1B396A);
  color: var(--color-white, #FFFFFF);
  padding: 8px 16px;
  border-bottom: 3px solid var(--color-accent, #C5A059);
}

.window-title-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.window-icon {
  width: 18px;
  height: 18px;
  color: var(--color-accent, #C5A059);
}

.window-title-text {
  font-size: 0.92rem;
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
  line-height: 1;
  cursor: pointer;
  display: grid;
  place-items: center;
  transition: background-color 0.15s ease;
}

.window-btn-close:hover {
  background-color: #B91C1C;
}

/* 2. Panel de contenido y campos */
.window-content-panel {
  padding: 24px 28px;
  display: flex;
  flex-direction: column;
  gap: 18px;
  background-color: var(--color-bg-light, #F8FAFC);
}

.form-row-group {
  display: flex;
  align-items: flex-end;
  gap: 16px;
  flex-wrap: wrap;
}

.field-item {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field-label {
  font-size: 0.84rem;
  font-weight: 700;
  color: var(--color-text-primary, #1E293B);
  letter-spacing: 0.02em;
}

.recibo-input-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
}

.input-recibo {
  width: 140px;
  font-weight: 700;
  color: var(--color-primary, #1B396A);
}

.item-total {
  margin-left: auto;
  align-items: flex-end;
}

.total-badge {
  padding: 6px 14px;
  background-color: var(--color-surface-white, #FFFFFF);
  border: 1px solid var(--color-border-medium, #CBD5E1);
  border-radius: 4px;
  font-weight: 700;
  color: var(--color-text-primary, #1E293B);
  min-width: 80px;
  text-align: center;
}

.item-concepto {
  flex: 1;
  min-width: 280px;
}

.select-wrap {
  width: 100%;
}

.tecnm-select {
  width: 100%;
  cursor: pointer;
}

.item-cuota {
  width: 130px;
}

.currency-input-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.currency-sign {
  position: absolute;
  left: 10px;
  font-weight: 700;
  color: var(--color-text-muted, #94A3B8);
  font-size: 0.9rem;
  pointer-events: none;
}

.input-cuota {
  padding-left: 24px;
  font-weight: 700;
}

.item-date {
  flex: 1;
  min-width: 180px;
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
  color: var(--color-accent, #C5A059);
  padding: 4px;
  border-radius: 4px;
  cursor: pointer;
  display: grid;
  place-items: center;
  transition: all 0.15s ease;
}

.btn-calendar-trigger:hover {
  background-color: var(--color-primary-subtle, #EBF3FF);
  color: var(--color-primary, #1B396A);
}

.calendar-icon {
  width: 17px;
  height: 17px;
}

.item-btn-imprimir {
  margin-left: auto;
}

.tecnm-input {
  padding: 7px 12px;
  border: 1px solid var(--color-border-medium, #CBD5E1);
  border-radius: 4px;
  font-size: 0.88rem;
  font-weight: 600;
  background-color: var(--color-surface-white, #FFFFFF);
  color: var(--color-text-primary, #1E293B);
  outline: none;
  transition: border-color 0.15s, box-shadow 0.15s;
}

.tecnm-input:focus {
  border-color: var(--color-accent, #C5A059);
  box-shadow: 0 0 0 3px rgba(197, 160, 89, 0.3);
}

/* Botones de acción */
.btn-action-primary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  background-color: var(--color-primary, #1B396A);
  color: #FFFFFF;
  border: 1px solid var(--color-primary-dark, #0F2548);
  padding: 7px 14px;
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-action-primary:hover {
  background-color: var(--color-primary-hover, #244B88);
  box-shadow: 0 2px 6px rgba(27, 57, 106, 0.25);
}

.btn-sm {
  padding: 6px 12px;
  font-size: 0.82rem;
}

.btn-imprimir {
  padding: 8px 20px;
  background-color: var(--color-primary, #1B396A);
  border-color: var(--color-accent, #C5A059);
}

.btn-icon {
  width: 15px;
  height: 15px;
}

/* 3. Barra inferior de acciones */
.window-footer-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 24px;
  background-color: var(--color-surface-white, #FFFFFF);
  border-top: 1px solid var(--color-border-medium, #CBD5E1);
}

.footer-buttons-group {
  display: flex;
  align-items: center;
  gap: 12px;
}

.btn-action-secondary {
  padding: 7px 18px;
  background-color: var(--color-surface-white, #FFFFFF);
  border: 1px solid var(--color-border-medium, #CBD5E1);
  color: var(--color-text-primary, #1E293B);
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-action-secondary:hover {
  background-color: var(--color-bg-light, #F8FAFC);
  border-color: var(--color-border-focus, #1B396A);
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
  transition: all 0.15s ease;
}

.btn-action-danger:hover {
  background-color: #B91C1C;
  box-shadow: 0 2px 6px rgba(220, 38, 38, 0.3);
}

.footer-hint {
  font-size: 0.78rem;
  font-weight: 700;
  color: var(--color-text-secondary, #64748B);
}

.footer-hint kbd {
  background-color: var(--color-bg-light, #F1F5F9);
  border: 1px solid var(--color-border-medium, #CBD5E1);
  border-radius: 3px;
  padding: 2px 6px;
  font-family: inherit;
  font-size: 0.75rem;
  font-weight: 800;
  color: var(--color-text-primary, #1E293B);
}

.font-mono {
  font-family: 'Consolas', 'Courier New', monospace;
}
</style>

