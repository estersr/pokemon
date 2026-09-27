//
//  ContentView.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import SwiftUI

struct ContentView: View {
    @State private var favorites = FavoritesStore()
    @State private var pokedexViewModel = PokedexViewModel()
    @State private var selectedPokemon: PokemonCardModel?

    @AppStorage("appTheme") private var themeRawValue = AppTheme.system.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: themeRawValue) ?? .system
    }

    var body: some View {
        ZStack {
            TabView {
                PokedexView(viewModel: pokedexViewModel, onSelect: select)
                    .tabItem {
                        Label("Pokédex", systemImage: "square.grid.2x2")
                    }
                FavoritesView(onSelect: select)
                    .tabItem {
                        Label("Favorites", systemImage: "heart")
                    }
            }
            .blur(radius: selectedPokemon == nil ? 0 : 8)
            .accessibilityHidden(selectedPokemon != nil)

            if let card = selectedPokemon {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { dismissDetail() }

                PokemonDetailModalView(card: card, onClose: dismissDetail, onNavigate: select)
                    .id(card.id)
                    .padding(20)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                    .zIndex(1)
            }

            if let removed = favorites.lastRemoved {
                UndoToast(message: "Removed \(removed.card.displayName)") {
                    favorites.undoRemoval()
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 66)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedPokemon)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: favorites.lastRemoved?.card.id)
        .environment(favorites)
        .preferredColorScheme(theme.colorScheme)
        .task {
            let warnings = NotificationCenter.default.notifications(
                named: UIApplication.didReceiveMemoryWarningNotification
            )
            for await _ in warnings {
                await ImageCache.shared.clearMemory()
            }
        }
    }

    private func select(_ card: PokemonCardModel) {
        dismissKeyboard()
        selectedPokemon = card
        // Warm the animated sprite while the modal animates open.
        if let url = AnimatedSpriteView.spriteURL(for: card.id) {
            Task { _ = try? await ImageCache.shared.gifData(for: url) }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
        )
    }

    private func dismissDetail() {
        selectedPokemon = nil
    }
}

#Preview {
    ContentView()
}
