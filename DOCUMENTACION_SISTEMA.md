# Sistema de Gestión de Ingredientes y Recetas

## 1. Visión General

Sistema que permite gestionar ingredientes disponibles en la heladera del usuario y buscar recetas desde **TheMealDB API** (gratuita) que se puedan preparar con esos ingredientes.

### Características Principales
- Gestión de ingredientes personales (agregar, listar, eliminar)
- Búsqueda de recetas desde API externa (TheMealDB)
- Filtrado inteligente: prioriza recetas con ingredientes exactos
- Como recurso secundario: recetas con 1-2 ingredientes faltantes
- Sistema de caché para optimizar consultas a la API

---

## 2. Casos de Uso

### CU-01: Gestionar Ingredientes del Usuario
**Actor:** Usuario  
**Flujo Principal:**
1. Usuario selecciona opción "Agregar ingrediente"
2. Sistema solicita nombre y cantidad (opcional)
3. Sistema guarda ingrediente en base de datos local
4. Sistema confirma operación

**Flujos Alternativos:**
- Listar todos los ingredientes disponibles
- Eliminar ingrediente
- Actualizar cantidad de ingrediente existente

---

### CU-02: Buscar Recetas Disponibles
**Actor:** Usuario  
**Flujo Principal:**
1. Usuario selecciona "Buscar recetas"
2. Sistema obtiene lista de ingredientes del usuario desde DB
3. **Sistema consulta TheMealDB API** para cada ingrediente principal
4. Sistema filtra resultados según disponibilidad:
   - **Prioridad 1:** Recetas donde TODOS los ingredientes están disponibles
   - **Prioridad 2:** Recetas con máximo 2 ingredientes faltantes
5. Sistema muestra recetas ordenadas por prioridad
6. Usuario puede ver detalle de receta específica

**Precondiciones:**
- Usuario debe tener al menos 1 ingrediente registrado

---

### CU-03: Ver Detalle de Receta
**Actor:** Usuario  
**Flujo Principal:**
1. Usuario selecciona una receta de la lista
2. Sistema consulta detalle completo desde API (o caché)
3. Sistema muestra:
   - Nombre y categoría
   - Imagen
   - Ingredientes con cantidades
   - **Ingredientes faltantes** (resaltados)
   - Instrucciones paso a paso
4. Sistema guarda en caché para consultas futuras

---

## 3. Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                   CAPA DE PRESENTACIÓN                      │
│                    CLI (Menú de Consola)                    │
│                                                             │
│  - Menú principal                                           │
│  - Entrada/Salida de usuario                                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   CAPA DE SERVICIO                          │
│                   (Lógica de Negocio)                       │
│                                                             │
│  ┌──────────────────────┐  ┌──────────────────────────┐    │
│  │ IngredienteService   │  │ RecetaService            │    │
│  │                      │  │                          │    │
│  │ - agregar()          │  │ - buscarRecetas()        │    │
│  │ - listar()           │  │ - obtenerDetalle()       │    │
│  │ - eliminar()         │  │ - filtrarPorDisponibles()│    │
│  │ - actualizar()       │  │ - calcularFaltantes()    │    │
│  └──────────────────────┘  └──────────────────────────┘    │
│                                      ↓                      │
│                         ┌─────────────────────────┐         │
│                         │  TheMealDBClient        │         │
│                         │  (Conexión a API)       │         │
│                         │                         │         │
│                         │ - buscarPorIngrediente()│         │
│                         │ - obtenerRecetaPorId()  │         │
│                         │ - parsearJSON()         │         │
│                         └─────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              CAPA DE ACCESO A DATOS (DAO)                   │
│                                                             │
│  ┌──────────────────────┐  ┌──────────────────────────┐    │
│  │ IngredienteDAO       │  │ RecetaCacheDAO           │    │
│  │                      │  │ (Opcional)               │    │
│  │ - insertar()         │  │                          │    │
│  │ - obtenerTodos()     │  │ - guardar()              │    │
│  │ - obtenerPorId()     │  │ - buscarPorApiId()       │    │
│  │ - actualizar()       │  │ - limpiarViejos()        │    │
│  │ - eliminar()         │  │                          │    │
│  └──────────────────────┘  └──────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    BASE DE DATOS                            │
│                    SQLite (local)                           │
│                                                             │
│  - ingrediente (tus ingredientes)                           │
│  - receta_cache (caché opcional de recetas consultadas)     │
└─────────────────────────────────────────────────────────────┘

                        API EXTERNA
