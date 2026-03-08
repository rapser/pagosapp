# Internacionalización (i18n)

Todos los textos visibles al usuario están centralizados para soportar varios idiomas.

## Estructura

- **`Resources/Base.lproj/Localizable.strings`**: Español (idioma base / fallback).
- **`Resources/en.lproj/Localizable.strings`**: Inglés.
- **`Resources/pt.lproj/Localizable.strings`**: Portugués.
- **`Shared/L10n/L10n.swift`**: Acceso type-safe a las cadenas desde el código. Usar siempre `L10n.*` en lugar de literales.

El idioma se elige según el idioma del dispositivo. Si no hay traducción para ese idioma, se usa Base (español).

## Uso en código

```swift
// General
Text(L10n.General.ok)
Text(L10n.General.save)

// Por módulo
Text(L10n.Payments.List.title)
Text(L10n.Statistics.chartByCategory)
Text(L10n.Profile.myProfile)

// Con parámetros
Text(L10n.Statistics.emptyNoPayments(currencyName))
Text(L10n.PaymentError.saveFailed(details))

// Enums (nombre para mostrar)
Text(L10n.Payments.categoryDisplayName(payment.category))
Text(L10n.Statistics.periodDisplayName(filter))
```

## Logs de consola (L10n.Log)

Los mensajes de log usan el mismo sistema de localización: **si la app está en español, los logs se muestran en español; si está en inglés o portugués, en ese idioma**. Usa `L10n.Log` en lugar de literales en los `logger.info`, `logger.error`, etc.

```swift
logger.info("\(L10n.Log.Auth.signIn)")
logger.error("\(L10n.Log.Auth.signInFailed(error.localizedDescription))")
logger.info("\(L10n.Log.Statistics.filteredCount(filtered.count, total))")
```

Las claves de log están en `Localizable.strings` bajo la sección `// MARK: - Logs`. Al añadir un nuevo idioma, hay que traducir también esas claves.

## Añadir un nuevo idioma

1. Crear la carpeta `Resources/<código>.lproj/` (ej. `fr.lproj` para francés).
2. Crear `Localizable.strings` con las mismas claves que en `Base.lproj` y traducir los valores.
3. En Xcode: proyecto → Info → Localizations, añadir el idioma si no está (para que aparezca en el proyecto).

## Nota sobre Auth

El módulo **Auth** es una librería autónoma. Sus cadenas (login, registro, errores) no usan `L10n` de la app y se mantienen dentro del propio módulo Auth. Para localizar Auth en el futuro, se puede definir un protocolo de localización que la app implemente e inyecte en Auth.
