<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { UiToggle } from '../../../shared/components'
import { useTheme } from '../../../shared/composables/useTheme'
import { logout, me } from '../../auth/api/authApi'
import { clearSessionMarker } from '../../../shared/utils/sessionCookie'
import * as cajaApi from '../api/cajaApi'
import type { DashboardIndicadoresResponse } from '../api/cajaApi'

// ==========================================
// Estado General y Navegación
// ==========================================
const router = useRouter()
const { dark } = useTheme()

const usuarioActual = ref('Administrador General')
const scopeLabel = ref('Vista Global (Administrador)')
const fechaHoy = ref(new Date().toISOString().split('T')[0])
const fechaReferencia = computed(() => fechaHoy.value)
const isCargando = ref(true)
const isExportandoPdf = ref(false)

// Periodo activo: 'hoy' | 'semana' | 'mes'
const periodoActivo = ref<'hoy' | 'semana' | 'mes'>('hoy')

// ==========================================
// Datos Calculados en Backend C# por Rol/Turno
// ==========================================
const dashboardData = ref<DashboardIndicadoresResponse | null>(null)

// ==========================================
// Carga de Datos desde C# (/api/dashboard/indicadores)
// ==========================================
async function cargarDatos(): Promise<void> {
  isCargando.value = true
  try {
    const res = await cajaApi.getDashboardIndicadores(periodoActivo.value)
    dashboardData.value = res
    if (res.usuarioActual) usuarioActual.value = res.usuarioActual
    if (res.scopeLabel) scopeLabel.value = res.scopeLabel
    if (res.fechaReferencia) fechaHoy.value = res.fechaReferencia
  } catch (err) {
    console.error('Error al cargar indicadores desde C#:', err)
    try {
      const u = await me()
      if (u?.name) usuarioActual.value = u.name
    } catch {
      // ignore
    }
  } finally {
    isCargando.value = false
  }
}

onMounted(() => {
  void cargarDatos()
})

watch(periodoActivo, () => {
  void cargarDatos()
})

// ==========================================
// 1. KPI Cards Superiores (Desde C#)
// ==========================================
const recaudacionTotal = computed(() => dashboardData.value?.recaudacionTotal ?? 0)
const metaObjetivo = computed(() => dashboardData.value?.metaObjetivo ?? 165000)

const metaLabel = computed(() => {
  if (periodoActivo.value === 'hoy') return 'diaria'
  if (periodoActivo.value === 'semana') return 'semanal'
  return 'mensual'
})

const periodoTexto = computed(() => {
  if (periodoActivo.value === 'hoy') return 'Hoy'
  if (periodoActivo.value === 'semana') return 'Esta Semana'
  return 'Este Mes'
})

const totalRecibosEmitidos = computed(() => dashboardData.value?.totalRecibosEmitidos ?? 0)
const ultimoFolio = computed(() => dashboardData.value?.ultimoFolio ?? '0')
const promedioPorRecibo = computed(() => dashboardData.value?.promedioPorRecibo ?? 0)

const totalAlumnosAtendidos = computed(() => dashboardData.value?.totalAlumnosAtendidos ?? 0)
const porcentajeAlCorriente = computed(() => dashboardData.value?.porcentajeAlCorriente ?? 100)
const porcentajeConAdeudo = computed(() => dashboardData.value?.porcentajeConAdeudo ?? 0)

const adeudosRecuperadosMonto = computed(() => dashboardData.value?.adeudosRecuperadosMonto ?? 0)
const alumnosAdeudoRecuperado = computed(() => dashboardData.value?.alumnosAdeudoRecuperado ?? 0)

// ==========================================
// 2. Gráfica de Métodos de Pago Más Usados (Desde C#)
// ==========================================
interface MetodoDesglose {
  key: string
  nombre: string
  monto: number
  porcentaje: number
  color: string
  strokeDashoffset: number
  strokeDasharray: string
}

const metodosPagoDesglose = computed<MetodoDesglose[]>(() => {
  const items = dashboardData.value?.metodosPago ?? []
  const circumference = 2 * Math.PI * 65 // radio = 65 -> ~408.4
  let currentOffset = 0

  return items.map(it => {
    const dashLength = (it.porcentaje / 100) * circumference
    const offset = currentOffset
    currentOffset += dashLength

    return {
      key: it.key,
      nombre: it.nombre,
      monto: Number(it.monto) || 0,
      porcentaje: it.porcentaje,
      color: it.color,
      strokeDashoffset: -offset,
      strokeDasharray: `${dashLength} ${circumference}`,
    }
  })
})

// ==========================================
// 3. Tendencia de Ingresos Semanales (Desde C#)
// ==========================================
interface DiaBarra {
  dia: string
  diaCorto: string
  monto: number
  etiquetaK: string
  porcentajeAltura: number
  esDestacado: boolean
}

