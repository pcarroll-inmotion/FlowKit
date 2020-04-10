//
//  UserService.swift
//  ExampleFlow
//
//  Created by Brian Howard on 4/10/20.
//  Copyright © 2020 InMotion Software. All rights reserved.
//

import Foundation
import PromiseKit

fileprivate var users = [
    User(firstName: "test", lastName: "test", email: "test@test.com", password: "abc123")
]

public struct UserService {

    public enum Error: Swift.Error {
        case invalidCreds
        case duplicateUser
        case invalidEmail
        case invalidPass
    }

    func resetPassword(email: String) -> Promise<Void> {
        guard (users.contains { $0.email == email }) else {
            return Promise(error: Error.invalidEmail)
        }
        return Promise.value(())
    }

    func autenticate(credentials: Credentials) -> Promise<OAuthToken> {
        Promise().map {
            let found = users.first { $0.email.caseInsensitiveCompare(credentials.username) == .orderedSame && $0.password == credentials.password }
            guard let user = found else { throw Error.invalidCreds }
            let jwt = JWT(payload: JWT.Payload(sub: user.userId.uuidString))
            let token = try jwt.token()
            return OAuthToken(token: token, type: "Bearer", expiration: Date())
        }
    }

    func createAccount(user: User) -> Promise<Void> {
        guard !user.email.isEmpty else { return Promise(error: Error.invalidEmail) }
        guard user.password.count >= 8 else { return Promise(error: Error.invalidPass) }
        guard !(users.contains {$0.email.caseInsensitiveCompare(user.email) == .orderedSame }) else { return Promise(error: Error.duplicateUser) }
        users.append(user)
        return Promise.value(())
    }
}

extension UserService.Error: LocalizedError {
    public var description: String {
        switch self {
            case .duplicateUser: return "User already exists"
            case .invalidCreds: return "Invalid credentials"
            case .invalidEmail: return "Invalid Email"
            case .invalidPass: return "Invalid Password"
        }
    }

    /// A localized message describing what error occurred.
    public var errorDescription: String? { return self.description }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { return "reason: \(self.description)" }

    /// A localized message describing how one might recover from the failure.
    public var recoverySuggestion: String? { return nil }

    /// A localized message providing "help" text if the user requests help.
    public var helpAnchor: String? { return nil }
}
