//
//  ViewController.swift
//  Auth
//
//  Created by Mario Kovacevic on 09/07/2018.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tokenTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func signInWithGoogle(_ sender: Any) {
        let googleViewController = SocialWebViewController(url: URL(string: "http://localhost:8080/google-login")!, onReceiveSuccessRespons: { token in
            self.tokenTextView.text = token ?? "no token"
        }, onReceiveErrorRespons: { error in
            self.tokenTextView.text = error ?? "error"
        })
        googleViewController.navigationItem.title = "Google"

        let navigationController = UINavigationController(rootViewController: googleViewController)
        self.present(navigationController, animated: true)
    }
    
    @IBAction func signInWithFacebook(_ sender: Any) {
        let facebookViewController = SocialWebViewController(url: URL(string: "http://localhost:8080/facebook-login")!, onReceiveSuccessRespons: { token in
            self.tokenTextView.text = token ?? "no token"
        }, onReceiveErrorRespons: { error in
            self.tokenTextView.text = error ?? "error"
        })
        facebookViewController.navigationItem.title = "Facebook"

        let navigationController = UINavigationController(rootViewController: facebookViewController)
        self.present(navigationController, animated: true)
    }
}