┌─────────────────────────────────────────────────────────────┐
│                   TheMealDB API                             │
│              https://www.themealdb.com/api.php              │
│                                                             │
│  - ~600 recetas                                             │
│  - Búsqueda por ingrediente                                 │
│  - Completamente GRATUITA                                   │
│  - Sin límite de requests                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Modelo de Datos

### Base de Datos Local (SQLite)

```sql
-- Tabla de ingredientes del usuario
CREATE TABLE ingrediente (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre VARCHAR(100) NOT NULL,
    cantidad DECIMAL(10,2),
    unidad_medida VARCHAR(20),
    categoria VARCHAR(50),
    fecha_agregado DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(nombre)
);

-- Tabla de caché de recetas (OPCIONAL - para optimización)
CREATE TABLE receta_cache (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    api_id VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    categoria VARCHAR(100),
    area VARCHAR(100),
    imagen_url TEXT,
    ingredientes_json TEXT,
    instrucciones TEXT,
    video_url TEXT,
    fecha_cache DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Índices para mejorar rendimiento
CREATE INDEX idx_ingrediente_nombre ON ingrediente(nombre);
CREATE INDEX idx_receta_cache_api_id ON receta_cache(api_id);
CREATE INDEX idx_receta_cache_fecha ON receta_cache(fecha_cache);
```

### Modelo de Objetos Java

```java
// Ingrediente.java
public class Ingrediente {
    private int id;
    private String nombre;
    private Double cantidad;
    private String unidadMedida;
    private String categoria;
    private LocalDateTime fechaAgregado;
    
    // Constructor, getters, setters, toString()
}

// Receta.java
public class Receta {
    private String idMeal;           // ID de TheMealDB
    private String nombre;
    private String categoria;
    private String area;             // Ej: "Italian", "Mexican"
    private String imagenUrl;
    private String instrucciones;
    private String videoUrl;
    private List<RecetaIngrediente> ingredientes;
    
    // Campos calculados
    private int ingredientesDisponibles;
    private int ingredientesFaltantes;
    private List<String> listaFaltantes;
    
    // Constructor, getters, setters
}

// RecetaIngrediente.java
public class RecetaIngrediente {
    private String nombre;
    private String cantidad;
    private boolean disponible;      // true si el usuario lo tiene
    
    // Constructor, getters, setters
}
```

---

## 5. TheMealDB API - Endpoints y Uso

### Endpoints Principales

#### 1. Buscar por Ingrediente Principal
```
GET https://www.themealdb.com/api/json/v1/1/filter.php?i={ingrediente}

Ejemplo: 
https://www.themealdb.com/api/json/v1/1/filter.php?i=chicken

Response:
{
  "meals": [
    {
      "strMeal": "Chicken Alfredo Primavera",
      "strMealThumb": "https://www.themealdb.com/images/media/meals/syqypv1486981727.jpg",
      "idMeal": "52796"
    },
    ...
  ]
}
```

**Limitación:** Solo devuelve ID, nombre e imagen. Necesitamos segundo request para el detalle.

---

#### 2. Obtener Detalle Completo de Receta
```
GET https://www.themealdb.com/api/json/v1/1/lookup.php?i={idMeal}

Ejemplo:
https://www.themealdb.com/api/json/v1/1/lookup.php?i=52796

Response:
{
  "meals": [
    {
      "idMeal": "52796",
      "strMeal": "Chicken Alfredo Primavera",
      "strCategory": "Chicken",
      "strArea": "Italian",
      "strInstructions": "Heat 1 tablespoon of butter...",
      "strMealThumb": "https://...",
      "strYoutube": "https://www.youtube.com/watch?v=...",
      "strIngredient1": "chicken",
      "strMeasure1": "2 cups",
      "strIngredient2": "heavy cream",
      "strMeasure2": "1 cup",
      // ... hasta strIngredient20 / strMeasure20
    }
  ]
}
```

