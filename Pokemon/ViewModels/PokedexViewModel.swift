//
//  PokedexViewModel.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import Foundation
import Observation

/// Drives the gallery: paging (40 at a time), the type filter and the debounced name search.
@MainActor
@Observable
final class PokedexViewModel {
    private(set) var cards: [PokemonCardModel] = []
    private(set) var selectedType: PokemonType?
    private(set) var isLoadingPage = false
    private(set) var canLoadMore = true
    private(set) var errorMessage: String?
    private(set) var hasLoadedOnce = false

    var searchText = "" {
        didSet {
            guard searchText != oldValue else { return }
            scheduleSearchRefresh()
        }
    }

    var isInitialLoading: Bool { isLoadingPage && cards.isEmpty }
    var isFiltering: Bool { selectedType != nil || !trimmedQuery.isEmpty }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespaces).lowercased()
    }

    private let service: any PokemonDataSource
    private let pageSize = 40

    init(dataSource: any PokemonDataSource = PokeAPIService.shared) {
        self.service = dataSource
    }

    private var offset = 0
    private var roster: [PokemonSummary] = []
    private var rosterIndex = 0

    private var generation = 0
    private var searchTask: Task<Void, Never>?

    func loadInitial() async {
        guard cards.isEmpty, !isLoadingPage else { return }
        await loadNextPage()
    }

    func selectType(_ type: PokemonType?) async {
        guard type != selectedType else { return }
        selectedType = type
        await refresh()
    }

    private func scheduleSearchRefresh() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    private func refresh() async {
        generation += 1
        cards = []
        offset = 0
        roster = []
        rosterIndex = 0
        canLoadMore = true
        errorMessage = nil
        isLoadingPage = false
        await loadNextPage()
    }

    func loadNextPage() async {
        guard !isLoadingPage, canLoadMore else { return }
        let currentGeneration = generation
        isLoadingPage = true
        errorMessage = nil
        defer {
            if currentGeneration == generation {
                isLoadingPage = false
                hasLoadedOnce = true
            }
        }

        do {
            let summaries: [PokemonSummary]
            let moreAvailable: Bool

            if isFiltering {
                if roster.isEmpty, rosterIndex == 0 {
                    let built = try await buildRoster()
                    guard currentGeneration == generation else { return }
                    roster = built
                }
                let end = min(rosterIndex + pageSize, roster.count)
                summaries = Array(roster[rosterIndex..<end])
                rosterIndex = end
                moreAvailable = end < roster.count
            } else {
                let page = try await service.pokemonPage(limit: pageSize, offset: offset)
                guard currentGeneration == generation else { return }
                summaries = page.results.compactMap(PokemonSummary.init)
                offset += pageSize
                moreAvailable = page.next != nil
            }

            let newCards = try await service.cards(for: summaries)
            guard currentGeneration == generation else { return }
            cards.append(contentsOf: newCards)
            canLoadMore = moreAvailable && !summaries.isEmpty
        } catch {
            guard currentGeneration == generation else { return }
            errorMessage = "Couldn't load Pokémon. Check your connection and try again."
        }
    }

    private func buildRoster() async throws -> [PokemonSummary] {
        var base: [PokemonSummary]
        if let selectedType {
            base = try await service.roster(for: selectedType)
        } else {
            base = try await service.allSummaries()
        }
        let query = trimmedQuery
        if !query.isEmpty {
            base = base.filter { $0.name.contains(query) }
        }
        return base
    }
}
