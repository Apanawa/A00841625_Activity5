//
//  ContentView.swift
//  A00841625_Activity5
//
//  Created by Adan González on 24/02/26.
//

import SwiftUI

// MARK: - ROOT (Cover -> Pokedex)
struct ContentView: View {
    @State private var isOpen = false

    var body: some View {
        ZStack {
            PokedexTheme.background.ignoresSafeArea()

            if isOpen {
                PokedexMainView {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
                        isOpen = false
                    }
                }
                .transition(.move(edge: .trailing))
            } else {
                PokedexCoverView {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
                        isOpen = true
                    }
                }
                .transition(.move(edge: .leading))
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.9), value: isOpen)
    }
}

// MARK: - COVER SCREEN
private struct PokedexCoverView: View {
    let onOpen: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            // Pokédex "cuerpo"
            ZStack {
                RoundedRectangle(cornerRadius: 26)
                    .fill(PokedexTheme.red)
                    .frame(height: 280)
                    .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)

                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(PokedexTheme.blueLight)
                            .frame(width: 54, height: 54)
                            .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 4))

                        HStack(spacing: 10) {
                            Circle().fill(PokedexTheme.redLight).frame(width: 14, height: 14)
                            Circle().fill(PokedexTheme.yellowLight).frame(width: 14, height: 14)
                            Circle().fill(PokedexTheme.greenLight).frame(width: 14, height: 14)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)

                    Spacer()

                    // Pantalla
                    RoundedRectangle(cornerRadius: 18)
                        .fill(PokedexTheme.screen.opacity(0.35))
                        .frame(height: 120)
                        .overlay {
                            VStack(spacing: 8) {
                                Text("MINI POKÉDEX")
                                    .font(.system(.title2, design: .rounded))
                                    .bold()
                                    .foregroundStyle(.white)

                                Text("Presiona para abrir")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 20)

                    Spacer(minLength: 14)
                }
            }
            .padding(.horizontal, 18)

            Button(action: onOpen) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("ABRIR POKÉDEX")
                        .font(.system(.headline, design: .rounded))
                        .bold()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(PokedexTheme.red)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.30), radius: 10, x: 0, y: 6)
            }
            .padding(.top, 6)

            Spacer()
        }
    }
}

// MARK: - MAIN POKEDEX (GRID + SCAN + CLOSE)
private struct PokedexMainView: View {
    let onClose: () -> Void

    @StateObject private var vm = PokedexViewModel()
    @State private var searchText: String = ""

    private var filtered: [PokemonListItem] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return vm.pokemonList }
        let q = searchText.lowercased()
        return vm.pokemonList.filter { $0.name.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PokedexTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    PokedexHeader(title: "Mini Pokédex")

                    Group {
                        if vm.isLoading && vm.pokemonList.isEmpty {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Cargando Pokédex…")
                                    .foregroundStyle(PokedexTheme.secondaryText)
                            }
                            .padding(.top, 40)
                        } else if let error = vm.errorMessage, vm.pokemonList.isEmpty {
                            PokedexErrorCard(message: error) {
                                Task { await vm.loadPokemonList() }
                            }
                            .padding(.top, 24)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(filtered) { p in
                                        NavigationLink {
                                            PokemonDetailView(name: p.name, index: p.index)
                                        } label: {
                                            PokemonCardRow(item: p)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 16)
                            }
                        }
                    }
                }

                // SCAN button
                Button {
                    startScan()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 16, weight: .bold))
                        Text("SCAN")
                            .font(.system(.headline, design: .rounded))
                            .bold()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(PokedexTheme.blueLight.opacity(0.95))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
                .disabled(vm.pokemonList.isEmpty || isScanning)

                // Scan overlay
                if isScanning {
                    ScanOverlay()
                        .transition(.opacity)
                }
            }
            // Navegación programática post-scan
            .navigationDestination(item: $scannedPokemon) { p in
                PokemonDetailView(name: p.name, index: p.index)
            }
            .navigationBarHidden(true)
            .task {
                if vm.pokemonList.isEmpty { await vm.loadPokemonList() }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Buscar Pokémon")
    }
}

private struct PokemonCardRow: View {
    let item: PokemonListItem

    var body: some View {
        PokedexCard {
            HStack(spacing: 12) {
                // Sprite
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(PokedexTheme.screen.opacity(0.25))
                        .frame(width: 64, height: 64)

                    if let url = item.spriteURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView().scaleEffect(0.9)
                            case .success(let img):
                                img.resizable().scaledToFit()
                                    .frame(width: 54, height: 54)
                            case .failure:
                                Image(systemName: "photo")
                                    .foregroundStyle(PokedexTheme.secondaryText)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(PokedexTheme.text)

                    Text(String(format: "#%03d", item.index))
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(PokedexTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PokedexTheme.secondaryText)
            }
        }
    }
}

