# Seguridad, contribución y metadatos

## 🔒 Seguridad

### Implementaciones de Seguridad

- 🔐 **Keychain**: Tokens y credenciales almacenados de forma segura
- 🚫 **Secrets.xcconfig**: Credenciales nunca en código
- 🛡 **RLS (Row Level Security)**: Cada usuario solo ve sus datos
- 👤 **Session Management**: Sesiones seguras con renovación automática
- 📱 **Biometrics**: Face ID/Touch ID opcional
- 🔑 **Build-time Injection**: Credenciales inyectadas en compilación
- 🔏 **SSL pinning (opcional)**: si incluyes certificados `.cer` en el bundle, `SupabaseClientFactory` usa `URLSession` con delegado de pinning; sin `.cer`, el cliente usa sesión estándar (ver [runbooks](runbooks/) si existen en el repo)

---

## 🤝 Contribución

### Workflow

1. **Fork** el proyecto
2. **Crea branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit** cambios (`git commit -m 'Add AmazingFeature'`)
4. **Push** a branch (`git push origin feature/AmazingFeature`)
5. **Abre Pull Request**

### Estándares de Código

- ✅ Swift 5 con async/await; aislamiento con `@MainActor` donde aplica; Sendable en piezas compartidas cuando el compilador lo exige
- ✅ Clean Architecture (Domain/Data/Presentation)
- ✅ @Observable para state management
- ✅ async/await (no Combine)
- ✅ **SwiftLint** sin errores en CI (`.swiftlint.yml`)
- ✅ Tests para nueva funcionalidad cuando toquen lógica crítica
- ✅ Documentación inline

---

## 📝 Changelog

Ver [CHANGELOG.md](../CHANGELOG.md) para historial completo de cambios.

### Highlights

- **2026-04 (v1.0.0 build 20)**: GitHub Actions (build + SwiftLint), pinning SSL con API moderna (`SecTrustCopyCertificateChain`), consola más silenciosa en rutas calientes; README y documentación bajo `docs/` alineados con Swift 5, iOS 18.0+ y dependencias; retirada la referencia a `TECHNICAL_AUDIT.md`
- **2026-03 (v1.0.0 build 15)**: Recordatorios (módulo completo, sync Supabase, notificaciones configurables), i18n (ES/EN/PT) ampliado, Calendario con pagos + recordatorios, Historial/Estadísticas desde Ajustes
- **2026-01 (v1.0.0 build 14)**: EventBus type-safe + Migración completa de NotificationCenter + Clean Architecture 100%
- **2026-01 (v1.0.0 build 11)**: Edición de pagos agrupados + Sincronización con calendario + Notificaciones locales restauradas
- **2026-01 (v1.0.0 build 10)**: Clean Architecture completa + Entity naming + refuerzo de concurrencia
- **2025-01**: Modernización de UI (iOS 18+) y stack actual
- **2024-11**: Módulo de autenticación con patrones de diseño
- **2024-10**: Release inicial v1.0

---

## 📄 Licencia

MIT License - Ver archivo LICENSE para detalles.

---

## 👤 Autor

**rapser**
- GitHub: [@rapser](https://github.com/rapser)

---

## 🙏 Agradecimientos

- [Supabase](https://supabase.com) - Backend as a Service
- [Swift Community](https://swift.org) - Amazing language
- Apple Developer Team - iOS SDK y frameworks
- Uncle Bob Martin - Clean Architecture principles

