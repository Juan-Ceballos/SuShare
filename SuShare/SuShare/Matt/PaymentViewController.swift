//
//  PaymentViewController.swift
//  SuShare
//
//  Created by Matthew Ramos on 6/16/20.
//  Copyright © 2020 Matthew Ramos. All rights reserved.
//

import UIKit
import Stripe

class PaymentViewController: UIViewController {
    
    private var paymentContext = STPPaymentContext()
    public var suShare: SuShare?
    private var paymentView = PaymentView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Checkout"
        paymentView.backgroundColor = .white
        view = paymentView
        
    }
   
}

class PaymentView: UIView {
    
    
    private lazy var joinSuShareButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.text = "Subscribe"
        button.backgroundColor = #colorLiteral(red: 0, green: 0.6613236666, blue: 0.617059052, alpha: 1)
        button.titleLabel?.textColor = .white
        button.layer.cornerRadius = 8
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        setupConstraints()
    }
    
    private func setupConstraints() {
        addSubview(joinSuShareButton)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            joinSuShareButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            joinSuShareButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -8),
            joinSuShareButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 8),
            joinSuShareButton.heightAnchor.constraint(equalToConstant: 50)
        ])
            
    }
}
