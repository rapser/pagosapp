# Fastlane — Guía para configurarlo bien (PagosApp y otros proyectos)

Esta guía resume lo que hizo falta para que **archive, IPA y subida a TestFlight** funcionaran sin errores típicos. Úsala al montar Fastlane en **otro repo iOS** o al revisar este.

> **Nota:** `fastlane/README.md` puede regenerarse al ejecutar Fastlane. Esta guía (`SETUP.md`) es la referencia estable.

---

## 1. Requisitos en Apple y en tu Mac

1. **Programa Apple Developer** de pago activo.
2. **App creada** en [App Store Connect](https://appstoreconnect.apple.com) con el mismo **Bundle ID** que en Xcode.
3. **Xcode** instalado, con **Command Line Tools** (Xcode → Settings → Locations).
4. **Firma Release**: certificado **Apple Distribution** y perfil **App Store** (o “Automatically manage signing” y equipo correcto). Sin eso, `gym` falla al exportar.
5. **Ruby** para Fastlane:
   - **No** uses el Ruby 2.6 del sistema para `bundle install`.
   - Instala Ruby con **Homebrew** (3.x o 4.x) y ponlo **primero** en el `PATH`.
   - En **Ruby 3.4+ / 4.x** hace falta **Fastlane ≥ 2.231** (corrige gems de stdlib y errores de carga).

```bash
brew install ruby
# Añade al PATH (Apple Silicon suele ser /opt/homebrew, Intel /usr/local):
echo 'export PATH="$(brew --prefix ruby)/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
ruby -v   # debe ser 3.x o 4.x
gem install bundler
```

---

## 2. Estructura mínima en el repo

En la **raíz** del proyecto (junto al `.xcodeproj` o `.xcworkspace`):

| Archivo | Para qué |
|---------|------------|
| `Gemfile` | Declara `fastlane` (p. ej. `~> 2.231`) |
| `Gemfile.lock` | Fija versiones; **sí** al git |
| `.ruby-version` | Opcional; ayuda a CI y a `ruby/setup-ruby` |
| `fastlane/Fastfile` | Lanes (`gym`, `upload_to_testflight`, etc.) |
| `fastlane/Appfile` | `app_identifier`, `team_id`, opcional `apple_id` |
| `fastlane/.env.example` | Plantilla **sin secretos** |
| `.gitignore` | Ignorar `.env`, `fastlane/.env`, `build/`, etc. |

```bash
cd /ruta/al/repo
bundle install
bundle exec fastlane reference   # lista lanes (si las definiste)
```

---

## 3. App Store Connect API Key (`.p8`)

1. App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API** → **Generate API Key**.
2. Rol **App Manager** o **Admin**.
3. Descarga **`AuthKey_XXXXXXXXXX.p8`** (solo una vez) y guarda **Key ID** e **Issuer ID**.

### Variables de entorno (`.env` en la raíz o `fastlane/.env`)

Obligatorias para subir con este proyecto:

```bash
APP_STORE_CONNECT_API_KEY_ID=XXXXXXXXXX
APP_STORE_CONNECT_ISSUER_ID=uuid-del-issuer
APP_STORE_CONNECT_P8_PATH=/ruta/absoluta/AuthKey_XXXXXXXXXX.p8
```

#### Errores que evitas así

| Error / síntoma | Causa habitual | Qué hacer |
|-----------------|----------------|-----------|
| `JSON::ParserError` / `invalid number: '-----BEGIN'` | Fastlane interpreta un path o variable como **JSON** y recibe el **PEM** del `.p8`. | Usa **`APP_STORE_CONNECT_P8_PATH`** para el fichero `.p8`. **No** pongas el `.p8` en **`APP_STORE_CONNECT_API_KEY_PATH`**: en Pilot esa variable es ruta a **JSON** (`Token.from_json_file`), no al `.p8` de Apple. |
| Lo mismo con `APP_STORE_CONNECT_API_KEY` | Esa variable debe ser **JSON** oficial (key_id, issuer_id, key en base64), no el texto PEM. | Usa `P8_PATH` + Key ID + Issuer, o JSON correcto según [docs.fastlane.tools](https://docs.fastlane.tools/app-store-connect-api/). |
| `abbrev` / `UpdateChecker` / fallo al arrancar Fastlane | Ruby 3.4+ y Fastlane viejo. | Sube Fastlane en el `Gemfile` a **≥ 2.231** y `bundle update fastlane`. |

En **CI**, si no quieres fichero en disco, puedes usar **`APP_STORE_CONNECT_API_KEY_CONTENT_BASE64`** (contenido del `.p8` en Base64, una línea). No commitees el `.p8` ni el `.env`.

---

## 4. Editor y `Fastfile`

- Edita el `Fastfile` con **Cursor, VS Code o Xcode**, no con **TextEdit** con “comillas inteligentes”: rompen strings Ruby (`desc "..."`) y dan **syntax error**.
- Si copias snippets de internet, revisa que las comillas sean **ASCII** `"` y `'` rectas.

---

## 5. Uso en este proyecto (PagosApp)

| Comando | Uso |
|---------|-----|
| `bundle exec fastlane menu` | Menú numerado (IPA Ad Hoc, App Store, subir a TestFlight, etc.) |
| `bundle exec fastlane reference` | Lista de lanes sin menú |
| `bundle exec fastlane ipa_app_store` | Solo IPA App Store (sin subir) |
| `bundle exec fastlane release_app_store_connect` | Archive + subida TestFlight / ASC |
| `bundle exec fastlane release_testflight_internal` | Igual con mensaje orientado a testers internos |

- El **build** (`CFBundleVersion`) se estampa con formato **`YYYYMM.DD.HHmm`** (ej. `202604.17.2112`). Detalle técnicos y flujo *desde cero* en [**`docs/build-number-xcode-fastlane.md`**](../docs/build-number-xcode-fastlane.md).
- Un **Archive en Xcode** (Release) aplica el formato: fase al final del target **Set CFBundleVersion in .app (Release)**, que escribe el `Info.plist` del `.app` con **PlistBuddy** (el script está **inline** en el proyecto, no hace falta un `.sh` separado; **Debug** no modifica el build).
- En **Fastlane**, `stamp_build_timestamp` escribe `CURRENT_PROJECT_VERSION` en el **target de la app** vía `xcodeproj` (no `agvtool` / `increment_build_number`, para alinear el IPA con el resumen; ver documentación enlace arriba). Luego `gym` con `SKIP_XCODE_STAMP=1` no vuelve a parchear el plist.
- Al terminar lanes relevantes se muestra **`Versión generada: marketing(build)`**.
- Tras elegir opción en el **menú**, se imprime el **tiempo total** (segundos si &lt; 60 s; si no, **minutos enteros hacia arriba**).

`SKIP_AUTO_INCREMENT_BUILD=1` evita cambiar el build (útil al depurar; afecta Fastlane y la fase de Xcode).

---

## 6. Copiar este enfoque a **otro** proyecto iOS

1. Copia **`Gemfile`**, **`Gemfile.lock`** (o genera lock con `bundle lock` en el nuevo repo), **`.ruby-version`** si aplica.
2. Copia **`fastlane/`** (`Fastfile`, `Appfile`, `.env.example`) y adapta:
   - `PROJECT` / `SCHEME` / `OUTPUT_DIR` / nombres de IPA en el `Fastfile`.
   - `app_identifier` y `team_id` en **`Appfile`**.
3. Añade al **`.gitignore`**: `.env`, `fastlane/.env`, `build/`, `fastlane/report.xml`, etc.
4. Crea la **API Key** en Connect para ese **Bundle ID** y rellena **`fastlane/.env`** desde **`.env.example`**.
5. En Xcode, un **Archive** manual de Release para comprobar firma antes de automatizar.
6. `bundle install` → `bundle exec fastlane menu` (o la lane de release).

---

## 7. CI (GitHub Actions u otro)

En este repo el flujo de **TestFlight en GitHub** está descrito en **[`.github/GITHUB_ACTIONS_TESTFLIGHT.md`](../.github/GITHUB_ACTIONS_TESTFLIGHT.md)** y el workflow en **[`.github/workflows/testflight-develop.yml`](../.github/workflows/testflight-develop.yml)**:

- Se ejecuta en **`push` a `develop`** (típico tras **merge** de un PR hacia `develop`), **no** en PRs ni en push a `main`.
- Invoca **`bundle exec fastlane release_app_store_connect`** (sin menú).
- Secretos: API Key en Base64, Key ID, Issuer; y para **firma** en el runner: `.p12` Distribution + perfil App Store en Base64 (o `match` si lo añades al `Fastfile`).
- Variable útil: `FASTLANE_SKIP_UPDATE_CHECK=1` (ya la pone el workflow).

Ejemplo mínimo genérico (otro proyecto):

```yaml
- uses: ruby/setup-ruby@v1
  with:
    ruby-version: .ruby-version
    bundler-cache: true
- env:
    APP_STORE_CONNECT_API_KEY_CONTENT_BASE64: ${{ secrets.APP_STORE_CONNECT_API_KEY_CONTENT_BASE64 }}
    APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
    APP_STORE_CONNECT_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
    FASTLANE_SKIP_UPDATE_CHECK: "1"
  run: bundle exec fastlane release_app_store_connect
```

---

## 8. Enlaces útiles

- [Instalar Fastlane](https://docs.fastlane.tools/getting-started/ios/setup/)
- [App Store Connect API — crear claves](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api)
- [Acción `app_store_connect_api_key`](https://docs.fastlane.tools/actions/app_store_connect_api_key/)
- [Acción `upload_to_testflight`](https://docs.fastlane.tools/actions/upload_to_testflight/)

---

## 9. Si Fastlane sobrescribe `fastlane/README.md`

Algunos comandos regeneran **`fastlane/README.md`** con la lista auto-generada de lanes. La guía operativa sigue en **`fastlane/SETUP.md`**; puedes volver a añadir al `README.md` de `fastlane/` un enlace a `SETUP.md` tras regenerar.
