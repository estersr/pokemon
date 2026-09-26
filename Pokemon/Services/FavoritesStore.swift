//
//  FavoritesStore.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class FavoritesStore {
    struct RemovedFavorite {
        let card: PokemonCardModel
        let index: Int
    }

    private(set) var favorites: [PokemonCardModel] = []

    // Hangs around for a few seconds after an unfavorite so the UI can offer Undo.
    private(set) var lastRemoved: RemovedFavorite?

    private var undoDismissTask: Task<Void, Never>?
    private static let storageKey = "favoritePokemon"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode([PokemonCardModel].self, from: data) {
            favorites = saved
        }
    }

    var count: Int { favorites.count }

    func isFavorite(_ id: Int) -> Bool {
        favorites.contains { $0.id == id }
    }

    func toggle(_ card: PokemonCardModel) {
        if let index = favorites.firstIndex(where: { $0.id == card.id }) {
            favorites.remove(at: index)
            offerUndo(for: card, at: index)
            Task { await DetailDiskCache.shared.remove(for: card.id) }
        } else {
            dismissUndo()
            favorites.append(card)
            cacheForOffline(card)
        }
        save()
    }

    func undoRemoval() {
        guard let removed = lastRemoved else { return }
        dismissUndo()
        favorites.insert(removed.card, at: min(removed.index, favorites.count))
        cacheForOffline(removed.card)
        save()
    }

    func dismissUndo() {
        undoDismissTask?.cancel()
        undoDismissTask = nil
        lastRemoved = nil
    }

    private func offerUndo(for card: PokemonCardModel, at index: Int) {
        undoDismissTask?.cancel()
        lastRemoved = RemovedFavorite(card: card, index: index)
        undoDismissTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            lastRemoved = nil
        }
    }

    private func cacheForOffline(_ card: PokemonCardModel) {
        Task {
            guard let detail = try? await PokeAPIService.shared.detail(for: card.id) else { return }
            let species = try? await PokeAPIService.shared.species(for: card.id)
            var evolution: [EvolutionStage] = []
            if let chainURL = species?.evolutionChain?.url {
                evolution = (try? await PokeAPIService.shared.evolutionStages(fromChainURL: chainURL)) ?? []
            }
            await DetailDiskCache.shared.save(
                CachedDetailBundle(detail: detail, species: species, evolution: evolution)
            )

            if let url = card.imageURL {
                _ = try? await ImageCache.shared.image(for: url)
            }
            for stage in evolution {
                if let url = stage.imageURL {
                    _ = try? await ImageCache.shared.image(for: url)
                }
            }
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
