//
//  UndoToast.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import SwiftUI

struct UndoToast: View {
    let message: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.slash.fill")
                .foregroundStyle(.pink)
            Text(message)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            Spacer(minLength: 8)
            Button("Undo", action: action)
                .font(.subheadline.weight(.bold))
                .tint(.pink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: 400)
        .padding(.horizontal, 24)
    }
}

#Preview {
    UndoToast(message: "Removed Charizard") {}
}
