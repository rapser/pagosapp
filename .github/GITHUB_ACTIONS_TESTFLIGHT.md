# GitHub Actions — TestFlight al mergear en `develop`

## Cuándo se sube a TestFlight

El workflow **[`testflight-develop.yml`](workflows/testflight-develop.yml)** se ejecuta **solo** en:

- **`push` a la rama `develop`** (lo habitual tras **fusionar un PR** hacia `develop`, p. ej. `feature/foo` → `develop`).
- **`workflow_dispatch`** (ejecución manual desde la pestaña *Actions* → *TestFlight (push a develop)* → *Run workflow*).

**No** se ejecuta en:

- Apertura o actualización de **pull requests** (el CI sigue en [`ci.yml`](workflows/ci.yml)).
- **`push` a `main`** (incluido el merge **develop → main**). No hay workflow de TestFlight ligado a `main` en este repo.

Flujo recomendado: **PR → `develop`** (revisión y checks de CI) → **merge** → **push a `develop`** → workflow de TestFlight.

---

## Secretos obligatorios (repositorio)

En GitHub: **Settings → Secrets and variables → Actions → New repository secret**.

| Secret | Descripción |
|--------|-------------|
| `APP_STORE_CONNECT_API_KEY_CONTENT_BASE64` | Contenido del fichero **AuthKey_XXX.p8** codificado en **Base64 en una sola línea** (sin saltos de línea). En tu Mac: `base64 < AuthKey_XXX.p8 \| tr -d '\n'` y pega el resultado. |
| `APP_STORE_CONNECT_API_KEY_ID` | **Key ID** de la clave API (10 caracteres, coincide con el sufijo del nombre del `.p8`). |
| `APP_STORE_CONNECT_ISSUER_ID` | **Issuer ID** (UUID) de App Store Connect → *Users and Access* → *Integrations* → *App Store Connect API*. |

Opcional:

| Secret | Descripción |
|--------|-------------|
| `FASTLANE_TEAM_ID` | Mismo **Team ID** que en `fastlane/Appfile` si hace falta forzarlo en CI. |

---

## Secretos de firma (para que `gym` archive en el runner)

En GitHub Actions el llavero está vacío: hace falta **certificado Apple Distribution** (`.p12`) y **perfil de aprovisionamiento App Store** para el bundle de la app.

| Secret | Descripción |
|--------|-------------|
| `BUILD_CERTIFICATE_BASE64` | Exporta tu certificado **Distribution** como `.p12` y codifícalo: `base64 < DistributionCert.p12 \| tr -d '\n'`. |
| `P12_PASSWORD` | Contraseña con la que exportaste el `.p12`. |
| `KEYCHAIN_PASSWORD` | Cualquier cadena fuerte (solo la usa el job para crear un llavero temporal en el runner). |
| `PROVISIONING_PROFILE_BASE64` | El fichero **`.mobileprovision`** del perfil **App Store** (descargado del portal o de Xcode), en Base64 una línea: `base64 < MyApp_AppStore.mobileprovision \| tr -d '\n'`. |

Si **falta alguno** de estos cuatro, el paso de importación se **omite** y el job intentará Fastlane igualmente; **`gym` suele fallar** por firma hasta que los configures.

Alternativa profesional: usar [**fastlane match**](https://docs.fastlane.tools/actions/match/) con un repo cifrado y secretos `MATCH_PASSWORD` / `MATCH_GIT_BASIC_AUTHORIZATION` (requiere cambiar el `Fastfile` para llamar a `match` antes de `gym`).

---

## Comprobar que funciona

1. Añade los secretos obligatorios (y los de firma).
2. Haz un cambio trivial en una rama, **PR a `develop`**, espera CI verde y **merge**.
3. En **Actions** debería aparecer el workflow **TestFlight (push a develop)** en verde.
4. En **App Store Connect → TestFlight** revisa el nuevo build (puede tardar unos minutos en procesarse).

Ejecución manual: **Actions** → **TestFlight (push a develop)** → **Run workflow** (útil para probar sin nuevo merge).

---

## Seguridad

- No subas `.p8`, `.p12` ni perfiles al repositorio.
- Rota las claves si sospechas filtrado.
- Puedes restringir quién puede mergear a `develop` con **branch protection rules** y, si quieres, un [**environment**](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) con aprobadores antes del job de TestFlight (requiere ajustar el YAML con `environment:`).
