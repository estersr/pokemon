//
//  StatsTabView.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import SwiftUI

/// The base stat bars. They fill in one after another when the tab appears.
struct StatsTabView: View {
    let detail: PokemonDetail

    @State private var animateBars = false

    private static let displayOrder: [(key: String, label: String)] = [
        ("hp", "HP"),
        ("attack", "Attack"),
        ("defense", "Defense"),
        ("special-attack", "Sp. Atk"),
        ("special-defense", "Sp. Def"),
        ("speed", "Speed"),
    ]

    private static let maxStatValue = 200.0

    private var accent: Color {
        detail.typeList.first?.color ?? .blue
    }

    private var rows: [(label: String, value: Int)] {
        Self.displayOrder.compactMap { entry in
            detail.stats.first { $0.stat.name == entry.key }.map { (entry.label, $0.baseStat) }
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            ForEach(Array(rows.enumerated()), id: \.element.label) { index, row in
                statRow(row, index: index)
            }
            Divider()
            HStack {
                Text("Total")
                    .font(.headline)
                Spacer()
                Text("\(detail.statTotal)")
                    .font(.headline)
                    .monospacedDigit()
            }
        }
        .padding(16)
        .sectionCard()
        .onAppear { animateBars = true }
    }

    private func statRow(_ row: (label: String, value: Int), index: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(row.label)
                    .font(.subheadline)
                Spacer()
                Text("\(row.value)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            GeometryReader { proxy in
                let fraction = min(1, Double(row.value) / Self.maxStatValue)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(accent.gradient)
                        .frame(width: animateBars ? proxy.size.width * fraction : 0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.06),
                            value: animateBars
                        )
                }
            }
            .frame(height: 8)
        }
    }
}
