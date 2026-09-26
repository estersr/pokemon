//
//  PokemonCardView.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import SwiftUI

struct PokemonCardView: View {
    let card: PokemonCardModel
    var onViewDetails: (() -> Void)? = nil

    @Environment(FavoritesStore.self) private var favorites

    private var accent: Color { card.types.first?.color ?? .gray }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 110, height: 110)
                artwork
                    .frame(width: 94, height: 94)
            }
            .frame(maxWidth: .infinity)

            Text(card.formattedNumber)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(card.displayName)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack(spacing: 6) {
                ForEach(card.types) { type in
                    TypeChipView(type: type)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.16), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                )
                .shadow(color: .black.opacity(0.07), radius: 8, y: 4)
        )
        .overlay(alignment: .topTrailing) {
            favoriteButton.padding(8)
        }
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .contextMenu {
            Button {
                withAnimation(.bouncy) {
                    favorites.toggle(card)
                }
            } label: {
                if favorites.isFavorite(card.id) {
                    Label("Remove from Favorites", systemImage: "heart.slash")
                } else {
                    Label("Add to Favorites", systemImage: "heart")
                }
            }
            if let onViewDetails {
                Button(action: onViewDetails) {
                    Label("View Details", systemImage: "info.circle")
                }
            }
        }
    }

    private var artwork: some View {
        PokemonImageView(url: card.imageURL)
    }

    private var favoriteButton: some View {
        FavoriteHeartButton(isFavorite: favorites.isFavorite(card.id)) {
            withAnimation(.bouncy) {
                favorites.toggle(card)
            }
        }
    }
}

struct PokemonCardPlaceholder: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 110, height: 110)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 46, height: 10)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 90, height: 14)
            Capsule()
                .fill(Color(.systemGray5))
                .frame(width: 70, height: 20)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .opacity(pulse ? 0.45 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
