# Mini Pokédex (SwiftUI + PokeAPI)

Una mini Pokédex hecha en SwiftUI para practicar consumo de APIs, parsing de JSON y navegación básica con un UI inspirado en la Pokédex (pantalla inicial “cerrada” + botón para abrir).

---

## ✨ Features
- **Pantalla de inicio** estilo Pokédex con botón **“ABRIR POKÉDEX”**
- **Grid (2 columnas)** con los primeros **50 Pokémon**
- **Detalle** por Pokémon con:
  - Sprite
  - Tipos
  - Altura y peso (convertidos a unidades “humanas”)
- **Botón SCAN** (elige un Pokémon random y te abre el detalle)
- **Search** para filtrar por nombre
- **Loading state** + **manejo de errores** con botón de reintento
- Animaciones **clean** (transición de abrir/cerrar, pulse en luz, pop en sprite, stagger en cards)

---

## 🧠 API (PokeAPI)
Se usan endpoints públicos (GET):

- Lista:
  - `https://pokeapi.co/api/v2/pokemon?limit=50`
- Detalle:
  - `https://pokeapi.co/api/v2/pokemon/{name}`

Sprites usados en UI (sin pedir otro endpoint):
- `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/{id}.png`

---

## 🧱 Arquitectura (MVVM)
- **Views (UI):**
  - `ContentView.swift`  
    - `PokedexCoverView` (inicio)
    - `PokedexMainView` (grid + scan)
    - `PokemonDetailView` (detalle)
- **ViewModels:**
  - `PokedexViewModel.swift`
    - `PokedexViewModel.loadPokemonList()`
    - `PokemonDetailViewModel.load(name:)`
- **Service (Networking):**
  - `PokeAPIService.swift`
    - `fetchPokemonList(limit:)`
    - `fetchPokemonDetail(name:)`
- **Models (Codable + UI models):**
  - `Models.swift`
    - DTOs: `PokemonListResponse`, `PokemonDetailDTO`, etc.
    - UI models: `PokemonListItem`, `PokemonDetail`

---

## 📐 Conversión de unidades
PokeAPI devuelve:
- `height` en **decímetros** → se convierte a **metros**: `height / 10`
- `weight` en **hectogramos** → se convierte a **kg**: `weight / 10`

Implementado en: `PokemonDetailViewModel.load(name:)` (`PokedexViewModel.swift`)

---

## ✅ Requisitos cubiertos (Activity 5)
- **API diferente** + **GET request real**: `PokeAPIService.swift`
- **JSON parsing (Codable)**: `Models.swift`
- **UI que muestra data + navegación**: `ContentView.swift`
- **Loading + error handling**: `PokedexViewModel.swift` + UI en `ContentView.swift`
- **Código limpio y organizado**: separación por capas (Models / Service / ViewModels / Views)

---

## ▶️ Cómo correr el proyecto
1. Abre el proyecto en **Xcode**
2. Selecciona un simulador (iPhone)
3. Run ▶️

> Recomendado: iOS 17+

---

## 🧩 Notas
- Asegúrate de tener **solo un archivo con `@main`** en el proyecto (`...App.swift`).
- La app requiere internet para obtener la lista y detalles desde PokeAPI.

---

## 📸 Evidencia
- Capturas de pantalla de:
  - Pantalla de inicio (Pokédex cerrada)
  - Grid de Pokémon
  - Detalle de un Pokémon
  - SCAN funcionando (opcional)
