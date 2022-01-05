//
//  ShaarliClient.swift
//  Aarlo
//
//  Created by martinhartl on 05.01.22.
//

import Foundation
import SwiftJWT

final class ShaarliClient {
    enum ClientError: Error {
        case unknownURL
    }

    func load() async throws -> [Link] {
        let claims = ShaarliClaims(iat: .now.addingTimeInterval(-10.0))
        let header = SwiftJWT.Header(typ: "JWT")

        var jwt = SwiftJWT.JWT(header: header, claims: claims)

        let secret = SettingsView.keychain[string: SettingsView.keychainKey] ?? ""
        let jwtSigner = JWTSigner.hs512(key: Data(secret.utf8))
        let signedJWT = try jwt.sign(using: jwtSigner)

        guard let URL = URL(string: "https://hartlco.uber.space/shaarli/index.php/api/v1/links") else {
            throw ClientError.unknownURL
        }
        var request = URLRequest(url: URL)
        request.httpMethod = "GET"

        request.addValue("Bearer " + signedJWT, forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let links = try decoder.decode([Link].self, from: data)

        return links
    }

    func loadMore(offset: Int) async throws -> [Link] {
        guard var URL = URL(string: "https://hartlco.uber.space/shaarli/index.php/api/v1/links") else {
            throw ClientError.unknownURL
        }

        let claims = ShaarliClaims(iat: .now.addingTimeInterval(-10.0))
        let header = SwiftJWT.Header(typ: "JWT")

        var jwt = SwiftJWT.JWT(header: header, claims: claims)

        let secret = SettingsView.keychain[string: SettingsView.keychainKey] ?? ""
        let jwtSigner = JWTSigner.hs512(key: Data(secret.utf8))
        let signedJWT = try jwt.sign(using: jwtSigner)

        URL = URL.appendingQueryParameters(["offset": "\(offset)"])

        var request = URLRequest(url: URL)
        request.httpMethod = "GET"

        request.addValue("Bearer " + signedJWT, forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let links = try decoder.decode([Link].self, from: data)

        return links
    }

    func createLink(link: Link) async throws {
        let claims = ShaarliClaims(iat: .now.addingTimeInterval(-10.0))
        let header = SwiftJWT.Header(typ: "JWT")

        var jwt = SwiftJWT.JWT(header: header, claims: claims)

        let secret = SettingsView.keychain[string: SettingsView.keychainKey] ?? ""
        let jwtSigner = JWTSigner.hs512(key: Data(secret.utf8))
        let signedJWT = try jwt.sign(using: jwtSigner)

        guard let URL = URL(string: "https://hartlco.uber.space/shaarli/index.php/api/v1/links") else {
            throw ClientError.unknownURL
        }
        var request = URLRequest(url: URL)
        request.httpMethod = "POST"
        request.addValue("Bearer " + signedJWT, forHTTPHeaderField: "Authorization")

        let linkData = try JSONEncoder().encode(link)
        request.httpBody = linkData

        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
        let dataString = String(data: data, encoding: .utf8)
        print(dataString)
    }
}