const diasSemanaGrafica = computed<DiaBarra[]>(() => {
  return (dashboardData.value?.tendenciaSemanal ?? []).map(d => ({
    dia: d.dia,
    diaCorto: d.diaCorto,
    monto: Number(d.monto) || 0,
    etiquetaK: d.etiquetaK,
    porcentajeAltura: d.porcentajeAltura,
    esDestacado: d.esDestacado,
  }))
})

const promedioSemanal = computed(() => dashboardData.value?.promedioSemanal ?? 0)

// ==========================================
// 4. Recaudación por Concepto (Desde C#)
// ==========================================
interface ConceptoProgreso {
  nombre: string
  monto: number
  porcentaje: number
}

const conceptosTop = computed<ConceptoProgreso[]>(() => {
  return (dashboardData.value?.conceptosTop ?? []).map(c => ({
    nombre: c.nombre,
    monto: Number(c.monto) || 0,
    porcentaje: c.porcentaje,
  }))
})

// ==========================================
// 5. Últimos Recibos Emitidos (Datos Reales C#)
// ==========================================
interface ReciboTablaItem {
  id: string
  folio: string
  matricula: string
  alumno: string
  metodoPago: string
  monto: number
  estado: string
}

const ultimosRecibosTabla = computed<ReciboTablaItem[]>(() => {
  return (dashboardData.value?.ultimosRecibos ?? []).map(r => ({
    id: r.id,
    folio: r.folio,
    matricula: r.matricula,
    alumno: r.alumno,
    metodoPago: r.metodoPago,
    monto: Number(r.monto) || 0,
    estado: r.estado,
  }))
})

// ==========================================
// Navegación
// ==========================================
function irAMenuPrincipal(): void {
  void router.push({ name: 'home' })
}

function irARecibo(): void {
  void router.push({ name: 'caja-recibo' })
}

async function cerrarSesion(): Promise<void> {
  try {
    await logout()
  } finally {
    clearSessionMarker()
    void router.push({ name: 'login' })
  }
}

// ==========================================
// Exportar a PDF (Descarga Directa de PDF desde C#)
// ==========================================
async function exportarCortePDF(): Promise<void> {
  if (isExportandoPdf.value) return
  isExportandoPdf.value = true
  try {
    const blob = await cajaApi.exportarDashboardPdf(periodoActivo.value)
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `Corte_Caja_${periodoActivo.value}_${fechaHoy.value}.pdf`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    URL.revokeObjectURL(url)
  } catch (err) {
    console.error('Error al exportar corte en PDF:', err)
  } finally {
    isExportandoPdf.value = false
  }
}

