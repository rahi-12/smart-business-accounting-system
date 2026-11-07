
-- Migration: 001_create_users.sql
-- Purpose: Create user profiles for Smart Business Accounting System

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    firebase_uid VARCHAR(128) NOT NULL UNIQUE,

    full_name VARCHAR(100) NOT NULL,

    username VARCHAR(30) NOT NULL,

    email VARCHAR(254) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT users_full_name_not_empty
        CHECK (LENGTH(TRIM(full_name)) > 0),

    CONSTRAINT users_username_format
        CHECK (username ~ '^[a-zA-Z0-9_]{3,30}$')
);

-- Usernames must be unique regardless of uppercase/lowercase.
CREATE UNIQUE INDEX users_username_lower_unique
ON users (LOWER(username));

-- Emails must also be unique regardless of uppercase/lowercase.
CREATE UNIQUE INDEX users_email_lower_unique
ON users (LOWER(email));
