# Testing

## 🧪 Testing

```bash
# Ejecutar todos los tests
⌘ + U

# O desde terminal (ajusta el simulador al que tengas instalado)
xcodebuild test -scheme pagosApp -project pagosApp.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Estado actual**: suite **mínima** centrada en **validadores** (email, contraseña) y test de arranque del target. Ampliar use cases, mappers, sync y UI entra en el roadmap de calidad (issues/PRs).

---
