//
//  PokemonModels.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import Foundation


// MARK: - Generic PokéAPI resources

nonisolated struct NamedAPIResource: Codable, Hashable {
    let name: String
    let url: String

    /// PokeAPI resource URLs end in .../{id}/, so we can pull the id from there.
    var resourceID: Int? {
        url.split(separator: "/").compactMap { Int($0) }.last
    }
}

nonisolated struct PokemonListResponse: Codable {
    let count: Int
    let next: String?
    let results: [NamedAPIResource]
}

nonisolated struct TypeDetailResponse: Codable {
    let pokemon: [Entry]

    struct Entry: Codable {
        let pokemon: NamedAPIResource
    }
}

// MARK: - Lightweight list models

nonisolated struct PokemonSummary: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String

    init?(resource: NamedAPIResource) {
        guard let id = resource.resourceID else { return nil }
        self.id = id
        self.name = resource.name
    }
}

/// Everything a grid card needs to render. Also what we persist for favorites.
nonisolated struct PokemonCardModel: Identifiable, Hashable, Codable, Sendable {
    let id: Int
    let name: String
    let types: [PokemonType]

    var displayName: String { name.displayCased }
    var formattedNumber: String { String(format: "#%03d", id) }
    var imageURL: URL? { Self.artworkURL(for: id) }

    static func artworkURL(for id: Int) -> URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png")
    }
}

extension PokemonCardModel {
    nonisolated init(detail: PokemonDetail) {
        self.init(id: detail.id, name: detail.name, types: detail.typeList)
    }
}

// MARK: - Full detail (modal)

nonisolated struct PokemonDetail: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let height: Int // decimetres
    let weight: Int // hectograms
    let baseExperience: Int?
    let stats: [StatEntry]
    let types: [TypeEntry]
    let abilities: [AbilityEntry]
    let moves: [MoveEntry]

    struct StatEntry: Codable, Sendable {
        let baseStat: Int
        let stat: NamedAPIResource
    }

    struct TypeEntry: Codable, Sendable {
        let slot: Int
        let type: NamedAPIResource
    }

    struct AbilityEntry: Codable, Sendable {
        let isHidden: Bool
        let ability: NamedAPIResource
    }

    struct MoveEntry: Codable, Sendable {
        let move: NamedAPIResource
        let versionGroupDetails: [VersionGroupDetail]
    }

    struct VersionGroupDetail: Codable, Sendable {
        let levelLearnedAt: Int
        let moveLearnMethod: NamedAPIResource
    }

    var typeList: [PokemonType] {
        types.sorted { $0.slot < $1.slot }.compactMap { PokemonType(rawValue: $0.type.name) }
    }

    var heightText: String { "\((Double(height) / 10).formatted()) m" }
    var weightText: String { "\((Double(weight) / 10).formatted()) kg" }

    var abilityNames: [String] {
        abilities.filter { !$0.isHidden }.map { $0.ability.name.displayCased }
    }

    var hiddenAbilityName: String? {
        abilities.first { $0.isHidden }?.ability.name.displayCased
    }

    var statTotal: Int {
        stats.map(\.baseStat).reduce(0, +)
    }

    struct LevelMove: Identifiable, Hashable, Sendable {
        let name: String
        let level: Int
        var id: String { name }
    }

    /// Level-up moves only, each at the earliest level it shows up.
    var levelUpMoves: [LevelMove] {
        moves.compactMap { entry in
            let levels = entry.versionGroupDetails
                .filter { $0.moveLearnMethod.name == "level-up" }
                .map(\.levelLearnedAt)
                .filter { $0 > 0 }
            guard let level = levels.min() else { return nil }
            return LevelMove(name: entry.move.name, level: level)
        }
        .sorted { $0.level == $1.level ? $0.name < $1.name : $0.level < $1.level }
    }
}