// Formateador de moneda
function formatearMoneda(val: number): string {
  return new Intl.NumberFormat('es-MX', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(val || 0)
}
</script>

<template>
  <div class="dashboard-wrapper" :class="{ 'dark-theme': dark }">
    <!-- BARRA DE MENÚ CLÁSICA INSTITUCIONAL TECNM -->
    <nav class="tecnm-classic-menubar no-print" aria-label="Menú principal del sistema" @click.stop>
      <div class="menubar-left-group">
        <button
          type="button"
          class="menubar-title-tag menubar-title-btn"
          title="Ir al Menú Principal"
          @click="irAMenuPrincipal"
        >
          MENÚ
        </button>

        <!-- BOTÓN INDICADORES DE CAJA SOLICITADO AL LADO DE MENÚ -->
        <button
          type="button"
          class="btn-indicadores-nav active"
          title="Estás en Indicadores de Caja"
        >
          <svg class="indicadores-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="3" width="7" height="9" rx="1" />
            <rect x="14" y="3" width="7" height="5" rx="1" />
            <rect x="14" y="12" width="7" height="9" rx="1" />
            <rect x="3" y="16" width="7" height="5" rx="1" />
          </svg>
          <span>Indicadores de Caja</span>
        </button>

        <div class="menubar-items-group">
          <!-- Archivo -->
          <div class="menubar-item">
            <button
              type="button"
              class="menubar-btn"
              title="Ir a Pantalla de Recibo"
              @click="irARecibo"
            >
              Archivo
            </button>
          </div>
        </div>
      </div>

      <!-- Info de Usuario y Toggle Dark Mode -->
      <div class="menubar-right-group">
        <div class="user-session-info">
          <span class="user-name">{{ usuarioActual }}</span>
          <span class="user-date">Fecha de Movimientos: {{ fechaReferencia }}</span>
        </div>

        <div class="menubar-theme-toggle">
          <UiToggle
            v-model="dark"
            type="switch"
            :label="dark ? 'Modo oscuro' : 'Modo claro'"
            class="theme-switch"
          />
        </div>

        <button type="button" class="btn-logout-nav" title="Cerrar sesión" @click="cerrarSesion">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="logout-icon">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
            <polyline points="16 17 21 12 16 7" />
            <line x1="21" y1="12" x2="9" y2="12" />
          </svg>
        </button>
      </div>
    </nav>

    <!-- ÁREA DE CONTENIDO PRINCIPAL DEL DASHBOARD -->
    <main class="dashboard-main">
      <!-- Encabezado de la Sección -->
      <div class="dashboard-header-row no-print">
        <div class="header-breadcrumb-area">
          <span class="breadcrumb-tag">TESORERÍA INSTITUCIONAL • {{ scopeLabel }}</span>
          <h1 class="dashboard-main-title">Resumen Ejecutivo de Caja</h1>
        </div>

        <div class="header-actions-area">
          <!-- Filtro de Periodos: Hoy | Esta Semana | Este Mes -->
          <div class="segmented-period-control" role="group" aria-label="Filtro de Periodo">
            <button
              type="button"
              class="period-btn"
              :class="{ active: periodoActivo === 'hoy' }"
              @click="periodoActivo = 'hoy'"
            >
              Hoy
            </button>
            <button
              type="button"
              class="period-btn"
              :class="{ active: periodoActivo === 'semana' }"
              @click="periodoActivo = 'semana'"
            >
              Esta Semana
            </button>
            <button
              type="button"
              class="period-btn"
              :class="{ active: periodoActivo === 'mes' }"
              @click="periodoActivo = 'mes'"
            >
              Este Mes
            </button>
          </div>

          <!-- Botón de Exportar Corte en PDF -->
          <button
            type="button"
            class="btn-export-pdf"
            title="Exportar Corte en formato PDF"
            @click="exportarCortePDF"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="btn-icon">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
              <polyline points="7 10 12 15 17 10" />
              <line x1="12" y1="15" x2="12" y2="3" />
            </svg>
            <span>Exportar Corte</span>
          </button>
        </div>
      </div>

      <!-- ============================================================ -->
      <!-- BLOQUE 1: TARJETAS KPI SUPERIORES (4 COLUMNAS)              -->
      <!-- ============================================================ -->
      <div class="kpi-cards-grid">
        <!-- 1. Recaudación Total -->
        <div class="kpi-card">
          <div class="kpi-top">
            <span class="kpi-title">Recaudación Total ({{ periodoTexto }})</span>
            <span class="kpi-badge badge-success">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="badge-icon">
                <polyline points="18 15 12 9 6 15" />
              </svg>
              +12.4%
            </span>
          </div>
          <div class="kpi-value-row">
            <span class="kpi-value">${{ formatearMoneda(recaudacionTotal) }}</span>
            <span class="kpi-currency">MXN</span>
          </div>
          <div class="kpi-footer">
            <span>Meta {{ metaLabel }}: ${{ formatearMoneda(metaObjetivo) }} MXN</span>
          </div>
        </div>

        <!-- 2. Recibos Emitidos -->
        <div class="kpi-card">
          <div class="kpi-top">
            <span class="kpi-title">Recibos Emitidos</span>
            <span class="kpi-badge badge-info">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="badge-icon">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                <polyline points="14 2 14 8 20 8" />
              </svg>
              Folio {{ ultimoFolio }}
            </span>
          </div>
          <div class="kpi-value-row">
            <span class="kpi-value">{{ totalRecibosEmitidos }}</span>
          </div>
          <div class="kpi-footer">
            <span>Promedio por recibo: ${{ formatearMoneda(promedioPorRecibo) }}</span>
          </div>
        </div>

        <!-- 3. Alumnos Atendidos -->
        <div class="kpi-card">
          <div class="kpi-top">
            <span class="kpi-title">Alumnos Atendidos</span>
            <span class="kpi-badge badge-teal">
              {{ porcentajeAlCorriente }}% al corriente
            </span>
          </div>
          <div class="kpi-value-row">
            <span class="kpi-value">{{ totalAlumnosAtendidos }}</span>
          </div>
          <div class="kpi-footer">
            <span>{{ porcentajeConAdeudo }}% con adeudo parcial activo</span>
          </div>
        </div>

        <!-- 4. Adeudos Recuperados -->
        <div class="kpi-card">
          <div class="kpi-top">
            <span class="kpi-title">Adeudos Recuperados</span>
            <span class="kpi-badge badge-warning">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="badge-icon">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                <circle cx="9" cy="7" r="4" />
              </svg>
              {{ alumnosAdeudoRecuperado }} alumnos
            </span>
          </div>
          <div class="kpi-value-row">
            <span class="kpi-value">${{ formatearMoneda(adeudosRecuperadosMonto) }}</span>
            <span class="kpi-currency">MXN</span>
          </div>
          <div class="kpi-footer">
            <span>Regularización de semestre</span>
          </div>
        </div>
      </div>

      <!-- ============================================================ -->
      <!-- BLOQUE 2: MÉTODOS DE PAGO Y TENDENCIA SEMANAL (2 COLUMNAS)   -->
      <!-- ============================================================ -->
      <div class="charts-two-columns-grid">
        <!-- Tarjeta Izquierda: Métodos de Pago Más Usados -->
        <div class="dashboard-card payment-methods-card">
          <div class="card-header-flex">
            <div>
              <h2 class="card-main-title">Métodos de Pago Más Usados</h2>
              <p class="card-subtitle">Distribución porcentual del ingreso</p>
            </div>
            <button
              type="button"
              class="btn-icon-reload"
              title="Actualizar datos"
              @click="cargarDatos"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="reload-svg">
                <path d="M23 4v6h-6" />
                <path d="M1 20v-6h6" />
                <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15" />
              </svg>
            </button>
          </div>

          <div class="donut-chart-container">
            <!-- Donut SVG -->
            <div class="donut-svg-wrap">
              <svg viewBox="0 0 160 160" class="donut-svg">
                <!-- Círculo base de fondo -->
                <circle
                  cx="80"
                  cy="80"
                  r="65"
                  fill="none"
                  stroke="var(--donut-track, #E2E8F0)"
                  stroke-width="26"
                />
                <!-- Segmentos de Métodos de Pago -->
                <circle
                  v-for="item in metodosPagoDesglose"
                  :key="item.key"
                  cx="80"
                  cy="80"
                  r="65"
                  fill="none"
                  :stroke="item.color"
                  stroke-width="26"
                  :stroke-dasharray="item.strokeDasharray"
                  :stroke-dashoffset="item.strokeDashoffset"
                  class="donut-segment"
                />
              </svg>
              <!-- Texto central del Donut -->
              <div class="donut-center-text">
                <span class="donut-center-label">Total</span>
                <strong class="donut-center-val">100%</strong>
              </div>
            </div>

            <!-- Leyenda de Métodos -->
            <div class="donut-legend-list">
              <div
                v-for="item in metodosPagoDesglose"
                :key="item.key"
                class="legend-item"
              >
                <div class="legend-left">
                  <span class="legend-bullet" :style="{ backgroundColor: item.color }" />
                  <span class="legend-name">{{ item.nombre }}</span>
                </div>
                <div class="legend-right">
                  <span class="legend-pct">{{ item.porcentaje }}%</span>
                  <span class="legend-amount">${{ formatearMoneda(item.monto) }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Tarjeta Derecha: Tendencia de Ingresos Semanales -->
        <div class="dashboard-card weekly-trend-card">
          <div class="card-header-flex">
            <div>
              <h2 class="card-main-title">Tendencia de Ingresos Semanales</h2>
              <p class="card-subtitle">Recaudación diaria de Lunes a Sábado (MXN)</p>
            </div>
            <div class="card-header-badge">
              <span>Promedio: ${{ formatearMoneda(promedioSemanal) }}</span>
            </div>
          </div>

          <div class="bar-chart-container">
            <!-- Líneas de eje Y -->
            <div class="y-axis-lines">
              <div class="y-line"><span>$200k</span></div>
              <div class="y-line"><span>$150k</span></div>
              <div class="y-line"><span>$100k</span></div>
              <div class="y-line"><span>$50k</span></div>
              <div class="y-line y-base"><span>$0</span></div>
            </div>

            <!-- Columnas de días -->
            <div class="bars-plot-area">
              <div
                v-for="dia in diasSemanaGrafica"
                :key="dia.dia"
                class="bar-column-item"
                :class="{ 'highlight-day': dia.esDestacado }"
              >
                <span class="bar-floating-val">{{ dia.etiquetaK }}</span>
                <div class="bar-track">
                  <div
                    class="bar-fill"
                    :style="{ height: `${dia.porcentajeAltura}%` }"
                    :title="`${dia.dia}: $${formatearMoneda(dia.monto)}`"
                  />
                </div>
                <span class="bar-day-name">{{ dia.diaCorto }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- ============================================================ -->
      <!-- BLOQUE 3: RECAUDACIÓN POR CONCEPTO Y ÚLTIMOS RECIBOS        -->
      <!-- ============================================================ -->
      <div class="charts-two-columns-grid">
        <!-- Tarjeta Izquierda: Recaudación por Concepto -->
        <div class="dashboard-card concepts-card">
          <div class="card-header-flex">
            <div>
              <h2 class="card-main-title">Recaudación por Concepto</h2>
              <p class="card-subtitle">Principales rubros de ingreso</p>
            </div>
            <div class="card-header-icon-box">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="chart-icon">
                <line x1="18" y1="20" x2="18" y2="10" />
                <line x1="12" y1="20" x2="12" y2="4" />
                <line x1="6" y1="20" x2="6" y2="14" />
              </svg>
            </div>
          </div>

          <div class="concepts-progress-list">
            <div
              v-for="c in conceptosTop"
              :key="c.nombre"
              class="concept-progress-item"
            >
              <div class="concept-meta-row">
                <span class="concept-label">{{ c.nombre }}</span>
                <span class="concept-amount">
                  ${{ formatearMoneda(c.monto) }} <span class="concept-pct">({{ c.porcentaje }}%)</span>
                </span>
              </div>
              <div class="concept-bar-track">
                <div
                  class="concept-bar-fill"
                  :style="{ width: `${Math.min(100, Math.max(5, c.porcentaje))}%` }"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- Tarjeta Derecha: Últimos Recibos Emitidos -->
        <div class="dashboard-card receipts-table-card">
          <div class="card-header-flex">
            <div>
              <h2 class="card-main-title">Últimos Recibos Emitidos</h2>
              <p class="card-subtitle">Movimientos recientes en caja</p>
            </div>
            <button
              type="button"
              class="link-view-all"
              @click="irARecibo"
            >
              Ver historial completo
            </button>
          </div>

          <div class="table-responsive-wrap">
            <table class="dashboard-table">
              <thead>
                <tr>
                  <th>FOLIO</th>
                  <th>MATRÍCULA</th>
                  <th>ALUMNO</th>
                  <th>MÉTODO DE PAGO</th>
                  <th class="text-right">MONTO</th>
                  <th class="text-center">ESTADO</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="r in ultimosRecibosTabla" :key="r.id">
                  <td class="font-bold">{{ r.folio }}</td>
                  <td class="font-mono text-muted">{{ r.matricula }}</td>
                  <td class="student-name-cell">{{ r.alumno }}</td>
                  <td>{{ r.metodoPago }}</td>
                  <td class="text-right font-bold">${{ formatearMoneda(r.monto) }}</td>
                  <td class="text-center">
                    <span
                      class="table-status-pill"
                      :class="r.estado === 'Cancelado' ? 'status-danger' : 'status-success'"
                    >
                      {{ r.estado }}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </main>

    <!-- PIE DE PÁGINA INSTITUCIONAL -->
    <footer class="dashboard-footer">
      <div class="footer-content">
        <span>© 2026 TECNM Monclova — Tesorería y Control de Caja Universitaria</span>
        <span class="footer-system-tag">Sistema Institucional de Finanzas</span>
      </div>
    </footer>
  </div>
</template>

<style scoped>
/* ==========================================================================
   DASHBOARD INSTITUCIONAL TECNM - PALETA OFICIAL
   ========================================================================== */
.dashboard-wrapper {
  min-height: 100vh;
  background-color: #f4f6fa;
  color: #1e293b;
  display: flex;
  flex-direction: column;
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  transition: background-color 0.25s, color 0.25s;
  border: none !important;
  outline: none !important;
  box-shadow: none !important;
}

/* Modo Oscuro Institucional */
.dashboard-wrapper.dark-theme {
  background-color: #0A1628 !important;
  color: #F8FAFC !important;
  border: none !important;
  outline: none !important;
  box-shadow: none !important;
}

/* ==========================================================================
   BARRA DE MENÚ (Idéntica a CajaPrincipalView y HomeView)
   ========================================================================== */
.tecnm-classic-menubar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  background-color: #FFFFFF;
  border-bottom: 2px solid #C5A059;
  padding: 0 20px;
  height: 44px;
  box-shadow: 0 2px 4px rgba(15, 37, 72, 0.05);
}

.dark-theme .tecnm-classic-menubar {
  background-color: #0F2548 !important;
  border-bottom-color: #D4B06A !important;
}

.menubar-left-group {
  display: flex;
  align-items: center;
  gap: 12px;
}

.menubar-right-group {
  display: flex;
  align-items: center;
  gap: 16px;
}

.menubar-title-tag {
  font-size: 0.8rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #C5A059;
  padding-right: 12px;
  border-right: 1px solid #E2E8F0;
  background: transparent;
  border-top: none;
  border-bottom: none;
  border-left: none;
  cursor: pointer;
  transition: opacity 0.15s ease;
}

.menubar-title-tag:hover {
  opacity: 0.8;
}

.dark-theme .menubar-title-tag {
  color: #D4B06A;
  border-right-color: #24457B;
}

/* Botón "Indicadores de Caja" al lado de MENÚ */
.btn-indicadores-nav {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 14px;
  font-size: 0.82rem;
  font-weight: 700;
  border-radius: 20px;
  background: #1B396A;
  color: #FFFFFF;
  border: 1px solid #C5A059;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-indicadores-nav:hover,
.btn-indicadores-nav.active {
  background: #244B88;
  box-shadow: 0 2px 8px rgba(197, 160, 89, 0.35);
  transform: translateY(-1px);
}

.dark-theme .btn-indicadores-nav {
  background: #10223D;
  color: #F8FAFC;
  border-color: #D4B06A;
}

.dark-theme .btn-indicadores-nav:hover,
.dark-theme .btn-indicadores-nav.active {
  background: #1B3762;
  color: #D4B06A;
  box-shadow: 0 2px 8px rgba(212, 176, 106, 0.3);
}

.indicadores-icon {
  width: 14px;
  height: 14px;
}

.menubar-btn {
  background: transparent;
  border: none;
  color: #1B396A;
  font-size: 0.82rem;
  font-weight: 600;
  padding: 4px 10px;
  cursor: pointer;
}

.dark-theme .menubar-btn {
  color: #F8FAFC !important;
}

.user-session-info {
  display: flex;
  flex-direction: column;
  text-align: right;
  line-height: 1.2;
}

.user-name {
  font-size: 0.82rem;
  font-weight: 700;
  color: #1B396A;
}

.dark-theme .user-name {
  color: #F8FAFC;
}

.user-date {
  font-size: 0.72rem;
  color: #64748B;
}

.dark-theme .user-date {
  color: #94A3B8;
}

.btn-logout-nav {
  background: transparent;
  border: none;
  color: #64748B;
  cursor: pointer;
  display: flex;
  align-items: center;
  padding: 4px;
  border-radius: 4px;
}

.btn-logout-nav:hover {
  color: #EF4444;
}

.logout-icon {
  width: 18px;
  height: 18px;
}

/* ==========================================================================
   MAIN DASHBOARD LAYOUT
   ========================================================================== */
.dashboard-main {
  flex: 1;
  max-width: 1440px;
  width: 100%;
  margin: 0 auto;
  padding: 24px 28px 48px;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  gap: 22px;
}

/* Encabezado y Selector de Periodos */
.dashboard-header-row {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 16px;
  margin-bottom: 4px;
}

.breadcrumb-tag {
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #64748B;
}

.dark-theme .breadcrumb-tag {
  color: #94A3B8;
}

.dashboard-main-title {
  font-size: 1.95rem;
  font-weight: 800;
  color: #1B396A;
  margin: 4px 0 0;
  letter-spacing: -0.02em;
}

.dark-theme .dashboard-main-title {
  color: #F8FAFC;
}

.header-actions-area {
  display: flex;
  align-items: center;
  gap: 12px;
}

/* Control Segmentado (Hoy / Esta Semana / Este Mes) */
.segmented-period-control {
  display: flex;
  background: #E2E8F0;
  border-radius: 8px;
  padding: 3px;
  gap: 2px;
}

.dark-theme .segmented-period-control {
  background: #10223D;
  border: 1px solid #1B3762;
}

.period-btn {
  background: transparent;
  border: none;
  font-size: 0.82rem;
  font-weight: 600;
  padding: 6px 14px;
  border-radius: 6px;
  color: #475569;
  cursor: pointer;
  transition: all 0.15s ease;
}

.period-btn.active {
  background: #1B396A;
  color: #FFFFFF;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.15);
}

.dark-theme .period-btn {
  color: #94A3B8;
}

.dark-theme .period-btn.active {
  background: #244B88;
  color: #FFFFFF;
  border: 1px solid #D4B06A;
}

/* Botón Exportar Corte */
.btn-export-pdf {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: #1B396A;
  color: #FFFFFF;
  font-size: 0.85rem;
  font-weight: 700;
  padding: 8px 18px;
  border-radius: 8px;
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 2px 6px rgba(27, 57, 106, 0.25);
}

.btn-export-pdf:hover {
  background: #244B88;
  box-shadow: 0 4px 12px rgba(27, 57, 106, 0.35);
  transform: translateY(-1px);
}

.dark-theme .btn-export-pdf {
  background: #1B396A;
  border: 1px solid #D4B06A;
}

.btn-icon {
  width: 16px;
  height: 16px;
}

/* ==========================================================================
   KPI CARDS GRID (4 Columnas)
   ========================================================================== */
.kpi-cards-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

@media (max-width: 1100px) {
  .kpi-cards-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 600px) {
  .kpi-cards-grid {
    grid-template-columns: 1fr;
  }
}

.kpi-card {
  background: #FFFFFF;
  border: 1px solid #E2E8F0;
  border-radius: 12px;
  padding: 18px 20px;
  box-shadow: 0 1px 4px rgba(15, 37, 72, 0.04);
  display: flex;
  flex-direction: column;
  gap: 8px;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}

.kpi-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(15, 37, 72, 0.08);
}

.dark-theme .kpi-card {
  background: #10223D !important;
  border-color: #1B3762 !important;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
}

.kpi-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.kpi-title {
  font-size: 0.8rem;
  font-weight: 600;
  color: #64748B;
}

.dark-theme .kpi-title {
  color: #94A3B8;
}

.kpi-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 0.72rem;
  font-weight: 700;
  padding: 3px 8px;
  border-radius: 12px;
}

.badge-icon {
  width: 12px;
  height: 12px;
}

.badge-success {
  background: #DCFCE7;
  color: #15803D;
}

.dark-theme .badge-success {
  background: #064E3B;
  color: #A7F3D0;
}

.badge-info {
  background: #EFF6FF;
  color: #1D4ED8;
}

.dark-theme .badge-info {
  background: #1E3A8A;
  color: #BFDBFE;
}

.badge-teal {
  background: #D1FAE5;
  color: #047857;
}

.dark-theme .badge-teal {
  background: #065F46;
  color: #6EE7B7;
}

.badge-warning {
  background: #FEF3C7;
  color: #B45309;
}

.dark-theme .badge-warning {
  background: #78350F;
  color: #FDE68A;
}

.kpi-value-row {
  display: flex;
  align-items: baseline;
  gap: 6px;
}

.kpi-value {
  font-size: 1.85rem;
  font-weight: 800;
  color: #0F172A;
  letter-spacing: -0.02em;
}

.dark-theme .kpi-value {
  color: #F8FAFC;
}

.kpi-currency {
  font-size: 0.8rem;
  font-weight: 600;
  color: #64748B;
}

.dark-theme .kpi-currency {
  color: #94A3B8;
}

.kpi-footer {
  font-size: 0.74rem;
  color: #64748B;
  margin-top: 2px;
}

.dark-theme .kpi-footer {
  color: #94A3B8;
}

/* ==========================================================================
   CHARTS AND TABLES 2-COLUMNS GRID
   ========================================================================== */
.charts-two-columns-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

@media (max-width: 960px) {
  .charts-two-columns-grid {
    grid-template-columns: 1fr;
  }
}

.dashboard-card {
  background: #FFFFFF;
  border: 1px solid #E2E8F0;
  border-radius: 12px;
  padding: 22px 24px;
  box-shadow: 0 1px 4px rgba(15, 37, 72, 0.04);
}

.dark-theme .dashboard-card {
  background: #10223D !important;
  border-color: #1B3762 !important;
}

.card-header-flex {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 18px;
}

.card-main-title {
  font-size: 1.05rem;
  font-weight: 700;
  color: #0F172A;
  margin: 0;
}

.dark-theme .card-main-title {
  color: #F8FAFC;
}

.card-subtitle {
  font-size: 0.76rem;
  color: #64748B;
  margin: 3px 0 0;
}

.dark-theme .card-subtitle {
  color: #94A3B8;
}

.card-header-badge {
  font-size: 0.74rem;
  font-weight: 700;
  background: #F1F5F9;
  color: #1B396A;
  padding: 4px 10px;
  border-radius: 6px;
}

.dark-theme .card-header-badge {
  background: #1B3762;
  color: #D4B06A;
}

.btn-icon-reload {
  background: transparent;
  border: 1px solid #E2E8F0;
  border-radius: 6px;
  padding: 6px;
  color: #64748B;
  cursor: pointer;
  display: flex;
  align-items: center;
  transition: all 0.15s ease;
}

.btn-icon-reload:hover {
  background: #F1F5F9;
  color: #1B396A;
}

.dark-theme .btn-icon-reload {
  border-color: #1B3762;
  color: #94A3B8;
}

.dark-theme .btn-icon-reload:hover {
  background: #1B3762;
  color: #D4B06A;
}

.reload-svg {
  width: 14px;
  height: 14px;
}

/* ==========================================================================
   DONUT CHART (Métodos de Pago)
   ========================================================================== */
.donut-chart-container {
  display: flex;
  align-items: center;
  justify-content: space-around;
  gap: 20px;
  padding: 10px 0;
  flex-wrap: wrap;
}

.donut-svg-wrap {
  position: relative;
  width: 160px;
  height: 160px;
  flex-shrink: 0;
}

.donut-svg {
  width: 100%;
  height: 100%;
  transform: rotate(-90deg);
}

.donut-segment {
  transition: stroke-dasharray 0.4s ease, stroke-dashoffset 0.4s ease;
}

.donut-center-text {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  line-height: 1.1;
  pointer-events: none;
}

.donut-center-label {
  font-size: 0.72rem;
  color: #64748B;
  text-transform: uppercase;
}

.donut-center-val {
  font-size: 1.25rem;
  font-weight: 800;
  color: #1B396A;
}

.dark-theme .donut-center-val {
  color: #F8FAFC;
}

.donut-legend-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  flex: 1;
  min-width: 220px;
}

