//
//  ModelTests.swift
//  PokemonTests
//
//  Created by Esther Ramos on 27/09/26.
//

import Testing
import Foundation
@testable import Pokemon

@Suite("Models")
struct ModelTests {

    @Test func summaryParsesIDFromResourceURL() {
        #expect(makeSummary(151, "mew").id == 151)
        #expect(PokemonSummary(resource: NamedAPIResource(name: "broken", url: "not-a-url")) == nil)
    }

    @Test func levelUpMovesUseEarliestLevelAndSortByLevel() {
        let detail = makeDetail(moves: [
            move("growl", details: [(1, "level-up"), (9, "level-up")]),
            move("tackle", details: [(1, "level-up")]),
            move("fly", details: [(0, "machine")]),
            move("vine-whip", details: [(13, "level-up"), (3, "level-up")]),
        ])

        #expect(detail.levelUpMoves.map(\.name) == ["growl", "tackle", "vine-whip"])
        #expect(detail.levelUpMoves.map(\.level) == [1, 1, 3])
    }

    @Test func statTotalSumsAllBaseStats() {
        let detail = makeDetail(stats: [("hp", 45), ("attack", 49), ("speed", 45)])
        #expect(detail.statTotal == 139)
    }

    @Test func speciesPicksEnglishEntryAndCleansControlCharacters() {
        let species = PokemonSpecies(
            captureRate: 45,
            flavorTextEntries: [
                .init(flavorText: "Texto em portugues", language: NamedAPIResource(name: "pt", url: "")),
                .init(flavorText: "A strange seed\nwas\u{0C}planted.", language: NamedAPIResource(name: "en", url: "")),
            ],
            genera: [.init(genus: "Seed Pokémon", language: NamedAPIResource(name: "en", url: ""))],
            growthRate: NamedAPIResource(name: "medium-slow", url: ""),
            evolutionChain: nil
        )

        #expect(species.pokedexEntry == "A strange seed was planted.")
        #expect(species.classification == "Seed Pokémon")
        #expect(species.growthRateText == "Medium Slow")
    }

    // MARK: - Fixtures

    private func makeDetail(
        moves: [PokemonDetail.MoveEntry] = [],
        stats: [(String, Int)] = []
    ) -> PokemonDetail {
        PokemonDetail(
            id: 1,
            name: "bulbasaur",
            height: 7,
            weight: 69,
            baseExperience: 64,
            stats: stats.map { PokemonDetail.StatEntry(baseStat: $0.1, stat: NamedAPIResource(name: $0.0, url: "")) },
            types: [],
            abilities: [],
            moves: moves
        )
    }

    private func move(_ name: String, details: [(Int, String)]) -> PokemonDetail.MoveEntry {
        PokemonDetail.MoveEntry(
            move: NamedAPIResource(name: name, url: ""),
            versionGroupDetails: details.map {
                PokemonDetail.VersionGroupDetail(
                    levelLearnedAt: $0.0,
                    moveLearnMethod: NamedAPIResource(name: $0.1, url: "")
                )
            }
        )
    }
}
