//
//  PokedexViewModel.swift
//  A00841625_Activity5
//
//  Created by Adan González on 24/02/26.
//

import Foundation
import Combine

@MainActor
final class PokedexViewModel: ObservableObject {
    @Published private(set) var pokemonList: [PokemonListItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let service = PokeAPIService()

    func loadPokemonList() async {
        isLoading = true
        errorMessage = nil

        do {
            let dto = try await service.fetchPokemonList(limit: 50)
            pokemonList = dto.enumerated().map { (offset, item) in
                PokemonListItem(index: offset + 1, name: item.name)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

@MainActor
final class PokemonDetailViewModel: ObservableObject {
    @Published private(set) var pokemon: PokemonDetail? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var spritePop = false

    private let service = PokeAPIService()

    func load(name: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let dto = try await service.fetchPokemonDetail(name: name)

            let heightMeters = Double(dto.height) / 10.0
            let weightKg = Double(dto.weight) / 10.0
            let types = dto.types.map { $0.type.name }

            pokemon = PokemonDetail(
                name: dto.name,
                height: heightMeters,
                weight: weightKg,
                spriteURL: dto.sprites.frontDefault,
                typeNames: types
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

