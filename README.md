# Pocket Pokédex

SwiftUI app to browse Pokémon and save favorites. Data comes from the public PokeAPI.

## What it does

- Grid of Pokémon cards, loads 40 at a time with a Load More button
- Filter by type and search by name (search covers the whole Pokédex, not just loaded cards)
- Tap a card for details: stats, moves, lore, evolution chain
- Favorites tab with its own search, sorting and type filter
- Favorited Pokémon keep working offline, their data and images get saved on device
- Light/dark mode toggle

## Structure

MVVM:

- Models: structs matching the API responses
- Services: API client (actor), image cache, favorites persistence
- ViewModels: pagination, filtering and search logic
- Views: the screens plus smaller reusable components

## Run

Open Pokemon.xcodeproj and run, no third party dependencies.

Tests run with Cmd+U. The view models are tested against a mock service so no network is needed.
