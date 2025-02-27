//
//  SupabaseManager.swift
//  Flash Chat iOS13
//
//  Created by Roman on 17.02.2025.
//  Copyright © 2025 Angela Yu. All rights reserved.
//

import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let supabase: SupabaseClient
    
    private init() {
        let supabaseUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_KEY"] ?? ""
        self.supabase = SupabaseClient(supabaseURL: URL(string: supabaseUrl)!, supabaseKey: supabaseKey)
    }
}
