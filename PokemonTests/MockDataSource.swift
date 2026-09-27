//
//  MockDataSource.swift
//  PokemonTests
//
//  Created by Esther Ramos on 27/09/26.
//

import Foundation
@testable import Pokemon

/// Deterministic stand-in for PokeAPIService so no test touches the network.
final class MockDataSource: PokemonDataSource, @unchecked Sendable {
    var pages: [PokemonListResponse] = []
    var rosters: [PokemonType: [PokemonSummary]] = [:]
    var index: [PokemonSummary] = []
    var details: [Int: PokemonDetail] = [:]
    var shouldFail = false
    var cardsGate: Gate?
    private(set) var rosterRequestCount = 0
    private var pageCursor = 0

    func pokemonPage(limit: Int, offset: Int) async throws -> PokemonListResponse {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        guard !pages.isEmpty else { return PokemonListResponse(count: 0, next: nil, results: []) }
        let page = pages[min(pageCursor, pages.count - 1)]
        pageCursor += 1
        return page
    }

    func roster(for type: PokemonType) async throws -> [PokemonSummary] {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        rosterRequestCount += 1
        return rosters[type] ?? []
    }

    func allSummaries() async throws -> [PokemonSummary] {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return index
    }

    func cards(for summaries: [PokemonSummary]) async throws -> [PokemonCardModel] {
        if let gate = cardsGate {
            cardsGate = nil
            await gate.wait()
        }
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return summaries.map { PokemonCardModel(id: $0.id, name: $0.name, types: [.normal]) }
    }

    func detail(for id: Int) async throws -> PokemonDetail {
        guard let detail = details[id] else { throw URLError(.resourceUnavailable) }
        return detail
    }

    func species(for id: Int) async throws -> PokemonSpecies {
        throw URLError(.resourceUnavailable)
    }

    func evolutionStages(fromChainURL urlString: String) async throws -> [EvolutionStage] {
        []
    }
}

/// One-shot latch that holds a mock call open until the test releases it.
actor Gate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }
}

// MARK: - Fixture helpers

func makeSummary(_ id: Int, _ name: String) -> PokemonSummary {
    PokemonSummary(resource: NamedAPIResource(name: name, url: "https://pokeapi.co/api/v2/pokemon/\(id)/"))!
}

func makeListResponse(_ entries: [(Int, String)], hasNext: Bool) -> PokemonListResponse {
    PokemonListResponse(
        count: entries.count,
        next: hasNext ? "https://pokeapi.co/api/v2/pokemon?offset=40" : nil,
        results: entries.map { NamedAPIResource(name: $0.1, url: "https://pokeapi.co/api/v2/pokemon/\($0.0)/") }
    )
}