.legend-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.8rem;
}

.legend-left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.legend-bullet {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
}

.legend-name {
  color: #334155;
  font-weight: 500;
}

.dark-theme .legend-name {
  color: #CBD5E1;
}

.legend-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.legend-pct {
  font-weight: 700;
  color: #1E293B;
  min-width: 32px;
  text-align: right;
}

.dark-theme .legend-pct {
  color: #F8FAFC;
}

.legend-amount {
  color: #64748B;
  font-size: 0.78rem;
  min-width: 65px;
  text-align: right;
}

.dark-theme .legend-amount {
  color: #94A3B8;
}

/* ==========================================================================
   BAR CHART (Tendencia Semanal)
   ========================================================================== */
.bar-chart-container {
  position: relative;
  height: 200px;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  margin-top: 10px;
}

.y-axis-lines {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 24px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  pointer-events: none;
}

.y-line {
  border-bottom: 1px dashed #E2E8F0;
  position: relative;
  width: 100%;
}

.dark-theme .y-line {
  border-bottom-color: #1B3762;
}

.y-line span {
  position: absolute;
  left: 0;
  top: -9px;
  font-size: 0.68rem;
  color: #94A3B8;
}

.bars-plot-area {
  position: relative;
  z-index: 2;
  display: flex;
  justify-content: space-around;
  align-items: flex-end;
  height: 170px;
  padding-left: 36px;
  margin-bottom: 4px;
}

