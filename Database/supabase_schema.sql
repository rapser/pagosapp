-- pagosApp Database Schema for Supabase
-- This file contains the SQL schema for the payments table

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create payments table
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount >= 0),
    currency TEXT NOT NULL DEFAULT 'PEN' CHECK (currency IN ('PEN', 'USD')),
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    is_paid BOOLEAN NOT NULL DEFAULT FALSE,
    category TEXT NOT NULL CHECK (category IN ('Recibo', 'Tarjeta de Crédito', 'Ahorro', 'Suscripción', 'Otro')),
    event_identifier TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on user_id for faster queries
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);

-- Create index on due_date for sorting
CREATE INDEX IF NOT EXISTS idx_payments_due_date ON payments(due_date);

-- Create index on is_paid for filtering
CREATE INDEX IF NOT EXISTS idx_payments_is_paid ON payments(is_paid);

-- Row Level Security (RLS) Policies
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own payments
CREATE POLICY "Users can view their own payments"
    ON payments FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own payments
CREATE POLICY "Users can insert their own payments"
    ON payments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own payments
CREATE POLICY "Users can update their own payments"
    ON payments FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own payments
CREATE POLICY "Users can delete their own payments"
    ON payments FOR DELETE
    USING (auth.uid() = user_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the update function
CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
