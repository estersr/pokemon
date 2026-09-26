//
//  FavoriteHeartButton.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import SwiftUI

struct FavoriteHeartButton: View {
    let isFavorite: Bool
    var background: AnyShapeStyle = AnyShapeStyle(.thinMaterial)
    let action: () -> Void

    @State private var ringScale = 0.4
    @State private var ringOpacity = 0.0

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isFavorite ? Color.pink : Color.secondary)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: isFavorite)
                .scaleEffect(isFavorite ? 1.1 : 1)
                .animation(.bouncy, value: isFavorite)
                .padding(8)
                .background(background, in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.pink, lineWidth: 1.5)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
        .sensoryFeedback(trigger: isFavorite) { _, becameFavorite in
            becameFavorite ? .success : .impact(weight: .light)
        }
        .onChange(of: isFavorite) { _, becameFavorite in
            guard becameFavorite else { return }
            ringScale = 0.4
            ringOpacity = 0.8
            withAnimation(.easeOut(duration: 0.45)) {
                ringScale = 1.9
                ringOpacity = 0
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        FavoriteHeartButton(isFavorite: false) {}
        FavoriteHeartButton(isFavorite: true) {}
    }
    .padding()
}
