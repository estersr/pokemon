//
//  FavoritesView.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import SwiftUI

enum FavoritesSort: String, CaseIterable, Identifiable {
    case recentlyAdded = "Recently Added"
    case number = "Number"
    case name = "Name"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .recentlyAdded: "clock"
        case .number: "number"
        case .name: "a.circle"
        }
    }
}

struct FavoritesView: View {
    @Environment(FavoritesStore.self) private var favorites

    let onSelect: (PokemonCardModel) -> Void

    @State private var selectedType: PokemonType?
    @State private var searchText = ""
    @AppStorage("favoritesSort") private var sortRawValue = FavoritesSort.recentlyAdded.rawValue

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 240), spacing: 16)]

    private var sort: FavoritesSort {
        FavoritesSort(rawValue: sortRawValue) ?? .recentlyAdded
    }

    private var sortBinding: Binding<FavoritesSort> {
        Binding(
            get: { sort },
            set: { sortRawValue = $0.rawValue }
        )
    }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespaces).lowercased()
    }

    private var availableTypes: [PokemonType] {
        PokemonType.allCases.filter { type in
            favorites.favorites.contains { $0.types.contains(type) }
        }
    }

    private var typeCounts: [PokemonType: Int] {
        var counts: [PokemonType: Int] = [:]
        for card in favorites.favorites {
            for type in card.types {
                counts[type, default: 0] += 1
            }
        }
        return counts
    }

    private var displayedFavorites: [PokemonCardModel] {
        var result = favorites.favorites
        if let selectedType {
            result = result.filter { $0.types.contains(selectedType) }
        }
        if !trimmedQuery.isEmpty {
            result = result.filter { $0.name.contains(trimmedQuery) }
        }
        switch sort {
        case .recentlyAdded: return result.reversed()
        case .number: return result.sorted { $0.id < $1.id }
        case .name: return result.sorted { $0.name < $1.name }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                if favorites.favorites.isEmpty {
                    ContentUnavailableView {
                        Label("No Favorites Yet", systemImage: "heart")
                    } description: {
                        Text("Tap the heart on any Pokémon card to keep it here.")
                    }
                } else {
                    SearchField(placeholder: "Search favorites", text: $searchText)

                    if availableTypes.count > 1 {
                        TypeFilterBar(selected: selectedType, types: availableTypes, counts: typeCounts) { type in
                            selectedType = type
                        }
                    }

                    if displayedFavorites.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        ScrollView {
                            if let selectedType, displayedFavorites.count >= 2 {
                                TypePowerComparisonView(type: selectedType, cards: displayedFavorites)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(displayedFavorites) { card in
                                    PokemonCardView(card: card, onViewDetails: { onSelect(card) })
                                        .onTapGesture { onSelect(card) }
                                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: displayedFavorites)
                        }
                        .scrollIndicators(.hidden)
                        .scrollDismissesKeyboard(.immediately)
                        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedType)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: favorites.favorites) {
                // If the last Pokémon of the selected type just got removed,drop back to All.
                if let type = selectedType,
                   !favorites.favorites.contains(where: { $0.types.contains(type) }) {
                    selectedType = nil
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("Favorites")
                .font(.title2.bold())
            if favorites.count > 0 {
                Text("\(favorites.count)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.pink.gradient))
                    .contentTransition(.numericText())
                    .transition(.scale.combined(with: .opacity))
            }
            Spacer()
            if !favorites.favorites.isEmpty {
                sortMenu
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .animation(.bouncy, value: favorites.count)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort by", selection: sortBinding) {
                ForEach(FavoritesSort.allCases) { option in
                    Label(option.rawValue, systemImage: option.icon)
                        .tag(option)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(9)
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .accessibilityLabel("Sort favorites")
    }
}
