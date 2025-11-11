//
//  AuthService.swift
//  music
//
//  Created by Nikolai Golubkin on 11/9/25.
//

import Foundation
import SwiftUI
import UIKit
import AuthenticationServices
import GoogleSignIn

// MARK: - User Model
struct User {
    let id: String
    let email: String?
    let name: String?
    let nickname: String?
    let avatarUrl: String?
    let provider: AuthProvider
}

// MARK: - API Response Models
struct AuthResponse: Codable {
    let authenticated: Bool
    let userId: String
    let message: String
}

struct UserResponse: Codable {
    let id: String
    let email: String
    let nickname: String?
    let avatarUrl: String?
    let accessLevel: String?
    let isActive: Bool
    let isVerified: Bool
    let lastLoginAt: String?
    let createdAt: String
}

struct AuthRequest: Codable {
    let email: String
    let password: String
}

enum AuthProvider: String, Codable {
    case guest
    case google
    case apple
    case email
}

// MARK: - Protocol (Interface Segregation)
protocol AuthServiceProtocol: ObservableObject {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    
    func signInWithGoogle() async throws
    func signInWithApple(authorization: ASAuthorizationAppleIDCredential) async throws
    func signInWithEmail(email: String, password: String) async throws
    func signOut() async
}

// MARK: - Implementation (Single Responsibility: Authentication)
class AuthService: ObservableObject, AuthServiceProtocol {
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated: Bool = false
    @Published var shouldNavigateToProfile: Bool = false
    
    private let userDefaultsKey = "current_user"
    
    init() {
        loadUser()
    }
    
    var effectiveUser: User {
        if let user = currentUser, user.provider != .guest {
            return user
        }
        // Return guest user by default
        return User(id: "guest", email: nil, name: "Guest", nickname: nil, avatarUrl: nil, provider: .guest)
    }
    
    // Base API URL - same as SongsService
    private var baseURL: String {
        return "https://music-back-g2u6.onrender.com"
    }
    
    func signInWithGoogle() async throws {
        guard let clientID = getGoogleClientID() else {
            throw AuthError.missingGoogleClientID
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Get the root view controller - try multiple approaches
        let rootViewController = await MainActor.run { () -> UIViewController? in
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        if window.isKeyWindow {
                            return window.rootViewController
                        }
                    }
                    // If no key window, try first window
                    if let firstWindow = windowScene.windows.first {
                        return firstWindow.rootViewController
                    }
                }
            }
            return nil
        }
        
        guard let presentingViewController = rootViewController else {
            throw AuthError.noPresentingViewController
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        
        let user = result.user
        guard let idToken = user.idToken?.tokenString else {
            throw AuthError.googleSignInFailed
        }
        
        let profile = user.profile
        
        let authUser = User(
            id: user.userID ?? UUID().uuidString,
            email: profile?.email,
            name: profile?.name,
            nickname: profile?.name,
            avatarUrl: profile?.imageURL(withDimension: 200)?.absoluteString,
            provider: .google
        )
        
        await MainActor.run {
            self.currentUser = authUser
            self.isAuthenticated = true
            saveUser(authUser)
        }
    }
    
    private func getGoogleClientID() -> String? {
        // Try to get from GoogleService-Info.plist
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientID = plist["CLIENT_ID"] as? String {
            return clientID
        }
        
        // Fallback: return nil (user needs to configure)
        return nil
    }
    
    func signInWithApple(authorization: ASAuthorizationAppleIDCredential) async throws {
        let user = User(
            id: authorization.user,
            email: authorization.email,
            name: authorization.fullName?.givenName,
            nickname: authorization.fullName?.givenName,
            avatarUrl: nil,
            provider: .apple
        )
        
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
            saveUser(user)
        }
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        // Basic validation
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        // Basic email validation
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            throw AuthError.invalidEmail
        }
        
        // Step 1: Authenticate with email and password
        let authURL = URL(string: "\(baseURL)/api/v1/auth/authenticate")!
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let authRequest = AuthRequest(email: email, password: password)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(authRequest)
        
        let (authData, authResponse) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = authResponse as? HTTPURLResponse else {
            throw AuthError.authenticationFailed
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw AuthError.invalidCredentials
            }
            throw AuthError.authenticationFailed
        }
        
        let decoder = JSONDecoder()
        let authResult = try decoder.decode(AuthResponse.self, from: authData)
        
        guard authResult.authenticated else {
            throw AuthError.authenticationFailed
        }
        
        // Step 2: Get user information
        let userURL = URL(string: "\(baseURL)/api/v1/users/\(authResult.userId)")!
        var userRequest = URLRequest(url: userURL)
        userRequest.httpMethod = "GET"
        
        let (userData, userResponse) = try await URLSession.shared.data(for: userRequest)
        
        guard let userHttpResponse = userResponse as? HTTPURLResponse,
              (200...299).contains(userHttpResponse.statusCode) else {
            throw AuthError.userInfoFailed
        }
        
        let userResult = try decoder.decode(UserResponse.self, from: userData)
        
        // Create user from API response
        let authUser = User(
            id: userResult.id,
            email: userResult.email,
            name: userResult.nickname ?? userResult.email.components(separatedBy: "@").first,
            nickname: userResult.nickname,
            avatarUrl: userResult.avatarUrl,
            provider: .email
        )
        
        await MainActor.run {
            self.currentUser = authUser
            self.isAuthenticated = true
            self.shouldNavigateToProfile = true
            saveUser(authUser)
        }
    }
    
    func signOut() async {
        // Sign out from Google if signed in with Google
        if currentUser?.provider == .google {
            GIDSignIn.sharedInstance.signOut()
        }
        
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
            self.shouldNavigateToProfile = false
            clearUser()
        }
    }
    
    private func saveUser(_ user: User) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(user) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadUser() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let user = try? JSONDecoder().decode(User.self, from: data),
              user.provider != .guest else {
            // Default to guest user
            currentUser = nil
            isAuthenticated = false
            return
        }
        
        currentUser = user
        isAuthenticated = true
    }
    
    private func clearUser() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case noPresentingViewController
    case missingGoogleClientID
    case googleSignInFailed
    case invalidCredentials
    case invalidEmail
    case weakPassword
    case authenticationFailed
    case userInfoFailed
    
    var errorDescription: String? {
        switch self {
        case .noPresentingViewController:
            return "No presenting view controller available"
        case .missingGoogleClientID:
            return "Google Client ID is missing. Please configure GoogleService-Info.plist"
        case .googleSignInFailed:
            return "Google Sign-In failed"
        case .invalidCredentials:
            return "Invalid email or password"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 6 characters long"
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials and try again."
        case .userInfoFailed:
            return "Failed to retrieve user information. Please try again."
        }
    }
}

// MARK: - User Codable Extension
extension User: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case nickname
        case avatarUrl
        case provider
    }
}

