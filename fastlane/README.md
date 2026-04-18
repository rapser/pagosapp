# Fastlane — PagosApp

Guía operativa y trucos para que **no falle** la configuración: **[SETUP.md](SETUP.md)** (léela antes de otro proyecto o si ves errores de API Key / JSON / Ruby).

## Comandos rápidos

```bash
cd /ruta/raíz-del-repo   # donde están Gemfile y pagosApp.xcodeproj
bundle install
bundle exec fastlane menu       # menú numerado
bundle exec fastlane reference  # lista de lanes (CI / copiar)
```

Plantilla de variables (sin secretos): **[.env.example](.env.example)**  
CI / GitHub Actions + TestFlight: **[`../.github/GITHUB_ACTIONS_TESTFLIGHT.md`](../.github/GITHUB_ACTIONS_TESTFLIGHT.md)**

## Lanes (referencia)

| Lane | Descripción |
|------|-------------|
| `menu` | Menú interactivo |
| `reference` | Ayuda de comandos |
| `stamp_build` | Solo actualiza CFBundleVersion (formato `YYYYMM.DD.HHmm`) |
| `ipa_pruebas` | IPA Ad Hoc |
| `ipa_app_store` | IPA App Store (sin subir) |
| `release_app_store_connect` | Archive + subida TestFlight / ASC |
| `release_testflight_internal` | Archive + subida (enfoque internos) |
| `upload_testflight` | Sube el último IPA en `build/` |

Documentación generada por Fastlane (lista detallada de acciones): [docs.fastlane.tools](https://docs.fastlane.tools).