.bar-column-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 36px;
  height: 100%;
  justify-content: flex-end;
}

.bar-floating-val {
  font-size: 0.68rem;
  font-weight: 700;
  color: #475569;
  margin-bottom: 6px;
}

.dark-theme .bar-floating-val {
  color: #CBD5E1;
}

.bar-track {
  width: 32px;
  height: 130px;
  display: flex;
  align-items: flex-end;
}

.bar-fill {
  width: 100%;
  background: #BFDBFE;
  border-radius: 6px 6px 0 0;
  transition: height 0.3s ease;
}

.dark-theme .bar-fill {
  background: #2563EB;
}

/* Columna destacada (Viernes o día pico) */
.bar-column-item.highlight-day .bar-fill {
  background: #1B396A;
}

.dark-theme .bar-column-item.highlight-day .bar-fill {
  background: #D4B06A;
}

.bar-column-item.highlight-day .bar-floating-val {
  color: #1B396A;
  font-weight: 800;
}

.dark-theme .bar-column-item.highlight-day .bar-floating-val {
  color: #D4B06A;
}

.bar-day-name {
  font-size: 0.74rem;
  font-weight: 600;
  color: #64748B;
  margin-top: 8px;
}

.dark-theme .bar-day-name {
  color: #94A3B8;
}

