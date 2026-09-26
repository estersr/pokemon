//
//  PokeAPIService.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import Foundation

actor PokeAPIService {
    static let shared = PokeAPIService()

    private let baseURL = URL(string: "https://pokeapi.co/api/v2")!
    private let decoder: JSONDecoder

    private var detailCache: [Int: PokemonDetail] = [:]
    private var speciesCache: [Int: PokemonSpecies] = [:]
    private var typeRosterCache: [PokemonType: [PokemonSummary]] = [:]
    private var allSummariesCache: [PokemonSummary]?

    init() {
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    // MARK: - List / gallery

    func pokemonPage(limit: Int = 40, offset: Int) async throws -> PokemonListResponse {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("pokemon"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
        ]
        return try await fetch(components.url!)
    }

    func allSummaries() async throws -> [PokemonSummary] {
        if let allSummariesCache { return allSummariesCache }
        let response = try await pokemonPage(limit: 100000, offset: 0)
        let summaries = response.results
            .compactMap(PokemonSummary.init)
            .filter { $0.id < 10000 }
            .sorted { $0.id < $1.id }
        allSummariesCache = summaries
        return summaries
    }

    /// All Pokémon of a given type. Skips special forms (id >= 10000) since they have no official artwork and mostly duplicate base entries.
    func roster(for type: PokemonType) async throws -> [PokemonSummary] {
        if let cached = typeRosterCache[type] { return cached }
        let response: TypeDetailResponse = try await fetch(
            baseURL.appendingPathComponent("type/\(type.rawValue)")
        )
        let roster = response.pokemon
            .compactMap { PokemonSummary(resource: $0.pokemon) }
            .filter { $0.id < 10000 }
            .sorted { $0.id < $1.id }
        typeRosterCache[type] = roster
        return roster
    }

    /// Turns summaries into card models, fetching details in parallel. One failed Pokémon just gets dropped; we only throw if the whole batch failed.
    func cards(for summaries: [PokemonSummary]) async throws -> [PokemonCardModel] {
        let cards = await withTaskGroup(of: PokemonCardModel?.self) { group in
            for summary in summaries {
                group.addTask {
                    guard let detail = try? await self.detail(for: summary.id) else { return nil }
                    return PokemonCardModel(detail: detail)
                }
            }
            var results: [PokemonCardModel] = []
            for await card in group {
                if let card { results.append(card) }
            }
            return results
        }
        if cards.isEmpty, !summaries.isEmpty {
            throw URLError(.cannotLoadFromNetwork)
        }
        return cards.sorted { $0.id < $1.id }
    }

    // MARK: - Detail / modal

    func detail(for id: Int) async throws -> PokemonDetail {
        if let cached = detailCache[id] { return cached }
        let detail: PokemonDetail = try await fetch(baseURL.appendingPathComponent("pokemon/\(id)"))
        detailCache[id] = detail
        return detail
    }

    func species(for id: Int) async throws -> PokemonSpecies {
        if let cached = speciesCache[id] { return cached }
        let species: PokemonSpecies = try await fetch(
            baseURL.appendingPathComponent("pokemon-species/\(id)")
        )
        speciesCache[id] = species
        return species
    }

    func evolutionStages(fromChainURL urlString: String) async throws -> [EvolutionStage] {
        guard let url = URL(string: urlString) else { return [] }
        let response: EvolutionChainResponse = try await fetch(url)
        var stages: [EvolutionStage] = []
        var current: EvolutionChainResponse.ChainLink? = response.chain
        while let link = current {
            if let id = link.species.resourceID {
                stages.append(
                    EvolutionStage(
                        id: id,
                        name: link.species.name,
                        minLevel: link.evolutionDetails.first?.minLevel
                    )
                )
            }
            current = link.evolvesTo.first
        }
        return stages
    }

    // MARK: - Networking

    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try decoder.decode(T.self, from: data)
    }
}
