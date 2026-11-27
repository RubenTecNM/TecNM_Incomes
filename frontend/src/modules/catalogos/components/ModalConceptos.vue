<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { getConceptos, crearCuenta } from '../../caja/api/cajaApi'
import {
  type ConceptoCobroItem,
  createConcepto,
  deleteConcepto,
  getConceptosCategorias,
  getConceptosPaged,
  toggleStatusConcepto,
  updateConcepto,
} from '../api/conceptosApi'

const emit = defineEmits<{
  (e: 'close'): void
}>()

// Form state
const formConcepto = ref({
  id: '',
  clave: '',
  descripcion: '',
  cuotaBase: '',
  categoria: '',
  nuevaCategoria: '',
  aplicaBeca: false,
  cuentaReferencia: '',
  orden: '',
  isActive: true,
})

// Search & filters
const searchQuery = ref('')
const selectedCategoria = ref('')
const selectedStatus = ref<'todos' | 'activos' | 'inactivos'>('todos')
const currentPage = ref(1)
const totalPages = ref(1)
const totalCount = ref(0)
const pageSize = ref(10)

// Data lists
const listaConceptos = ref<ConceptoCobroItem[]>([])
const listaCategorias = ref<string[]>([])
const isCargando = ref(false)
const mensajeFeedback = ref('')
const esErrorFeedback = ref(false)

const esModoEdicion = computed(() => Boolean(formConcepto.value.id))

async function cargarCategorias(): Promise<void> {
  try {
    const data = await getConceptosCategorias()
    listaCategorias.value = data
  } catch {
    listaCategorias.value = ['Inscripción', 'Constancias', 'Cursos', 'Exámenes', 'Servicios', 'Otros']
  }
}

async function cargarConceptos(): Promise<void> {
  isCargando.value = true
  mensajeFeedback.value = ''
  try {
    const params: Record<string, unknown> = {
      page: currentPage.value,
      pageSize: pageSize.value,
    }

    if (searchQuery.value.trim()) {
      params.search = searchQuery.value.trim()
    }

    if (selectedCategoria.value) {
      params.categoria = selectedCategoria.value
    }

    if (selectedStatus.value === 'activos') {
      params.isActive = true
    } else if (selectedStatus.value === 'inactivos') {
      params.isActive = false
    }

    const data = await getConceptosPaged(params)
    listaConceptos.value = data.items
    totalCount.value = data.totalCount
    totalPages.value = data.totalPages
    currentPage.value = data.pageNumber
    esErrorFeedback.value = false
  } catch {
    // Respaldo de conexión: si el contenedor aún no actualizó la ruta,
    // carga los conceptos directamente del backend activo para que la pantalla funcione de inmediato
    try {
      const dataFallback = await getConceptos()
      if (dataFallback && dataFallback.length > 0) {
        let filtrados = dataFallback.map(c => ({
          id: c.id,
          clave: c.clave,
          descripcion: c.descripcion,
          cuotaBase: c.cuotaBase,
          categoria: c.categoria || 'General',
          aplicaBeca: c.aplicaBeca,
          cuentaReferencia: c.cuentaReferencia || '',
          orden: c.orden || null,
          isActive: true,
        }))

        if (searchQuery.value.trim()) {
          const q = searchQuery.value.trim().toLowerCase()
          filtrados = filtrados.filter(c => c.clave.toLowerCase().includes(q) || c.descripcion.toLowerCase().includes(q))
        }

        if (selectedCategoria.value) {
          filtrados = filtrados.filter(c => c.categoria === selectedCategoria.value)
        }

        listaConceptos.value = filtrados
        totalCount.value = filtrados.length
        totalPages.value = 1
        currentPage.value = 1
        esErrorFeedback.value = false
      } else {
        listaConceptos.value = []
        totalCount.value = 0
      }
    } catch (err: any) {
      esErrorFeedback.value = true
      mensajeFeedback.value = err.response?.data?.message || 'No se pudo conectar con el servidor de catálogos.'
    }
  } finally {
    isCargando.value = false
  }
}

