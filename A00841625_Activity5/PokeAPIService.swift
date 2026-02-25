//
//  PokeAPIService.swift
//  A00841625_Activity5
//
//  Created by Adan González on 24/02/26.
//

import Foundation

enum PokeError: LocalizedError {
    case badURL
    case badResponse
    case httpStatus(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .badURL: return "URL inválida."
        case .badResponse: return "Respuesta inválida del servidor."
        case .httpStatus(let code): return "Error HTTP: \(code)"
        case .decodingFailed: return "No se pudo leer la respuesta (decoding)."
        }
    }
}

final class PokeAPIService {
    private let base = "https://pokeapi.co/api/v2"

    func fetchPokemonList(limit: Int = 50) async throws -> [PokemonListItemDTO] {
        guard let url = URL(string: "\(base)/pokemon?limit=\(limit)") else {
            throw PokeError.badURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw PokeError.badResponse }
        guard (200...299).contains(http.statusCode) else { throw PokeError.httpStatus(http.statusCode) }

        do {
            return try JSONDecoder().decode(PokemonListResponse.self, from: data).results
        } catch {
            throw PokeError.decodingFailed
        }
    }

    func fetchPokemonDetail(name: String) async throws -> PokemonDetailDTO {
        guard let url = URL(string: "\(base)/pokemon/\(name.lowercased())") else {
            throw PokeError.badURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw PokeError.badResponse }
        guard (200...299).contains(http.statusCode) else { throw PokeError.httpStatus(http.statusCode) }

        do {
            return try JSONDecoder().decode(PokemonDetailDTO.self, from: data)
        } catch {
            throw PokeError.decodingFailed
        }
    }
}
