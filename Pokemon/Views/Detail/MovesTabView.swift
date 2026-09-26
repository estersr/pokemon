//
//  MovesTabView.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import SwiftUI

/// Level-up moves, lowest level first.
struct MovesTabView: View {
    let detail: PokemonDetail

    private var moves: [PokemonDetail.LevelMove] {
        detail.levelUpMoves
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Level-up Moves")
                .font(.headline)
                .padding(.bottom, 6)

            if moves.isEmpty {
                Text("No level-up moves found.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(moves.enumerated()), id: \.element.id) { index, move in
                    HStack {
                        Text(move.name.displayCased)
                            .font(.subheadline)
                        Spacer()
                        Text("Level \(move.level)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 10)
                    if index < moves.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .sectionCard()
    }
}