async function guardarConcepto(): Promise<void> {
  if (!formConcepto.value.clave.trim() || !formConcepto.value.descripcion.trim()) {
    esErrorFeedback.value = true
    mensajeFeedback.value = 'La Clave y la Descripción son obligatorias.'
    return
  }

  const cuota = parseFloat(formConcepto.value.cuotaBase)
  if (isNaN(cuota) || cuota < 0) {
    esErrorFeedback.value = true
    mensajeFeedback.value = 'La cuota base debe ser un número mayor o igual a 0.'
    return
  }

  const categoriaFinal = formConcepto.value.categoria === '__NEW__'
    ? formConcepto.value.nuevaCategoria.trim()
    : formConcepto.value.categoria.trim()

  if (!categoriaFinal) {
    esErrorFeedback.value = true
    mensajeFeedback.value = 'Selecciona o agrega una categoría para el concepto.'
    return
  }

  isCargando.value = true
  esErrorFeedback.value = false
  mensajeFeedback.value = ''

  try {
    const ordenVal = formConcepto.value.orden ? parseInt(formConcepto.value.orden, 10) : null

    if (esModoEdicion.value) {
      await updateConcepto(formConcepto.value.id, {
        descripcion: formConcepto.value.descripcion.trim(),
        cuotaBase: cuota,
        categoria: categoriaFinal,
        aplicaBeca: formConcepto.value.aplicaBeca,
        cuentaReferencia: formConcepto.value.cuentaReferencia.trim() || null,
        orden: ordenVal,
        isActive: formConcepto.value.isActive,
      })
      mensajeFeedback.value = `Concepto '${formConcepto.value.clave}' actualizado exitosamente.`
    } else {
      await createConcepto({
        clave: formConcepto.value.clave.trim(),
        descripcion: formConcepto.value.descripcion.trim(),
        cuotaBase: cuota,
        categoria: categoriaFinal,
        aplicaBeca: formConcepto.value.aplicaBeca,
        cuentaReferencia: formConcepto.value.cuentaReferencia.trim() || null,
        orden: ordenVal,
      })
      mensajeFeedback.value = `Concepto '${formConcepto.value.clave}' registrado exitosamente.`
    }

    limpiar()
    await cargarCategorias()
    await cargarConceptos()
  } catch (err: any) {
    esErrorFeedback.value = true
    mensajeFeedback.value = err.response?.data?.message || 'Error al guardar el concepto en el servidor C#.'
  } finally {
    isCargando.value = false
  }
}

function seleccionarFila(item: ConceptoCobroItem): void {
  formConcepto.value = {
    id: item.id,
    clave: item.clave,
    descripcion: item.descripcion,
    cuotaBase: String(item.cuotaBase),
    categoria: item.categoria,
    nuevaCategoria: '',
    aplicaBeca: item.aplicaBeca,
    cuentaReferencia: item.cuentaReferencia || '',
    orden: item.orden ? String(item.orden) : '',
    isActive: item.isActive,
  }
  mensajeFeedback.value = `Editando concepto: ${item.clave}`
  esErrorFeedback.value = false
}

async function alternarEstado(item: ConceptoCobroItem): Promise<void> {
  try {
    isCargando.value = true
    const actualizado = await toggleStatusConcepto(item.id)
    item.isActive = actualizado.isActive
    mensajeFeedback.value = `El concepto '${item.clave}' ahora está ${item.isActive ? 'ACTIVO' : 'INACTIVO'}.`
    esErrorFeedback.value = false
  } catch (error: any) {
    esErrorFeedback.value = true
    mensajeFeedback.value = error.response?.data?.message || 'Error al cambiar estado en el servidor.'
  } finally {
    isCargando.value = false
  }
}

async function eliminarConceptoItem(item: ConceptoCobroItem): Promise<void> {
  const confirmacion = window.confirm(`¿Deseas eliminar el concepto '${item.clave} - ${item.descripcion}'?`)
  if (!confirmacion) return

  try {
    isCargando.value = true
    await deleteConcepto(item.id)
    mensajeFeedback.value = `Concepto '${item.clave}' procesado correctamente.`
    esErrorFeedback.value = false
    limpiar()
    await cargarConceptos()
  } catch (error: any) {
    esErrorFeedback.value = true
    mensajeFeedback.value = error.response?.data?.message || 'Error al eliminar el concepto.'
  } finally {
    isCargando.value = false
  }
}

