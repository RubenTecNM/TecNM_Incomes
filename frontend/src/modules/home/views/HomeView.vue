<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { UiToggle } from '../../../shared/components'
import { useTheme } from '../../../shared/composables/useTheme'
import { logout, me } from '../../auth/api/authApi'
import { clearSessionMarker } from '../../../shared/utils/sessionCookie'
import ModalCuentas from '../../catalogos/components/ModalCuentas.vue'
import ModalEmpleados from '../../catalogos/components/ModalEmpleados.vue'
import ModalImprimeVerano from '../../caja/components/ModalImprimeVerano.vue'
import ModalPolizaIngresos from '../../caja/components/ModalPolizaIngresos.vue'
import ModalReporteIngresos from '../../caja/components/ModalReporteIngresos.vue'
import ModalPolizaIngresoPeriodo from '../../caja/components/ModalPolizaIngresoPeriodo.vue'
import ModalReporteIngresosPeriodo from '../../caja/components/ModalReporteIngresosPeriodo.vue'
import ModalReporteVarios from '../../caja/components/ModalReporteVarios.vue'
import ModalReporteDeudores from '../../caja/components/ModalReporteDeudores.vue'
import ModalReporteDeudoresFechaCorte from '../../caja/components/ModalReporteDeudoresFechaCorte.vue'
import ModalReporteDeudoresFechaCuenta from '../../caja/components/ModalReporteDeudoresFechaCuenta.vue'
import ModalReporteDeudoresInscritos from '../../caja/components/ModalReporteDeudoresInscritos.vue'
import ModalDepositoBancario from '../../caja/components/ModalDepositoBancario.vue'
import ModalDepositoBancarioPropedeutico from '../../caja/components/ModalDepositoBancarioPropedeutico.vue'
import ModalReciboProvisional from '../../caja/components/ModalReciboProvisional.vue'
import ModalReciboProvisionalCancelar from '../../caja/components/ModalReciboProvisionalCancelar.vue'

const router = useRouter()
const { dark } = useTheme()

// ==========================================
// Sesión y usuario actual
// ==========================================
const usuarioActual = ref('')
const isCerrandoSesion = ref(false)

onMounted(async () => {
  try {
    const user = await me()
    if (user?.name) {
      usuarioActual.value = user.name
    } else if (user?.username) {
      usuarioActual.value = user.username
    }
  } catch {
    // offline / sin sesión
  }
})

async function endSession(): Promise<void> {
  isCerrandoSesion.value = true
  try {
    await logout()
  } catch {
    // Si el API falla igual limpiamos sesión local
  } finally {
    clearSessionMarker()
    await router.replace({ name: 'login' })
    isCerrandoSesion.value = false
  }
}

// ==========================================
// Control de Menú
// ==========================================
const menuAbierto = ref<'catalogo' | 'imprimir' | 'control' | 'utilerias' | null>(null)
const mostrarModalCuentas = ref(false)
const mostrarModalEmpleados = ref(false)
const mostrarModalImprimeVerano = ref(false)
const mostrarModalPolizaIngresos = ref(false)
const mostrarModalReporteIngresos = ref(false)
const mostrarModalPolizaIngresoPeriodo = ref(false)
const mostrarModalReporteIngresosPeriodo = ref(false)
const mostrarModalReporteVarios = ref(false)
const mostrarModalReporteDeudores = ref(false)
const mostrarModalReporteDeudoresFechaCorte = ref(false)
const mostrarModalReporteDeudoresFechaCuenta = ref(false)
const mostrarModalReporteDeudoresInscritos = ref(false)
const mostrarModalDepositoBancario = ref(false)
const mostrarModalDepositoBancarioPropedeutico = ref(false)
const mostrarModalReciboProvisional = ref(false)
const mostrarModalReciboProvisionalCancelar = ref(false)

function toggleMenu(menu: 'catalogo' | 'imprimir' | 'control' | 'utilerias'): void {
  menuAbierto.value = menuAbierto.value === menu ? null : menu
}

function cerrarMenus(): void {
  menuAbierto.value = null
}

function abrirModalCuentas(): void {
  mostrarModalCuentas.value = true
  cerrarMenus()
}

function abrirModalEmpleados(): void {
  mostrarModalEmpleados.value = true
  cerrarMenus()
}

function abrirModalImprimeVerano(): void {
  mostrarModalImprimeVerano.value = true
  cerrarMenus()
}

