//
//  DetailDiskCache.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import Foundation

/// Snapshot of everything the detail modal shows, taken when favoriting.
nonisolated struct CachedDetailBundle: Codable, Sendable {
    let detail: PokemonDetail
    let species: PokemonSpecies?
    let evolution: [EvolutionStage]
}

/// Saves favorites detail bundles as JSON in Application Support, so their modal still opens when there's no connection.
actor DetailDiskCache {
    static let shared = DetailDiskCache()

    private let directory: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = base.appendingPathComponent("FavoriteDetails", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func save(_ bundle: CachedDetailBundle) {
        guard let data = try? JSONEncoder().encode(bundle) else { return }
        try? data.write(to: fileURL(for: bundle.detail.id), options: .atomic)
    }

    func load(for id: Int) -> CachedDetailBundle? {
        guard let data = try? Data(contentsOf: fileURL(for: id)) else { return nil }
        return try? JSONDecoder().decode(CachedDetailBundle.self, from: data)
    }

    func remove(for id: Int) {
        try? FileManager.default.removeItem(at: fileURL(for: id))
    }

    private func fileURL(for id: Int) -> URL {
        directory.appendingPathComponent("\(id).json")
    }
}
