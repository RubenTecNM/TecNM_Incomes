<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { actualizarCuenta, crearCuenta, getCuentas } from '../../caja/api/cajaApi'

const emit = defineEmits<{
  (e: 'close'): void
}>()

const formCuenta = ref({
  id: '',
  cuenta: '',
  descripcion: '',
  costo: '',
})

interface CuentaItem {
  id: string
  cuenta: string
  descripcion: string
  costo: number
}
const listaCuentas = ref<CuentaItem[]>([])
const isCargando = ref(false)
const mensajeFeedback = ref('')

async function cargarCuentas(): Promise<void> {
  isCargando.value = true
  try {
    const data = await getCuentas()
    if (data && data.length > 0) {
      listaCuentas.value = data.map(c => ({
        id: c.id,
        cuenta: c.cuenta,
        descripcion: c.descripcion,
        costo: c.costo,
      }))
    }
  } catch {
    // Si falla se conservan los valores existentes
  } finally {
    isCargando.value = false
  }
}

async function guardarCuenta(): Promise<void> {
  if (!formCuenta.value.cuenta.trim() || !formCuenta.value.descripcion.trim()) {
    mensajeFeedback.value = 'Complete la cuenta y la descripción.'
    return
  }

  isCargando.value = true
  try {
    const costoNum = parseFloat(formCuenta.value.costo) || 0
    if (formCuenta.value.id) {
      // Actualizar existente
      await actualizarCuenta(formCuenta.value.id, {
        descripcion: formCuenta.value.descripcion.trim(),
        costo: costoNum,
      })
      mensajeFeedback.value = 'Cuenta actualizada exitosamente en PostgreSQL.'
    } else {
      // Crear nueva
      await crearCuenta({
        cuenta: formCuenta.value.cuenta.trim(),
        descripcion: formCuenta.value.descripcion.trim(),
        costo: costoNum,
      })
      mensajeFeedback.value = 'Cuenta creada exitosamente en PostgreSQL.'
    }
    limpiar()
    await cargarCuentas()
  } catch {
    mensajeFeedback.value = 'Error al procesar la cuenta en el servidor.'
  } finally {
    isCargando.value = false
  }
}

function seleccionarFila(item: CuentaItem): void {
  formCuenta.value = {
    id: item.id,
    cuenta: item.cuenta,
    descripcion: item.descripcion,
    costo: String(item.costo),
  }
}