function abrirModalPolizaIngresos(): void {
  mostrarModalPolizaIngresos.value = true
  cerrarMenus()
}

function abrirModalReporteIngresos(): void {
  mostrarModalReporteIngresos.value = true
  cerrarMenus()
}

function abrirModalPolizaIngresoPeriodo(): void {
  mostrarModalPolizaIngresoPeriodo.value = true
  cerrarMenus()
}

function abrirModalReporteIngresosPeriodo(): void {
  mostrarModalReporteIngresosPeriodo.value = true
  cerrarMenus()
}

function abrirModalReporteVarios(): void {
  mostrarModalReporteVarios.value = true
  cerrarMenus()
}

function abrirModalReporteDeudores(): void {
  mostrarModalReporteDeudores.value = true
  cerrarMenus()
}

function abrirModalReporteDeudoresFechaCorte(): void {
  mostrarModalReporteDeudoresFechaCorte.value = true
  cerrarMenus()
}

function abrirModalReporteDeudoresFechaCuenta(): void {
  mostrarModalReporteDeudoresFechaCuenta.value = true
  cerrarMenus()
}

function abrirModalReporteDeudoresInscritos(): void {
  mostrarModalReporteDeudoresInscritos.value = true
  cerrarMenus()
}

function abrirModalDepositoBancario(): void {
  mostrarModalDepositoBancario.value = true
  cerrarMenus()
}

function abrirModalDepositoBancarioPropedeutico(): void {
  mostrarModalDepositoBancarioPropedeutico.value = true
  cerrarMenus()
}

function abrirModalReciboProvisional(): void {
  mostrarModalReciboProvisional.value = true
  cerrarMenus()
}

function abrirModalReciboProvisionalCancelar(): void {
  mostrarModalReciboProvisionalCancelar.value = true
  cerrarMenus()
}

function irARecibo(): void {
  cerrarMenus()
  void router.push({ name: 'caja-recibo' })
}

// ==========================================
// Hora actual en tiempo real
// ==========================================
const horaActual = ref('')
function actualizarHora(): void {
  horaActual.value = new Date().toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
}
actualizarHora()
setInterval(actualizarHora, 1000)
</script>

