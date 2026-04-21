# Requisitos e instalación

## 📋 Requisitos

- **iOS**: 18.5 o superior
- **Xcode**: 16.4 o superior
- **Swift**: 6.0
- **macOS**: Sequoia 15.0+ (desarrollo)
- **Cuenta Supabase**: [Crear gratis](https://supabase.com)
- **SwiftLint** (opcional, local): `brew install swiftlint` — mismo chequeo que en CI

---

## 🚀 Instalación y Configuración

### 1️⃣ Clonar Repositorio

```bash
git clone <url-del-repositorio>
cd <nombre-de-la-carpeta-del-repo>   # raíz: deben verse las carpetas pagosApp/, Config/, etc.
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

### 6️⃣ SwiftLint (opcional, antes de commitear)

```bash
swiftlint lint
```

### 7️⃣ Fastlane (IPA y subida a TestFlight)

**Guía completa (recomendada para otro proyecto o si algo falla):** [fastlane/SETUP.md](../fastlane/SETUP.md) — Ruby, API Key, variables **`APP_STORE_CONNECT_P8_PATH`** vs **`APP_STORE_CONNECT_API_KEY_PATH`**, errores típicos (`JSON::ParserError`, Ruby 4), CI y checklist.

**Resumen:** menú local `bundle exec fastlane menu`; en CI, lane explícita `bundle exec fastlane release_app_store_connect` (u otra). Lista de lanes: `bundle exec fastlane reference`. Plantilla de variables: **`fastlane/.env.example`**. [App Store Connect API — crear claves](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api).

- El **`.p8`** va en **`APP_STORE_CONNECT_P8_PATH`**. No uses **`APP_STORE_CONNECT_API_KEY_PATH`** para el `.p8` (en Fastlane/Pilot eso es ruta a **JSON**, no al PEM de Apple).
- No pegues el PEM en **`APP_STORE_CONNECT_API_KEY`** (esa variable es JSON).

```bash
gem install bundler   # si hace falta, con el Ruby de Homebrew
bundle install
bundle exec fastlane menu
bundle exec fastlane release_app_store_connect   # ejemplo sin menú (CI)
```

---
