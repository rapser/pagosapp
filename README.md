# PagosApp 🚀

> **Aplicación iOS moderna para gestión de pagos recurrentes con autenticación segura y sincronización en la nube.**

[![iOS](https://img.shields.io/badge/iOS-18.5%2B-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-16.4%2B-blue.svg)](https://developer.apple.com/xcode/)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM-green.svg)](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel)
[![Quality](https://img.shields.io/badge/Quality-100%25-brightgreen.svg)](MODERNIZATION_REPORT.md)

## ✨ Características

### 🔐 Seguridad
- ✅ Autenticación con Supabase (Email/Password)
- ✅ Face ID / Touch ID para acceso rápido
- ✅ Recuperación de contraseña
- ✅ Keychain para almacenamiento seguro

### 💰 Gestión de Pagos
- ✅ Crear, editar y eliminar pagos
- ✅ Categorización de pagos
- ✅ Soporte multi-moneda (PEN/USD)
- ✅ Historial completo de pagos
- ✅ Estadísticas y reportes

### 📅 Organización
- ✅ Sincronización con calendario iOS
- ✅ Notificaciones de recordatorio
- ✅ Vista de calendario integrada
- ✅ Pagos recurrentes

### ☁️ Cloud
- ✅ Sincronización automática con Supabase
- ✅ Backup en la nube
- ✅ Acceso desde múltiples dispositivos
- ✅ Offline-first con SwiftData

---

## 🏗 Arquitectura Moderna iOS 18.5

### Stack Tecnológico

- **iOS**: 18.5+ (Latest features)
- **Swift**: 6.0 (Strict concurrency)
- **SwiftUI**: @Observable + @State + @Environment
- **SwiftData**: Local persistence
- **Supabase**: Cloud backend
- **Async/Await**: Modern concurrency
- **Actor Isolation**: Thread-safe by design

### Patrones de Diseño

```
┌─────────────────────────────────────────┐
│         Views (@State/@Environment)      │
├─────────────────────────────────────────┤
│    ViewModels (@Observable @MainActor)  │
├─────────────────────────────────────────┤
│      Managers (Business Logic)          │
├─────────────────────────────────────────┤
│    Services (Async/Await Operations)    │
├─────────────────────────────────────────┤
│   Repositories (Protocol-Based)         │
├─────────────────────────────────────────┤
│    Storage (SwiftData + Supabase)       │
└─────────────────────────────────────────┘
```

**Principios SOLID** + **MVVM** + **Repository Pattern** + **Dependency Injection**

---

## 📋 Requisitos

- **iOS**: 18.5 o superior
- **Xcode**: 16.4 o superior  
- **Swift**: 6.0
- **macOS**: Sequoia 15.0+ (para desarrollo)
- **Cuenta Supabase**: [Crear cuenta gratis](https://supabase.com)

## 🚀 Quick Start

### 1️⃣ Clonar Repositorio

```bash
git clone <url-del-repositorio>
cd pagosApp
```

### 2️⃣ Configurar Supabase

```bash
# Copiar template de configuración
cp Config/Secrets.template.xcconfig Config/Secrets.xcconfig

# Editar con tus credenciales (usa tu editor favorito)
nano Config/Secrets.xcconfig
```

Reemplaza con tus credenciales reales:
```xcconfig
SUPABASE_URL = https://tu-proyecto.supabase.co
SUPABASE_KEY = tu_anon_key_aqui
```

> 🔒 **Seguridad**: `Secrets.xcconfig` está en `.gitignore` - Tus credenciales nunca se commitean.

### 3️⃣ Abrir en Xcode

```bash
open pagosApp.xcodeproj
```

**Xcode instalará automáticamente**:
- ✅ Supabase Swift SDK (v2.5.1+)
- ✅ Todas las dependencias necesarias

### 4️⃣ Configurar Build Settings

1. **Project Navigator** → Selecciona proyecto `pagosApp`
2. **Info Tab** → **Configurations**
3. Asigna `Secrets.xcconfig` a **Debug** y **Release**

### 5️⃣ Build & Run

```
⌘ + R
```

✅ La app está lista para usar en simulador o dispositivo físico.

---

## 📱 Setup Inicial en la App

### Primera Vez

1. **Registro**: Crea una cuenta con email/password
2. **Face ID**: Configura acceso biométrico (opcional)
3. **Permisos**: 
   - 📅 Calendario (para sincronización)
   - 🔔 Notificaciones (para recordatorios)
4. **¡Listo!**: Comienza a agregar pagos

---

## 🗄 Base de Datos

### Setup de Supabase

El proyecto incluye scripts SQL en la carpeta `Database/`:

```bash
Database/
├── supabase_schema.sql              # Schema completo
├── migration_add_currency.sql       # Migración de monedas
└── verify_currency_migration.sql    # Verificación
```

#### Ejecutar en Supabase Dashboard

1. Ve a **SQL Editor** en tu proyecto Supabase
2. Ejecuta `supabase_schema.sql` primero
3. Ejecuta las migraciones si es necesario
4. Verifica con `verify_currency_migration.sql`

#### Tablas Creadas

- **`payments`**: Información de pagos
- **Row Level Security (RLS)**: Habilitado para seguridad
- **Policies**: Solo el usuario autenticado ve sus pagos

---

## 🏗 Estructura del Proyecto

```
pagosApp/
├── App/                        # Entry point
│   └── pagosAppApp.swift
├── Views/                      # SwiftUI Views
│   ├── LoginView.swift
│   ├── PaymentsListView.swift
│   └── ...
├── ViewModels/                 # @Observable ViewModels
│   ├── PaymentsListViewModel.swift
│   └── ...
├── Managers/                   # Business Logic
│   ├── AuthenticationManager.swift
│   ├── PaymentSyncManager.swift
│   └── ...
├── Services/                   # Async Operations
│   ├── PaymentSyncService.swift
│   └── ...
├── Repositories/               # Data Layer
│   ├── PaymentRepository.swift
│   └── ...
├── Models/                     # Data Models
│   ├── Payment.swift
│   └── ...
├── Auth/                       # Authentication Module
│   ├── Services/
│   ├── Repositories/
│   └── README.md
└── Config/                     # Configuration
    └── Secrets.xcconfig

Tests/
└── pagosAppTests/              # Unit Tests
    ├── AuthenticationManagerTests.swift
    └── ...
```

---

## 🧪 Testing

### Ejecutar Tests

```bash
# Todos los tests
⌘ + U

# O desde terminal
xcodebuild test -scheme pagosApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Coverage

- ✅ Authentication Manager: 85%+
- ✅ ViewModels: 70%+
- ✅ Configuration Manager: 90%+
- ✅ Email Validator: 100%

---

## 📚 Documentación Adicional

- **[CHANGELOG.md](CHANGELOG.md)**: Historial completo de cambios
- **[MODERNIZATION_REPORT.md](MODERNIZATION_REPORT.md)**: Reporte de modernización iOS 18.5
- **[Auth/README.md](pagosApp/Auth/README.md)**: Módulo de autenticación
- **[Config/README.md](Config/README.md)**: Configuración de credenciales

---

## 🔧 Configuración Avanzada

### Obtener Credenciales Supabase

1. Ve a [supabase.com](https://supabase.com)
2. Crea proyecto o selecciona existente
3. **Project Settings** → **API**:
   - 📋 Copia **Project URL** → `SUPABASE_URL`
   - 🔑 Copia **anon/public key** → `SUPABASE_KEY`

### Variables de Entorno

**Agregar nueva variable**:

1. En `Config/Secrets.xcconfig`:
   ```xcconfig
   MI_NUEVA_KEY = valor_secreto
   ```

2. En `Config/Secrets.template.xcconfig` (para otros devs):
   ```xcconfig
   MI_NUEVA_KEY = TU_VALOR_AQUI
   ```

3. En `Info.plist` (si necesitas acceder desde Swift):
   ```xml
   <key>MI_NUEVA_KEY</key>
   <string>$(MI_NUEVA_KEY)</string>
   ```

4. Leer en Swift:
   ```swift
   let miKey = Bundle.main.infoDictionary?["MI_NUEVA_KEY"] as? String
   ```

---

## 🔒 Seguridad

### ✅ Buenas Prácticas Implementadas

- 🔐 **Keychain**: Tokens almacenados de forma segura
- 🚫 **Git**: `Secrets.xcconfig` en `.gitignore`
- 🔑 **Build-time**: Credenciales inyectadas en compilación
- 🛡 **RLS**: Row Level Security en Supabase
- 👤 **Auth**: Solo datos del usuario autenticado
- 📱 **Biometrics**: Face ID/Touch ID opcional

### ⚠️ IMPORTANTE

- ❌ **NUNCA** commitear `Config/Secrets.xcconfig`
- ❌ **NUNCA** hardcodear credenciales en código
- ✅ **SIEMPRE** usar `Secrets.template.xcconfig` como referencia
- ✅ **SIEMPRE** rotar keys si se exponen

---

## 🛠 Desarrollo

### Pre-requisitos

```bash
# Verificar versiones
swift --version        # Swift 6.0+
xcodebuild -version    # Xcode 16.4+
```

### Debug Build

```bash
# Build debug
xcodebuild -scheme pagosApp -configuration Debug

# Run tests
xcodebuild test -scheme pagosApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Release Build

```bash
# Archive for distribution
xcodebuild -scheme pagosApp -configuration Release archive \
  -archivePath ./build/pagosApp.xcarchive
```

### Code Quality

```bash
# SwiftLint (si lo usas)
swiftlint

# SwiftFormat (si lo usas)
swiftformat .
```

---

## 🤝 Contribución

### Workflow

1. **Fork** el proyecto
2. **Crea branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit** cambios (`git commit -m 'Add AmazingFeature'`)
4. **Push** a branch (`git push origin feature/AmazingFeature`)
5. **Abre Pull Request**

### Estándares de Código

- ✅ Swift 6 strict concurrency
- ✅ MVVM + SOLID principles
- ✅ @Observable para state management
- ✅ async/await (no Combine)
- ✅ Tests para nueva funcionalidad
- ✅ Documentación inline

---

## 📝 Changelog

Ver [CHANGELOG.md](CHANGELOG.md) para historial completo de cambios.

### Highlights

- **2025-01**: 🚀 Modernización completa iOS 18.5 + Swift 6
- **2024-11**: 🔐 Módulo de autenticación con patrones de diseño
- **2024-10**: 📱 Release inicial v1.0

---

## 📄 Licencia

Este proyecto es de código abierto bajo licencia MIT.

---

## 👤 Autor

**rapser**
- GitHub: [@rapser](https://github.com/rapser)
- Proyecto: pagosApp

---

## 🙏 Agradecimientos

- [Supabase](https://supabase.com) - Backend as a Service
- [Swift Community](https://swift.org) - Amazing language
- Apple Developer Team - iOS SDK

---

## 📞 Soporte

¿Problemas? ¿Preguntas?

1. 📖 Revisa la [documentación](docs/)
2. 🐛 [Abre un issue](../../issues)
3. 💬 [Discusiones](../../discussions)

---

**Made with ❤️ and Swift 6**
