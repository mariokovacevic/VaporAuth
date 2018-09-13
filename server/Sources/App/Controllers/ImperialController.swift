/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Vapor
import Imperial
import Authentication

struct ImperialController: RouteCollection {
    
    let redirectURLWithToken = "login-complete?token"
    
    func boot(router: Router) throws {
        guard let googleCallbackURL = Environment.get("GOOGLE_CALLBACK_URL") else { fatalError("Google callback URL not set") }
        guard let facebookCallbackURL = Environment.get("FACEBOOK_CALLBACK_URL") else { fatalError("Facebook callback URL not set") }
        
        try router.oAuth(from: Google.self, authenticate: "google-login", callback: googleCallbackURL, scope: ["profile", "email"], completion: self.processGoogleLogin)
        try router.oAuth(from: Facebook.self, authenticate: "facebook-login", callback: facebookCallbackURL, scope: ["public_profile", "email"], completion: self.processFacebookLogin)
    }
}

// Google
extension ImperialController {
    func processGoogleLogin(request: Request, token: String) throws -> Future<ResponseEncodable> {
        return try self.getGoogleProfile(on: request).flatMap(to: ResponseEncodable.self) { userInfo in
            return User.query(on: request).filter(\.email == userInfo.email).first().flatMap(to: ResponseEncodable.self) { foundUser in
                guard let existingUser = foundUser else {
                    let password = PasswordGenerator.sharedInstance.generateBasicPassword()
                    print("password: \(password)") // TODO: REMOVE
                    let user = User(name: userInfo.name, email: userInfo.email, picture: userInfo.picture, password: password)
                    user.password = try BCrypt.hash(user.password)
                    return user.save(on: request).map(to: ResponseEncodable.self) { user in
                        try request.authenticateSession(user)
                        let token = try Token.generate(for: user)
                        return token.save(on: request).map({ token in
                            return request.redirect(to: "/\(self.redirectURLWithToken)=\(token.token.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")
                        })
                    }
                }
                try request.authenticateSession(existingUser)
                let token = try Token.generate(for: existingUser)
                return token.save(on: request).map({ token in
                    return request.redirect(to: "/\(self.redirectURLWithToken)=\(token.token)")
                })
            }
        }
    }
    
    func getGoogleProfile(on request: Request) throws -> Future<GoogleUserInfo> {
        var headers = HTTPHeaders()
        headers.bearerAuthorization = try BearerAuthorization(token: request.session().accessToken())
        
        let googleAPIURL = "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
        return try request.client().get(googleAPIURL, headers: headers).map(to: GoogleUserInfo.self) { response in
            guard response.http.status == .ok else {
                if response.http.status == .unauthorized {
                    throw Abort.redirect(to: "/google-login")
                } else {
                    throw Abort(.internalServerError)
                }
            }
            return try response.content.syncDecode(GoogleUserInfo.self)
        }
    }
}

// Facebook
extension ImperialController {
    func processFacebookLogin(request: Request, token: String) throws -> Future<ResponseEncodable> {
        return try self.getFacebookProfile(on: request).flatMap(to: ResponseEncodable.self) { userInfo in
            return User.query(on: request).filter(\.email == userInfo.email).first().flatMap(to: ResponseEncodable.self) { foundUser in
                guard let existingUser = foundUser else {
                    let password = PasswordGenerator.sharedInstance.generateBasicPassword()
                    print("password: \(password)") // TODO: REMOVE
                    let user = User(name: userInfo.name, email: userInfo.email, picture: userInfo.picture?.data.url, password: password)
                    user.password = try BCrypt.hash(user.password)
                    return user.save(on: request).map(to: ResponseEncodable.self) { user in
                        try request.authenticateSession(user)
                        let token = try Token.generate(for: user)
                        return token.save(on: request).map({ token in
                            return request.redirect(to: "/\(self.redirectURLWithToken)=\(token.token.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")
                        })
                    }
                }
                try request.authenticateSession(existingUser)
                let token = try Token.generate(for: existingUser)
                return token.save(on: request).map({ token in
                    return request.redirect(to: "/\(self.redirectURLWithToken)=\(token.token)")
                })
            }
        }
    }
    
    func getFacebookProfile(on request: Request) throws -> Future<FacebookUserInfo> {
        let facebookAPIURL = "https://graph.facebook.com/v3.1/me?fields=email,picture.type(large),id,name&access_token=\(try request.accessToken())"
        return try request.client().get(facebookAPIURL).map(to: FacebookUserInfo.self) { response in
            guard response.http.status == .ok else {
                if response.http.status == .unauthorized {
                    throw Abort.redirect(to: "/facebook-login")
                } else {
                    throw Abort(.internalServerError)
                }
            }
            return try response.content.syncDecode(FacebookUserInfo.self)
        }
    }
}

struct GoogleUserInfo: Content {
    let email: String
    let id:String
    let locale:String
    let name: String
    let picture:String?
}

struct FacebookUserInfo: Content {
    let email: String
    let id:String
    let name: String
    let picture: PictureData?
    
    struct PictureData: Content {
        let data: PictureURL
    }
    
    struct PictureURL: Content {
        let url: String
    }
}
