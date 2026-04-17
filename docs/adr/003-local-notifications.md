# ADR 003: Notificaciones locales (pagos y recordatorios)

## Estado

Aceptado.

## Decisión

- Un **scheduler genérico** (`GenericNotificationScheduler`) calcula fechas y registra `UNNotificationRequest` con triggers de calendario.
- Los textos e identificadores específicos van en **builders** (`PaymentNotificationContentBuilder`, `ReminderNotificationContentBuilder`).
- Los identificadores siguen un único formato definido en **`LocalNotificationIdentifiers`** con prefijos `payment-` y `reminder-`, más cancelación de IDs legacy sin prefijo durante la transición.

## Consecuencias

- Cualquier nuevo offset de días debe reflejarse en el builder y en el catálogo de cancelación asociado (o reutilizar funciones del tipo `LocalNotificationIdentifiers`).
