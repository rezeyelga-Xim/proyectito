# 🍳 Recipe Manager - Gestor de Recetas con Ingredientes

Sistema de gestión de ingredientes que permite buscar recetas basadas en los ingredientes disponibles en tu heladera. Utiliza la API gratuita de TheMealDB para obtener recetas y prioriza aquellas que puedes preparar con lo que ya tienes.

## 🎯 Características

- ✅ Gestión de ingredientes personales (agregar, listar, eliminar, actualizar)
- 🔍 Búsqueda inteligente de recetas desde TheMealDB API
- 📊 Priorización automática:
  - **Prioridad 1:** Recetas con todos los ingredientes disponibles
  - **Prioridad 2:** Recetas con máximo 2 ingredientes faltantes
- 💾 Base de datos local SQLite
- 🚀 Sin frameworks - Java puro
- 📦 Sistema de caché opcional para optimizar consultas

## 🛠️ Tecnologías

- **Java 11+** (utilizando `java.net.http` para requests HTTP)
- **SQLite** (base de datos embebida)
- **TheMealDB API** (API gratuita de recetas)
- **JSON** (parseo de respuestas de la API)

## 📋 Requisitos Previos

- JDK 11 o superior
- Maven 3.6+ (opcional, si usas Maven)
- SQLite JDBC Driver

## 🚀 Instalación

### Opción 1: Con Maven

```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/recipe-manager.git
cd recipe-manager

# Compilar el proyecto
mvn clean compile

# Ejecutar
mvn exec:java -Dexec.mainClass="com.recetas.Main"
```

### Opción 2: Sin Maven (compilación manual)

```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/recipe-manager.git
cd recipe-manager

# Descargar dependencias manualmente
# - sqlite-jdbc-3.45.0.0.jar
# - json-20240303.jar
# Colocarlas en la carpeta lib/

# Compilar
javac -cp "lib/*" -d bin src/main/java/com/recetas/**/*.java

# Ejecutar
java -cp "bin:lib/*" com.recetas.Main
```

## 📁 Estructura del Proyecto

```
recipe-manager/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── recetas/
│   │   │           ├── Main.java
│   │   │           ├── model/
│   │   │           │   ├── Ingrediente.java
│   │   │           │   ├── Receta.java
│   │   │           │   └── RecetaIngrediente.java
│   │   │           ├── dao/
│   │   │           │   ├── IngredienteDAO.java
│   │   │           │   └── RecetaCacheDAO.java
│   │   │           ├── service/
│   │   │           │   ├── IngredienteService.java
│   │   │           │   └── RecetaService.java
│   │   │           ├── api/
│   │   │           │   └── TheMealDBClient.java
│   │   │           └── util/
│   │   │               └── DatabaseConnection.java
│   │   └── resources/
│   │       ├── schema.sql
│   │       └── db.properties
│   └── test/
│       └── java/
│           └── com/
│               └── recetas/
├── docs/
│   └── DOCUMENTACION_SISTEMA.md
├── lib/ (dependencias si no usas Maven)
├── .gitignore
├── pom.xml
├── LICENSE
└── README.md
```

## 🎮 Uso

### 1. Agregar Ingredientes

```
=== GESTIONAR INGREDIENTES ===
1. Agregar ingrediente
2. Listar ingredientes
3. Eliminar ingrediente
4. Volver

Opción: 1
Nombre del ingrediente: pollo
Cantidad (opcional): 500
Unidad de medida (opcional): gramos

✓ Ingrediente agregado exitosamente
```

### 2. Buscar Recetas

```
🔍 Buscando recetas con tus ingredientes...
   Ingredientes disponibles: pollo, arroz, tomate

=== RECETAS DISPONIBLES ===

✅ PRIORIDAD 1 - PUEDES HACER CON TUS INGREDIENTES:
1. Arroz con Pollo
   Ingredientes: 3/3 disponibles ✓
```

### 3. Ver Detalle de Receta

```
═══════════════════════════════════════════════════
            ARROZ CON POLLO
═══════════════════════════════════════════════════

INGREDIENTES:
✓ Chicken - 1 whole
✓ Rice - 2 cups
✓ Tomatoes - 3 chopped

INSTRUCCIONES:
1. Heat oil in a large pan...
2. Add chicken and brown on all sides...
```

## 🔄 API Utilizada

Este proyecto utiliza [TheMealDB API](https://www.themealdb.com/api.php) en su versión gratuita:

- 🆓 Completamente gratuita
- 📚 ~600 recetas
- 🌐 Sin límite de requests
- 📖 [Documentación oficial](https://www.themealdb.com/api.php)

### Endpoints principales:

- **Buscar por ingrediente:** `GET /api/json/v1/1/filter.php?i={ingrediente}`
- **Detalle de receta:** `GET /api/json/v1/1/lookup.php?i={id}`

## 🔮 Migración Futura

El proyecto está diseñado para migrar fácilmente a otras APIs más potentes como:

- **Spoonacular API** - Búsqueda por múltiples ingredientes, 1M+ recetas
- **Edamam API** - 2.3M recetas, filtros avanzados

Solo necesitas crear un nuevo cliente (ej: `SpoonacularClient.java`) e implementar la misma interfaz.

## 🗄️ Base de Datos

El proyecto utiliza SQLite con las siguientes tablas:

### `ingrediente`
Almacena los ingredientes del usuario.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | INTEGER | PK autoincremental |
| nombre | VARCHAR(100) | Nombre del ingrediente |
| cantidad | DECIMAL | Cantidad disponible |
| unidad_medida | VARCHAR(20) | Unidad (gramos, litros, etc.) |
| categoria | VARCHAR(50) | Categoría del ingrediente |
| fecha_agregado | DATETIME | Timestamp de creación |

### `receta_cache` (opcional)
Caché local de recetas consultadas para optimizar requests.

## 🤝 Contribuir

Las contribuciones son bienvenidas. Para cambios importantes:

1. Fork el proyecto
2. Crea tu rama de feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add: nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📝 TODO / Roadmap

- [ ] Implementar sistema de caché de recetas
- [ ] Agregar soporte para ingredientes en español
- [ ] Crear interfaz gráfica (Swing/JavaFX)
- [ ] Migrar a Spoonacular API
- [ ] Agregar filtros por dieta (vegetariano, vegano, etc.)
- [ ] Exportar/Importar lista de ingredientes
- [ ] Sistema de favoritos
- [ ] Planificador de comidas semanal

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 👨‍💻 Autor

Tu Nombre - [@tu_twitter](https://twitter.com/tu_twitter)

## 🙏 Agradecimientos

- [TheMealDB](https://www.themealdb.com/) por su increíble API gratuita
- Comunidad de Java por las excelentes herramientas
- Todos los contribuidores que hacen posible este proyecto

---

⭐ Si este proyecto te resultó útil, considera darle una estrella!