<template>
  <div class="home-wrapper" :class="{ 'dark-theme': dark }" @click="cerrarMenus">
    <!-- BARRA DE MENÚ (igual que CajaPrincipalView) -->
    <nav class="tecnm-classic-menubar" aria-label="Menú principal del sistema" @click.stop>
      <div class="menubar-left-group">
        <span class="menubar-title-tag">Menú</span>
        <div class="menubar-items-group">
          <!-- 1. Archivo -->
          <div class="menubar-item">
            <button type="button" class="menubar-btn">Archivo</button>
          </div>

          <!-- 2. Catálogo -->
          <div class="menubar-item dropdown-parent" :class="{ open: menuAbierto === 'catalogo' }">
            <button
              type="button"
              class="menubar-btn btn-dropdown"
              :aria-expanded="menuAbierto === 'catalogo'"
              @click.stop="toggleMenu('catalogo')"
            >
              Catálogo <span class="arrow-indicator">▾</span>
            </button>
            <div v-if="menuAbierto === 'catalogo'" class="menubar-dropdown-panel" role="menu">
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalEmpleados">
                <svg class="entry-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                  <circle cx="9" cy="7" r="4" />
                </svg>
                <span>Empleados</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalCuentas">
                <svg class="entry-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect x="3" y="4" width="18" height="16" rx="2" />
                  <line x1="3" y1="10" x2="21" y2="10" />
                </svg>
                <span>Cuentas</span>
              </button>
            </div>
          </div>

          <!-- 3. Imprimir -->
          <div class="menubar-item dropdown-parent" :class="{ open: menuAbierto === 'imprimir' }">
            <button
              type="button"
              class="menubar-btn btn-dropdown"
              :aria-expanded="menuAbierto === 'imprimir'"
              @click.stop="toggleMenu('imprimir')"
            >
              Imprimir <span class="arrow-indicator">▾</span>
            </button>
            <div v-if="menuAbierto === 'imprimir'" class="menubar-dropdown-panel menubar-dropdown-scroll" role="menu">
              <button type="button" class="dropdown-entry" role="menuitem" @click="irARecibo">
                <span>Recibo</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalPolizaIngresos">
                <span>Poliza de Ingresos</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReporteIngresos">
                <span>Reporte de Ingresos</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalPolizaIngresoPeriodo">
                <span>Poliza de Ingreso Periodo</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReporteIngresosPeriodo">
                <span>Reporte de Ingresos por Periodo</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReporteVarios">
                <span>Reporte Varios</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReporteDeudores">
                <span>Reporte Deudores</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReporteDeudoresFechaCorte">
                <span>Reporte Deudores Fecha de Corte</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReporteDeudoresFechaCuenta">
                <span>Reporte Deudores Fecha y Cuenta</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReporteDeudoresInscritos">
                <span>Reporte Deudores Inscritos</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalDepositoBancario">
                <span>Deposito Bancario</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReciboProvisional">
                <span>Recibo Provisional</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalReciboProvisionalCancelar">
                <span>Recibo Provisional Cancelar</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalDepositoBancarioPropedeutico">
                <span>Deposito Bancario - Curso Propedeutico</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="abrirModalImprimeVerano">
                <span>Imprime Verano</span>
              </button>
            </div>
          </div>

          <!-- 4. Control -->
          <div class="menubar-item dropdown-parent" :class="{ open: menuAbierto === 'control' }">
            <button
              type="button"
              class="menubar-btn btn-dropdown"
              :aria-expanded="menuAbierto === 'control'"
              @click.stop="toggleMenu('control')"
            >
              Control <span class="arrow-indicator">▾</span>
            </button>
            <div v-if="menuAbierto === 'control'" class="menubar-dropdown-panel" role="menu">
              <button type="button" class="dropdown-entry" role="menuitem" @click="cerrarMenus">
                <span>Consulta y Cancelación de Recibos</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="cerrarMenus">
                <span>Corte por Empleado</span>
              </button>
            </div>
          </div>

          <!-- 5. Utilerías -->
          <div class="menubar-item dropdown-parent" :class="{ open: menuAbierto === 'utilerias' }">
            <button
              type="button"
              class="menubar-btn btn-dropdown"
              :aria-expanded="menuAbierto === 'utilerias'"
              @click.stop="toggleMenu('utilerias')"
            >
              Utilerías <span class="arrow-indicator">▾</span>
            </button>
            <div v-if="menuAbierto === 'utilerias'" class="menubar-dropdown-panel" role="menu">
              <button type="button" class="dropdown-entry" role="menuitem" @click="cerrarMenus">
                <span>Cambio de Contraseña</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="cerrarMenus">
                <span>Cierre de Semestre</span>
              </button>
              <button type="button" class="dropdown-entry" role="menuitem" @click="cerrarMenus">
                <span>Crear Usuario</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Toggle Modo Oscuro/Claro -->
      <div class="menubar-theme-toggle">
        <UiToggle
          v-model="dark"
          type="switch"
          :label="dark ? 'Modo oscuro' : 'Modo claro'"
          class="theme-switch"
        />
      </div>
    </nav>

    <!-- CONTENIDO PRINCIPAL: Bienvenida -->
    <main class="home-main" @click.stop>
      <!-- Hero de bienvenida -->
      <div class="welcome-hero">
        <!-- Escudo / logotipo TecNM -->
        <div class="hero-logo-wrap">
          <svg class="hero-logo-svg" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg">
            <rect width="80" height="80" rx="40" fill="#C5A059" />
            <text x="40" y="52" text-anchor="middle" font-family="'Inter', sans-serif" font-size="26" font-weight="800" fill="#1B396A">TM</text>
          </svg>
        </div>

        <div class="hero-text">
          <p class="hero-subtitle">Instituto Tecnológico Nacional de México</p>
          <h1 class="hero-title">Sistema de Control de Caja</h1>
          <p class="hero-campus">Campus Monclova — CashierPoint v2.0</p>
        </div>
      </div>

      <!-- Tarjeta de sesión activa -->
      <div class="session-card">
        <div class="session-info">
          <div class="session-avatar">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
              <circle cx="12" cy="7" r="4" />
            </svg>
          </div>
          <div class="session-details">
            <span class="session-label">Sesión activa</span>
            <strong class="session-name">{{ usuarioActual || 'Cargando…' }}</strong>
          </div>
        </div>
        <div class="session-clock">
          <span class="clock-time">{{ horaActual }}</span>
          <span class="clock-date">{{ new Date().toLocaleDateString('es-MX', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }) }}</span>
        </div>
        <button
          type="button"
          class="btn-cerrar-sesion-home"
          :disabled="isCerrandoSesion"
          @click="endSession"
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="logout-icon-sm">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
            <polyline points="16 17 21 12 16 7" />
            <line x1="21" y1="12" x2="9" y2="12" />
          </svg>
          {{ isCerrandoSesion ? 'Cerrando…' : 'Cerrar sesión' }}
        </button>
      </div>

      <!-- Accesos Rápidos -->
      <section class="quick-access-section">
        <h2 class="section-heading">Accesos Rápidos</h2>
        <div class="quick-access-grid">
          <!-- Recibo / Emisión de cobro -->
          <button class="quick-card primary-card" type="button" @click="irARecibo">
            <div class="quick-card-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                <polyline points="14 2 14 8 20 8" />
                <line x1="16" y1="13" x2="8" y2="13" />
                <line x1="16" y1="17" x2="8" y2="17" />
                <polyline points="10 9 9 9 8 9" />
              </svg>
            </div>
            <div class="quick-card-text">
              <span class="quick-card-title">Emisión de Recibo</span>
              <span class="quick-card-desc">Registrar cobros y emitir recibos a estudiantes</span>
            </div>
            <svg class="quick-card-arrow" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="5" y1="12" x2="19" y2="12" />
              <polyline points="12 5 19 12 12 19" />
            </svg>
          </button>

          <!-- Catálogo de Empleados -->
          <button class="quick-card" type="button" @click="abrirModalEmpleados">
            <div class="quick-card-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                <circle cx="9" cy="7" r="4" />
                <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                <path d="M16 3.13a4 4 0 0 1 0 7.75" />
              </svg>
            </div>
            <div class="quick-card-text">
              <span class="quick-card-title">Catálogo de Empleados</span>
              <span class="quick-card-desc">Alta, cambios y consulta de empleados del sistema</span>
            </div>
            <svg class="quick-card-arrow" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="5" y1="12" x2="19" y2="12" />
              <polyline points="12 5 19 12 12 19" />
            </svg>
          </button>

          <!-- Catálogo de Cuentas -->
          <button class="quick-card" type="button" @click="abrirModalCuentas">
            <div class="quick-card-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="4" width="18" height="16" rx="2" />
                <line x1="3" y1="10" x2="21" y2="10" />
                <line x1="8" y1="15" x2="10" y2="15" />
                <line x1="14" y1="15" x2="16" y2="15" />
              </svg>
            </div>
            <div class="quick-card-text">
              <span class="quick-card-title">Catálogo de Cuentas</span>
              <span class="quick-card-desc">Administración de cuentas y conceptos de cobro</span>
            </div>
            <svg class="quick-card-arrow" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="5" y1="12" x2="19" y2="12" />
              <polyline points="12 5 19 12 12 19" />
            </svg>
          </button>

          <!-- Imprime Verano -->
          <button class="quick-card" type="button" @click="abrirModalImprimeVerano">
            <div class="quick-card-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="6 9 6 2 18 2 18 9" />
                <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2" />
                <rect x="6" y="14" width="12" height="8" />
              </svg>
            </div>
            <div class="quick-card-text">
              <span class="quick-card-title">Imprime Verano</span>
              <span class="quick-card-desc">Generar reporte de pagos de cursos de verano</span>
            </div>
            <svg class="quick-card-arrow" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="5" y1="12" x2="19" y2="12" />
              <polyline points="12 5 19 12 12 19" />
            </svg>
          </button>

          <!-- Corte por Empleado -->
          <button class="quick-card" type="button" @click="cerrarMenus">
            <div class="quick-card-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="18" y1="20" x2="18" y2="10" />
                <line x1="12" y1="20" x2="12" y2="4" />
                <line x1="6" y1="20" x2="6" y2="14" />
              </svg>
            </div>
            <div class="quick-card-text">
              <span class="quick-card-title">Corte por Empleado</span>
              <span class="quick-card-desc">Resumen de movimientos del turno por cajero</span>
            </div>
            <svg class="quick-card-arrow" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="5" y1="12" x2="19" y2="12" />
              <polyline points="12 5 19 12 12 19" />
            </svg>
          </button>

          <!-- Cambio de Contraseña -->
          <button class="quick-card" type="button" @click="cerrarMenus">
            <div class="quick-card-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                <path d="M7 11V7a5 5 0 0 1 10 0v4" />
              </svg>
            </div>
            <div class="quick-card-text">
              <span class="quick-card-title">Cambio de Contraseña</span>
              <span class="quick-card-desc">Actualizar credenciales de acceso al sistema</span>
            </div>
            <svg class="quick-card-arrow" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="5" y1="12" x2="19" y2="12" />
              <polyline points="12 5 19 12 12 19" />
            </svg>
          </button>
        </div>
      </section>

      <!-- Footer institucional -->
      <footer class="home-footer">
        <span>TecNM Campus Monclova &nbsp;·&nbsp; Sistema de Control de Caja Universitaria &nbsp;·&nbsp; v2.0</span>
      </footer>
    </main>

    <!-- Modales -->
    <ModalCuentas v-if="mostrarModalCuentas" @close="mostrarModalCuentas = false" />
    <ModalEmpleados v-if="mostrarModalEmpleados" @close="mostrarModalEmpleados = false" />
    <ModalImprimeVerano v-if="mostrarModalImprimeVerano" @close="mostrarModalImprimeVerano = false" />
    <ModalPolizaIngresos v-if="mostrarModalPolizaIngresos" @close="mostrarModalPolizaIngresos = false" />
    <ModalReporteIngresos v-if="mostrarModalReporteIngresos" @close="mostrarModalReporteIngresos = false" />
    <ModalPolizaIngresoPeriodo v-if="mostrarModalPolizaIngresoPeriodo" @close="mostrarModalPolizaIngresoPeriodo = false" />
    <ModalReporteIngresosPeriodo v-if="mostrarModalReporteIngresosPeriodo" @close="mostrarModalReporteIngresosPeriodo = false" />
    <ModalReporteVarios v-if="mostrarModalReporteVarios" @close="mostrarModalReporteVarios = false" />
    <ModalReporteDeudores v-if="mostrarModalReporteDeudores" @close="mostrarModalReporteDeudores = false" />
    <ModalReporteDeudoresFechaCorte v-if="mostrarModalReporteDeudoresFechaCorte" @close="mostrarModalReporteDeudoresFechaCorte = false" />
    <ModalReporteDeudoresFechaCuenta v-if="mostrarModalReporteDeudoresFechaCuenta" @close="mostrarModalReporteDeudoresFechaCuenta = false" />
    <ModalReporteDeudoresInscritos v-if="mostrarModalReporteDeudoresInscritos" @close="mostrarModalReporteDeudoresInscritos = false" />
    <ModalDepositoBancario v-if="mostrarModalDepositoBancario" @close="mostrarModalDepositoBancario = false" />
    <ModalDepositoBancarioPropedeutico v-if="mostrarModalDepositoBancarioPropedeutico" @close="mostrarModalDepositoBancarioPropedeutico = false" />
    <ModalReciboProvisional v-if="mostrarModalReciboProvisional" @close="mostrarModalReciboProvisional = false" />
    <ModalReciboProvisionalCancelar v-if="mostrarModalReciboProvisionalCancelar" @close="mostrarModalReciboProvisionalCancelar = false" />
  </div>
