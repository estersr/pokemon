//
//  PokemonDataSource.swift
//  Pokemon
//
//  Created by Esther Ramos on 27/09/26.
//

import Foundation

/// What the view models need from the data layer. The app uses PokeAPIService;
/// tests swap in a mock so no test ever touches the network.
nonisolated protocol PokemonDataSource: Sendable {
    func pokemonPage(limit: Int, offset: Int) async throws -> PokemonListResponse
    func roster(for type: PokemonType) async throws -> [PokemonSummary]
    func allSummaries() async throws -> [PokemonSummary]
    func cards(for summaries: [PokemonSummary]) async throws -> [PokemonCardModel]
    func detail(for id: Int) async throws -> PokemonDetail
    func species(for id: Int) async throws -> PokemonSpecies
    func evolutionStages(fromChainURL urlString: String) async throws -> [EvolutionStage]
}

extension PokeAPIService: PokemonDataSource {}
