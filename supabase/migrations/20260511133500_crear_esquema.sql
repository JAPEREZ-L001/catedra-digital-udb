-- 1. Crear tablas necesarias para el juego
CREATE TABLE IF NOT EXISTS partidas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  estado TEXT NOT NULL
);

-- (El agente debe añadir aquí cualquier otra tabla como 'jugadores', 'nodos', etc.)
CREATE TABLE IF NOT EXISTS jugadores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  partida_id UUID REFERENCES partidas(id),
  nombre TEXT NOT NULL
);

-- 2. Habilitar el Realtime en las tablas creadas
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime;
COMMIT;
ALTER PUBLICATION supabase_realtime ADD TABLE partidas, jugadores;
