//
//  PokemonDetailViewModel.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import Foundation
import Observation

/// Loads what the modal needs: the full detail, species lore and the evolution chain.
@MainActor
@Observable
final class PokemonDetailViewModel {
    let card: PokemonCardModel

    private(set) var detail: PokemonDetail?
    private(set) var species: PokemonSpecies?
    private(set) var evolution: [EvolutionStage] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var isShowingCachedData = false

    private let service = PokeAPIService.shared

    init(card: PokemonCardModel) {
        self.card = card
    }

    var currentCard: PokemonCardModel {
        detail.map(PokemonCardModel.init) ?? card
    }

    func load() async {
        guard detail == nil, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            detail = try await service.detail(for: card.id)
            let species = try await service.species(for: card.id)
            self.species = species
            if let chainURL = species.evolutionChain?.url {
                evolution = (try? await service.evolutionStages(fromChainURL: chainURL)) ?? []
            }
        } catch {
            // Offline fallback. Favorites keep a snapshot on disk.
            if detail == nil, let cached = await DetailDiskCache.shared.load(for: card.id) {
                detail = cached.detail
                species = cached.species
                evolution = cached.evolution
                isShowingCachedData = true
            } else if detail == nil {
                errorMessage = "Couldn't load details for \(card.displayName)."
            }
        }
        isLoading = false
    }
}
