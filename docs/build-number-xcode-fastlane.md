# Build autogenerado (CFBundleVersion) — Xcode y Fastlane

Esta guía documenta el enfoque usado en **PagosApp** para que el **build** (`CFBundleVersion`) tenga el formato por fecha/hora **`YYYYMM.DD.HHmm`** (ej. `202604.26.1530` = 26 abr 2026, 15:30) tanto con **Product → Archive** en Xcode como con **Fastlane + gym**.

## Por qué no usamos `agvtool` en el Run Script (Xcode)

- **`xcrun agvtool new-version`** reescribe el `project.pbxproj` *durante* el build. En **Xcode 15+** eso a menudo hace que el Archive **se cancele** o falle al detectar el proyecto en disco “mutando” a mitad de la compilación.
- Alternativas basadas en **escribir un `.xcconfig` en Derived** o **`#include?` dinámico** se fusionan, en la práctica, **demasiado pronto** y el app seguía mostrando el **valor fijo** (p. ej. 20) en el binario o en *General*.

**Solución en este repo:** al **final** de las fases del target, un **Run Script** escribe solo el **`Info.plist` dentro del `.app`** con **`PlistBuddy`**, ajustando `CFBundleVersion`. Así el **.pbx** no se toca durante el build; el producto queda con el build estampado.

## Resumen: dos vías, mismo formato

| Origen | Cómo se fija el build |
|--------|------------------------|
| **Solo Xcode** (Archive/Release) | Fase de script al final: `PlistBuddy` en `.../TúApp.app/Info.plist` |
| **Fastlane** (antes de `gym`) | `stamp_build_timestamp` pone `CURRENT_PROJECT_VERSION` en el target de la app (p. ej. vía `xcodeproj`); `gym` pasa `SKIP_XCODE_STAMP=1` y la fase de Xcode **no** vuelve a parchar el plist (evita doble criterio) |

Formato: **`%Y%m.%d.%H%M` → `YYYYMM.DD.HHmm`**.

---

## 1) Requisitos en el proyecto de Xcode (desde cero o migración)

### 1.1 Versionado Apple

- En el **target** de la app: `VERSIONING_SYSTEM` = `apple-generic`.
- Tener **`MARKETING_VERSION`** (versión al usuario) y, para el *fallback* del nº de build, un **`CURRENT_PROJECT_VERSION`** (p. ej. `20`) vía `xcconfig` o build settings, hasta que se estampe o se parchee el plist.

### 1.2 `Info.plist` generado

- Con **`GENERATE_INFOPLIST_FILE` = YES**, `CFBundleVersion` sale de los *build settings*; el **Run Script** final **sobrescribe** el valor en el plist del bundle, que es el que empaqueta el **IPA/Archive**.

### 1.3 Base de `xcconfig` (PagosApp)

- `pagosApp/Config/SharedApp.xcconfig` incluye `Secrets` y un `CURRENT_PROJECT_VERSION` por defecto; la pestaña *General* puede mostrar **20**; el **.ipa/Archive** usa el valor puesto al final en el `Info.plist` del `.app` (ver comentario en el propio `SharedApp.xcconfig`).
- **Target → Base de configuración** = `Config/SharedApp.xcconfig` (o tu wrapper equivalente con credenciales).

### 1.4 Sandbox de scripts (importante)

- El script debe poder ejecutarse sin la restricción de **User Script Sandboxing** que impida leer/escribir en el `.app` y en `DERIVED`. En PagosApp, en el **target** de la app (Debug/Release) está: **`ENABLE_USER_SCRIPT_SANDBOXING = NO`**.

### 1.5 Orden de fases

El Run Script **debe ir al final** del target, **después** de *Resources* (y de cualquier otra fase que deje creado el `.app` con `Info.plist`):

- Orden típico: *Sources* → *Frameworks* → *Resources* → **Set CFBundleVersion in .app (Release)**.

### 1.6 Fase: Run Script

