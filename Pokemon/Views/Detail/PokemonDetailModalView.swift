//
//  PokemonDetailModalView.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import SwiftUI

enum DetailTab: String, CaseIterable {
    case stats = "Stats"
    case moves = "Moves"
    case about = "About"
}

/// The detail modal. Hero summary on top, then the Stats / Moves / About tabs.
struct PokemonDetailModalView: View {
    @Environment(FavoritesStore.self) private var favorites

    @State private var viewModel: PokemonDetailViewModel
    @State private var selectedTab: DetailTab = .stats

    private let onClose: () -> Void
    private let onNavigate: (PokemonCardModel) -> Void

    init(
        card: PokemonCardModel,
        onClose: @escaping () -> Void,
        onNavigate: @escaping (PokemonCardModel) -> Void
    ) {
        _viewModel = State(initialValue: PokemonDetailViewModel(card: card))
        self.onClose = onClose
        self.onNavigate = onNavigate
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isShowingCachedData {
                        offlineBanner
                    }
                    heroCard
                    DetailTabPicker(selection: $selectedTab)
                    tabContent
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: 560, maxHeight: 720)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(.systemBackground)))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.25), radius: 30, y: 10)
        .task { await viewModel.load() }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text("Pokémon Details")
                .font(.headline)
            HStack {
                favoriteButton
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color(.secondarySystemBackground), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var favoriteButton: some View {
        FavoriteHeartButton(
            isFavorite: favorites.isFavorite(viewModel.card.id),
            background: AnyShapeStyle(Color(.secondarySystemBackground))
        ) {
            withAnimation(.bouncy) {
                favorites.toggle(viewModel.currentCard)
            }
        }
    }

    private var offlineBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.slash")
            Text("Offline — showing saved data")
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.orange)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.orange.opacity(0.12)))
    }

    // MARK: - Hero summary

    private var heroCard: some View {
        let detail = viewModel.detail
        let types = detail?.typeList ?? viewModel.card.types
        let accent = types.first?.color ?? .blue

        return VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.14))
                        .frame(width: 116, height: 116)
                    PokemonImageView(url: viewModel.card.imageURL)
                        .frame(width: 100, height: 100)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.card.formattedNumber)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(viewModel.card.displayName)
                        .font(.title2.bold())
                    HStack(spacing: 6) {
                        ForEach(types) { type in
                            TypeChipView(type: type)
                        }
                    }
                }
                Spacer(minLength: 0)
            }

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                GridRow {
                    infoItem(icon: "ruler", tint: .blue, title: "Height", value: detail?.heightText ?? "—")
                    infoItem(icon: "scalemass", tint: .green, title: "Weight", value: detail?.weightText ?? "—")
                }
                GridRow {
                    infoItem(
                        icon: "bolt.fill",
                        tint: .yellow,
                        title: "Abilities",
                        value: detail.map { $0.abilityNames.joined(separator: ", ") } ?? "—"
                    )
                    infoItem(
                        icon: "star",
                        tint: .purple,
                        title: "Hidden Ability",
                        value: detail?.hiddenAbilityName ?? "—"
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.10), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color(.separator).opacity(0.4))
                )
        )
    }

    private func infoItem(icon: String, tint: Color, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(tint)
                .frame(width: 16)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "—" : value)
                    .font(.subheadline.weight(.medium))
            }
        }
        .gridColumnAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Tabs

    @ViewBuilder
    private var tabContent: some View {
        if let detail = viewModel.detail {
            Group {
                switch selectedTab {
                case .stats:
                    StatsTabView(detail: detail)
                case .moves:
                    MovesTabView(detail: detail)
                case .about:
                    AboutTabView(
                        detail: detail,
                        species: viewModel.species,
                        evolution: viewModel.evolution,
                        onNavigate: onNavigate
                    )
                }
            }
            .id(selectedTab)
            .transition(
                .asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 12)),
                    removal: .opacity
                )
            )
            .animation(.easeOut(duration: 0.22), value: selectedTab)
        } else if let error = viewModel.errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 50)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 80)
        }
    }
}

/// Segmented control with the sliding selection pill.
struct DetailTabPicker: View {
    @Binding var selection: DetailTab
    @Namespace private var pillNamespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        selection = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline.weight(selection == tab ? .semibold : .regular))
                        .foregroundStyle(selection == tab ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if selection == tab {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                                    .matchedGeometryEffect(id: "selectionPill", in: pillNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
    }
}
