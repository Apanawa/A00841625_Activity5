//
//  ContentView.swift
//  A00841625_Activity5
//
//  Created by Adan González on 24/02/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = PokedexViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.pokemonList.isEmpty {
                    ProgressView("Cargando Pokédex...")
                } else if let error = vm.errorMessage, vm.pokemonList.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                        Text("Ocurrió un error")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Reintentar") {
                            Task { await vm.loadPokemonList() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List(vm.pokemonList) { item in
                        NavigationLink {
                            PokemonDetailView(name: item.name)
                        } label: {
                            HStack {
                                Text("#\(item.index)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 52, alignment: .leading)

                                Text(item.displayName)
                                    .font(.headline)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Mini Pokédex")
            .task {
                if vm.pokemonList.isEmpty {
                    await vm.loadPokemonList()
                }
            }
            .refreshable {
                await vm.loadPokemonList()
            }
        }
    }
}

// MARK: - Detail View
private struct PokemonDetailView: View {
    let name: String
    @StateObject private var vm = PokemonDetailViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView("Cargando \(name.capitalized)...")
            } else if let error = vm.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.largeTitle)
                    Text("No se pudo cargar")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Reintentar") {
                        Task { await vm.load(name: name) }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if let p = vm.pokemon {
                ScrollView {
                    VStack(spacing: 16) {
                        // Sprite
                        if let urlString = p.spriteURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 200)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                case .failure:
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                        .frame(height: 200)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }

                        Text(p.displayName)
                            .font(.largeTitle)
                            .bold()

                        // Tipos
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tipos")
                                .font(.headline)

                            HStack {
                                ForEach(p.typeNames, id: \.self) { t in
                                    Text(t.capitalized)
                                        .font(.subheadline)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.thinMaterial)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                        // Stats simples
                        VStack(alignment: .leading, spacing: 10) {
                            InfoRow(title: "Altura", value: "\(p.height)m aprox.")
                            InfoRow(title: "Peso", value: "\(p.weight)kg aprox.")
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 20)
                }
            } else {
                Text("Sin datos.")
            }
        }
        .navigationTitle(name.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if vm.pokemon == nil {
                await vm.load(name: name)
            }
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}
