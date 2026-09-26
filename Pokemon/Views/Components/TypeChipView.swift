//
//  TypeChipView.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import SwiftUI

struct TypeChipView: View {
    let type: PokemonType

    var body: some View {
        Text(type.displayName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(type.color.gradient))
    }
}

#Preview {
    HStack {
        TypeChipView(type: .grass)
        TypeChipView(type: .poison)
        TypeChipView(type: .fire)
    }
    .padding()
}
