-- Add 'crm' to user_role enum
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'crm';
