//
//  ViewController.swift
//  Auth
//
//  Created by Mario Kovacevic on 09/07/2018.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tokenTextView: UITextView!
    
    var googleViewController: GoogleWebViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.googleViewController = GoogleWebViewController(url: URL(string: "http://localhost:8080/google-login")!, onReceiveSuccessRespons: { token in
            self.tokenTextView.text = token ?? "no token"
        }, onReceiveErrorRespons: { error in
            self.tokenTextView.text = error ?? "error"
        })
    }
    
    @IBAction func signInWithGoogle(_ sender: Any) {
        let navigationController = UINavigationController(rootViewController: self.googleViewController!)
        self.present(navigationController, animated: true)
    }
    
}

