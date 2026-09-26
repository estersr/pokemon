//
//  AboutTabView.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import SwiftUI

/// The lore tab: Pokédex entry, training, physical attributes, evolution
/// chain and classification.
struct AboutTabView: View {
    let detail: PokemonDetail
    let species: PokemonSpecies?
    let evolution: [EvolutionStage]
    let onNavigate: (PokemonCardModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            section(icon: "book", tint: .blue, title: "Pokédex Entry") {
                Text(species?.pokedexEntry ?? "No entry available.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            section(icon: "figure.run", tint: .green, title: "Training") {
                Grid(alignment: .leading, horizontalSpacing: 32, verticalSpacing: 12) {
                    GridRow {
                        labeledValue("Base EXP", detail.baseExperience.map(String.init) ?? "—")
                        labeledValue("Catch Rate", species.map { "\($0.captureRate)" } ?? "—")
                    }
                    GridRow {
                        labeledValue("Growth Rate", species?.growthRateText ?? "—")
                    }
                }
            }

            section(icon: "ruler", tint: .indigo, title: "Physical Attributes") {
                Grid(alignment: .leading, horizontalSpacing: 32, verticalSpacing: 12) {
                    GridRow {
                        labeledValue("Height", detail.heightText)
                        labeledValue("Weight", detail.weightText)
                    }
                }
            }

            if evolution.count > 1 {
                section(icon: "arrow.triangle.branch", tint: .purple, title: "Evolution Chain") {
                    evolutionChain
                }
            }

            if let classification = species?.classification {
                section(icon: "sparkles", tint: .pink, title: "Classification") {
                    Text(classification)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.blue.opacity(0.25))
                                )
                        )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionCard()
    }

    private var evolutionChain: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(evolution.enumerated()), id: \.element.id) { index, stage in
                    if index > 0 {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let level = stage.minLevel {
                                Text("Lv. \(level)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    evolutionStageView(stage)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func evolutionStageView(_ stage: EvolutionStage) -> some View {
        let isCurrent = stage.id == detail.id
        return Button {
            guard !isCurrent else { return }
            onNavigate(PokemonCardModel(id: stage.id, name: stage.name, types: []))
        } label: {
            VStack(spacing: 4) {
                PokemonImageView(url: stage.imageURL)
                    .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(isCurrent ? Color.blue.opacity(0.12) : Color.clear)
                        .padding(-4)
                )
                Text(stage.displayName)
                    .font(.caption2.weight(isCurrent ? .semibold : .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint(isCurrent ? "" : "Show \(stage.displayName) details")
    }

    private func section(
        icon: String,
        tint: Color,
        title: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(tint)
                .frame(width: 22)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                content()
            }
            Spacer(minLength: 0)
        }
    }

    private func labeledValue(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}