</template>

<style scoped>
/* =====================================================
   VARIABLES TecNM Identity Manual
   ===================================================== */
:root {
  --tecnm-marino: #1B396A;
  --tecnm-dorado: #C5A059;
  --tecnm-cobalto: #244B88;
}

/* =====================================================
   WRAPPER GLOBAL
   ===================================================== */
.home-wrapper {
  min-height: 100vh;
  background: #f4f6fa;
  display: flex;
  flex-direction: column;
  font-family: 'Inter', system-ui, sans-serif;
  transition: background 0.25s, color 0.25s;
}

.home-wrapper.dark-theme {
  background: #0f172a;
  color: #e2e8f0;
}

/* =====================================================
   BARRA DE MENÚ — idéntica a CajaPrincipalView
   ===================================================== */
.tecnm-classic-menubar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #1B396A;
  padding: 0 16px;
  height: 42px;
  border-bottom: 2px solid #C5A059;
  position: relative;
  z-index: 100;
}

.menubar-left-group {
  display: flex;
  align-items: center;
  gap: 0;
}

.menubar-title-tag {
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.08em;
  color: #C5A059;
  border-right: 1px solid rgba(197, 160, 89, 0.4);
  padding: 0 14px 0 4px;
  margin-right: 6px;
  text-transform: uppercase;
}

