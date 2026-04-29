# QA Manual — claude-prompt-library

## Requisitos previos

- Claude Code CLI instalado (`claude --version` debe responder)
- `jq` instalado (`jq --version`)
- `bash` 4+ (`bash --version`)
- Cuenta de GitHub con acceso al repo

## Instalación para testing

```bash
# Opción A: desde el marketplace (producción)
claude plugin marketplace add franciscomastromarino/claude-prompt-library
claude plugin install claude-prompt-library@claude-prompt-library --scope user

# Opción B: desarrollo local (sin instalar)
git clone https://github.com/franciscomastromarino/claude-prompt-library.git
claude --plugin-dir ./claude-prompt-library
```

Verificar instalación:

```bash
claude plugin list
# Debe mostrar: claude-prompt-library@claude-prompt-library — Status: ✔ enabled
```

---

## Plan de pruebas

### 1. Detección del skill

| # | Paso | Resultado esperado | Pass/Fail |
|---|------|-------------------|-----------|
| 1.1 | Abrir nueva sesión de Claude Code | Sesión inicia sin errores | |
| 1.2 | Escribir `/prompt` y esperar autocomplete | Aparece sugerencia: `/prompt (prompt-library)` | |
| 1.3 | Presionar Enter en `/prompt` | Claude ejecuta el skill sin error "Unknown skill" | |
| 1.4 | Escribir `/prompt list` | Claude ejecuta `prompt-lib list` y muestra resultado | |

### 2. Librería vacía (estado inicial)

| # | Paso | Resultado esperado | Pass/Fail |
|---|------|-------------------|-----------|
| 2.1 | `/prompt list` con librería vacía | Mensaje: "No prompts saved yet" | |
| 2.2 | `/prompt load inexistente` | Mensaje de error claro, no crash | |
| 2.3 | `/prompt search algo` | "No results found" | |
| 2.4 | `/prompt delete inexistente` | Mensaje de error claro, no crash | |

### 3. Guardar un prompt

| # | Paso | Resultado esperado | Pass/Fail |
|---|------|-------------------|-----------|
| 3.1 | `/prompt save code-reviewer` | Claude pide contenido, descripción, categoría y tags | |
| 3.2 | Proveer contenido y metadata | Ejecuta `prompt-lib save` y confirma "saved: code-reviewer" | |
| 3.3 | Verificar archivo creado | Existe `~/.claude/plugins/data/prompt-library/prompts/code-reviewer.md` | |
| 3.4 | Verificar índice actualizado | `INDEX.json` contiene entrada con slug, name, description, category, tags, created | |
| 3.5 | `/prompt list` | Muestra el prompt recién guardado con todos sus campos | |

### 4. Cargar un prompt

| # | Paso | Resultado esperado | Pass/Fail |
|---|------|-------------------|-----------|
| 4.1 | `/prompt load code-reviewer` | Muestra el contenido completo del prompt | |
| 4.2 | Verificar que el frontmatter se muestra | Description, category y tags visibles | |
| 4.3 | Verificar que Claude ofrece opciones | Pregunta si usar as-is o modificar | |

### 5. Buscar prompts

Prerequisito: guardar al menos 3 prompts con distintas categorías y tags.

| # | Paso | Resultado esperado | Pass/Fail |
|---|------|-------------------|-----------|
| 5.1 | `/prompt search` + nombre parcial | Encuentra por slug | |
| 5.2 | `/prompt search` + tag | Encuentra por tag | |
| 5.3 | `/prompt search` + categoría | Encuentra por categoría | |
| 5.4 | `/prompt search` + palabra del contenido | Encuentra en content match | |
| 5.5 | `/prompt search` + texto inexistente | "No results found" | |
| 5.6 | Búsqueda case-insensitive | `API` y `api` dan el mismo resultado | |

### 6. Editar un prompt