private struct PokemonDetailView: View {
    let name: String
    let index: Int
    @StateObject private var vm = PokemonDetailViewModel()

    private var spriteURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(index).png")
    }

    var body: some View {
        ZStack {
            PokedexTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header tipo “pantalla” de Pokédex
                    PokedexCard {
                        VStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(PokedexTheme.screen.opacity(0.35))
                                .frame(height: 220)
                                .overlay {
                                    if let url = spriteURL {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                            case .success(let img):
                                                img.resizable().scaledToFit()
                                                    .frame(height: 180)
                                            case .failure:
                                                Image(systemName: "photo")
                                                    .font(.largeTitle)
                                                    .foregroundStyle(PokedexTheme.secondaryText)
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    }
                                }

                            Text(name.capitalized)
                                .font(.system(.title, design: .rounded))
                                .bold()
                                .foregroundStyle(PokedexTheme.text)

                            Text(String(format: "#%03d", index))
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(PokedexTheme.secondaryText)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                    if vm.isLoading {
                        ProgressView("Cargando…")
                            .foregroundStyle(PokedexTheme.secondaryText)
                            .padding(.top, 20)
                    } else if let error = vm.errorMessage {
                        PokedexErrorCard(message: error) {
                            Task { await vm.load(name: name) }
                        }
                        .padding(.horizontal, 14)
                    } else if let p = vm.pokemon {
                        // Tipos
                        PokedexCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Tipos")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(PokedexTheme.text)

                                HStack {
                                    ForEach(p.typeNames, id: \.self) { t in
                                        Text(t.capitalized)
                                            .font(.system(.subheadline, design: .rounded))
                                            .foregroundStyle(PokedexTheme.text)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(PokedexTheme.chip)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 14)

                        // Info básica
                        PokedexCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Información")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(PokedexTheme.text)

                                InfoRow(title: "Altura", value: "\(p.height)m aprox.")
                                InfoRow(title: "Peso", value: "\(p.weight)kg aprox.")
                            }
                        }
                        .padding(.horizontal, 14)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Pokédex")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if vm.pokemon == nil { await vm.load(name: name) }
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(PokedexTheme.secondaryText)
            Spacer()
            Text(value)
                .foregroundStyle(PokedexTheme.text)
                .bold()
        }
        .font(.system(.body, design: .rounded))
    }
}

// MARK: - Header (lucecitas estilo pokédex)
private struct PokedexHeader: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                PokedexTheme.red
                    .frame(height: 120)
                    .overlay(alignment: .topLeading) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(PokedexTheme.blueLight)
                                .frame(width: 44, height: 44)
                                .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 3))

                            HStack(spacing: 8) {
                                Circle().fill(PokedexTheme.redLight).frame(width: 12, height: 12)
                                Circle().fill(PokedexTheme.yellowLight).frame(width: 12, height: 12)
                                Circle().fill(PokedexTheme.greenLight).frame(width: 12, height: 12)
                            }
                        }
                        .padding(.top, 18)
                        .padding(.leading, 16)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text(title)
                            .font(.system(.title2, design: .rounded))
                            .bold()
                            .foregroundStyle(.white)
                            .padding(.leading, 16)
                            .padding(.bottom, 14)
                    }

                // Línea negra tipo separación
                Rectangle()
                    .fill(.black.opacity(0.35))
                    .frame(height: 6)
                    .offset(y: 3)
            }
        }
    }
}

// MARK: - Card reusable (pantalla/tarjeta)
private struct PokedexCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PokedexTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
    }
}

private struct PokedexErrorCard: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        PokedexCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(PokedexTheme.yellowLight)
                    Text("Ocurrió un error")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(PokedexTheme.text)
                }

                Text(message)
                    .foregroundStyle(PokedexTheme.secondaryText)
                    .font(.system(.subheadline, design: .rounded))

                Button("Reintentar", action: retry)
                    .buttonStyle(.borderedProminent)
                    .tint(PokedexTheme.red)
            }
        }
        .padding(.horizontal, 14)
    }
}

// MARK: - Theme
private enum PokedexTheme {
    static let background = Color(red: 0.07, green: 0.08, blue: 0.10)
    static let card = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let screen = Color(red: 0.18, green: 0.22, blue: 0.25)

    static let text = Color.white
    static let secondaryText = Color.white.opacity(0.70)

    static let red = Color(red: 0.83, green: 0.12, blue: 0.16)
    static let chip = Color.white.opacity(0.10)

    static let blueLight = Color(red: 0.25, green: 0.75, blue: 0.95)
    static let redLight = Color(red: 0.95, green: 0.25, blue: 0.25)
    static let yellowLight = Color(red: 0.98, green: 0.80, blue: 0.25)
    static let greenLight = Color(red: 0.35, green: 0.85, blue: 0.45)
}
