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
    
    @IBOutlet var webView: WKWebView!
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var forwardButton: UIBarButtonItem!
    
    
    private var searchBar: UISearchBar!
    private var reloadButton: UIBarButtonItem!
    private var progressView = UIProgressView()
    
    private var scrollBeginningPoint: CGPoint = .zero
    private var isViewShowed: Bool!
    
    
    deinit{
        self.webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        self.webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.isLoading))
        self.webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack))
        self.webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.canGoForward))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.load(URLRequest(url: URL(string: "https://www.google.com/")!))
        webView.allowsBackForwardNavigationGestures = true
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.delegate = self
        
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoForward), options: .new, context: nil)
        
        setUpSearchBar()
        setUpProgressBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isViewShowed = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isViewShowed = false
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case #keyPath(WKWebView.estimatedProgress):
            self.progressView.setProgress(Float(self.webView.estimatedProgress), animated: true)
        case #keyPath(WKWebView.isLoading):
            if self.webView.isLoading {
                self.progressView.setProgress(0.1, animated: true)
            }else{
                self.progressView.setProgress(0.0, animated: true)
            }
        case #keyPath(WKWebView.canGoBack):
            backButton.isEnabled = !(webView.canGoBack) ? false : true
        case #keyPath(WKWebView.canGoForward):
            forwardButton.isEnabled = !(webView.canGoForward) ? false : true
        default:
            break
        }
    }
    
    func setUpSearchBar(){
        searchBar = UISearchBar(frame:CGRect(x:0, y:0, width:270, height:80))
        searchBar.delegate = self
        searchBar.layer.position = CGPoint(x: self.view.bounds.width/2, y: 20)
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
    
    func setUpProgressBar(){
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        
        progressView = UIProgressView(frame: CGRect(x: 0, y: self.navigationController!.navigationBar.frame.height+10, width: self.view.frame.size.width, height: 10))
        progressView.progressViewStyle = .bar
        self.navigationController?.navigationBar.addSubview(progressView)
    }
    
    @IBAction func handleBackButton(_ sender: Any) {
        webView.goBack()
    }
    @IBAction func handleForwardButton(_ sender: Any) {
        webView.goForward()
    }
    
    @objc func handleReloadButton(sender : UIButton){
        if webView.url == nil{
            webView.load(URLRequest(url: URL(string: "https://www.google.com/")!))
        }
        else{
            self.webView.reload()
        }
    }
    
    
}

//MARK: - WKNavigationDelegate
extension ViewController: WKNavigationDelegate{
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        backButton.isEnabled = !(webView.canGoBack) ? false : true
        forwardButton.isEnabled = !(webView.canGoForward) ? false : true
        //progressView.setProgress(0, animated: false)
        
        if (webView.url?.absoluteString.contains("google."))! && (webView.url?.absoluteString.contains("search"))!{
            searchBar.text = webView.title?.split(separator: "-").map({String($0)})[0]
        }
        else if (webView.url?.absoluteString.contains("https://www.google.com/"))! && [29,23].contains(webView.url?.absoluteString.count){
            searchBar.text = ""
        }
        else{
            searchBar.text = webView.url?.absoluteString
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let e = error as NSError
        if e.code == -1009{
            print("don't connected to internet")
        }
        else{
            
        }
    }
    
}

// MARK: - WKUIDelegate
extension ViewController: WKUIDelegate{
    // target=_blank
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        
        return nil
    }
}

// MARK: - UISearchBarDelegate
extension ViewController: UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        search(urlString: searchBar.text!)
        searchBar.resignFirstResponder()
    }
    
    func search( urlString:String)
    {
        var urlString = urlString
        if(urlString == ""){
            return;
        }
        
        var strUrl: String
        var searchWord:String = ""
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
        
        let encodedUrlString = urlString.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)
        let url = NSURL(string: encodedUrlString!)
        let request = NSURLRequest(url: url! as URL)
        self.webView.load(request as URLRequest)
    }
}

extension ViewController: UIScrollViewDelegate{
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollBeginningPoint = scrollView.contentOffset
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPoint = scrollView.contentOffset
        let contentSize = scrollView.contentSize
        let frameSize = scrollView.frame
        let maxOffSet = contentSize.height - frameSize.height
        
        if currentPoint.y >= maxOffSet || scrollBeginningPoint.y < currentPoint.y {
            self.navigationController?.setToolbarHidden(true, animated: true)
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        } else{
            self.navigationController?.setToolbarHidden(false, animated: true)
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
}