function limpiar(): void {
  formCuenta.value = {
    id: '',
    cuenta: '',
    descripcion: '',
    costo: '',
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
  void cargarCuentas()
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<template>
  <div class="modal-backdrop" @click.self="cerrar">
    <div class="tecnm-window" role="dialog" aria-modal="true" aria-labelledby="cuentas-title">
      <!-- 1. Barra de título institucional TecNM -->
      <header class="window-title-bar">
        <div class="window-title-left">
          <svg class="window-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="4" width="18" height="16" rx="2" />
            <line x1="3" y1="10" x2="21" y2="10" />
            <line x1="9" y1="14" x2="15" y2="14" />
          </svg>
          <span id="cuentas-title" class="window-title-text">Alta y Cambios en Cuentas</span>
        </div>
        <button type="button" class="window-btn-close" title="Cerrar (ESC)" aria-label="Cerrar ventana" @click="cerrar">
          &times;
        </button>
      </header>

      <!-- 2. Panel superior de captura - Identidad Oficial TecNM (Azul Marino + Dorado) -->
      <section class="window-form-panel">
        <div class="form-row">
          <label for="modal-input-cuenta" class="form-label">Cuenta:</label>
          <div class="form-input-wrap input-cuenta-wrap">
            <input
              id="modal-input-cuenta"
              v-model="formCuenta.cuenta"
              type="text"
              class="tecnm-input"
              placeholder="Ej. 5200-001-002-055"
              autocomplete="off"
            />
          </div>
        </div>

        <div class="form-row">
          <label for="modal-input-desc" class="form-label">Descripción:</label>
          <div class="form-input-wrap input-desc-wrap">
            <input
              id="modal-input-desc"
              v-model="formCuenta.descripcion"
              type="text"
              class="tecnm-input"
              placeholder="Ej. CUOTA DE MTTO. AGOSTO 2025-ENERO 2026"
              autocomplete="off"
            />
          </div>
        </div>

        <div class="form-row">
          <label for="modal-input-costo" class="form-label">Costo:</label>
          <div class="form-input-wrap input-costo-wrap">
            <input
              id="modal-input-costo"
              v-model="formCuenta.costo"
              type="number"
              step="0.01"
              class="tecnm-input"
              placeholder="0.00"
              autocomplete="off"
            />
          </div>
        </div>
      </section>

      <!-- 3. Rejilla / Tabla central (preparada para la BD) -->
      <section class="window-grid-panel">
        <div class="grid-table-scroll">
          <table class="tecnm-data-table">
            <thead>
              <tr>
                <th class="th-cuenta">Cuenta</th>
                <th class="th-desc">Descripción</th>
                <th class="th-costo">Costo</th>
              </tr>
            </thead>
            <tbody>
              <!-- Estado vacío: preparado para conectar a PostgreSQL -->
              <tr v-if="listaCuentas.length === 0" class="tr-empty">
                <td colspan="3" class="td-empty">
                  <div class="empty-state-content">
                    <svg class="empty-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                      <path d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7" />
                      <ellipse cx="12" cy="7" rx="8" ry="3" />
                      <path d="M4 12c0 2.21 3.582 4 8 4s8-1.79 8-4" />
                    </svg>
                    <p class="empty-title">Sin cuentas registradas</p>
                    <span class="empty-subtitle">
                      Los registros se obtendrán automáticamente al vincular la base de datos PostgreSQL.
                    </span>
                  </div>
                </td>
              </tr>

              <tr
                v-for="item in listaCuentas"
                :key="item.id"
                class="data-row cursor-pointer"
                :class="{ 'is-selected': formCuenta.id === item.id }"
                @click="seleccionarFila(item)"
              >
                <td class="td-cuenta font-mono">{{ item.cuenta }}</td>
                <td class="td-desc">{{ item.descripcion }}</td>
                <td class="td-costo font-mono font-bold">${{ item.costo.toFixed(2) }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- 4. Barra inferior de acciones conforme a la foto -->
      <footer class="window-footer-bar">
        <div class="footer-buttons">
          <button type="button" class="btn-tecnm btn-primary" :disabled="isCargando" @click="guardarCuenta">
            Guardar
          </button>
          <button type="button" class="btn-tecnm btn-accent" :disabled="isCargando" @click="cargarCuentas">
            Actualizar
          </button>
          <button type="button" class="btn-tecnm btn-secondary" @click="limpiar">
            Limpiar
          </button>
          <button type="button" class="btn-tecnm btn-danger" @click="cerrar">
            Salir
          </button>
        </div>
        <div class="footer-hint">
          <span v-if="mensajeFeedback" class="feedback-text">{{ mensajeFeedback }}</span>
        </div>
      </footer>
    </div>
  </div>
</template>

<style scoped>
/* Tipografía y variables institucionales TecNM */
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
  max-width: 920px;
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
  font-size: 0.95rem;
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

/* 2. Panel superior de captura - Manual de Identidad TecNM */
.window-form-panel {
  background: linear-gradient(135deg, #1B396A 0%, #244B88 100%);
  padding: 16px 22px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  border-bottom: 2px solid var(--color-accent, #C5A059);
}

.form-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.form-label {
  width: 110px;
  color: #FFFFFF;
  font-weight: 700;
  font-size: 0.88rem;
  text-align: right;
  flex-shrink: 0;
  letter-spacing: 0.02em;
}

.form-input-wrap {
  flex: 1;
}

.input-cuenta-wrap { max-width: 240px; }
.input-desc-wrap { max-width: 520px; }
.input-costo-wrap { max-width: 150px; }

.tecnm-input {
  width: 100%;
  padding: 7px 12px;
  border: 1px solid var(--color-border-medium, #CBD5E1);
  border-radius: 4px;
  font-size: 0.88rem;
  font-weight: 600;
  background-color: #FFFFFF;
  color: var(--color-text-primary, #1E293B);
  outline: none;
  transition: border-color 0.15s, box-shadow 0.15s;
}

.tecnm-input:focus {
  border-color: var(--color-accent, #C5A059);
  box-shadow: 0 0 0 3px rgba(197, 160, 89, 0.3);
}

/* 3. Rejilla / Tabla de datos */
.window-grid-panel {
  padding: 16px 20px;
  background-color: var(--color-bg-light, #F8FAFC);
}

.grid-table-scroll {
  max-height: 380px;
  min-height: 240px;
  overflow-y: auto;
  border: 1px solid var(--color-border-medium, #CBD5E1);
  border-radius: 6px;
  background-color: var(--color-surface-white, #FFFFFF);
}

.tecnm-data-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.86rem;
}

.tecnm-data-table thead {
  position: sticky;
  top: 0;
  z-index: 2;
  background-color: var(--color-border-light, #F1F5F9);
  border-bottom: 2px solid var(--color-border-medium, #CBD5E1);
}

.tecnm-data-table th {
  padding: 10px 14px;
  text-align: left;
  font-weight: 700;
  color: var(--color-primary-dark, #0F2548);
  font-size: 0.85rem;
  letter-spacing: 0.02em;
}

.th-cuenta { width: 220px; }
.th-desc { width: auto; }
.th-costo { width: 140px; text-align: right; }

.tecnm-data-table td {
  padding: 8px 14px;
  border-bottom: 1px solid var(--color-border, #E2E8F0);
  color: var(--color-text-primary, #1E293B);
}

.data-row {
  background-color: var(--color-surface-white, #FFFFFF);
  transition: background-color 0.15s;
}

.data-row:hover {
  background-color: var(--color-bg-light, #F8FAFC);
}

.data-row.is-selected {
  background-color: var(--color-primary, #1B396A) !important;
}

.data-row.is-selected td {
  color: #FFFFFF !important;
}

/* Modo Oscuro Robusto y Legible para ModalCuentas */
:global([data-theme="dark"]) .tecnm-window {
  background-color: #141E33 !important;
  border-color: #2B5EA7 !important;
}

:global([data-theme="dark"]) .window-grid-panel {
  background-color: #101A2C !important;
}

:global([data-theme="dark"]) .grid-table-scroll {
  background-color: #141E33 !important;
  border-color: #2E3F5E !important;
}

:global([data-theme="dark"]) .tecnm-data-table thead {
  background-color: #101A2C !important;
  border-bottom-color: #2E3F5E !important;
}

:global([data-theme="dark"]) .tecnm-data-table th {
  color: #D4B06A !important;
}

:global([data-theme="dark"]) .data-row {
  background-color: #141E33 !important;
}

:global([data-theme="dark"]) .data-row:hover {
  background-color: #1E2E4A !important;
}

:global([data-theme="dark"]) .tecnm-data-table td {
  color: #F8FAFC !important;
  border-bottom-color: #1E2C44 !important;
}

:global([data-theme="dark"]) .window-footer-bar {
  background-color: #101A2C !important;
  border-top-color: #2E3F5E !important;
}

:global([data-theme="dark"]) .tecnm-input {
  background-color: #0B111E !important;
  color: #F8FAFC !important;
  border-color: #2E3F5E !important;
}

:global([data-theme="dark"]) .btn-secondary {
  background-color: #141E33 !important;
  color: #F8FAFC !important;
  border-color: #2E3F5E !important;
}

.td-costo { text-align: right; }
.font-mono { font-family: monospace; }
.font-bold { font-weight: 700; }

.td-empty {
  padding: 44px 16px;
  text-align: center;
}

.empty-state-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  color: var(--color-text-secondary, #64748B);
}

.empty-icon {
  width: 44px;
  height: 44px;
  color: var(--color-accent, #C5A059);
}

.empty-title {
  margin: 0;
  font-weight: 700;
  font-size: 0.95rem;
  color: var(--color-text-primary, #1E293B);
}

.empty-subtitle {
  font-size: 0.82rem;
  color: var(--color-text-muted, #94A3B8);
  max-width: 400px;
  line-height: 1.4;
}

/* 4. Barra inferior de acciones */
.window-footer-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 20px;
  background-color: var(--color-border-light, #F1F5F9);
  border-top: 1px solid var(--color-border-medium, #CBD5E1);
}

.footer-buttons {
  display: flex;
  gap: 10px;
}

.btn-tecnm {
  padding: 8px 18px;
  border-radius: 6px;
  font-size: 0.88rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.15s ease;
  min-width: 95px;
}

.btn-primary {
  background-color: var(--color-primary, #1B396A);
  color: #FFFFFF;
  border: 1px solid var(--color-primary-dark, #0F2548);
}
.btn-primary:hover {
  background-color: var(--color-primary-hover, #244B88);
}

.btn-accent {
  background-color: var(--color-accent, #C5A059);
  color: #FFFFFF;
  border: 1px solid #B38E46;
}
.btn-accent:hover {
  background-color: #B38E46;
}

.btn-secondary {
  background-color: #FFFFFF;
  color: var(--color-text-primary, #1E293B);
  border: 1px solid var(--color-border-medium, #CBD5E1);
}
.btn-secondary:hover {
  background-color: var(--color-border-light, #F1F5F9);
}

.btn-danger {
  background-color: #FFFFFF;
  color: #DC2626;
  border: 1px solid #DC2626;
}
.btn-danger:hover {
  background-color: #FEE2E2;
}

.footer-hint {
  font-size: 0.82rem;
  color: var(--color-text-secondary, #64748B);
  font-weight: 600;
}

.footer-hint kbd {
  background-color: #E2E8F0;
  border: 1px solid #CBD5E1;
  border-radius: 4px;
  padding: 2px 6px;
  font-size: 0.75rem;
  color: #1E293B;
  font-family: monospace;
}

@media (max-width: 680px) {
  .form-row { flex-direction: column; align-items: flex-start; gap: 4px; }
  .form-label { text-align: left; width: auto; }
  .input-cuenta-wrap, .input-desc-wrap, .input-costo-wrap { max-width: 100%; }
  .window-footer-bar { flex-direction: column; gap: 10px; }
  .footer-buttons { flex-wrap: wrap; width: 100%; }
}
</style>

