//
//  BaseViewController.swift
//  Sample
//
//  Created by Bodia on 10.03.2021.
//

import UIKit
import Fakery
import AkuratecoSDK

class BaseViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var lbResponse: UILabel!
    @IBOutlet var loader: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    lazy var faker = Faker()
    lazy var transactionStorage = AkuratecoTransactionStorage()
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lbResponse.text = ""
        lbResponse.numberOfLines = 0
        lbResponse.font = .systemFont(ofSize: 13)
        lbResponse.textColor = .darkText
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    // MARK: - Methods
    
    func openRedirect3Ds(termUrl: String, termUrl3Ds: String) {
        let redirect3DsVC = AkuratecoRedirect3dsVC()
        redirect3DsVC.termUrl = termUrl
        redirect3DsVC.termUrl3Ds = termUrl3Ds
        redirect3DsVC.completion = { [unowned self] in
            if ($0) { self.showInfo("The 3ds operation has been completed.") }
        }
        
        let navigation = UINavigationController(rootViewController: redirect3DsVC)
        present(navigation, animated: true, completion: nil)
    }
    
    func showInfo(_ info: String) {
        let alert = UIAlertController(title: "", message: info, preferredStyle: .alert)
        alert.addAction(.init(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Private Methods
    
    @objc private func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset.bottom = 0
        } else {
            scrollView.contentInset.bottom = keyboardViewEndFrame.height
        }
        
        scrollView.scrollIndicatorInsets.bottom = scrollView.contentInset.bottom
    }
}

// MARK: - AkuratecoResponseDelegate

extension BaseViewController: AkuratecoAdapterDelegate {
    func willSendRequest(_ request: AkuratecoDataRequest) {
        loader.startAnimating()
    }
    
    func didReceiveResponse(_ reponse: AkuratecoDataResponse?) {
        if let data = reponse?.data,
              let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
              let dictData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
            lbResponse.text = String(data: dictData, encoding: .utf8)
        
        } else {
            lbResponse.text = ""
        }
        
        DispatchQueue.main.async {
            self.scrollView.scrollRectToVisible(self.lbResponse.convert(self.lbResponse.frame, to: self.scrollView), animated: true)
        }
        
        loader.stopAnimating()
    }
}
