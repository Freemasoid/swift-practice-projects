//
//  RegisterViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {
    
    let supabase = SupabaseManager.shared.supabase

    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    
    @IBAction func registerPressed(_ sender: UIButton) {
        if let email = emailTextfield.text, let password = passwordTextfield.text {
            Task {
                do {
                    try await supabase.auth.signUp(email: email, password: password)
                    self.performSegue(withIdentifier: K.registerSegue, sender: self)
                } catch {
                    print("Error registering: \(error)")
                }
            }
        }
    }
    
}
