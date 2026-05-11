# Plan de Despliegue del Juego (Agent-Ready)

Este documento describe los pasos automatizados (sin prompts interactivos) para configurar la base de datos con Realtime, pushear al repositorio y desplegar el juego utilizando exclusivamente herramientas de línea de comandos (CLI) junto con el archivo `.env`.

## Requisitos Previos (Para el Agente)
El agente debe asegurarse de cargar o exportar las variables definidas en el archivo `.env` antes de ejecutar las fases.

**Notas del Proyecto Actual:**
1. **GitHub:** El repositorio ya existe en `https://github.com/JAPEREZ-L001/catedra-digital-udb.git`. Solo se requiere hacer commit y push.
2. **Supabase:** La base de datos ya existe (y las credenciales están en el `.env`), pero no tiene las tablas ni el Realtime habilitado.
3. **Vercel:** Las variables `VERCEL_ORG_ID` y `VERCEL_PROJECT_ID` pueden no estar configuradas, pero disponiendo de `VERCEL_TOKEN` el agente avanzará utilizando la bandera `--yes`.

---

## Fase 1: Creación de Migraciones y Realtime en Supabase

Dado que la base de datos ya existe, inyectaremos directamente el esquema y aplicaremos los cambios.

**1. Vincular el proyecto local con la nube (Opcional si la carpeta supabase está ya vinculada):**
```bash
# Requiere SUPABASE_PROJECT_REF_ID y SUPABASE_DB_PASSWORD exportados en el entorno
supabase link --project-ref $SUPABASE_PROJECT_REF_ID --password $SUPABASE_DB_PASSWORD
```

**2. Crear la migración para las tablas y Realtime:**
Para evitar prompts o buscar archivos con fechas aleatorias generadas por `supabase migration new`, el agente creará el archivo de migración directamente:
```bash
# Crear directorio si no existe
mkdir -p supabase/migrations

# Generar el archivo SQL con timestamp y el esquema
MIGRATION_FILE="supabase/migrations/$(date +%Y%m%d%H%M%S)_crear_esquema.sql"

cat << 'EOF' > $MIGRATION_FILE
-- 1. Crear tablas necesarias para el juego
CREATE TABLE IF NOT EXISTS partidas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  estado TEXT NOT NULL
);

-- (El agente debe añadir aquí cualquier otra tabla como 'jugadores', 'nodos', etc.)

-- 2. Habilitar el Realtime en las tablas creadas
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime;
COMMIT;
ALTER PUBLICATION supabase_realtime ADD TABLE partidas;
EOF
```

**3. Aplicar los cambios a producción:**
```bash
supabase db push --password $SUPABASE_DB_PASSWORD
```

---

## Fase 2: Sincronización con GitHub

Dado que el repositorio remoto ya existe, solo actualizaremos la rama principal.

**1. Configurar credenciales:**
```bash
# Autenticar a gh sin interacción
echo $GH_TOKEN | gh auth login --with-token

# (Solo si es necesario configurar identidad local en la máquina)
git config --global user.name "Agente Automatizado"
git config --global user.email "agente@bot.com"
```

**2. Preparar y subir los cambios:**
```bash
git init
git add .
git commit -m "feat: Configuración automatizada de despliegue, Supabase y esquema"

# Configurar el origen al repo existente
git remote add origin https://github.com/JAPEREZ-L001/catedra-digital-udb.git || git remote set-url origin https://github.com/JAPEREZ-L001/catedra-digital-udb.git

# Subir forzando tracking a main
git branch -M main
git push -u origin main
```

---

## Fase 3: Despliegue con Vercel CLI

Se utiliza intensivamente la bandera `--yes` para saltar cualquier diálogo y `VERCEL_TOKEN` para la autenticación.

**1. Inicializar y vincular el proyecto:**
```bash
# Crea/Enlaza el proyecto con las opciones por defecto
vercel link --yes --token $VERCEL_TOKEN
```

**2. Configurar Variables de Entorno en la nube de Vercel:**
Para evitar el menú interactivo, forzamos que las variables apliquen a `production`, `preview` y `development`.
*(Nota: El agente debe extraer los valores de `NEXT_PUBLIC_SUPABASE_URL` y `NEXT_PUBLIC_SUPABASE_ANON_KEY` del archivo `.env` antes de inyectarlos)*.

```bash
# Añadir la URL de Supabase
echo -n $NEXT_PUBLIC_SUPABASE_URL | vercel env add NEXT_PUBLIC_SUPABASE_URL production preview development --token $VERCEL_TOKEN

# Añadir el Anon Key de Supabase
echo -n $NEXT_PUBLIC_SUPABASE_ANON_KEY | vercel env add NEXT_PUBLIC_SUPABASE_ANON_KEY production preview development --token $VERCEL_TOKEN
```

**3. Despliegue a Producción:**
```bash
# Despliega directamente a producción saltándose verificaciones
vercel --prod --yes --token $VERCEL_TOKEN
```
