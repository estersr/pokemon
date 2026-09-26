//
//  TypeFilterBar.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import SwiftUI

struct TypeFilterBar: View {
    let selected: PokemonType?
    var types: [PokemonType] = PokemonType.allCases
    var counts: [PokemonType: Int]? = nil
    let onSelect: (PokemonType?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(
                    title: "All",
                    icon: "square.grid.2x2.fill",
                    color: .indigo,
                    count: nil,
                    isSelected: selected == nil
                ) {
                    onSelect(nil)
                }
                ForEach(types) { type in
                    chip(
                        title: type.displayName,
                        icon: type.icon,
                        color: type.color,
                        count: counts?[type],
                        isSelected: selected == type
                    ) {
                        onSelect(type)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selected)
    }

    private func chip(
        title: String,
        icon: String,
        color: Color,
        count: Int?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline.weight(.medium))
                if let count {
                    Text("\(count)")
                        .font(.caption2.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(isSelected ? color : Color.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(isSelected ? Color.white : color.opacity(0.85)))
                        .contentTransition(.numericText())
                }
            }
            .foregroundStyle(isSelected ? Color.white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(isSelected ? AnyShapeStyle(color.gradient) : AnyShapeStyle(color.opacity(0.13)))
            )
            .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.06 : 1)
    }
}

#Preview {
    TypeFilterBar(selected: .fire, counts: [.fire: 3, .water: 1]) { _ in }
}