/* ==========================================================================
   CONCEPTS PROGRESS LIST
   ========================================================================== */
.concepts-progress-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding-top: 6px;
}

.concept-progress-item {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.concept-meta-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.82rem;
}

.concept-label {
  font-weight: 600;
  color: #1E293B;
}

.dark-theme .concept-label {
  color: #F8FAFC;
}

.concept-amount {
  font-weight: 700;
  color: #0F172A;
}

.dark-theme .concept-amount {
  color: #F8FAFC;
}

.concept-pct {
  color: #64748B;
  font-weight: 500;
}

.dark-theme .concept-pct {
  color: #94A3B8;
}

.concept-bar-track {
  width: 100%;
  height: 8px;
  background: #F1F5F9;
  border-radius: 4px;
  overflow: hidden;
}

.dark-theme .concept-bar-track {
  background: #1B3762;
}

.concept-bar-fill {
  height: 100%;
  background: #1B396A;
  border-radius: 4px;
  transition: width 0.3s ease;
}

.dark-theme .concept-bar-fill {
  background: #3B82F6;
}

/* ==========================================================================
   ÚLTIMOS RECIBOS TABLE
   ========================================================================== */
.link-view-all {
  background: transparent;
  border: none;
  font-size: 0.78rem;
  font-weight: 600;
  color: #1B396A;
  cursor: pointer;
  text-decoration: underline;
}

