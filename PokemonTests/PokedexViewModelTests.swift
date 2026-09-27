//
//  PokedexViewModelTests.swift
//  PokemonTests
//
//  Created by Esther Ramos on 27/09/26.
//

import Testing
import Foundation
@testable import Pokemon

@Suite("PokedexViewModel")
struct PokedexViewModelTests {

    @Test func loadsFirstPage() async {
        let mock = MockDataSource()
        mock.pages = [makeListResponse([(1, "bulbasaur"), (4, "charmander")], hasNext: true)]
        let viewModel = PokedexViewModel(dataSource: mock)

        await viewModel.loadInitial()

        #expect(viewModel.cards.map(\.id) == [1, 4])
        #expect(viewModel.canLoadMore)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func loadMoreAppendsAndStopsAtLastPage() async {
        let mock = MockDataSource()
        mock.pages = [
            makeListResponse([(1, "bulbasaur")], hasNext: true),
            makeListResponse([(2, "ivysaur")], hasNext: false),
        ]
        let viewModel = PokedexViewModel(dataSource: mock)

        await viewModel.loadInitial()
        await viewModel.loadNextPage()

        #expect(viewModel.cards.map(\.id) == [1, 2])
        #expect(viewModel.canLoadMore == false)
    }

    @Test func typeFilterFetchesRosterOnceAndPagesLocally() async {
        let mock = MockDataSource()
        mock.pages = [makeListResponse([(1, "bulbasaur")], hasNext: true)]
        mock.rosters[.fire] = (1...50).map { makeSummary($0 + 100, "fire\($0)") }
        let viewModel = PokedexViewModel(dataSource: mock)
        await viewModel.loadInitial()

        await viewModel.selectType(.fire)
        #expect(viewModel.cards.count == 40)
        #expect(viewModel.canLoadMore)

        await viewModel.loadNextPage()
        #expect(viewModel.cards.count == 50)
        #expect(viewModel.canLoadMore == false)
        #expect(mock.rosterRequestCount == 1)
    }

    @Test func searchFiltersTheFullIndex() async throws {
        let mock = MockDataSource()
        mock.index = [
            makeSummary(1, "bulbasaur"),
            makeSummary(4, "charmander"),
            makeSummary(5, "charmeleon"),
        ]
        let viewModel = PokedexViewModel(dataSource: mock)

        viewModel.searchText = "char"
        try await Task.sleep(for: .milliseconds(700)) // debounce is 300 ms

        #expect(viewModel.cards.map(\.id) == [4, 5])
    }

    @Test func searchCombinesWithTypeFilter() async throws {
        let mock = MockDataSource()
        mock.rosters[.fire] = [makeSummary(4, "charmander"), makeSummary(37, "vulpix")]
        let viewModel = PokedexViewModel(dataSource: mock)

        await viewModel.selectType(.fire)
        viewModel.searchText = "char"
        try await Task.sleep(for: .milliseconds(700))

        #expect(viewModel.cards.map(\.id) == [4])
    }

    @Test func staleLoadIsDiscardedWhenFilterChanges() async {
        let mock = MockDataSource()
        mock.pages = [makeListResponse([(1, "bulbasaur"), (2, "ivysaur")], hasNext: true)]
        mock.rosters[.fire] = [makeSummary(4, "charmander")]
        let gate = Gate()
        mock.cardsGate = gate
        let viewModel = PokedexViewModel(dataSource: mock)

        let staleLoad = Task { await viewModel.loadInitial() }
        try? await Task.sleep(for: .milliseconds(100)) // let it reach the gate
        await viewModel.selectType(.fire)
        await gate.open()
        await staleLoad.value

        #expect(viewModel.cards.map(\.id) == [4])
    }

    @Test func networkFailureSurfacesAnErrorMessage() async {
        let mock = MockDataSource()
        mock.shouldFail = true
        let viewModel = PokedexViewModel(dataSource: mock)

        await viewModel.loadInitial()

        #expect(viewModel.cards.isEmpty)
        #expect(viewModel.errorMessage != nil)
    }
}
