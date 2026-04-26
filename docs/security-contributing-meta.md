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

- ✅ Swift 6 con async/await; aislamiento con `@MainActor` donde aplica; `Sendable` y reglas de concurrencia estrictas según el compilador
- ✅ Clean Architecture (Domain/Data/Presentation)
- ✅ @Observable para state management
- ✅ async/await (no Combine)
- ✅ **SwiftLint** sin errores en CI (`.swiftlint.yml`)
- ✅ Tests para nueva funcionalidad cuando toquen lógica crítica
- ✅ Documentación inline

---

## 📝 Changelog y versión

[CHANGELOG.md](../CHANGELOG.md) resume la **versión** (marketing/build), el **alcance del producto** (qué hace la app) y el **stack** con el que se construye. No sustituye al historial de `git` para el detalle de revisiones.

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