- **Nombre** (sugerido): `Set CFBundleVersion in .app (Release)`.
- **Shell:** `/bin/sh`.
- Lógica (resumida, igual al proyecto actual):
  1. Salir si `CONFIGURATION` ≠ `Release` (o si no aplica tu política de estampar).
  2. Salir si `SKIP_XCODE_STAMP` está definido (lo pone **Fastlane** alrededor de `gym`).
  3. Salir si `SKIP_AUTO_INCREMENT_BUILD=1` (depurar sin estampar).
  4. `STAMP=$(date +%Y%m).$(date +%d).$(date +%H%M)`.
  5. Localizar el `Info.plist` del producto, p. ej.:
     - `CODESIGNING_FOLDER_PATH/Info.plist` **si** existe, o
     - primer `*.app` en `BUILT_PRODUCTS_DIR` + `/Info.plist`.
  6. `PlistBuddy` **Set** `CFBundleVersion` o **Add** si no existe.
  7. Escribir un fichero de salida bajo `DERIVED` para análisis de dependencias (ver siguiente apartado).

### 1.7 Lista de salida del script (`outputFileListPaths`)

- Archivo de texto en el repo, p. ej. `scripts/StampBuildPhase-output.xcfilelist`, con **una** línea:

```text
$(DERIVED_FILE_DIR)/cfbundleversion.stamp
```

- El **Run Script** debe hacer `echo "$STAMP" > "$DERIVED_FILE_DIR/cfbundleversion.stamp"` para que el analizador de dependencias tenga un **output** declarado (reduce avisos de “script sin outputs”).

- En el **.pbxproj**: `outputFileListPaths = ( "$(SRCROOT)/scripts/StampBuildPhase-output.xcfilelist", );`

### 1.8 Archivo opcional: `scripts/stamp-xcode-build.sh`

- En PagosApp es informativo (no se invoca como fase; el script está **inline** en el proyecto). Sirve de referencia; la estampa real la hace el bloque de shell embebido o **Fastlane**.

### 1.9 Variables de entorno (resumen)

| Variable | Efecto |
|----------|--------|
| `SKIP_XCODE_STAMP=1` | La fase de Xcode **no** parcha el plist; usar alrededor de `gym` si Fastlane ya fijó el build en el pbx. |
| `SKIP_AUTO_INCREMENT_BUILD=1` | **No** estampar (Xcode: sale al inicio del script; Fastlane: `stamp_build_timestamp` se salta). |

### 1.10 Comprobación

- **Product → Clean Build Folder** → **Archive** (Release) → en el **Organizer**, el build debe mostrar el stamp `YYYYMM.DD.HHmm` del **momento** del archive (o máximo 1 min de diferencia).

---

## 2) Requisitos en Fastlane (PagosApp)

### 2.1 Lane de estampado

- `stamp_build_timestamp` (privada) hace:
  - `Time.now.strftime("%Y%m.%d.%H%M")` (mismo patrón que arriba)
  - Escribe **`CURRENT_PROJECT_VERSION`** en el **target de la app** (p. ej. `pagosApp`) con la gema **`xcodeproj`**, y guarda el `.pbxproj`.
- **No** se usa `increment_build_number` de Fastlane: por debajo invoca **`agvtool`**, que puede reescribir versiones de forma distinta (p. ej. otro formato en el IPA) y, si el build del target vive en **xcconfig** sin override en el pbx, el **número impreso** al final (`agvtool` / `get_build_number`) no coincidía con el **CFBundleVersion** de la app en TestFlight.

### 2.2 Envolver `gym` con `SKIP_XCODE_STAMP`

- Antes de `gym` y en un `begin/ensure` (o `ensure` equivalente):

  ```ruby
  ENV["SKIP_XCODE_STAMP"] = "1"
  begin
    gym(**gym_args)
  ensure
    ENV.delete("SKIP_XCODE_STAMP")
  end
  ```

- Aplica en las **lanes** que primero llaman a `stamp_build_timestamp` y luego a `gym` (en este repo: p. ej. `gym_app_store_ipa` e `ipa_pruebas`).

