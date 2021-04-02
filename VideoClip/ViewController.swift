//
//  ViewController.swift
//  VideoClip
//
//  Created by p-x9 on 2021/03/18.
//  
//

import UIKit
import WebKit

class ViewController: UIViewController {

    enum ExpansionState {
        case expanding
        case contracting
        case stable
    }

    var expansionState: ExpansionState = .stable

    private var searchBar: UISearchBar!
    private var reloadButton: UIBarButtonItem!
    private var progressView = UIProgressView()

    private var scrollPreviousPoint: CGPoint = .zero
    private var isViewShowed: Bool!
    private let defaultSearchEngineURL = URL(string: "https://www.google.com/")

    private var observeEstimatedProgress: NSKeyValueObservation?
    private var observeIsLoading: NSKeyValueObservation?
    private var observeCanGoBack: NSKeyValueObservation?
    private var observeCanGoForward: NSKeyValueObservation?

    @IBOutlet private var webView: WKWebView!
    @IBOutlet private var backButton: UIBarButtonItem!
    @IBOutlet private var forwardButton: UIBarButtonItem!

    @IBOutlet private var webViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var webViewTopConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = defaultSearchEngineURL {
            webView.load(URLRequest(url: url))
        }
        webView.allowsBackForwardNavigationGestures = true

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.delegate = self

        setUpSearchBar()
        setUpProgressBar()
        observeKeysForWebView()
        webView.layer.borderWidth = 1
        webView.layer.borderColor = UIColor.cyan.cgColor
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isViewShowed = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isViewShowed = false
    }

    @IBAction private func handleBackButton(_ sender: Any) {
        webView.goBack()
    }
    @IBAction private func handleForwardButton(_ sender: Any) {
        webView.goForward()
    }
    @IBAction private func handleActionButton(_ sender: Any) {
        guard let shareText = webView.title,
              let shareWebsite = webView.url else {
            return
        }
        let activityVC = UIActivityViewController(activityItems: [shareText, shareWebsite], applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
    }

    @objc
    func handleReloadButton(sender: UIButton) {
        if webView.url == nil ,
           let url = URL(string: "https://www.google.com/") {
            webView.load(URLRequest(url: url))
        } else {
            self.webView.reload()
        }
    }

    func setUpSearchBar() {
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 270, height: 80))
        searchBar.delegate = self
        searchBar.layer.position = CGPoint(x: self.view.bounds.width / 2, y: 20)
        searchBar.searchBarStyle = UISearchBar.Style.minimal
        searchBar.placeholder = "URLまたは検索ワード"
        searchBar.tintColor = UIColor.blue

        searchBar.showsSearchResultsButton = false
        searchBar.showsCancelButton = false
        searchBar.showsBookmarkButton = false

        self.navigationItem.titleView = searchBar

        // Reload Button
        reloadButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(handleReloadButton(sender:)))
        self.navigationItem.rightBarButtonItem = reloadButton
    }

    func setUpProgressBar() {
        progressView = UIProgressView(frame: CGRect(x: 0, y: (self.navigationController?.navigationBar.frame.height ?? 0) + 10, width: self.view.frame.size.width, height: 10))
        progressView.progressViewStyle = .bar
        self.navigationController?.navigationBar.addSubview(progressView)
    }

    func observeKeysForWebView() {
        self.observeEstimatedProgress = self.webView.observe(\.estimatedProgress, options: [.new]) {_, change in
            self.progressView.setProgress(Float(change.newValue ?? 0), animated: true)
        }
        self.observeIsLoading = self.webView.observe(\.isLoading, options: [.new]) {_, change in
            if let newValue = change.newValue, newValue {
                self.progressView.setProgress(0.1, animated: true)
            } else {
                self.progressView.setProgress(0.0, animated: true)
            }
        }
        self.observeCanGoBack = self.webView.observe(\.canGoBack, options: [.new]) {webView, _ in
            self.backButton.isEnabled = !(webView.canGoBack) ? false : true
        }
        self.observeCanGoForward = self.webView.observe(\.canGoForward, options: [.new]) {webView, _ in
            self.forwardButton.isEnabled = !(webView.canGoForward) ? false : true
        }
    }

    //    deinit {
    //        self.webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    //        self.webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.isLoading))
    //        self.webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack))
    //        self.webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.canGoForward))
    //    }

}

// MARK: - WKNavigationDelegate
extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        backButton.isEnabled = !(webView.canGoBack) ? false : true
        forwardButton.isEnabled = !(webView.canGoForward) ? false : true

        guard let url = webView.url,
              var urlComponents = URLComponents(string: url.absoluteString),
              let defaultURL = self.defaultSearchEngineURL else {
            return
        }

        urlComponents.query = nil

        guard let urlString = urlComponents.string else {
            return
        }

        // Google's domains differ by country.
        if urlString.contains("https://www.google.") && urlString.contains("search") {
            searchBar.text = webView.title?.split(separator: "-").map { String($0) }[0]
        } else if urlString == defaultURL.absoluteString {
            searchBar.text = ""
        } else {
            searchBar.text = webView.url?.absoluteString
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {

    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let e = error as NSError
        if e.code == -1009 {
            print("don't connected to internet")
        } else {

        }
    }

    //  Display within this app without launching other installed apps.
    //  ref: https://stackoverflow.com/questions/58291683/disable-youtube-app-redirect-from-wkwebview-in-swift
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            decisionHandler(.cancel)
            DispatchQueue.main.async {
                webView.load(navigationAction.request)
            }
        } else {
            decisionHandler(.allow)
        }
    }

}

