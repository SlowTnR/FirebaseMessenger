//
//  ViewController.swift
//  FirebaseMessenger
//
//  Created by Ilja Patrushev on 19.12.2020.
//

import UIKit
import FirebaseAuth

// TODO ...


class ConversationsViewController: UIViewController {
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validateAuth()

    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil{
            
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    
    
    
    
    
}



