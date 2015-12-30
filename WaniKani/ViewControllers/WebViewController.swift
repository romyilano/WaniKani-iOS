//
//  WebViewController.swift
//
//
//  Created by Andriy K. on 8/26/15.
//
//

import UIKit
import LGSideMenuController


protocol WebViewControllerDelegate: class {
  func webViewControllerBecomeReadyForLoad(vc: WebViewController)
  func startShowingKanji()
  func endShowingKanji()
}


class WebViewController: UIViewController {
  
  // Public API:
  
  weak var delegate: WebViewControllerDelegate?
  
  func loadURL(url: String?, type: WebSessionType) {
    self.url = url
    self.type = type
    
    if let url = url {
      if let realURL = NSURL(string: url) {
        let request = NSURLRequest(URL: realURL)
        webView?.loadRequest(request)
        webView?.keyboardDisplayRequiresUserAction = false
      }
    }
  }
  
  
  //
  private var url: String?
  private var type = WebSessionType.Lesson {
    didSet {
      submitButton?.title = buttonTitle
    }
  }
  
  private var buttonTitle: String {
    var title = "End session"
    if (type == .Review) && (SettingsSuit.sharedInstance.shouldUseGameCenter == true) {
      title = "Submit to GameCenter"
    }
    return title
  }
  
  private var newScoreEarned = 0
  private var oldOffset: CGFloat?
  
  @IBOutlet weak var submitButton: UIBarButtonItem! {
    didSet {
      submitButton?.accessibilityIdentifier = "Submit"
      submitButton?.title = buttonTitle
    }
  }
  
  @IBOutlet weak var webView: UIWebView! {
    didSet {
      webView.scrollView.delegate = self
      webView.delegate = self
      delegate?.webViewControllerBecomeReadyForLoad(self)
    }
  }
  @IBAction func cancelPressed(sender: AnyObject) {
    checkForNewScore()
    submitScore()
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return SettingsSuit.sharedInstance.hideStatusBarEnabled
  }
}

extension WebViewController: UIWebViewDelegate {
  
  private func checkForNewScore() {
    if let response = webView.stringByEvaluatingJavaScriptFromString("getScore();"),
      let score = Int(response) where score != 0 {
        print("score: = \(newScoreEarned) + \(score)")
        newScoreEarned += score
    }
  }
  
  private func submitScore() {
    AwardsManager.sharedInstance.saveHighscore(newScoreEarned)
  }
  
  func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
    
    if let url = url where url.containsString(request.URL!.absoluteString) {
      checkForNewScore()
      return true
    } else {
      return request.URL!.absoluteString == "https://www.wanikani.com/login"
    }
  }
  
  func webViewDidFinishLoad(webView: UIWebView) {
    SettingsSuit.sharedInstance.applyUserScriptsToWebView(webView, type: type)
  }
}

extension WebViewController: UIScrollViewDelegate {
  func scrollViewDidScroll(scrollView: UIScrollView) {
    let new = scrollView.contentOffset.y
    let old = oldOffset ?? new
    let delta = max((old - new), -(old - new))
    if delta > 35 {
      scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: 0)
    }
    oldOffset = new
  }
}