| # | Paso | Resultado esperado | Pass/Fail |
|---|------|-------------------|-----------|
| 6.1 | `/prompt edit code-reviewer` | Claude obtiene la ruta del archivo | |
| 6.2 | Pedir un cambio al contenido | Claude lee el archivo, lo modifica con Edit tool | |
| 6.3 | `/prompt load code-reviewer` | Muestra el contenido actualizado | |

### 7. Eliminar un prompt

| # | Paso | Resultado esperado | Pass/Fail |
|---|------|-------------------|-----------|
| 7.1 | `/prompt delete code-reviewer` | Claude confirma antes de borrar | |
| 7.2 | Confirmar eliminación | "deleted: code-reviewer" | |
| 7.3 | Verificar que el archivo ya no existe | `ls` del directorio no muestra el archivo | |
| 7.4 | Verificar que INDEX.json se actualizó | La entrada fue removida | |
| 7.5 | `/prompt list` | Ya no muestra el prompt eliminado | |

### 8. Casos borde

| # | Paso | Resultado esperado | Pass/Fail |
|---|------|-------------------|-----------|
| 8.1 | Guardar prompt con nombre con espacios: `mi prompt largo` | Slugifica a `mi-prompt-largo` | |
| 8.2 | Guardar prompt con nombre con mayúsculas: `CodeReview` | Slugifica a `codereview` | |
| 8.3 | Guardar prompt con caracteres especiales: `test@#$%` | Slugifica correctamente sin caracteres inválidos | |
| 8.4 | Guardar prompt con el mismo nombre que uno existente | Sobreescribe el existente, actualiza INDEX.json | |
| 8.5 | Guardar prompt con contenido vacío (solo frontmatter) | Se guarda correctamente o error claro | |
| 8.6 | Prompt con contenido muy largo (>10KB) | Se guarda y carga sin truncar | |
| 8.7 | INDEX.json corrupto (borrar manualmente) | `prompt-lib init` lo regenera | |
| 8.8 | Directorio de datos no existe | Se crea automáticamente al primer uso | |

### 9. CLI directo (sin Claude)

Ejecutar fuera de Claude Code para verificar que el CLI funciona independiente:

```bash
export CLAUDE_PLUGIN_DATA="$HOME/.claude/plugins/data/prompt-library"
prompt-lib help
prompt-lib init
prompt-lib save test-cli <<'EOF'
---
description: Test desde CLI
category: general
tags: [test]
---
Contenido de prueba
EOF
prompt-lib list
prompt-lib load test-cli
prompt-lib search test
prompt-lib delete test-cli
prompt-lib list
```

| # | Paso | Resultado esperado | Pass/Fail |
|---|------|-------------------|-----------|
| 9.1 | `prompt-lib help` | Muestra ayuda completa | |
| 9.2 | Todos los comandos CRUD | Funcionan sin error | |
| 9.3 | Ejecución sin `CLAUDE_PLUGIN_DATA` | Usa fallback `~/.claude/plugins/data/prompt-library` | |
| 9.4 | Ejecución sin `jq` instalado | Error claro indicando dependencia | |

### 10. Instalación y desinstalación

| # | Paso | Resultado esperado | Pass/Fail |
|---|------|-------------------|-----------|
| 10.1 | `claude plugin install` desde marketplace | Instala correctamente | |
| 10.2 | `claude plugin list` | Muestra plugin enabled | |
| 10.3 | `claude plugin disable` | Desactiva, skill ya no disponible | |
| 10.4 | `claude plugin enable` | Reactiva, skill disponible de nuevo | |
| 10.5 | `claude plugin uninstall` | Desinstala limpiamente | |
| 10.6 | Verificar que los datos persisten post-desinstalación | `~/.claude/plugins/data/prompt-library/` sigue existiendo | |

---

## Mejoras sugeridas

### Prioridad alta

1. **Detección de dependencias**: El script debería verificar que `jq` está instalado y dar un error claro si no lo está, en lugar de fallar silenciosamente.

2. **Comando `prompt-lib export`**: Exportar uno o todos los prompts a un directorio del proyecto (`.claude/prompts/`) para compartirlos con el equipo.

