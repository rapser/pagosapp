# PagosApp

Aplicación iOS para gestionar y realizar seguimiento de pagos recurrentes con integración a Supabase.

## Características

- Gestión de pagos recurrentes
- Autenticación segura con Face ID
- Sincronización con calendario
- Notificaciones de recordatorio
- Integración con Supabase para almacenamiento en la nube

## Requisitos

- iOS 18.5+
- Xcode 16.4+
- Swift 5.0+
- Cuenta de Supabase

## Instalación

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd pagosApp
```

### 2. Instalar dependencias

El proyecto utiliza Swift Package Manager. Las dependencias se descargarán automáticamente al abrir el proyecto en Xcode.

Dependencias incluidas:
- [supabase-swift](https://github.com/supabase/supabase-swift) v2.5.1+

### 3. Configurar credenciales de Supabase

1. Copia el archivo de plantilla de configuración:
   ```bash
   cp Config/Secrets.template.xcconfig Config/Secrets.xcconfig
   ```

2. Edita `Config/Secrets.xcconfig` y reemplaza los valores con tus credenciales de Supabase:
   ```
   SUPABASE_URL = tu_url_de_supabase_aqui
   SUPABASE_KEY = tu_key_anon_de_supabase_aqui
   ```

3. **IMPORTANTE**: El archivo `Secrets.xcconfig` ya está en `.gitignore` para proteger tus credenciales.

### 4. Configurar el archivo en Build Settings

1. Abre `pagosApp.xcodeproj` en Xcode
2. Selecciona el proyecto `pagosApp` en el navegador
3. Ve a la pestaña **"Info"**
4. En la sección **"Configurations"**, asigna `Secrets.xcconfig` a:
   - Debug
   - Release

### 5. Verificar Info.plist

El archivo `Info.plist` ya contiene las configuraciones necesarias:
- `SUPABASE_URL`: Variable que tomará el valor de Secrets.xcconfig
- `SUPABASE_KEY`: Variable que tomará el valor de Secrets.xcconfig
- Permisos para Face ID, Calendar y Notificaciones

### 6. Compilar y ejecutar

1. Selecciona tu dispositivo o simulador
2. Presiona `Cmd + R` para compilar y ejecutar

## Estructura del Proyecto

```
pagosApp/
├── Config/
│   ├── Secrets.template.xcconfig    # Plantilla de configuración
│   └── Secrets.xcconfig             # Tu configuración (no versionada)
├── pagosApp/
│   ├── Info.plist                   # Configuración de la app
│   └── ...                          # Código fuente
└── pagosAppTests/                   # Tests unitarios
```

## Configuración de Supabase

Para obtener tus credenciales de Supabase:

1. Ve a [supabase.com](https://supabase.com)
2. Crea un nuevo proyecto o selecciona uno existente
3. En "Project Settings" → "API":
   - Copia la **Project URL** → `SUPABASE_URL`
   - Copia la **anon/public key** → `SUPABASE_KEY`

## Seguridad

- **NUNCA** commitees el archivo `Config/Secrets.xcconfig` al repositorio
- Usa `Secrets.template.xcconfig` como referencia para otros desarrolladores
- Las credenciales se inyectan en tiempo de compilación desde el archivo xcconfig

## Desarrollo

### Agregar nuevas variables de entorno

1. Agrega la variable en `Config/Secrets.xcconfig`:
   ```
   MI_NUEVA_KEY = valor
   ```

2. Agrégala también en `Config/Secrets.template.xcconfig`:
   ```
   MI_NUEVA_KEY = TU_VALOR_AQUI
   ```

3. Si necesitas accederla desde Swift, agrégala al `Info.plist`:
   ```xml
   <key>MI_NUEVA_KEY</key>
   <string>$(MI_NUEVA_KEY)</string>
   ```

## Licencia

[Especifica tu licencia aquí]

## Autor

[Tu nombre o equipo]
