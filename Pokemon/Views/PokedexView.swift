//
//  PokedexView.swift
//  Pokemon
//
//  Created by Esther Ramos on 25/09/26.
//

import SwiftUI

struct PokedexView: View {
    @Bindable var viewModel: PokedexViewModel
    let onSelect: (PokemonCardModel) -> Void

    @AppStorage("appTheme") private var themeRawValue = AppTheme.system.rawValue

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 240), spacing: 16)]

    private var currentTheme: AppTheme {
        AppTheme(rawValue: themeRawValue) ?? .system
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                searchField
                TypeFilterBar(selected: viewModel.selectedType) { type in
                    Task { await viewModel.selectType(type) }
                }
                content
            }
            .background(Color(.systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await viewModel.loadInitial() }
    }

    private var header: some View {
        HStack {
            Text("Pocket Pokédex")
                .font(.title2.bold())
            Spacer()
            themeMenu
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private var searchField: some View {
        SearchField(placeholder: "Search by name", text: $viewModel.searchText)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isInitialLoading {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(0..<8, id: \.self) { _ in
                        PokemonCardPlaceholder()
                    }
                }
                .padding(.horizontal)
            }
            .scrollDisabled(true)
        } else if let error = viewModel.errorMessage, viewModel.cards.isEmpty {
            ContentUnavailableView {
                Label("Something Went Wrong", systemImage: "wifi.exclamationmark")
            } description: {
                Text(error)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.loadNextPage() }
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.hasLoadedOnce, viewModel.cards.isEmpty {
            emptyResults
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.cards) { card in
                        PokemonCardView(card: card, onViewDetails: { onSelect(card) })
                            .onTapGesture { onSelect(card) }
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }
                }
                .padding(.horizontal)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.cards)

                footer
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
        }
    }

    private var emptyResults: some View {
        Group {
            if viewModel.searchText.isEmpty {
                ContentUnavailableView("No Pokémon Found", systemImage: "questionmark.circle")
            } else {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        if viewModel.canLoadMore {
            Button {
                Task { await viewModel.loadNextPage() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoadingPage {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(viewModel.isLoadingPage ? "Loading…" : "Load More Pokémon")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 26)
                .padding(.vertical, 13)
                .background(Capsule().fill(Color.indigo.gradient))
                .shadow(color: .indigo.opacity(0.35), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingPage)
            .padding(.vertical, 24)
        } else if !viewModel.cards.isEmpty, !viewModel.isFiltering {
            Text("You caught 'em all! 🎉")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 24)
        }
    }

    private var themeMenu: some View {
        Menu {
            Picker("Appearance", selection: $themeRawValue) {
                ForEach(AppTheme.allCases) { theme in
                    Label(theme.label, systemImage: theme.icon)
                        .tag(theme.rawValue)
                }
            }
        } label: {
            Image(systemName: currentTheme.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(9)
                .glassEffect(.regular.interactive(), in: Circle())
                .contentTransition(.symbolEffect(.replace))
        }
    }
}
