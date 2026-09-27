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
    @State private var selectedTab = 0
    @State private var showBackToTop = false
    @State private var galleryScrollPosition = ScrollPosition()

    @AppStorage("appTheme") private var themeRawValue = AppTheme.system.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: themeRawValue) ?? .system
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                PokedexView(
                    viewModel: pokedexViewModel,
                    onSelect: select,
                    showBackToTop: $showBackToTop,
                    scrollPosition: $galleryScrollPosition
                )
                .tabItem {
                    Label("Pokédex", systemImage: "square.grid.2x2")
                }
                .tag(0)
                FavoritesView(onSelect: select)
                    .tabItem {
                        Label("Favorites", systemImage: "heart")
                    }
                    .tag(1)
            }
            .blur(radius: selectedPokemon == nil ? 0 : 8)
            .accessibilityHidden(selectedPokemon != nil)

            // Floats in the free space beside the tab bar capsule.
            if selectedTab == 0, showBackToTop, selectedPokemon == nil {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        galleryScrollPosition.scrollTo(edge: .top)
                    }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(8)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 36)
                .offset(y: 6)
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel("Back to top")
            }

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