**Nota:** Los ingredientes vienen en campos separados (strIngredient1-20, strMeasure1-20). Los campos vacíos vienen como null o "".

---

#### 3. Listar Todas las Categorías (Opcional)
```
GET https://www.themealdb.com/api/json/v1/1/categories.php
```

---

#### 4. Listar Todas las Áreas (Opcional)
```
GET https://www.themealdb.com/api/json/v1/1/list.php?a=list
```

---

## 6. Algoritmo de Búsqueda y Filtrado

### Flujo Completo

```
1. OBTENER ingredientes del usuario desde DB
   → List<Ingrediente> ingredientesUsuario

2. Para CADA ingrediente del usuario:
   → Llamar API: filter.php?i={ingrediente}
   → Guardar todas las recetas encontradas en un Set (evitar duplicados)

3. Para CADA receta encontrada:
   → Llamar API: lookup.php?i={idMeal}
   → Parsear ingredientes de la receta
   → Comparar con ingredientes del usuario
   → Calcular:
      - ingredientesDisponibles (cuántos tiene)
      - ingredientesFaltantes (cuántos le faltan)
      - listaFaltantes (nombres de los que faltan)

4. CLASIFICAR recetas:
   → Prioridad 1: ingredientesFaltantes == 0
   → Prioridad 2: ingredientesFaltantes <= 2
   → Descartar: ingredientesFaltantes > 2

5. ORDENAR resultados:
   → Primero: mayor cantidad de ingredientesDisponibles
   → Segundo: menor cantidad de ingredientesFaltantes

6. MOSTRAR al usuario
```

### Pseudocódigo Detallado

```java
// RecetaService.java

public List<Receta> buscarRecetasDisponibles() {
    // 1. Obtener ingredientes del usuario
    List<Ingrediente> misIngredientes = ingredienteDAO.obtenerTodos();
    Set<String> nombresIngredientes = misIngredientes.stream()
        .map(i -> i.getNombre().toLowerCase())
        .collect(Collectors.toSet());
    
    // 2. Buscar recetas en la API
    Set<RecetaBasica> recetasEncontradas = new HashSet<>();
    for (Ingrediente ing : misIngredientes) {
        List<RecetaBasica> recetas = apiClient.buscarPorIngrediente(ing.getNombre());
        recetasEncontradas.addAll(recetas);
    }
    
    // 3. Obtener detalle y filtrar
    List<Receta> recetasCompletas = new ArrayList<>();
    for (RecetaBasica rb : recetasEncontradas) {
        Receta receta = apiClient.obtenerDetalle(rb.getIdMeal());
        
        // Verificar disponibilidad de ingredientes
        int disponibles = 0;
        int faltantes = 0;
        List<String> listaFaltantes = new ArrayList<>();
        
        for (RecetaIngrediente ri : receta.getIngredientes()) {
            String nombreIng = ri.getNombre().toLowerCase();
            if (nombresIngredientes.contains(nombreIng)) {
                disponibles++;
                ri.setDisponible(true);
            } else {
                faltantes++;
                ri.setDisponible(false);
                listaFaltantes.add(ri.getNombre());
            }
        }
        
        receta.setIngredientesDisponibles(disponibles);
        receta.setIngredientesFaltantes(faltantes);
        receta.setListaFaltantes(listaFaltantes);
        
        // Filtrar: solo agregar si faltantes <= 2
        if (faltantes <= 2) {
            recetasCompletas.add(receta);
        }
    }
    
    // 4. Ordenar
    recetasCompletas.sort((r1, r2) -> {
        // Primero por faltantes (menor es mejor)
        int compareFaltantes = Integer.compare(
            r1.getIngredientesFaltantes(), 
            r2.getIngredientesFaltantes()
        );
        if (compareFaltantes != 0) return compareFaltantes;
        
        // Luego por disponibles (mayor es mejor)
        return Integer.compare(
            r2.getIngredientesDisponibles(), 
            r1.getIngredientesDisponibles()
        );
    });
    
    return recetasCompletas;
}
```

---

## 7. Estructura de Paquetes del Proyecto

