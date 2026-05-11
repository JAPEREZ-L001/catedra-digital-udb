-- Add puntos and fecha columns to jugadores table if they don't exist
ALTER TABLE jugadores 
ADD COLUMN IF NOT EXISTS puntos INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS fecha TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now());