.dark-theme .link-view-all {
  color: #D4B06A;
}

.table-responsive-wrap {
  width: 100%;
  overflow-x: auto;
}

.dashboard-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.8rem;
}

.dashboard-table th {
  text-align: left;
  padding: 8px 10px;
  font-size: 0.7rem;
  font-weight: 700;
  color: #64748B;
  border-bottom: 1px solid #E2E8F0;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.dark-theme .dashboard-table th {
  color: #94A3B8;
  border-bottom-color: #1B3762;
}

.dashboard-table td {
  padding: 10px 10px;
  border-bottom: 1px solid #F1F5F9;
  color: #1E293B;
  vertical-align: middle;
}

.dark-theme .dashboard-table td {
  border-bottom-color: #1B3762;
  color: #F8FAFC;
}

.student-name-cell {
  max-width: 160px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  font-weight: 500;
}

.table-status-pill {
  display: inline-block;
  font-size: 0.72rem;
  font-weight: 700;
  padding: 3px 8px;
  border-radius: 12px;
}

.status-success {
  background: #DCFCE7;
  color: #15803D;
}

.dark-theme .status-success {
  background: #064E3B;
  color: #A7F3D0;
}

.status-danger {
  background: #FEE2E2;
  color: #DC2626;
}

.dark-theme .status-danger {
  background: #7F1D1D;
  color: #FCA5A5;
}

/* ==========================================================================
   FOOTER
   ========================================================================== */
.dashboard-footer {
  margin-top: auto;
  border-top: 1px solid #E2E8F0;
  background: #FFFFFF;
  padding: 16px 28px;
  font-size: 0.76rem;
  color: #64748B;
}

.dark-theme .dashboard-footer {
  background: #0A1628;
  border-top-color: #1B3762;
  color: #94A3B8;
}

.footer-content {
  max-width: 1440px;
  margin: 0 auto;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
}

.footer-system-tag {
  font-weight: 600;
}

/* ==========================================================================
   FORMATO DE IMPRESIÓN OFICIAL PDF (@media print)
   ========================================================================== */
@media print {
  .no-print,
  .btn-icon-reload,
  .link-view-all {
    display: none !important;
  }

  body,
  .dashboard-wrapper {
    background: #FFFFFF !important;
    color: #000000 !important;
  }

  .dashboard-card,
  .kpi-card {
    border: 1px solid #000000 !important;
    box-shadow: none !important;
    break-inside: avoid;
  }

  .kpi-value,
  .card-main-title {
    color: #000000 !important;
  }
}
</style>
