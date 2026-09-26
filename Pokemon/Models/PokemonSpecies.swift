//
//  PokemonSpecies.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import Foundation

/// Species data: lore/flavor text, training info and the link to the evolution chain.
nonisolated struct PokemonSpecies: Codable, Sendable {
    let captureRate: Int
    let flavorTextEntries: [FlavorText]
    let genera: [Genus]
    let growthRate: NamedAPIResource
    let evolutionChain: ResourceLink?

    struct FlavorText: Codable, Sendable {
        let flavorText: String
        let language: NamedAPIResource
    }

    struct Genus: Codable, Sendable {
        let genus: String
        let language: NamedAPIResource
    }

    struct ResourceLink: Codable, Sendable {
        let url: String
    }

    var pokedexEntry: String? {
        flavorTextEntries
            .first { $0.language.name == "en" }?
            .flavorText
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\u{0C}", with: " ")
    }

    var classification: String? {
        genera.first { $0.language.name == "en" }?.genus
    }

    var growthRateText: String {
        growthRate.name.displayCased
    }
}

// MARK: - Evolution chain

nonisolated struct EvolutionChainResponse: Codable, Sendable {
    let chain: ChainLink

    struct ChainLink: Codable, Sendable {
        let species: NamedAPIResource
        let evolvesTo: [ChainLink]
        let evolutionDetails: [EvolutionDetail]
    }

    struct EvolutionDetail: Codable, Sendable {
        let minLevel: Int?
    }
}

nonisolated struct EvolutionStage: Identifiable, Hashable, Codable, Sendable {
    let id: Int
    let name: String
    let minLevel: Int?

    var displayName: String { name.displayCased }
    var imageURL: URL? { PokemonCardModel.artworkURL(for: id) }
}
