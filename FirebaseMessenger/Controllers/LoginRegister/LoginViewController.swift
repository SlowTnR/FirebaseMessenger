//
//  LoginViewController.swift
//  FirebaseMessenger
//
//  Created by Ilja Patrushev on 19.12.2020.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.keyboardType = .emailAddress
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Enter Email"
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.keyboardType = .default
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Enter Password"
        field.isSecureTextEntry = true
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Sign In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        
        return button
    }()
    
    private let fbLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["email,public_profile"]
        
        return button
    }()
    
    private let googleLoginButton: GIDSignInButton = {
       
        let button = GIDSignInButton()
        
        return button
    }()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: {[weak self] _ in
            guard let strongSelf = self else {return}
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        title = "Log In"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Up", style: .done, target: self, action: #selector(didTapRegister))
        
        
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        fbLoginButton.delegate = self
        
        // Add subviews
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(fbLoginButton)
        scrollView.addSubview(googleLoginButton)
        
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width - size)/2 , y: 20, width: size, height: size)
        
        emailField.frame = CGRect(x: 30, y: imageView.bottom + 10, width: scrollView.width - 60, height: 52)
        
        passwordField.frame = CGRect(x: 30, y: emailField.bottom + 10, width: scrollView.width - 60, height: 52)
        
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom + 10, width: scrollView.width - 60, height: 52)
        
        
        fbLoginButton.frame = CGRect(x: 30, y: loginButton.bottom + 10, width: scrollView.width - 60, height: 52)
        googleLoginButton.frame = CGRect(x: 30, y: fbLoginButton.bottom + 10, width: scrollView.width - 60, height: 52)
        
        
    }
    
    @objc private func loginButtonTapped() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
        // Firebase Log In
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: {[weak self ]authResult, error in
            
            guard let strongSelf = self else {return}
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult, error == nil else {
                print ("Failed to log in user with email: \(email)")
                return
            }
            
            let user = result.user
            print("User: \(user) is logged in succesfully")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            
            
        })
    }
    
    func alertUserLoginError(){
        let alert = UIAlertController(title: "Something went wrong", message: "Please enter correct email or/and password", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        
        else if textField == passwordField {
            loginButtonTapped()
        }
        
        return true
    }
    
}

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed login with facebook.")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields":
                                                                        "email, name"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start(completionHandler: {_, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("Failed to make facebook graph request: " )
                return
            }
            
            print("Result: \(result)")
            
            guard let userName = result["name"] as? String,
                  let email = result["email"] as? String else {
                print("Failed to get email and name from facebook")
                return
            }
            let nameComponents = userName.components(separatedBy: " ")
            guard nameComponents.count == 2 else {return}
            
            let firstName = nameComponents[0]
            let lastName = nameComponents[1]
            
            DatabaseManager.shared.userExists(with: email, completion: {exists in
                if !exists {
                    DatabaseManager.shared.insertuser(with: ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email))
                }
            })
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { [weak self] authResult, error in
                guard let strongSelf = self else {return}
                
                guard  authResult != nil, error == nil else {
                    if let error = error {
                        print("Facebook credential login failed. Maybe MFA needed: \(error)")
                    }
                    
                    return
                }
                
                print("Login success")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
    }
    
}


