# Configuración de Secretos

## Setup Inicial

1. Copia el archivo template:
   ```bash
   cp Secrets.template.xcconfig Secrets.xcconfig
   ```

2. Edita `Secrets.xcconfig` con tus credenciales reales de Supabase

3. Agrega el archivo `Secrets.xcconfig` al proyecto en Xcode:
   - Abre Xcode
   - Click derecho en la carpeta `Config`
   - "Add Files to pagosApp..."
   - Selecciona `Secrets.xcconfig`

4. Configura el archivo en Build Settings:
   - Selecciona el proyecto pagosApp
   - Ve a la pestaña "Info"
   - En "Configurations", asigna `Secrets.xcconfig` a Debug y Release

5. Agrega las keys al Info.plist:
   - Abre `Info.plist`
   - Agrega las siguientes keys:
     - `SUPABASE_URL` (String) con valor `$(SUPABASE_URL)`
     - `SUPABASE_KEY` (String) con valor `$(SUPABASE_KEY)`

## Seguridad

⚠️ **IMPORTANTE**: El archivo `Secrets.xcconfig` está en `.gitignore` y NO debe ser commitado al repositorio.

## Obtener tus credenciales de Supabase

1. Ve a [https://app.supabase.com](https://app.supabase.com)
2. Selecciona tu proyecto
3. Ve a Settings → API
4. Copia:
   - **URL**: La URL del proyecto
   - **anon/public key**: La clave pública (anon key)

## Estructura

```
Config/
├── README.md                    # Este archivo
├── Secrets.template.xcconfig    # Template (commitado a git)
└── Secrets.xcconfig            # Tus credenciales (NO commitado)
```
