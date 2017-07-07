//
//  SteamLoginViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 6/23/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit
import WebKit

protocol SteamLoginViewControllerDelegate {
    func got(steamId: String?, username: String?)
}

class SteamLoginViewController: UIViewController {
    
    var webView: WKWebView!
    var delegate: SteamLoginViewControllerDelegate?
    
    override func loadView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.navigationDelegate = self
        view = self.webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let url = URL(string: "https://steamcommunity.com/login/home/?goto=%2Fmy%2Fprofile")!
        self.webView.load(URLRequest(url: url))
        self.webView.allowsBackForwardNavigationGestures = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension SteamLoginViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if let scheme = url.scheme, scheme == "http" {
                guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                    NSLog("Could not convert URL to components")
                    decisionHandler(.cancel)
                    return
                }
                components.scheme = "https"
                print(url)
                print("http. redirecting to https")
                
                webView.load(URLRequest(url: try! components.asURL()))
                decisionHandler(.cancel)
            } else if url.absoluteString.hasPrefix("https://steamcommunity.com/id/") {
                let urlComponents = url.absoluteString.components(separatedBy: "/")
                let username = urlComponents[4]
                self.delegate?.got(steamId: nil, username: username)
                decisionHandler(.cancel)
            } else if url.absoluteString.hasPrefix("https://steamcommunity.com/profiles/") {
                let urlComponents = url.absoluteString.components(separatedBy: "/")
                let steamId = urlComponents[4]
                self.delegate?.got(steamId: steamId, username: nil)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }
}
