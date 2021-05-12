//
//  BrowserTabView.swift
//  VideoClip
//
//  Created by p-x9 on 2021/04/26.
//  
//

import UIKit
import SnapKit

protocol BrowserTabViewDelegate: AnyObject {
    func browserTabView(didTap view: BrowserTabView)
    func browserTabView(closeRequired view: BrowserTabView)
}

class BrowserTabView: UIView {

    var title: String? {
        didSet {
            self.label.text = self.title
        }
    }

    let label: UILabel
    let imageView: UIImageView
    let closeButton: UIButton

    weak var delegate: BrowserTabViewDelegate?

    init() {
        self.label = UILabel()
        self.imageView = UIImageView()
        self.closeButton = UIButton()

        super.init(frame: .zero)

        self.addSubview(label)
        self.addSubview(imageView)
        self.addSubview(closeButton)

        self.setUpConstraints()
        self.setUpGestureRecognizer()

        self.closeButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUpConstraints() {
        self.label.snp.makeConstraints { make in
            make.top.bottom.equalTo(self)
            make.leading.equalTo(self.imageView).offset(4)
            make.trailing.equalTo(self.closeButton).offset(4)
        }
        self.imageView.snp.makeConstraints {make in
            make.width.height.equalTo(15)
            make.leading.equalTo(self).offset(4)
            make.centerY.equalTo(self)
        }
        self.closeButton.snp.makeConstraints {make in
            make.width.height.equalTo(15)
            make.centerY.equalTo(self)
            make.trailing.equalTo(self).offset(-4)
        }
    }
    func setUpGestureRecognizer() {
        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.addTarget(self, action: #selector(didTapped(_:)))
        self.addGestureRecognizer(gestureRecognizer)
    }

    @objc
    func didTapped(_ sender: UITapGestureRecognizer) {
        print("didTapped:\(self)")
        delegate?.browserTabView(didTap: self)
    }

    @objc
    func handleCloseButton(_ sender: UIButton) {
        delegate?.browserTabView(closeRequired: self)
    }
}
