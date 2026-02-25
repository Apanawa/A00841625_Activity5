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

    @State private var isScanning = false
    private struct ScannedSelection: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let index: Int
    }

    @State private var scannedPokemon: ScannedSelection? = nil

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var filtered: [PokemonListItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return vm.pokemonList }
        return vm.pokemonList.filter { $0.name.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                PokedexTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    PokedexTopBar(title: "Mini Pokédex", onClose: onClose)

                    SearchBar(text: $searchText)
                        .padding(.horizontal, 14)
                        .padding(.top, 10)

                    if vm.isLoading && vm.pokemonList.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Cargando Pokémon…")
                                .foregroundStyle(PokedexTheme.secondaryText)
                        }
                        .padding(.top, 40)

                    } else if let error = vm.errorMessage, vm.pokemonList.isEmpty {
                        PokedexErrorCard(message: error) {
                            Task { await vm.loadPokemonList() }
                        }
                        .padding(.top, 22)

                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(filtered) { p in
                                    NavigationLink {
                                        PokemonDetailView(name: p.name, index: p.index)
                                    } label: {
                                        PokemonGridCard(item: p)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                        }
                        .refreshable {
                            await vm.loadPokemonList()
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
            .task {
                if vm.pokemonList.isEmpty {
                    await vm.loadPokemonList()
                }
            }
        }
    }

    private func startScan() {
        guard !vm.pokemonList.isEmpty else { return }
        isScanning = true

        let pool = filtered.isEmpty ? vm.pokemonList : filtered
        let pick = pool.randomElement()

        Task {
            try? await Task.sleep(nanoseconds: 900_000_000) // 0.9s
            isScanning = false
            if let pick {
                scannedPokemon = ScannedSelection(name: pick.name, index: pick.index)
            }
        }
    }
}

// MARK: - DETAIL (misma idea, estilo “pantalla”)
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
                VStack(spacing: 14) {
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
                    .padding(.top, 12)

                    if vm.isLoading {
                        ProgressView("Cargando…")
                            .foregroundStyle(PokedexTheme.secondaryText)
                            .padding(.top, 18)
                    } else if let error = vm.errorMessage {
                        PokedexErrorCard(message: error) {
                            Task { await vm.load(name: name) }
                        }
                        .padding(.horizontal, 14)
                    } else if let p = vm.pokemon {

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
                                            .background(PokedexTheme.chip) // neutro (sin colores por tipo)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 14)

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

// MARK: - GRID CARD
private struct PokemonGridCard: View {
    let item: PokemonListItem

    var body: some View {
        PokedexCard {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(PokedexTheme.screen.opacity(0.30))
                        .frame(height: 110)

                    if let url = URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(item.index).png") {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let img):
                                img.resizable().scaledToFit()
                                    .frame(height: 92)
                            case .failure:
                                Image(systemName: "photo")
                                    .foregroundStyle(PokedexTheme.secondaryText)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }

                Text(item.displayName)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(PokedexTheme.text)
                    .lineLimit(1)

                Text(String(format: "#%03d", item.index))
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(PokedexTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - SMALL UI PIECES
private struct PokedexTopBar: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        ZStack {
            PokedexTheme.red
                .frame(height: 110)
                .overlay(alignment: .topLeading) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(PokedexTheme.blueLight)
                            .frame(width: 42, height: 42)
                            .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 3))

                        HStack(spacing: 8) {
                            Circle().fill(PokedexTheme.redLight).frame(width: 12, height: 12)
                            Circle().fill(PokedexTheme.yellowLight).frame(width: 12, height: 12)
                            Circle().fill(PokedexTheme.greenLight).frame(width: 12, height: 12)
                        }

                        Spacer()

                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white.opacity(0.95))
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                }
                .overlay(alignment: .bottomLeading) {
                    Text(title)
                        .font(.system(.title2, design: .rounded))
                        .bold()
                        .foregroundStyle(.white)
                        .padding(.leading, 16)
                        .padding(.bottom, 12)
                }

            Rectangle()
                .fill(.black.opacity(0.35))
                .frame(height: 6)
                .offset(y: 55)
        }
    }
}

private struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(PokedexTheme.secondaryText)

            TextField("Buscar Pokémon…", text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .foregroundStyle(PokedexTheme.text)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(PokedexTheme.secondaryText)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(PokedexTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.10), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct ScanOverlay: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(PokedexTheme.blueLight.opacity(0.25))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulse ? 1.12 : 0.92)
                        .opacity(pulse ? 0.7 : 0.4)

                    Circle()
                        .stroke(PokedexTheme.blueLight, lineWidth: 4)
                        .frame(width: 80, height: 80)

                    Image(systemName: "viewfinder")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("Escaneando…")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(PokedexTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 10)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = true
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
                .foregroundStyle(PokedexTheme.secondaryText)
            Spacer()
            Text(value)
                .foregroundStyle(PokedexTheme.text)
                .bold()
        }
        .font(.system(.body, design: .rounded))
    }
}

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

// MARK: - THEME
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

