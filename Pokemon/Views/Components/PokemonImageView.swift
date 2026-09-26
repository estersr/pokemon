//
//  PokemonImageView.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import SwiftUI

struct PokemonImageView: View {
    let url: URL?

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            } else if failed {
                Image(systemName: "questionmark.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
            } else {
                ProgressView()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: image)
        .task(id: url) { await load() }
    }

    private func load() async {
        guard image == nil else { return }
        failed = false
        guard let url else {
            failed = true
            return
        }
        do {
            image = try await ImageCache.shared.image(for: url)
        } catch {
            if !Task.isCancelled { failed = true }
        }
    }
}
