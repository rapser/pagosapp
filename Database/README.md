# Database – Supabase

Scripts SQL para crear y mantener las tablas de **pagosApp** en Supabase. Cada tabla tiene su propio archivo.

## Archivos

| Archivo | Tabla | Uso |
|--------|--------|-----|
| **payments.sql** | `public.payments` | Pagos del usuario (offline + sync). |
| **reminders.sql** | `public.reminders` | Recordatorios del usuario (offline + sync). |
| **user_profiles.sql** | `public.user_profiles` | Perfil extendido del usuario (nombre, email, moneda, etc.). |

## Cómo usar los scripts

1. Entra en [Supabase Dashboard](https://app.supabase.com) y abre tu proyecto.
2. Ve a **SQL Editor**.
3. Ejecuta los scripts **en este orden** (por dependencias con `auth.users`):

   **Orden recomendado**

   1. **payments.sql** – crea la tabla de pagos.
   2. **reminders.sql** – crea la tabla de recordatorios.
   3. **user_profiles.sql** – crea la tabla de perfiles de usuario.

4. En cada ejecución:
   - Copia todo el contenido del `.sql`.
   - Pégalo en el editor.
   - Pulsa **Run** (o el botón equivalente).

No hace falta ejecutar los tres a la vez; puedes ejecutar solo el que necesites (por ejemplo solo `reminders.sql` si ya tienes el resto).

## Verificación rápida

Después de ejecutar, puedes comprobar que las tablas existen:

```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('payments', 'reminders', 'user_profiles');
```

Comprobar RLS de una tabla (ej. pagos):

```sql
SELECT * FROM pg_policies WHERE tablename = 'payments';
```

## Resumen por tabla

### payments (pagos)

- **Columnas:** `id`, `user_id`, `name`, `amount`, `currency`, `due_date`, `is_paid`, `category`, `event_identifier`, `group_id`, `created_at`, `updated_at`.
- **Monedas:** `PEN`, `USD` (por defecto `PEN`).
- **RLS:** cada usuario solo ve/edita sus propios pagos.

### reminders (recordatorios)

- **Columnas:** `id`, `user_id`, `reminder_type`, `title`, `description`, `due_date`, `is_completed`, `created_at`, `updated_at`.
- **reminder_type:** `cardRenewal`, `membership`, `subscription`, `pension`, `deposit`, `savings`, `documents`, `taxes`, `other`.
- **RLS:** cada usuario solo ve/edita sus propios recordatorios.

### user_profiles (usuario)

- **Columnas:** `user_id` (PK), `full_name`, `email`, `phone`, `date_of_birth`, `gender`, `country`, `city`, `preferred_currency`.
- **RLS:** cada usuario solo ve/edita su propio perfil.

Los tres scripts son suficientes para crear el esquema en Supabase o para migrar/recrear las tablas en otro motor (PostgreSQL compatible).

## Troubleshooting

- **"relation does not exist"**  
  Ejecuta el script correspondiente a esa tabla (`payments.sql`, `reminders.sql` o `user_profiles.sql`).

- **"new row violates row-level security policy"**  
  Asegúrate de que el usuario esté autenticado (`auth.uid()` no nulo) y de que las políticas RLS estén creadas (vuelve a ejecutar el script de esa tabla).

- **Trigger: EXECUTE FUNCTION no reconocido**  
  En versiones antiguas de Postgres puede ser necesario usar `EXECUTE PROCEDURE` en lugar de `EXECUTE FUNCTION`. En ese caso edita la última línea del trigger en el script y cambia la palabra clave.