```
src/
├── main/
│   ├── java/
│   │   └── com/
│   │       └── recetas/
│   │           ├── Main.java
│   │           │
│   │           ├── model/
│   │           │   ├── Ingrediente.java
│   │           │   ├── Receta.java
│   │           │   └── RecetaIngrediente.java
│   │           │
│   │           ├── dao/
│   │           │   ├── IngredienteDAO.java
│   │           │   └── RecetaCacheDAO.java (opcional)
│   │           │
│   │           ├── service/
│   │           │   ├── IngredienteService.java
│   │           │   └── RecetaService.java
│   │           │
│   │           ├── api/
│   │           │   ├── TheMealDBClient.java
│   │           │   └── HttpClientUtil.java
│   │           │
│   │           └── util/
│   │               ├── DatabaseConnection.java
│   │               └── JSONParser.java
│   │
│   └── resources/
│       ├── db.properties
│       └── schema.sql
│
└── test/ (opcional)
    └── java/
        └── com/
            └── recetas/
                └── service/
                    └── RecetaServiceTest.java
```

---

## 8. Plan de Implementación (Paso a Paso)

### FASE 1: Setup Inicial (1-2 horas)
- [ ] Crear estructura de paquetes
- [ ] Configurar SQLite y crear schema.sql
- [ ] Implementar DatabaseConnection.java (patrón Singleton)
- [ ] Crear clases de modelo básicas

### FASE 2: Gestión de Ingredientes (2-3 horas)
- [ ] Implementar IngredienteDAO (CRUD completo)
- [ ] Implementar IngredienteService
- [ ] Crear menú CLI básico para probar
- [ ] Agregar datos de prueba

### FASE 3: Conexión con API (3-4 horas)
- [ ] Implementar HttpClientUtil (usando HttpURLConnection)
- [ ] Implementar TheMealDBClient:
  - [ ] Método buscarPorIngrediente()
  - [ ] Método obtenerDetalle()
  - [ ] Parseo de JSON (manual o con biblioteca)
- [ ] Probar endpoints manualmente

### FASE 4: Lógica de Búsqueda (3-4 horas)
- [ ] Implementar RecetaService
- [ ] Implementar algoritmo de filtrado
- [ ] Implementar ordenamiento de resultados
- [ ] Testing con diferentes ingredientes

### FASE 5: Interfaz CLI Completa (2-3 horas)
- [ ] Menú principal completo
- [ ] Opciones de gestión de ingredientes
- [ ] Búsqueda y visualización de recetas
- [ ] Ver detalle de receta
- [ ] Manejo de errores y validaciones

### FASE 6: Optimizaciones (Opcional, 2-3 horas)
- [ ] Implementar RecetaCacheDAO
- [ ] Sistema de caché para recetas
- [ ] Limpieza de caché antiguo
- [ ] Mejoras en la interfaz

---

## 9. Tecnologías y Dependencias

### Dependencias Mínimas (Sin Frameworks)
```xml
<!-- Solo si decides usar Maven para gestión de dependencias -->
<dependencies>
    <!-- SQLite JDBC Driver -->
    <dependency>
        <groupId>org.xerial</groupId>
        <artifactId>sqlite-jdbc</artifactId>
        <version>3.45.0.0</version>
    </dependency>
    
    <!-- JSON Parsing (opcional, puedes hacerlo manual) -->
    <dependency>
        <groupId>org.json</groupId>
        <artifactId>json</artifactId>
        <version>20240303</version>
    </dependency>
</dependencies>
```

### Alternativa Sin Maven
- Descargar JARs manualmente:
  - sqlite-jdbc-3.45.0.0.jar
  - json-20240303.jar (opcional)
- Agregar al classpath del proyecto

### Java Standard Library (Sin dependencias externas)
- `java.sql.*` para SQLite
- `java.net.http.*` para HTTP requests (Java 11+)
- Parseo JSON manual con String manipulation

---

## 10. Ejemplos de Uso (Desde el Usuario)

### Escenario 1: Agregar Ingredientes
```
=== MENÚ PRINCIPAL ===
1. Gestionar ingredientes
2. Buscar recetas
3. Salir

Opción: 1

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

Opción: 1
Nombre del ingrediente: arroz
Cantidad (opcional): 
Unidad de medida (opcional): 

✓ Ingrediente agregado exitosamente
```

