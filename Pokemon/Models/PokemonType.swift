//
//  PokemonType.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import SwiftUI

nonisolated enum PokemonType: String, CaseIterable, Identifiable, Codable {
    case normal, fire, water, electric, grass, ice
    case fighting, poison, ground, flying, psychic, bug
    case rock, ghost, dragon, dark, steel, fairy

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .normal: Color(hex: 0xA8A77A)
        case .fire: Color(hex: 0xEE8130)
        case .water: Color(hex: 0x6390F0)
        case .electric: Color(hex: 0xE3B505)
        case .grass: Color(hex: 0x7AC74C)
        case .ice: Color(hex: 0x59B8B4)
        case .fighting: Color(hex: 0xC22E28)
        case .poison: Color(hex: 0xA33EA1)
        case .ground: Color(hex: 0xD9A954)
        case .flying: Color(hex: 0xA98FF3)
        case .psychic: Color(hex: 0xF95587)
        case .bug: Color(hex: 0xA6B91A)
        case .rock: Color(hex: 0xB6A136)
        case .ghost: Color(hex: 0x735797)
        case .dragon: Color(hex: 0x6F35FC)
        case .dark: Color(hex: 0x705746)
        case .steel: Color(hex: 0x8F8FA8)
        case .fairy: Color(hex: 0xD685AD)
        }
    }

    var icon: String {
        switch self {
        case .normal: "circle.fill"
        case .fire: "flame.fill"
        case .water: "drop.fill"
        case .electric: "bolt.fill"
        case .grass: "leaf.fill"
        case .ice: "snowflake"
        case .fighting: "figure.boxing"
        case .poison: "smoke.fill"
        case .ground: "mountain.2.fill"
        case .flying: "wind"
        case .psychic: "brain.head.profile"
        case .bug: "ant.fill"
        case .rock: "circle.hexagongrid.fill"
        case .ghost: "moon.stars.fill"
        case .dragon: "lizard.fill"
        case .dark: "moon.fill"
        case .steel: "gearshape.fill"
        case .fairy: "sparkles"
        }
    }
}
