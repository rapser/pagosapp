-- Verification Script: Check currency migration
-- Run this after applying migration_add_currency.sql

-- 1. Check if currency column exists
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_name = 'payments' AND column_name = 'currency';

-- 2. Check if currency constraint exists
SELECT conname, contype, pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conname LIKE '%currency%' AND conrelid = 'payments'::regclass;

-- 3. Check currency distribution
SELECT 
    currency,
    COUNT(*) as payment_count,
    SUM(amount) as total_amount
FROM payments
GROUP BY currency
ORDER BY currency;

-- 4. Check for any NULL currencies (should be 0)
SELECT COUNT(*) as null_currency_count
FROM payments
WHERE currency IS NULL;

-- 5. Sample payments by currency
SELECT 
    currency,
    name,
    amount,
    due_date,
    category
FROM payments
ORDER BY currency, due_date DESC
LIMIT 10;

-- 6. Verify index exists
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'payments' AND indexname = 'idx_payments_currency';

-- Expected Results:
-- ✅ Column exists with type TEXT and default 'PEN'
-- ✅ CHECK constraint validates IN ('PEN', 'USD')
-- ✅ All existing payments have currency = 'PEN'
-- ✅ NULL count is 0
-- ✅ Index idx_payments_currency exists