3. **Comando `prompt-lib import`**: Importar prompts desde un archivo `.md` o un directorio, para migrar prompts existentes.

4. **Confirmación en overwrite**: Cuando se guarda un prompt con un nombre que ya existe, avisar que se va a sobreescribir y pedir confirmación.

5. **Versionado de prompts**: Guardar versiones anteriores al editar (backup en `prompts/.history/<name>/<timestamp>.md`).

### Prioridad media

6. **Comando `prompt-lib stats`**: Mostrar estadísticas: total de prompts, por categoría, más recientes, más usados.

7. **Tags como primer ciudadano**: Comando `prompt-lib tags` para listar todos los tags usados y cuántos prompts tiene cada uno.

8. **Formato de salida configurable**: `prompt-lib list --json` para integración con otros tools.

9. **Soporte para templates con variables**: Placeholders como `{{nombre}}`, `{{contexto}}` que Claude rellena al cargar.

10. **Favoritos / pinned**: Marcar prompts como favoritos para que aparezcan primero en `list`.

### Prioridad baja

11. **Sync entre máquinas**: Sincronizar la librería de prompts via git (un repo dedicado como storage).

12. **Prompts compartidos por proyecto**: Además de `~/.claude/plugins/data/`, soportar `.claude/prompts/` a nivel proyecto.

13. **Categorías custom**: Permitir categorías más allá de las predefinidas.

14. **Autocompletado de nombres**: Que `prompt-lib load <TAB>` autocomplete nombres de prompts existentes.

---

## Proceso de onboarding

Guía paso a paso para alguien que nunca usó el plugin.

### Paso 1: Contexto (30 segundos)

> **¿Qué es esto?** Un plugin para Claude Code que te permite guardar prompts que usás frecuentemente y reutilizarlos en cualquier proyecto. Pensalo como un "bookmark" de prompts.

### Paso 2: Instalación (1 minuto)

```bash
# Registrar el marketplace
claude plugin marketplace add franciscomastromarino/claude-prompt-library

# Instalar
claude plugin install claude-prompt-library@claude-prompt-library --scope user
```

Verificar:
```bash
claude plugin list
# Buscar: claude-prompt-library — Status: ✔ enabled
```

### Paso 3: Primer uso — guardar un prompt (2 minutos)

Abrir Claude Code y escribir:

```
/prompt save code-review
```

Claude te va a pedir:
1. **Contenido del prompt** — pegá o escribí el prompt que querés guardar
2. **Descripción** — una línea explicando para qué sirve
3. **Categoría** — elegí entre: `api`, `system`, `chat`, `agent`, `task`, `general`
4. **Tags** — palabras clave separadas por coma (opcional)

### Paso 4: Recuperar un prompt (30 segundos)

```
/prompt load code-review
```

Claude te muestra el prompt y te pregunta si querés usarlo tal cual o modificarlo.

### Paso 5: Explorar la librería (30 segundos)

```
/prompt list           # ver todos
/prompt search api     # buscar por palabra clave
```

### Paso 6: Flujo recomendado para el día a día

```
Sesión nueva → necesitás un prompt que ya escribiste antes

  /prompt search <lo que recuerdes>
  /prompt load <nombre>
  → Claude lo carga y podés usarlo directo

Terminaste de escribir un buen prompt en la conversación

  /prompt save <nombre-descriptivo>
  → Queda guardado para la próxima
```

### Cheat sheet para imprimir

```
┌─────────────────────────────────────────────┐
│         claude-prompt-library               │
├─────────────────────────────────────────────┤
│  /prompt list          Ver todos            │
│  /prompt save <name>   Guardar nuevo        │
│  /prompt load <name>   Cargar existente     │
│  /prompt search <q>    Buscar               │
│  /prompt edit <name>   Editar               │
│  /prompt delete <name> Eliminar             │
├─────────────────────────────────────────────┤
│  Categorías: api | system | chat | agent    │
│              task | general                 │
└─────────────────────────────────────────────┘
```
