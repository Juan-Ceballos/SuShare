//
//  LoginViewController.swift
//  SuShare
//
//  Created by Matthew Ramos on 5/25/20.
//  Copyright © 2020 Matthew Ramos. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

enum AccountState {
    case existingUser
    case newUser
}

class LoginViewController: UIViewController {
    
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var containerView: DesignableView!
    @IBOutlet weak var emailTextField: DesignableTextField!
    
    @IBOutlet weak var passwordTextfield: DesignableTextField!
    @IBOutlet weak var confirmPasswordTextField: DesignableTextField!
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usernameTextField: DesignableTextField!
    
    @IBOutlet weak var loginButton: DesignableButton!
    
    @IBOutlet weak var accountStateMessageLabel: UILabel!
    @IBOutlet weak var accountStateButton: UIButton!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var firstNameTextField: DesignableTextField!
    @IBOutlet weak var lastNameTextField: DesignableTextField!
    
    
    private var accountState: AccountState = .existingUser
    private var authSession = AuthenticationSession()
    private var databaseService = DatabaseService()
    private let apiClient = MyAPIClient.sharedClient
    
    let hidden = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clearErrorLabel()
        clearNewUserTextFields()
        GIDSignIn.sharedInstance()?.presentingViewController = self
    }
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        if accountState == .newUser {
            guard let email = emailTextField.text,
                !email.isEmpty,
                let password = passwordTextfield.text,
                !password.isEmpty,
                let username = usernameTextField.text,
                !username.isEmpty,
                let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty, confirmPassword == password else {
                    print("missing fields")
                    return
            }
            continueLoginFlow(email: email, password: password, username: username)
        }
        
        if accountState == .existingUser{
            guard let email = emailTextField.text,
                !email.isEmpty,
                let password = passwordTextfield.text,
                !password.isEmpty else {
                    print("missing fields")
                    return
            }
            continueLoginFlow(email: email, password: password)
        }
    }
    
    private func continueLoginFlow(email: String, password: String, username: String? = nil, firstName: String? = nil, lastName: String? = nil) {
        if accountState == .existingUser {
            authSession.signExistingUser(email: email, password: password) { [weak self] (result) in
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.errorLabel.text = "\(error.localizedDescription)"
                        self?.errorLabel.textColor = .systemRed
                    }
                case .success:
                    DispatchQueue.main.async {
                        self?.navigateToMainView()
                    }
                }
            }
        } else {
            authSession.createNewUser(email: email, password: password) { [weak self] (result) in
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.errorLabel.text = "\(error.localizedDescription)"
                        self?.errorLabel.textColor = .systemRed
                    }
                case .success(let authDataResult):
                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                    changeRequest?.displayName = username
                    changeRequest?.commitChanges(completion: { (error) in
                        if let error = error    {
                            print("profile name setup error \(error.localizedDescription)")
                        } else  {
                            print("success user name setup")
                        }
                    })
                    // create a database user only from a new authenticated account
                    self?.createDatabaseUser(authDataResult: authDataResult)
                    self?.databaseService.updateDatabaseUser(username: username ?? "") { (result) in
                        switch result   {
                        case .failure(let error):
                            print(error.localizedDescription)
                        case .success:
                            print("update successful")
                        }
                    }
                }
            }
        }
    }
    
    private func retieveUserEnteredData(){
        guard let first = firstNameTextField.text, !first.isEmpty,
            let last  = lastNameTextField.text, !last.isEmpty else {
                showAlert(title: "missing fields", message: "please make sure all the fields are filled in")
                return
        }
        
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        print(user)
        let fullName = "\(first) \(last) "
        
        apiClient.createDummyUser(fullName: fullName) { (result) in
            switch result{
            case .failure(let error):
                print("the error is: \(error.localizedDescription)")
            case.success(let stripeCustomerID):
                self.updateUserDataBaseInfo(fullName: fullName, stripeCustomerId: stripeCustomerID)
            }
        }
        
        
    }
    
    
    private func updateUserDataBaseInfo(fullName: String, stripeCustomerId: String) {
        
        databaseService.updateFireBaseUserWithStripeStuff(fullName: fullName, stripeCustomerId: stripeCustomerId) { (result) in
            switch result {
            case .failure(let error):
                print("error is: \(error.localizedDescription)")
            case .success(let itWork):
                print(itWork)
                // dismiss to the main storyboard
                // MARK: needs to navigate to the main storyboard
                
            }
        }
    }
    
    private func createDatabaseUser(authDataResult: AuthDataResult) {
        databaseService.createDatabaseUser(authDataResult: authDataResult) { [weak self] (result) in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "Account error", message: error.localizedDescription)
                }
            case .success:
                DispatchQueue.main.async {
                    self?.navigateToMainView()
                }
            }
        }
    }
    
    private func navigateToMainView() {
        //UIViewController.showViewController(storyBoardName: "Highlights", viewControllerId: "HighlightsViewController")
        UIViewController.showVC(viewcontroller: TabController())
    }
    
    private func clearErrorLabel() {
        errorLabel.text = ""
    }
    
    private func clearNewUserTextFields() {
        confirmPasswordTextField.isHidden = true
        usernameTextField.isHidden = true
        usernameLabel.isHidden = true
        nameLabel.isHidden = true
        firstNameTextField.isHidden = true
        lastNameTextField.isHidden = true
    }
    
    private func showNewUserTextFields(){
        confirmPasswordTextField.isHidden = false
        usernameTextField.isHidden = false
        usernameLabel.isHidden = false
        nameLabel.isHidden = false
        firstNameTextField.isHidden = false
        lastNameTextField.isHidden = false
    }
    
    @IBAction func toggleAccountState(_ sender: UIButton) {
        // change the account login state
        accountState = accountState == .existingUser ? .newUser : .existingUser
        
        // animation duration
        let duration: TimeInterval = 1.0 // 1 sec
        
        if accountState == .existingUser {
            UIView.transition(with: containerView, duration: duration, options: [.transitionCrossDissolve], animations: {
                self.loginButton.setTitle("Login", for: .normal)
                self.clearNewUserTextFields()
                self.accountStateMessageLabel.text = "Don't have an account ?"
                self.accountStateButton.setTitle("SIGNUP", for: .normal)
            }, completion: nil)
        } else {
            UIView.transition(with: containerView, duration: duration, options: [.transitionCrossDissolve], animations: {
                self.loginButton.setTitle("Sign Up", for: .normal)
                self.showNewUserTextFields()
                // self.confirmPasswordTextField.isHidden = false
                //self.usernameTextField.isHidden = false
                self.accountStateMessageLabel.text = "Already have an account ?"
                self.accountStateButton.setTitle("LOGIN", for: .normal)
            }, completion: nil)
        }
    }
}