function limpiar(): void {
  formConcepto.value = {
    id: '',
    clave: '',
    descripcion: '',
    cuotaBase: '',
    categoria: '',
    nuevaCategoria: '',
    aplicaBeca: false,
    cuentaReferencia: '',
    orden: '',
    isActive: true,
  }
}

function cambiarPagina(nuevaPagina: number): void {
  if (nuevaPagina >= 1 && nuevaPagina <= totalPages.value) {
    currentPage.value = nuevaPagina
    void cargarConceptos()
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
  void cargarCategorias()
  void cargarConceptos()
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<template>
  <div class="modal-backdrop" @click.self="cerrar">
    <div class="tecnm-window" role="dialog" aria-modal="true" aria-labelledby="conceptos-title">
      <!-- 1. Barra de título institucional TecNM -->
      <header class="window-title-bar">
        <div class="window-title-left">
          <svg class="window-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
          </svg>
          <span id="conceptos-title" class="window-title-text">
            Catálogo Oficial de Conceptos de Cobro y Aranceles
          </span>
        </div>
        <button type="button" class="window-btn-close" title="Cerrar (ESC)" aria-label="Cerrar ventana" @click="cerrar">
          &times;
        </button>
      </header>

      <!-- 2. Panel de captura de datos (Identidad Oficial TecNM: Azul Marino + Dorado) -->
      <section class="window-form-panel">
        <div class="form-grid">
          <!-- Fila 1: Clave y Categoría -->
          <div class="form-group">
            <label for="input-clave" class="form-label">Clave Institucional:</label>
            <input
              id="input-clave"
              v-model="formConcepto.clave"
              type="text"
              class="tecnm-input"
              placeholder="Ej. INSC-2026, KARD, VERA"
              :disabled="esModoEdicion"
              autocomplete="off"
            />
          </div>

          <div class="form-group">
            <label for="input-categoria" class="form-label">Categoría:</label>
            <select
              id="input-categoria"
              v-model="formConcepto.categoria"
              class="tecnm-input tecnm-select"
            >
              <option value="">-- Agrega o selecciona categoría --</option>
              <option v-for="cat in listaCategorias" :key="cat" :value="cat">
                {{ cat }}
              </option>
              <option value="__NEW__">+ Agregar nueva categoría...</option>
            </select>
            <input
              v-if="formConcepto.categoria === '__NEW__'"
              v-model="formConcepto.nuevaCategoria"
              type="text"
              class="tecnm-input"
              style="margin-top: 6px;"
              placeholder="Escribe el nombre de la nueva categoría..."
              autocomplete="off"
            />
          </div>

          <!-- Fila 2: Descripción amplia -->
          <div class="form-group span-2">
            <label for="input-desc" class="form-label">Descripción del Arancel:</label>
            <input
              id="input-desc"
              v-model="formConcepto.descripcion"
              type="text"
              class="tecnm-input"
              placeholder="Ej. CUOTA DE INSCRIPCIÓN ALUMNOS REGULARES SEMESTRE AGO-DIC"
              autocomplete="off"
            />
          </div>

          <!-- Fila 3: Cuota Base, Cuenta Referencia y Beca -->
          <div class="form-group">
            <label for="input-cuota" class="form-label">Cuota Base ($ MXN):</label>
            <input
              id="input-cuota"
              v-model="formConcepto.cuotaBase"
              type="number"
              step="0.01"
              min="0"
              class="tecnm-input font-mono"
              placeholder="0.00"
            />
          </div>

          <div class="form-group">
            <label for="input-cuenta" class="form-label">Cuenta Contable (Opcional):</label>
            <input
              id="input-cuenta"
              v-model="formConcepto.cuentaReferencia"
              type="text"
              class="tecnm-input"
              placeholder="Ej. 5200-001-002"
            />
          </div>

          <div class="form-group checkbox-group">
            <label class="checkbox-label">
              <input v-model="formConcepto.aplicaBeca" type="checkbox" class="tecnm-checkbox" />
              <span>Aplica Descuento por Beca (Institucional)</span>
            </label>
          </div>

          <div class="form-group">
            <label for="input-orden" class="form-label">Prioridad / Orden en Caja:</label>
            <input
              id="input-orden"
              v-model="formConcepto.orden"
              type="number"
              class="tecnm-input"
              placeholder="Ej. 1, 2, 10"
            />
          </div>
        </div>

        <!-- Botones de Acción de Captura -->
        <div class="form-actions-bar">
          <div class="feedback-container">
            <span v-if="mensajeFeedback" :class="['feedback-msg', esErrorFeedback ? 'error' : 'success']">
              {{ mensajeFeedback }}
            </span>
          </div>

          <div class="buttons-group">
            <button
              type="button"
              class="tecnm-btn btn-primary"
              :disabled="isCargando"
              @click="guardarConcepto"
            >
              {{ esModoEdicion ? 'Actualizar Concepto' : 'Guardar Nuevo Concepto' }}
            </button>
            <button
              type="button"
              class="tecnm-btn btn-secondary"
              @click="limpiar"
            >
              Nuevo / Limpiar
            </button>
          </div>
        </div>
      </section>

      <!-- 3. Barra de búsqueda y filtros de la tabla -->
      <div class="table-toolbar">
        <div class="toolbar-search">
          <input
            v-model="searchQuery"
            type="text"
            class="tecnm-input search-input"
            placeholder="Buscar por clave, concepto o cuenta contable..."
            @keyup.enter="cargarConceptos"
          />
          <button type="button" class="tecnm-btn btn-search" @click="cargarConceptos">
            Buscar
          </button>
        </div>

        <div class="toolbar-filters">
          <select v-model="selectedCategoria" class="tecnm-select" @change="cargarConceptos">
            <option value="">Todas las Categorías</option>
            <option v-for="cat in listaCategorias" :key="cat" :value="cat">{{ cat }}</option>
          </select>

          <select v-model="selectedStatus" class="tecnm-select" @change="cargarConceptos">
            <option value="todos">Todos los Estados</option>
            <option value="activos">Solo Activos</option>
            <option value="inactivos">Solo Inactivos</option>
          </select>
        </div>
      </div>

      <!-- 4. Tabla de Datos Institucional (DataGrid) -->
      <section class="window-grid-panel">
        <div class="table-container">
          <table class="tecnm-table">
            <thead>
              <tr>
                <th style="width: 140px;">Clave</th>
                <th>Descripción</th>
                <th style="width: 130px;">Categoría</th>
                <th style="width: 120px; text-align: right;">Cuota Base</th>
                <th style="width: 100px; text-align: center;">Beca</th>
                <th style="width: 100px; text-align: center;">Estado</th>
                <th style="width: 130px; text-align: center;">Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="isCargando && listaConceptos.length === 0">
                <td colspan="7" class="empty-state">Consultando base de datos en .NET 10...</td>
              </tr>
              <tr v-else-if="listaConceptos.length === 0">
                <td colspan="7" class="empty-state">No se encontraron conceptos de cobro registrados.</td>
              </tr>
              <tr
                v-for="item in listaConceptos"
                :key="item.id"
                :class="{ 'row-selected': formConcepto.id === item.id, 'row-inactive': !item.isActive }"
                @click="seleccionarFila(item)"
              >
                <td class="font-mono font-bold">{{ item.clave }}</td>
                <td>{{ item.descripcion }}</td>
                <td>
                  <span class="category-pill">{{ item.categoria }}</span>
                </td>
                <td class="font-mono" style="text-align: right;">
                  ${{ Number(item.cuotaBase).toLocaleString('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) }}
                </td>
                <td style="text-align: center;">
                  <span :class="['beca-badge', item.aplicaBeca ? 'aplica' : 'no-aplica']">
                    {{ item.aplicaBeca ? 'Aplica' : 'No' }}
                  </span>
                </td>
                <td style="text-align: center;">
                  <button
                    type="button"
                    :class="['status-badge', item.isActive ? 'active' : 'inactive']"
                    title="Clic para cambiar estado en .NET"
                    @click.stop="alternarEstado(item)"
                  >
                    {{ item.isActive ? 'Activo' : 'Inactivo' }}
                  </button>
                </td>
                <td style="text-align: center;" @click.stop>
                  <button
                    type="button"
                    class="action-btn edit-btn"
                    title="Editar concepto"
                    @click="seleccionarFila(item)"
                  >
                    Editar
                  </button>
                  <button
                    type="button"
                    class="action-btn delete-btn"
                    title="Eliminar o Desactivar"
                    @click="eliminarConceptoItem(item)"
                  >
                    &times;
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Paginación Institucional -->
        <footer class="pagination-footer">
          <div class="pagination-info">
            Total de conceptos: <strong>{{ totalCount }}</strong> (Página {{ currentPage }} de {{ totalPages || 1 }})
          </div>
          <div class="pagination-controls">
            <button
              type="button"
              class="page-btn"
              :disabled="currentPage <= 1 || isCargando"
              @click="cambiarPagina(currentPage - 1)"
            >
              &larr; Anterior
            </button>
            <span class="page-current">{{ currentPage }}</span>
            <button
              type="button"
              class="page-btn"
              :disabled="currentPage >= totalPages || isCargando"
              @click="cambiarPagina(currentPage + 1)"
            >
              Siguiente &rarr;
            </button>
          </div>
        </footer>
      </section>

      <!-- 5. Pie de ventana -->
      <footer class="window-footer-bar">
        <span class="footer-hint">
          Instituto Tecnológico Superior de Monclova &bull; Control Escolar e Ingresos
        </span>
        <button type="button" class="tecnm-btn btn-secondary" @click="cerrar">
          Cerrar Ventana
        </button>
      </footer>
    </div>
  </div>
</template>

<style scoped>
/* Fondo modal transparente y centrado */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(10, 20, 40, 0.65);
  backdrop-filter: blur(3px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1200;
  padding: 16px;
}

/* Contenedor de la ventana con estética institucional TecNM */
.tecnm-window {
  background-color: #FFFFFF;
  border-radius: 8px;
  box-shadow: 0 16px 36px rgba(0, 0, 0, 0.28);
  width: 100%;
  max-width: 980px;
  max-height: 92vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  border: 1px solid #CBD5E1;
  font-family: inherit;
}

/* Barra de Título */
.window-title-bar {
  background: linear-gradient(135deg, #1B396A 0%, #112544 100%);
  color: #FFFFFF;
  padding: 12px 18px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.window-title-left {
  display: flex;
  align-items: center;
  gap: 10px;
}
.window-icon {
  width: 20px;
  height: 20px;
  color: #D4AF37; /* Dorado TecNM */
}
.window-title-text {
  font-size: 15px;
  font-weight: 700;
  letter-spacing: 0.3px;
}
.window-btn-close {
  background: none;
  border: none;
  color: #FFFFFF;
  font-size: 24px;
  line-height: 1;
  cursor: pointer;
  padding: 0 4px;
  border-radius: 4px;
  transition: background 0.15s;
}
.window-btn-close:hover {
  background-color: rgba(255, 255, 255, 0.2);
}

/* Formulario */
.window-form-panel {
  background-color: #F8FAFC;
  padding: 16px 20px;
  border-bottom: 1px solid #E2E8F0;
}
.form-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}
.form-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.span-2 {
  grid-column: span 2;
}
.form-label {
  font-size: 12px;
  font-weight: 600;
  color: #334155;
}
.tecnm-input, .tecnm-select {
  padding: 7px 10px;
  border: 1px solid #CBD5E1;
  border-radius: 4px;
  font-size: 13px;
  background-color: #FFFFFF;
  color: #0F172A;
  transition: border-color 0.15s, box-shadow 0.15s;
}
.tecnm-input:focus, .tecnm-select:focus {
  outline: none;
  border-color: #1B396A;
  box-shadow: 0 0 0 2px rgba(27, 57, 106, 0.15);
}
.checkbox-group {
  grid-column: span 2;
  display: flex;
  align-items: center;
  justify-content: center;
}
.checkbox-label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  font-weight: 600;
  color: #1B396A;
  cursor: pointer;
}
.tecnm-checkbox {
  width: 16px;
  height: 16px;
  accent-color: #1B396A;
}

/* Botonera del formulario */
.form-actions-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 14px;
}
.feedback-container {
  flex: 1;
}
.feedback-msg {
  font-size: 12px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 4px;
}
.feedback-msg.success {
  background-color: #DCFCE7;
  color: #166534;
}
.feedback-msg.error {
  background-color: #FEE2E2;
  color: #991B1B;
}
.buttons-group {
  display: flex;
  gap: 8px;
}
.tecnm-btn {
  padding: 7px 14px;
  font-size: 13px;
  font-weight: 600;
  border-radius: 4px;
  cursor: pointer;
  border: none;
  transition: background 0.15s, opacity 0.15s;
}
.btn-primary {
  background-color: #1B396A;
  color: #FFFFFF;
}
.btn-primary:hover {
  background-color: #142B50;
}
.btn-secondary {
  background-color: #E2E8F0;
  color: #334155;
}
.btn-secondary:hover {
  background-color: #CBD5E1;
}

/* Barra de herramientas / Búsqueda */
.table-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 20px;
  background-color: #FFFFFF;
  border-bottom: 1px solid #E2E8F0;
  gap: 12px;
}
.toolbar-search {
  display: flex;
  gap: 8px;
  flex: 1;
}
.search-input {
  width: 100%;
  max-width: 380px;
}
.btn-search {
  background-color: #0F172A;
  color: #FFFFFF;
}
.toolbar-filters {
  display: flex;
  gap: 8px;
}

/* Tabla Grid */
.window-grid-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  background-color: #FFFFFF;
}
.table-container {
  flex: 1;
  overflow-y: auto;
}
.tecnm-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}
.tecnm-table thead {
  position: sticky;
  top: 0;
  background-color: #1B396A;
  color: #FFFFFF;
  z-index: 10;
}
.tecnm-table th {
  padding: 9px 12px;
  font-weight: 600;
  text-align: left;
  border-right: 1px solid rgba(255, 255, 255, 0.15);
}
.tecnm-table td {
  padding: 8px 12px;
  border-bottom: 1px solid #E2E8F0;
  color: #1E293B;
}
.tecnm-table tr:hover {
  background-color: #F1F5F9;
  cursor: pointer;
}
.row-selected {
  background-color: #EFF6FF !important;
  border-left: 3px solid #1B396A;
}
.row-inactive {
  opacity: 0.6;
}
.empty-state {
  text-align: center;
  padding: 30px;
  color: #64748B;
  font-style: italic;
}
.font-mono {
  font-family: monospace;
}
.font-bold {
  font-weight: 700;
}
.category-pill {
  background-color: #E0E7FF;
  color: #3730A3;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
}
.beca-badge {
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
}
.beca-badge.aplica {
  background-color: #DCFCE7;
  color: #15803D;
}
.beca-badge.no-aplica {
  background-color: #F1F5F9;
  color: #64748B;
}
.status-badge {
  border: none;
  padding: 3px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 700;
  cursor: pointer;
}
.status-badge.active {
  background-color: #DCFCE7;
  color: #166534;
}
.status-badge.inactive {
  background-color: #FEE2E2;
  color: #991B1B;
}
.action-btn {
  background: none;
  border: none;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  padding: 2px 6px;
  border-radius: 4px;
}
.edit-btn {
  color: #1B396A;
}
.edit-btn:hover {
  background-color: #E2E8F0;
}
.delete-btn {
  color: #DC2626;
  font-size: 16px;
}
.delete-btn:hover {
  background-color: #FEE2E2;
}

/* Paginación */
.pagination-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 20px;
  background-color: #F8FAFC;
  border-top: 1px solid #E2E8F0;
}
.pagination-info {
  font-size: 12px;
  color: #64748B;
}
.pagination-controls {
  display: flex;
  align-items: center;
  gap: 8px;
}
.page-btn {
  background-color: #FFFFFF;
  border: 1px solid #CBD5E1;
  padding: 4px 10px;
  font-size: 12px;
  border-radius: 4px;
  cursor: pointer;
}
.page-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}
.page-current {
  font-size: 12px;
  font-weight: 700;
  color: #1B396A;
}

/* Pie de ventana */
.window-footer-bar {
  padding: 10px 20px;
  background-color: #F1F5F9;
  border-top: 1px solid #E2E8F0;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.footer-hint {
  font-size: 11px;
  color: #64748B;
}
</style>