// MARK: - WKUIDelegate
extension ViewController: WKUIDelegate {
    // target=_blank
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }

        return nil
    }
}

// MARK: - UISearchBarDelegate
extension ViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        if let text = searchBar.text {
            search(urlString: text)
        }
    }

    func search( urlString: String) {
        var urlString = urlString
        if urlString.isEmpty {
            return
        }

        var strUrl: String
        var searchWord: String = ""
        let chkURL = urlString.components(separatedBy: ".")
        if chkURL.count > 1 {
            // URLの場合
            if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            } else {
                strUrl = "http://"
                strUrl = strUrl.appending(urlString)
            }
        } else {
            // 検索ワード
            urlString = urlString.replacingOccurrences(of: "?", with: " ")
            let words = urlString.components(separatedBy: " ")
            searchWord = words.joined(separator: "+")
            urlString = "https://www.google.co.jp/search?&q=\(searchWord)"
        }

        if let encodedUrlString = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed),
           let url = URL(string: encodedUrlString) {
            let request = URLRequest(url: url)
            self.webView.load(request)
        }
    }
}

extension ViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollPreviousPoint = scrollView.contentOffset
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPoint = scrollView.contentOffset
//        let contentSize = scrollView.contentSize
//        let frameSize = scrollView.frame
//        let maxOffSet = contentSize.height - frameSize.height

        guard let navigationVC = self.navigationController,
              let toolBar = navigationVC.toolbar else {
            return
        }
        let navigationBar = navigationVC.navigationBar
        let statusBarHeight = self.view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        let maxConstant = max(navigationBar.frame.height, toolBar.frame.height) + statusBarHeight

        let currentOffset = -self.webViewTopConstraint.constant
        let difference = -currentPoint.y + scrollPreviousPoint.y
        let offset = currentOffset - difference
        // print("offset:\(offset)")

        if difference == 0 {
            self.expansionState = .stable
        } else {
            self.expansionState = difference > 0 ? .contracting:.expanding
        }

        if scrollView.isReachedToTop || scrollView.isReachedToBottom {
            // scrollPreviousPoint = scrollView.contentOffset
            return
        }

        if 0 <= offset && offset <= maxConstant {
            navigationBar.transform = CGAffineTransform(translationX: 0, y: -offset)
            toolBar.transform = CGAffineTransform(translationX: 0, y: offset)
            self.webViewTopConstraint.constant = -offset
            self.webViewBottomConstraint.constant = -offset
        } else if offset > maxConstant {
            navigationBar.transform = CGAffineTransform(translationX: 0, y: -maxConstant)
            toolBar.transform = CGAffineTransform(translationX: 0, y: maxConstant)
            self.webViewTopConstraint.constant = -maxConstant
            self.webViewBottomConstraint.constant = -maxConstant
            self.expansionState = .stable
        } else {
            navigationBar.transform = .identity
            toolBar.transform = .identity
            self.webViewTopConstraint.constant = 0
            self.webViewBottomConstraint.constant = 0
            self.expansionState = .stable
        }

        webView.layoutIfNeeded()

//        if offset >= maxConstant {
//            navigationBar.isHidden = true
//            toolBar.isHidden = true
//        } else {
//            navigationBar.isHidden = false
//            toolBar.isHidden = false
//        }
        scrollPreviousPoint = scrollView.contentOffset

    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.stoppedScrolling(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.stoppedScrolling(scrollView)
        }
    }

    func stoppedScrolling(_ scrollView: UIScrollView) {
        guard let navigationVC = self.navigationController,
              let toolBar = navigationVC.toolbar else {
            return
        }
        let navigationBar = navigationVC.navigationBar
        let statusBarHeight = self.view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        let maxConstant = max(navigationBar.frame.height, toolBar.frame.height) + statusBarHeight

        switch self.expansionState {
        case .expanding:
            UIView.animate(withDuration: 0.2) {
                navigationBar.transform = CGAffineTransform(translationX: 0, y: -maxConstant)
                toolBar.transform = CGAffineTransform(translationX: 0, y: maxConstant)
                self.webViewTopConstraint.constant = -maxConstant
                self.webViewBottomConstraint.constant = -maxConstant
            }
        //            navigationBar.isHidden = true
        //            toolBar.isHidden = true
        case .contracting:
            UIView.animate(withDuration: 0.2) {
                navigationBar.transform = .identity
                toolBar.transform = .identity
                self.webViewTopConstraint.constant = 0
                self.webViewBottomConstraint.constant = 0
            }
        //            navigationBar.isHidden = false
        //            toolBar.isHidden = false
        default:
            break
        }

        webView.layoutIfNeeded()
        self.expansionState = .stable
        scrollPreviousPoint = scrollView.contentOffset

    }
}
