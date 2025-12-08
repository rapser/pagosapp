-- Migration: Add currency column to payments table
-- Date: 2025-12-06
-- Description: Adds support for multiple currencies (PEN and USD) to payments

-- Add currency column with default value 'PEN' for existing records
ALTER TABLE payments 
ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'PEN' 
CHECK (currency IN ('PEN', 'USD'));

-- Create index on currency for filtering
CREATE INDEX IF NOT EXISTS idx_payments_currency ON payments(currency);

-- Update any NULL currencies to 'PEN' (safety measure)
UPDATE payments 
SET currency = 'PEN' 
WHERE currency IS NULL;

-- Add comment to document the column
COMMENT ON COLUMN payments.currency IS 'Currency code: PEN (Soles) or USD (Dollars)';
