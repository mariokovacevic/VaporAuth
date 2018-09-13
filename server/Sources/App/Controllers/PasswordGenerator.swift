//
//  PasswordGenerator.swift
//  DogCarePackageDescription
//
//  Created by Mario Kovacevic on 01/02/2018.
//

import Foundation

public typealias CharactersArray = [Character]
public typealias CharactersHash = [CharactersGroup : CharactersArray]

public enum CharactersGroup {
    case letters
    case numbers
    case punctuation
    case symbols
    
    public static var groups: [CharactersGroup] {
        get {
            return [.letters, .numbers, .punctuation, .symbols]
        }
    }
    
    private static func charactersString(group: CharactersGroup) -> String {
        switch group {
        case .letters:
            return "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        case .numbers:
            return "0123456789"
        case .punctuation:
            return ".!?"
        case .symbols:
            return ";,&%$@#^*~"
        }
    }
    
    private static func characters(group: CharactersGroup) -> CharactersArray {
        var array: CharactersArray = []
        
        let string = charactersString(group: group)
        assert(string.count > 0)
        var index = string.startIndex
        
        while index != string.endIndex {
            let character = string[index]
            array.append(character)
            index = string.index(index, offsetBy: 1)
        }
        
        return array
    }
    
    public static var hash: CharactersHash {
        get {
            var hash: CharactersHash = [:]
            for group in groups {
                hash[group] = characters(group: group)
            }
            return hash
        }
    }
    
}

public class PasswordGenerator {
    
    private var hash: CharactersHash = [:]
    
    public static let sharedInstance = PasswordGenerator()
    
    private init() {
        self.hash = CharactersGroup.hash
    }
    
    public func generateBasicPassword() -> String {
        return generatePassword(includeNumbers: true, includePunctuation: false, includeSymbols: false, length: 8)
    }
    
    public func generateComplexPassword() -> String {
        return generatePassword(includeNumbers: true, includePunctuation: true, includeSymbols: true, length: 16)
    }
    
    private func charactersForGroup(group: CharactersGroup) -> CharactersArray {
        if let characters = hash[group] {
            return characters
        }
        assertionFailure("Characters should always be defined")
        return []
    }
    
    public func generatePassword(includeNumbers: Bool = true, includePunctuation: Bool = true, includeSymbols: Bool = true, length: Int = 16) -> String {
        
        var characters: CharactersArray = []
        characters.append(contentsOf: charactersForGroup(group: .letters))
        if includeNumbers {
            characters.append(contentsOf: charactersForGroup(group: .numbers))
        }
        if includePunctuation {
            characters.append(contentsOf: charactersForGroup(group: .punctuation))
        }
        if includeSymbols {
            characters.append(contentsOf: charactersForGroup(group: .symbols))
        }
        
        var passwordArray: CharactersArray = []
        
        while passwordArray.count < length {
            let index = Int(arc4random()) % (characters.count - 1)
            passwordArray.append(characters[index])
        }
        
        let password = String(passwordArray)
        
        return password
    }
}
