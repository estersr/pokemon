//
//  TypePowerComparisonView.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import SwiftUI

struct TypePowerComparisonView: View {
    let type: PokemonType
    let cards: [PokemonCardModel]

    @State private var totals: [Int: Int] = [:]
    @State private var animateBars = false
    @State private var isExpanded = false

    private let collapsedCount = 3

    private var ranked: [(card: PokemonCardModel, total: Int)] {
        cards
            .compactMap { card in totals[card.id].map { (card, $0) } }
            .sorted { $0.1 == $1.1 ? $0.0.name < $1.0.name : $0.1 > $1.1 }
    }

    private var maxTotal: Int { ranked.first?.total ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(type.color)
                Text("Power Comparison")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Base stat total")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if ranked.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Comparing…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                let visible = isExpanded ? ranked : Array(ranked.prefix(collapsedCount))
                ForEach(Array(visible.enumerated()), id: \.element.card.id) { index, entry in
                    row(entry, rank: index)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                if ranked.count > collapsedCount {
                    expandButton
                }
            }
        }
        .padding(14)
        .sectionCard()
        .task(id: taskKey) { await loadTotals() }
    }

    /// Re-runs the fetch when the type or the visible cards change.
    private var taskKey: String {
        type.rawValue + "-" + cards.map { String($0.id) }.joined(separator: ",")
    }

    private func loadTotals() async {
        animateBars = false
        var result: [Int: Int] = [:]
        await withTaskGroup(of: (Int, Int)?.self) { group in
            for card in cards {
                group.addTask {
                    if let detail = try? await PokeAPIService.shared.detail(for: card.id) {
                        return (card.id, detail.statTotal)
                    }
                    // Offline fallback. Favorites keep a snapshot on disk.
                    if let cached = await DetailDiskCache.shared.load(for: card.id) {
                        return (card.id, cached.detail.statTotal)
                    }
                    return nil
                }
            }
            for await pair in group {
                if let (id, total) = pair { result[id] = total }
            }
        }
        totals = result
        isExpanded = false
        animateBars = true
    }

    private var expandButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Text(isExpanded ? "Show Less" : "Show \(ranked.count - collapsedCount) More")
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(type.color)
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
        }
        .buttonStyle(.plain)
    }

    private func row(_ entry: (card: PokemonCardModel, total: Int), rank: Int) -> some View {
        HStack(spacing: 10) {
            PokemonImageView(url: entry.card.imageURL)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(entry.card.displayName)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                    if rank == 0 {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.yellow)
                    }
                }
                GeometryReader { proxy in
                    let fraction = maxTotal > 0 ? Double(entry.total) / Double(maxTotal) : 0
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                        Capsule()
                            .fill(type.color.gradient)
                            .frame(width: animateBars ? proxy.size.width * fraction : 0)
                            .animation(
                                .spring(response: 0.55, dampingFraction: 0.8)
                                    .delay(Double(rank) * 0.05),
                                value: animateBars
                            )
                    }
                }
                .frame(height: 6)
            }

            Text("\(entry.total)")
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(type.color)
                .frame(width: 36, alignment: .trailing)
        }
    }
}