.menubar-items-group {
  display: flex;
  align-items: center;
  gap: 2px;
}

.menubar-item {
  position: relative;
}

.menubar-btn {
  background: transparent;
  border: none;
  color: #fff;
  font-size: 13px;
  font-weight: 500;
  padding: 0 14px;
  height: 42px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
  border-radius: 0;
  transition: background 0.15s;
}

.menubar-btn:hover,
.dropdown-parent.open > .menubar-btn {
  background: rgba(197, 160, 89, 0.18);
  color: #C5A059;
}

.arrow-indicator {
  font-size: 11px;
  opacity: 0.75;
}

.menubar-dropdown-panel {
  position: absolute;
  top: 42px;
  left: 0;
  min-width: 230px;
  background: #fff;
  border: 1px solid #dde1ea;
  border-top: 2px solid #C5A059;
  border-radius: 0 0 6px 6px;
  box-shadow: 0 8px 24px rgba(27, 57, 106, 0.15);
  z-index: 200;
  padding: 4px 0;
}

.dark-theme .menubar-dropdown-panel {
  background: #1e293b;
  border-color: #334155;
  border-top-color: #C5A059;
}

.menubar-dropdown-scroll {
  max-height: 340px;
  overflow-y: auto;
}

.dropdown-entry {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  background: none;
  border: none;
  padding: 8px 16px;
  font-size: 13px;
  color: #1B396A;
  cursor: pointer;
  text-align: left;
  transition: background 0.12s;
}

