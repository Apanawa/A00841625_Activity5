//
//  Models.swift
//  A00841625_Activity5
//
//  Created by Adan González on 24/02/26.
//

import Foundation

// MARK: - List response
struct PokemonListResponse: Codable {
    let results: [PokemonListItemDTO]
}

struct PokemonListItemDTO: Codable {
    let name: String
    let url: String
}

// MARK: - Detail response
struct PokemonDetailDTO: Codable {
    let name: String
    let height: Int
    let weight: Int
    let sprites: SpritesDTO
    let types: [PokemonTypeEntryDTO]
}

struct SpritesDTO: Codable {
    let frontDefault: String?

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}

struct PokemonTypeEntryDTO: Codable {
    let type: PokemonTypeDTO
}

struct PokemonTypeDTO: Codable {
    let name: String
}

// MARK: - UI Models
struct PokemonListItem: Identifiable {
    let id = UUID()
    let index: Int
    let name: String

    var displayName: String {
        name.prefix(1).uppercased() + name.dropFirst()
    }
}

struct PokemonDetail {
    let name: String
    let height: Double   // metros aprox.
    let weight: Double   // kg aprox.
    let spriteURL: String?
    let typeNames: [String]

    var displayName: String {
        name.prefix(1).uppercased() + name.dropFirst()
    }
}
