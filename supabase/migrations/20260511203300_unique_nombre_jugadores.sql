-- Add UNIQUE constraint to the 'nombre' column in the 'jugadores' table
ALTER TABLE jugadores ADD CONSTRAINT unique_nombre UNIQUE (nombre);
