# Visión del producto y funcionalidades

## 📱 Descripción del Proyecto

**PagosApp** es una aplicación iOS moderna y profesional para la gestión integral de pagos recurrentes. Diseñada con **Clean Architecture 100%**, ofrece una experiencia offline-first con sincronización en la nube, autenticación segura mediante biometría, y sincronización automática con el calendario de iOS.

### 🎯 ¿Qué hace la App?

- **Gestión de Pagos Recurrentes**: Crea, edita y organiza todos tus pagos mensuales (Netflix, tarjetas de crédito, servicios, etc.)
- **Recordatorios**: Gestiona eventos que no son pagos (renovación de tarjeta, membresías, cobros, impuestos, ahorro, etc.) con título, descripción y fecha; notificaciones con ventana estándar **3, 2, 1 y 0 días** antes del vencimiento (más opciones avanzadas según tipo)
- **Sincronización con Calendario iOS**: Pagos y recordatorios se muestran en el calendario nativo
- **Notificaciones**: **Pagos** a **3, 2 y 1 día** antes más el **día del vencimiento** (9:00 y 14:00). **Recordatorios**: misma ventana estándar u opciones avanzadas (p. ej. 7 / 14 / 30 días) según `NotificationSettings`
- **Multi-moneda**: Soporte para PEN (Soles) y USD (Dólares) con conversión automática
- **Estadísticas e Historial**: Gráficos de gastos por categoría, tendencias mensuales e historial; accesibles desde Ajustes
- **Offline-First**: Funciona sin internet; sincronización manual (pagos + recordatorios) desde Ajustes
- **Autenticación Segura**: Face ID/Touch ID + Email/Password
- **Internacionalización**: Español (por defecto), inglés y portugués

---

## ✨ Features Principales

### 🔐 Autenticación & Seguridad
- ✅ Registro e inicio de sesión con Supabase (Email/Password)
- ✅ Face ID / Touch ID para acceso rápido y seguro
- ✅ Recuperación de contraseña por email
- ✅ Almacenamiento seguro de credenciales en Keychain
- ✅ Row Level Security (RLS) en base de datos
- ✅ Sesiones persistentes con renovación automática

### 💰 Gestión de Pagos
- ✅ CRUD completo de pagos (Crear, Leer, Actualizar, Eliminar)
- ✅ Categorización flexible (Entretenimiento, Tarjetas, Servicios, etc.)
- ✅ Soporte multi-moneda (PEN/USD)
- ✅ **Pagos Agrupados**: Tarjetas de crédito bimoneda (PEN + USD) agrupadas automáticamente
- ✅ **Edición de Pagos Agrupados**: Edita ambos montos (PEN y USD) desde un solo formulario
- ✅ Estados de pago (Pendiente/Completado)
- ✅ Edición en tiempo real con validación
- ✅ Búsqueda y filtros avanzados
- ✅ Duplicación de pagos recurrentes

### 📅 Integración con Calendario iOS
- ✅ **Sincronización Automática**: Los eventos se crean/actualizan/eliminan automáticamente
- ✅ Cada pago genera un evento en el calendario nativo
- ✅ Actualización automática al modificar pagos
- ✅ Eliminación sincronizada de eventos
- ✅ **Pagos Agrupados**: Un solo evento compartido para pagos PEN + USD (evita duplicados)
- ✅ Selección de calendario destino
- ✅ Soporte para calendarios compartidos

### 🔔 Notificaciones
- ✅ **Pagos**: **3, 2 y 1 día** antes del vencimiento más el **mismo día** (9:00 y 14:00)
- ✅ **Recordatorios**: ventana estándar **3, 2, 1 y 0 días** (9:00 y 14:00); tipos de recordatorio pueden activar avisos a **7 / 14 / 30 días** adicionales
- ✅ Restauración automática al iniciar sesión; cancelación al marcar completado o eliminar
- ✅ Alertas de errores con sugerencias de recuperación

### 📊 Estadísticas y Visualización
- ✅ Dashboard con métricas en tiempo real
- ✅ Gráficos de gastos por categoría (Pie Charts)
- ✅ Tendencias mensuales (Line Charts)
- ✅ Total gastado por mes y categoría
- ✅ Proyección de gastos futuros
- ✅ Comparativas mes a mes

### 📌 Recordatorios (no son pagos)
- ✅ Tipos: renovación tarjeta, membresía, suscripción, cobro, ahorro, documentos, impuestos, otro
- ✅ Título, descripción opcional y fecha; sin monto
- ✅ Marcar como completado/cancelado (checkbox en lista)
- ✅ Sincronización con Supabase (tabla `reminders`); mismo flujo offline-first que pagos
- ✅ Un botón **Sincronizar** en Ajustes sube/baja pagos y recordatorios

### ☁️ Sincronización Cloud
- ✅ Sincronización con Supabase (pagos + recordatorios)
- ✅ Un solo botón en Ajustes sincroniza ambos
- ✅ Offline-first: todo funciona sin internet; sync manual cuando quieras
- ✅ Multi-dispositivo: mismo usuario, múltiples dispositivos

### 👤 Perfil y Ajustes
- ✅ Gestión de perfil personal y moneda preferida
- ✅ **Desde Ajustes**: Historial de pagos, Estadísticas, Sincronización, reparar base de datos, cerrar sesión
- ✅ Activación/desactivación de Face ID y desvincular dispositivo
- ✅ Cierre de sesión seguro

### 🌐 Internacionalización (i18n)
- ✅ Español por defecto (fallback)
- ✅ Inglés y portugués
- ✅ Textos de UI, notificaciones locales y mensajes de error vía `Localizable.strings` + `Localizable.stringsdict` (plurales) y capa **L10n** (`L10n.swift`)

---
