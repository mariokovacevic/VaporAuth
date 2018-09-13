//
//  SocialWebViewController.swift
//  Auth
//
//  Created by Mario Kovacevic on 09/07/2018.
//

import Foundation
import WebKit

class SocialWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    open var didReceiveSuccessRespons: ((_ response:String?)->())?
    open var didReceiveErrorRespons: ((_ error:String?)->())?
    
    var wkWebView: WKWebView = {
        let preferences:WKPreferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true;
        preferences.javaScriptEnabled = true
        
        let configuration:WKWebViewConfiguration? = WKWebViewConfiguration()
        configuration!.preferences = preferences;
        
        var wkWebView = WKWebView(frame: .zero, configuration: configuration!)
        wkWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wkWebView.scrollView.isScrollEnabled = false
        wkWebView.scrollView.bounces = false
        wkWebView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A356 Safari/604.1"
        return wkWebView
    }()
    var url:URL!
    
    convenience init(url:URL, onReceiveSuccessRespons: ((_ response:String?)->())?, onReceiveErrorRespons: ((_ error:String?)->())?) {
        self.init(nibName:nil, bundle:nil)
        self.url = url
        
        if let didReceiveSuccessRespons = onReceiveSuccessRespons {
            self.didReceiveSuccessRespons = didReceiveSuccessRespons
        }
        
        if let didReceiveErrorRespons = onReceiveErrorRespons {
            self.didReceiveErrorRespons = didReceiveErrorRespons
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let request = URLRequest(url: self.url, cachePolicy: .reloadIgnoringCacheData)

        self.wkWebView.navigationDelegate = self
        self.wkWebView.uiDelegate = self
        self.wkWebView.load(request)
        
        let leftButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissViewController))
        self.navigationItem.leftBarButtonItem = leftButton
        
        self.modalPresentationStyle = .overCurrentContext
        self.view = self.wkWebView
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        URLCache.shared.removeAllCachedResponses()
        
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { (records) in
            for record in records {
                dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: [record], completionHandler: {
                    print("Deleted: " + record.displayName);
                })
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var facebookSuccess = false

        if let url = navigationAction.request.url {
            print(url)
            if url.absoluteString.contains("login-complete") {
                for element in url.query?.split(separator: "&") ?? [] {
                    if element.contains("token") {
                        if let jwt = element.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true).last {
                            facebookSuccess = true
                            if self.didReceiveSuccessRespons != nil{
                                self.didReceiveSuccessRespons!(String(jwt))
                            }
                        }
                    }
                }
                decisionHandler(.cancel)
                self.dismiss(animated: true, completion: {
                    if !facebookSuccess {
                        if self.didReceiveErrorRespons != nil{
                            self.didReceiveErrorRespons!("No token")
                        }
                    }
                })
                return
            }
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
    
    @objc func dismissViewController() {
        self.dismiss(animated: true) {

        }
    }
    
}
