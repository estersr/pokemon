//
//  FavoritesStoreTests.swift
//  PokemonTests
//
//  Created by Esther Ramos on 27/09/26.
//

import Testing
import Foundation
@testable import Pokemon

@Suite("FavoritesStore")
struct FavoritesStoreTests {

    private func makeStore() -> FavoritesStore {
        let defaults = UserDefaults(suiteName: "FavoritesStoreTests-\(UUID().uuidString)")!
        return FavoritesStore(defaults: defaults, dataSource: MockDataSource())
    }

    @Test func togglingAddsAndRemoves() {
        let store = makeStore()
        let card = PokemonCardModel(id: 6, name: "charizard", types: [.fire, .flying])

        store.toggle(card)
        #expect(store.isFavorite(6))
        #expect(store.count == 1)

        store.toggle(card)
        #expect(!store.isFavorite(6))
        #expect(store.lastRemoved?.card.id == 6)
    }

    @Test func undoRestoresOriginalPosition() {
        let store = makeStore()
        store.toggle(PokemonCardModel(id: 1, name: "bulbasaur", types: [.grass]))
        store.toggle(PokemonCardModel(id: 4, name: "charmander", types: [.fire]))
        store.toggle(PokemonCardModel(id: 7, name: "squirtle", types: [.water]))

        store.toggle(PokemonCardModel(id: 4, name: "charmander", types: [.fire]))
        #expect(store.favorites.map(\.id) == [1, 7])

        store.undoRemoval()
        #expect(store.favorites.map(\.id) == [1, 4, 7])
        #expect(store.lastRemoved == nil)
    }

    @Test func favoritesSurviveRelaunch() {
        let defaults = UserDefaults(suiteName: "FavoritesStoreTests-\(UUID().uuidString)")!
        let store = FavoritesStore(defaults: defaults, dataSource: MockDataSource())
        store.toggle(PokemonCardModel(id: 25, name: "pikachu", types: [.electric]))

        let reloaded = FavoritesStore(defaults: defaults, dataSource: MockDataSource())
        #expect(reloaded.favorites.map(\.id) == [25])
    }

    @Test func favoritingAgainDismissesPendingUndo() {
        let store = makeStore()
        let card = PokemonCardModel(id: 133, name: "eevee", types: [.normal])
        store.toggle(card)
        store.toggle(card) // removed — undo pending
        #expect(store.lastRemoved != nil)

        store.toggle(PokemonCardModel(id: 1, name: "bulbasaur", types: [.grass]))
        #expect(store.lastRemoved == nil)
    }
}
