//
//  ImageCache.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import UIKit

actor ImageCache {
    static let shared = ImageCache()

    /// Max images kept in RAM, roughly 90 MB worth of artwork.
    private let memoryLimit = 100

    private var images: [URL: UIImage] = [:]
    /// Least recently used first.
    private var recency: [URL] = []
    private var inFlight: [URL: Task<UIImage, Error>] = [:]

    private let directory: URL

    init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = base.appendingPathComponent("PokemonImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func image(for url: URL) async throws -> UIImage {
        if let cached = images[url] {
            touch(url)
            return cached
        }
        if let task = inFlight[url] { return try await task.value }

        let fileURL = fileURL(for: url)
        if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
            store(image, for: url)
            return image
        }

        let task = Task<UIImage, Error> {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let image = UIImage(data: data) else {
                throw URLError(.cannotDecodeContentData)
            }
            try? data.write(to: fileURL, options: .atomic)
            return image
        }
        inFlight[url] = task
        defer { inFlight[url] = nil }

        let image = try await task.value
        store(image, for: url)
        return image
    }

    /// Raw GIF data with the same disk caching as regular images. GIFs skip
    /// the RAM tier since only one plays at a time (the open detail modal).
    func gifData(for url: URL) async throws -> Data {
        let fileURL = fileURL(for: url)
        if let data = try? Data(contentsOf: fileURL) { return data }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        try? data.write(to: fileURL, options: .atomic)
        return data
    }

    /// Dumps the RAM tier (called on memory warnings). Disk copies stay put.
    func clearMemory() {
        images.removeAll()
        recency.removeAll()
    }

    // MARK: - LRU bookkeeping

    private func store(_ image: UIImage, for url: URL) {
        images[url] = image
        touch(url)
        while images.count > memoryLimit, let oldest = recency.first {
            recency.removeFirst()
            images.removeValue(forKey: oldest)
        }
    }

    private func touch(_ url: URL) {
        if let index = recency.firstIndex(of: url) {
            recency.remove(at: index)
        }
        recency.append(url)
    }

    private func fileURL(for url: URL) -> URL {
        let name = url.absoluteString
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: "_")
        return directory.appendingPathComponent(name)
    }
}
