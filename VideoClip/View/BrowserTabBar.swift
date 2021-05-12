//
//  BrowserTabBar.swift
//  VideoClip
//
//  Created by p-x9 on 2021/04/26.
//  
//

import UIKit
import SnapKit

class BrowserTabBar: UIView {

    static var defaultTabWidth: CGFloat = 100
    var tabViews: [BrowserTabView] = []

    var selectedIndex: Int {
        get {
            self._selectedIndex
        }
        set {
            self.updateSelectedIndex(from: self._selectedIndex, to: newValue)
            self._selectedIndex = newValue
            self.scroll(to: newValue, animated: true)
        }
    }

    private var _selectedIndex: Int = 0
    private var scrollView: UIScrollView! {
        didSet {
            self.scrollView.isScrollEnabled = true
            self.scrollView.showsVerticalScrollIndicator = false
            self.scrollView.showsHorizontalScrollIndicator = false
        }
    }
    private var addButton: UIButton!

    init() {
        super.init(frame: .zero)

        self.scrollView = {
            let scrollView = UIScrollView()
            scrollView.isScrollEnabled = true
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false

            self.addSubview(scrollView)

            scrollView.snp.makeConstraints {make in
                make.top.bottom.leading.equalTo(self)
            }

            return scrollView
        }()

        self.addButton = {
            let button = UIButton()
            button.setImage(UIImage(systemName: "plus"), for: .normal)
            button.addTarget(self, action: #selector(handleAddButton(sender:)), for: .touchUpInside)
            self.addSubview(button)
            button.snp.makeConstraints {make in
                make.width.height.equalTo(self.snp.height).offset(2)
                make.centerY.equalTo(self)
                make.leading.equalTo(self.scrollView.snp.trailing).offset(4)
                make.trailing.equalTo(self).offset(4)
            }
            return button
        }()

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSelectedIndex(from: Int, to: Int) {

    }
    func scroll(to tab: BrowserTabView, animated: Bool) {
        guard scrollView.contentSize.width > scrollView.frame.width else {
            return
        }
        let maxOffset = scrollView.contentSize.width - scrollView.frame.width
        scrollView.setContentOffset(CGPoint(x: min(maxOffset, tab.frame.origin.x), y: 0), animated: true)
    }
    func scroll(to index: Int, animated: Bool) {
        let tabView = self.tabViews[index]
        self.scroll(to: tabView, animated: animated)
    }

    @objc
    func handleAddButton(sender: UIButton) {
        let newTab = BrowserTabView()
        newTab.backgroundColor = .white
        self.tabViews.append(newTab)
        self.scrollView.addSubview(newTab)
        self.scrollView.sendSubviewToBack(newTab)
        self.selectedIndex = self.tabViews.count - 1

        for (i, tab) in tabViews.enumerated() {
            tab.snp.remakeConstraints { make in
                make.top.bottom.equalTo(self.scrollView)
                make.height.equalTo(self.frame.height)
                if i > 0 {
                    let lastTab = self.tabViews[i - 1]
                    make.left.equalTo(lastTab.snp.right).offset(6)
                } else {
                    make.left.equalTo(self.scrollView)
                }
                make.width.equalTo(BrowserTabBar.defaultTabWidth)
            }
        }

        UIView.animate(withDuration: 0.25, animations: {
            self.layoutIfNeeded()
        }, completion: {_ in
            self.scrollView.contentSize = CGSize(width: BrowserTabBar.defaultTabWidth * CGFloat(self.tabViews.count) + 6 * CGFloat(self.tabViews.count - 1), height: self.frame.size.height)
        })

        self.scroll(to: newTab, animated: true)
    }
}

extension BrowserTabBar: BrowserTabViewDelegate {
    func browserTabView(didTap view: BrowserTabView) {
        self.selectedIndex = self.tabViews.firstIndex(of: view) ?? 0
    }

    func browserTabView(closeRequired view: BrowserTabView) {
        guard let index = self.tabViews.firstIndex(of: view),
              self.tabViews.indices.contains(index) else {
            return
        }
        self.tabViews.remove(at: index)

        /// TODO:  index == 0
        self.updateSelectedIndex(from: index, to: index - 1)
    }
}