.dark-theme .dropdown-entry {
  color: #e2e8f0;
}

.dropdown-entry:hover {
  background: #f0f4ff;
  color: #1B396A;
}

.dark-theme .dropdown-entry:hover {
  background: rgba(197, 160, 89, 0.12);
  color: #C5A059;
}

.entry-icon {
  width: 15px;
  height: 15px;
  flex-shrink: 0;
  opacity: 0.65;
}

.menubar-theme-toggle {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #fff;
  font-size: 12px;
}

/* =====================================================
   MAIN
   ===================================================== */
.home-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 48px 24px 32px;
  gap: 36px;
}

/* =====================================================
   HERO BIENVENIDA
   ===================================================== */
.welcome-hero {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  text-align: center;
  max-width: 640px;
}

.hero-logo-wrap {
  filter: drop-shadow(0 4px 16px rgba(27, 57, 106, 0.3));
}

.hero-logo-svg {
  width: 90px;
  height: 90px;
}

.hero-text {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.hero-subtitle {
  font-size: 13px;
  font-weight: 500;
  color: #64748b;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  margin: 0;
}

.dark-theme .hero-subtitle {
  color: #94a3b8;
}

.hero-title {
  font-size: clamp(24px, 4vw, 36px);
  font-weight: 800;
  color: #1B396A;
  margin: 0;
  line-height: 1.15;
}

.dark-theme .hero-title {
  color: #C5A059;
}

.hero-campus {
  font-size: 14px;
  color: #244B88;
  font-weight: 500;
  margin: 0;
}

.dark-theme .hero-campus {
  color: #93c5fd;
}

/* =====================================================
   TARJETA DE SESIÓN
   ===================================================== */
.session-card {
  display: flex;
  align-items: center;
  gap: 24px;
  background: #fff;
  border: 1px solid #dde1ea;
  border-left: 4px solid #C5A059;
  border-radius: 12px;
  padding: 18px 24px;
  width: 100%;
  max-width: 820px;
  box-shadow: 0 2px 12px rgba(27, 57, 106, 0.08);
  flex-wrap: wrap;
}

.dark-theme .session-card {
  background: #1e293b;
  border-color: #334155;
  border-left-color: #C5A059;
}

.session-info {
  display: flex;
  align-items: center;
  gap: 14px;
  flex: 1;
}

.session-avatar {
  width: 44px;
  height: 44px;
  background: linear-gradient(135deg, #1B396A, #244B88);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.session-avatar svg {
  width: 22px;
  height: 22px;
  stroke: #fff;
}

.session-details {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.session-label {
  font-size: 11px;
  font-weight: 600;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.06em;
}

.dark-theme .session-label {
  color: #94a3b8;
}

.session-name {
  font-size: 16px;
  font-weight: 700;
  color: #1B396A;
}

.dark-theme .session-name {
  color: #e2e8f0;
}

.session-clock {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
}

.clock-time {
  font-size: 22px;
  font-weight: 700;
  color: #1B396A;
  font-variant-numeric: tabular-nums;
  letter-spacing: 0.03em;
}

.dark-theme .clock-time {
  color: #C5A059;
}

.clock-date {
  font-size: 12px;
  color: #64748b;
  text-transform: capitalize;
}

.dark-theme .clock-date {
  color: #94a3b8;
}

.btn-cerrar-sesion-home {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #fff;
  border: 1.5px solid #e2e8f0;
  color: #64748b;
  font-size: 13px;
  font-weight: 600;
  padding: 8px 16px;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s;
  white-space: nowrap;
}

.btn-cerrar-sesion-home:hover {
  border-color: #ef4444;
  color: #ef4444;
  background: #fff5f5;
}

.dark-theme .btn-cerrar-sesion-home {
  background: #0f172a;
  border-color: #334155;
  color: #94a3b8;
}

.dark-theme .btn-cerrar-sesion-home:hover {
  border-color: #ef4444;
  color: #ef4444;
  background: rgba(239, 68, 68, 0.1);
}

.logout-icon-sm {
  width: 16px;
  height: 16px;
}

/* =====================================================
   ACCESOS RÁPIDOS
   ===================================================== */
.quick-access-section {
  width: 100%;
  max-width: 820px;
}

.section-heading {
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #64748b;
  margin: 0 0 16px 0;
}

.dark-theme .section-heading {
  color: #94a3b8;
}

.quick-access-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

@media (max-width: 600px) {
  .quick-access-grid {
    grid-template-columns: 1fr;
  }
}

.quick-card {
  display: flex;
  align-items: center;
  gap: 14px;
  background: #fff;
  border: 1px solid #dde1ea;
  border-radius: 12px;
  padding: 16px 18px;
  cursor: pointer;
  transition: all 0.18s;
  text-align: left;
  box-shadow: 0 1px 4px rgba(27, 57, 106, 0.06);
}

.dark-theme .quick-card {
  background: #1e293b;
  border-color: #334155;
}

.quick-card:hover {
  border-color: #244B88;
  box-shadow: 0 4px 16px rgba(27, 57, 106, 0.14);
  transform: translateY(-1px);
}

.dark-theme .quick-card:hover {
  border-color: #C5A059;
  box-shadow: 0 4px 16px rgba(197, 160, 89, 0.12);
}

.primary-card {
  border-left: 4px solid #1B396A;
  background: linear-gradient(135deg, #f8faff 0%, #fff 100%);
}

.dark-theme .primary-card {
  background: linear-gradient(135deg, #1e2d47 0%, #1e293b 100%);
  border-left-color: #C5A059;
}

.primary-card:hover {
  border-color: #1B396A;
  border-left-color: #1B396A;
}

.dark-theme .primary-card:hover {
  border-color: #C5A059;
  border-left-color: #C5A059;
}

.quick-card-icon {
  width: 42px;
  height: 42px;
  background: #f0f4ff;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.dark-theme .quick-card-icon {
  background: rgba(197, 160, 89, 0.1);
}

.quick-card-icon svg {
  width: 20px;
  height: 20px;
  stroke: #1B396A;
}

.dark-theme .quick-card-icon svg {
  stroke: #C5A059;
}

.primary-card .quick-card-icon {
  background: #1B396A;
}

.primary-card .quick-card-icon svg {
  stroke: #fff;
}

.dark-theme .primary-card .quick-card-icon {
  background: #C5A059;
}

.dark-theme .primary-card .quick-card-icon svg {
  stroke: #1B396A;
}

.quick-card-text {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.quick-card-title {
  font-size: 14px;
  font-weight: 700;
  color: #1B396A;
}

.dark-theme .quick-card-title {
  color: #e2e8f0;
}

.quick-card-desc {
  font-size: 12px;
  color: #64748b;
  line-height: 1.4;
}

.dark-theme .quick-card-desc {
  color: #94a3b8;
}

.quick-card-arrow {
  width: 16px;
  height: 16px;
  stroke: #94a3b8;
  flex-shrink: 0;
  transition: transform 0.15s;
}

.quick-card:hover .quick-card-arrow {
  stroke: #244B88;
  transform: translateX(3px);
}

.dark-theme .quick-card:hover .quick-card-arrow {
  stroke: #C5A059;
}

/* =====================================================
   FOOTER
   ===================================================== */
.home-footer {
  font-size: 11px;
  color: #94a3b8;
  text-align: center;
  padding-top: 8px;
}

.dark-theme .home-footer {
  color: #475569;
}
</style>

