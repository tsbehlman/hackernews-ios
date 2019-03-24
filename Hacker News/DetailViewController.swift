//
//  DetailViewController.swift
//  Hacker News
//
//  Created by Trevor Behlman on 3/23/19.
//  Copyright © 2019 Trevor Behlman. All rights reserved.
//

import UIKit
import WebKit

class DetailViewController: UIViewController, WKNavigationDelegate {

    func configureView() {
        // Update the user interface for the detail item.
        if let story = detailItem {
            if let view = self.view as! WKWebView? {
                let storyURL = HackerNews.readableURL(forStory: story)
                let storyRequest = URLRequest(url: storyURL)
                view.load(storyRequest)
            }
            self.navigationItem.title = story.domain
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureView()
        
        if let view = self.view as! WKWebView? {
            view.navigationDelegate = self
        }
    }

    var detailItem: Story? {
        didSet {
            // Update the view.
            configureView()
        }
    }
}

