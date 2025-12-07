# Database Setup - Supabase

## Configuración Inicial

### 1. Crear la tabla en Supabase

1. Ve a tu proyecto en [Supabase Dashboard](https://app.supabase.com)
2. Ve a **SQL Editor**
3. Copia y pega el contenido de `supabase_schema.sql`
4. Ejecuta el script

Esto creará:
- ✅ Tabla `payments` con todas las columnas necesarias
- ✅ Índices para mejorar el performance
- ✅ Row Level Security (RLS) policies para seguridad
- ✅ Trigger para actualizar automáticamente `updated_at`

### 2. Aplicar Migración de Moneda (si ya tienes la tabla creada)

Si ya tienes la tabla `payments` creada y necesitas agregar soporte para múltiples monedas:

1. Ve a **SQL Editor** en Supabase
2. Copia y pega el contenido de `migration_add_currency.sql`
3. Ejecuta el script

Esto agregará:
- ✅ Columna `currency` con valor por defecto 'PEN'
- ✅ Índice en la columna currency
- ✅ Constraint para validar solo PEN o USD
- ✅ Actualización de registros existentes a 'PEN'

### 3. Verificar la configuración

#### Verificar la tabla
```sql
SELECT * FROM payments LIMIT 5;
```

#### Verificar las políticas RLS
```sql
SELECT * FROM pg_policies WHERE tablename = 'payments';
```

Deberías ver 4 políticas:
- `Users can view their own payments`
- `Users can insert their own payments`
- `Users can update their own payments`
- `Users can delete their own payments`

## Row Level Security (RLS)

Las políticas RLS aseguran que:
- ✅ Los usuarios solo pueden ver sus propios pagos
- ✅ Los usuarios solo pueden crear pagos asociados a su cuenta
- ✅ Los usuarios solo pueden editar/eliminar sus propios pagos
- ❌ Un usuario NO puede acceder a los pagos de otro usuario

## Estructura de la Tabla

| Columna | Tipo | Descripción | Restricciones |
|---------|------|-------------|---------------|
| `id` | UUID | Identificador único | PRIMARY KEY |
| `user_id` | UUID | ID del usuario (FK a auth.users) | NOT NULL, ON DELETE CASCADE |
| `name` | TEXT | Nombre del pago | NOT NULL |
| `amount` | DECIMAL(10,2) | Monto del pago | NOT NULL, >= 0 |
| `currency` | TEXT | Moneda del pago (PEN o USD) | NOT NULL, DEFAULT 'PEN' |
| `due_date` | TIMESTAMPTZ | Fecha de vencimiento | NOT NULL |
| `is_paid` | BOOLEAN | Estado del pago | NOT NULL, DEFAULT FALSE |
| `category` | TEXT | Categoría del pago | NOT NULL, CHECK constraint |
| `event_identifier` | TEXT | ID del evento en Calendar | NULLABLE |
| `created_at` | TIMESTAMPTZ | Fecha de creación | DEFAULT NOW() |
| `updated_at` | TIMESTAMPTZ | Última actualización | DEFAULT NOW() |

## Categorías Válidas

- `Recibo`
- `Tarjeta de Crédito`
- `Ahorro`
- `Suscripción`
- `Otro`

## Monedas Soportadas

- `PEN` - Soles Peruanos (S/)
- `USD` - Dólares Americanos ($)

Por defecto, todos los pagos se crean en **PEN** (Soles).

## Índices

Para mejorar el performance de las queries:

1. `idx_payments_user_id` - Acelera filtrado por usuario
2. `idx_payments_due_date` - Acelera ordenamiento por fecha
3. `idx_payments_is_paid` - Acelera filtrado por estado
4. `idx_payments_currency` - Acelera filtrado por moneda

## Testing Manual

### Insertar un pago de prueba en Soles
```sql
INSERT INTO payments (user_id, name, amount, currency, due_date, is_paid, category)
VALUES (
    auth.uid(), -- Tu user ID actual
    'Test Payment - Soles',
    100.50,
    'PEN',
    '2025-12-01',
    FALSE,
    'Recibo'
);
```

### Insertar un pago de prueba en Dólares
```sql
INSERT INTO payments (user_id, name, amount, currency, due_date, is_paid, category)
VALUES (
    auth.uid(), -- Tu user ID actual
    'Test Payment - Dollars',
    50.00,
    'USD',
    '2025-12-15',
    FALSE,
    'Suscripción'
);
```

### Ver tus pagos
```sql
SELECT * FROM payments WHERE user_id = auth.uid();
```

### Actualizar un pago
```sql
UPDATE payments
SET is_paid = TRUE
WHERE id = 'tu-payment-id';
```

### Eliminar un pago
```sql
DELETE FROM payments WHERE id = 'tu-payment-id';
```

## Sincronización en la App

La app usa `PaymentSyncManager` para sincronizar automáticamente:

- **Al iniciar sesión**: Sincronización completa
- **Al crear/editar/eliminar pago**: Sincronización inmediata
- **Periódicamente**: Cada hora (si hay cambios)

## Troubleshooting

### Error: "new row violates row-level security policy"
- Verifica que RLS esté habilitado: `ALTER TABLE payments ENABLE ROW LEVEL SECURITY;`
- Verifica que las políticas estén creadas correctamente

### Error: "relation 'payments' does not exist"
- Ejecuta el script `supabase_schema.sql` completo

### Los datos no se sincronizan
- Verifica que estés autenticado: `SELECT auth.uid();` debe devolver tu user ID
- Verifica los logs de la app en Xcode Console
- Verifica las credenciales en `Config/Secrets.xcconfig`

## Backup y Migraciones

### Backup de la tabla
```sql
SELECT * FROM payments;
```
(Exporta como CSV desde Supabase Dashboard)

### Restaurar backup
Usa la interfaz de Supabase Dashboard para importar CSV.

## Próximos Pasos

- [ ] Configurar webhooks para sincronización en tiempo real
- [ ] Agregar tabla de `payment_history` para auditoría
- [ ] Implementar soft deletes (en lugar de DELETE)
- [ ] Agregar campos para adjuntos/recibos escaneados