---

### Escenario 2: Buscar Recetas
```
Opción: 2

🔍 Buscando recetas con tus ingredientes...
   Ingredientes disponibles: pollo, arroz, tomate

📡 Consultando API...
   ✓ 45 recetas encontradas con pollo
   ✓ 23 recetas encontradas con arroz
   ✓ 31 recetas encontradas con tomate
   
🧮 Filtrando resultados...

=== RECETAS DISPONIBLES ===

✅ PRIORIDAD 1 - PUEDES HACER CON TUS INGREDIENTES:
────────────────────────────────────────────────────
1. Arroz con Pollo
   Categoría: Chicken
   Ingredientes: 3/3 disponibles ✓
   
2. Chicken Rice Casserole
   Categoría: Chicken
   Ingredientes: 3/3 disponibles ✓

⚠️ PRIORIDAD 2 - TE FALTA 1-2 INGREDIENTES:
────────────────────────────────────────────────────
3. Chicken Tikka Masala
   Categoría: Chicken
   Ingredientes: 2/5 disponibles
   Faltantes: yogurt, curry powder, garam masala

Selecciona una receta (1-3) o 0 para volver: 1
```

---

### Escenario 3: Ver Detalle
```
═══════════════════════════════════════════════════
            ARROZ CON POLLO
═══════════════════════════════════════════════════

📷 Imagen: https://www.themealdb.com/images/media/meals/...
🍽️  Categoría: Chicken
🌍 Origen: Spanish

─────────────────────────────────────────────────
INGREDIENTES:
─────────────────────────────────────────────────
✓ Chicken - 1 whole
✓ Rice - 2 cups
✓ Tomatoes - 3 chopped
  
─────────────────────────────────────────────────
INSTRUCCIONES:
─────────────────────────────────────────────────
1. Heat oil in a large pan...
2. Add chicken and brown on all sides...
3. Add rice and stir to coat...
...

🎥 Video: https://www.youtube.com/watch?v=...

Presiona ENTER para volver...
```

---

## 11. Consideraciones Importantes

### Limitaciones de TheMealDB
1. **Búsqueda básica:** Solo busca por ingrediente principal, no por múltiples ingredientes
2. **~600 recetas:** Base de datos limitada comparada con APIs pagas
3. **Sin filtros avanzados:** No tiene filtros por dieta, alergias, etc.
4. **Ingredientes en inglés:** La API está principalmente en inglés

### Estrategia para Manejar Limitaciones
1. **Normalización:** Convertir todos los ingredientes a minúsculas
2. **Mapeo de nombres:** Crear un diccionario español → inglés para ingredientes comunes
3. **Búsqueda múltiple:** Buscar con CADA ingrediente del usuario y unir resultados
4. **Filtrado local:** El filtrado inteligente se hace en tu código, no en la API

### Optimizaciones Recomendadas
1. **Caché de recetas:** Guardar recetas ya consultadas en DB local
2. **Limitar requests:** No buscar más de 5-10 ingredientes a la vez
3. **Timeout:** Configurar timeout de 10 segundos para requests HTTP
4. **Manejo de errores:** API puede estar caída, manejar excepciones

---

## 12. Migración Futura a Spoonacular

Cuando decidas migrar a una API paga (Spoonacular), solo necesitarás:

1. Crear nuevo cliente: `SpoonacularClient.java`
2. Cambiar la implementación en `RecetaService`:
```java
// Antes
TheMealDBClient apiClient = new TheMealDBClient();

// Después
SpoonacularClient apiClient = new SpoonacularClient();
```

3. Ventajas de Spoonacular:
   - Endpoint específico de búsqueda por múltiples ingredientes
   - Más recetas (1M+)
   - Filtros avanzados
   - Mejor precisión en resultados

---

## 13. Siguientes Pasos

1. **Revisar esta documentación**
2. **Crear estructura de carpetas**
3. **Implementar FASE 1** (Setup + Base de Datos)
4. **Probar conexión a TheMealDB API** manualmente
5. **Implementar FASE 2 y 3** (DAOs + API Client)

¿Listo para empezar con el código? 🚀
