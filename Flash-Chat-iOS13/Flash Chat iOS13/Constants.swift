//
//  Constants.swift
//  Flash Chat iOS13
//
//  Created by Roman on 18.02.2025.
//  Copyright © 2025 Angela Yu. All rights reserved.
//

struct K {
    static let appName = "⚡️FlashChat"
    static let cellIdentifier = "ReusableCell"
    static let cellNibName = "MessageCell"
    static let registerSegue = "RegisterToChat"
    static let loginSegue = "LoginToChat"
    
    struct BrandColours {
        static let purple = "BrandPurple"
        static let lightPurple = "BrandLightPurple"
        static let blue = "BrandBlue"
        static let lightBlue = "BrandLightBlue"
    }
    
    struct SupaStore {
        static let collectionName = "messages"
        static let senderField = "sender" // string
        static let bodyField = "messageBody" // string
        static let createdAt = "created_at"
    }
}