**Razón:** si no, `gym` ejecutaría el Run Script de Xcode, que **volvería a escribir** el `Info.plist` con **otro** `date` (segundos o minutos distintos) o duplicaría criterio con lo ya puesto en el proyecto.

### 2.3 Lanes que solo usan el stamp de Fastlane

- Cualquier flujo que haga: `stamp_build_timestamp` → `gym` con `SKIP_XCODE_STAMP` deja un único criterio de build en el **build de CI/local vía Fastlane** (número en `pbx` + compila; el plist de la app refleja lo que derive el merge de ajustes de Xcode, y la fase de parcheo **se omite**).

### 2.4 Depurar sin tocar el build

- `SKIP_AUTO_INCREMENT_BUILD=1` (entorno) evita el incremento en `stamp_build_timestamp` y, en Xcode, la fase de `Plist` también hace *early exit*.

### 2.5 Locale (UTF-8) al abrir el proyecto con `xcodeproj`

- Si al ejecutar Fastlane falla con `invalid byte sequence in US-ASCII` al abrir el `.pbxproj`, fija `LANG` / `LC_ALL` a `en_US.UTF-8` (o el equivalente UTF-8) en el entorno, como recomienda la documentación de Fastlane. En el `Fastfile` de este repo se fuerza `Encoding.default_*` a UTF-8 para reducir el fallo en CI o terminales sin locale.

---

## 3) Añadir esto a un **proyecto iOS vacío** (checklist mínima)

1. Asegurar `VERSIONING_SYSTEM` = `apple-generic` y build settings coherentes.
2. Crear `scripts/StampBuildPhase-output.xcfilelist` con `$(DERIVED_FILE_DIR)/cfbundleversion.stamp` (o el nombre de fichero que el script vaya a generar; que coincida 1:1 con la línea del **.xcfilelist**).
3. Añadir fase **Run Script** al **final** del target con el contenido lógico descrito (Plist + stamp + `echo` a `DERIVED`).
4. Añadir `outputFileListPaths` apuntando a ese **.xcfilelist**.
5. Poner `ENABLE_USER_SCRIPT_SANDBOXING` = `NO` en el target (app) si el sandbox impide tocar el `.app` o `DERIVED` en build.
6. (Opcional) `xcconfig` con fallback `CURRENT_PROJECT_VERSION` para *General* / debug.
7. **Fastlane:** `stamp` poniendo `CURRENT_PROJECT_VERSION` en el **target** de la app (p. ej. vía `xcodeproj` como en este repo) y `gym` con `SKIP_XCODE_STAMP=1`.
8. Probar: **Xcode** solo → Archive; **Fastlane** → `ipa_app_store` o `release_app_store_connect`.

---

## 4) Referencia en este repositorio

| Elemento | Ruta / archivo |
|----------|----------------|
| Fase (inline en pbx) | `pagosApp.xcodeproj/project.pbxproj` — fase *Set CFBundleVersion in .app (Release)* |
| Salidas declaradas | `scripts/StampBuildPhase-output.xcfilelist` |
| `xcconfig` base app | `pagosApp/Config/SharedApp.xcconfig` |
| Lanes y env | `fastlane/Fastfile` — `stamp_build_timestamp`, `gym` + `SKIP_XCODE_STAMP` |
| Guía Fastlane general | `fastlane/SETUP.md` (sección de uso) |

## 5) Notas

- **General en Xcode** puede mostrar un número fijo; lo definitivo en el entregable es el **CFBundleVersion** en el `Info` del producto.
- Cada **Archive** pone un **nuevo** minuto/hora; no es un número monotónico 1, 2, 3, salvo que cambies a otro criterio.
- Si duplicas el enfoque en **otro** bundle ID, adapta nombres de `PRODUCT_NAME` / ruta al `.app` en el script (el fallback con `ls …/*.app` asume un solo app en el directorio de producto del target).
