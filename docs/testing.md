# Testing

## 🧪 Testing

```bash
# Ejecutar todos los tests
⌘ + U

# O desde terminal (ajusta el simulador al que tengas instalado)
xcodebuild test -scheme pagosApp -project pagosApp.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Estado actual**: suite **mínima** centrada en **validadores** (email, contraseña) y test de arranque del target; ampliar use cases, mappers, sync y UI está en el roadmap de calidad (ver [TECHNICAL_AUDIT.md](../TECHNICAL_AUDIT.md)).

---
