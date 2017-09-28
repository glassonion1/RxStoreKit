//
//  SKPaymentQueue+Rx.swift
//  RxStoreKit
//
//  Created by taisuke fujita on 2017/06/21.
//  Copyright © 2017年 Taisuke Fujita. All rights reserved.
//

import StoreKit
import RxSwift
import RxCocoa

public enum ReceiptError: Error {
    case invalid(code: Int)
    case illegal
}

extension ReceiptError: CustomStringConvertible {
    
    public var description: String {
        let message: String
        switch self {
        case .invalid(21000):
            message = "The App Store could not read the JSON object you provided."
        case .invalid(21002):
            message = "The data in the receipt-data property was malformed or missing."
        case .invalid(21003):
            message = "The receipt could not be authenticated."
        case .invalid(21004):
            message = "The shared secret you provided does not match the shared secret on file for your account."
        case .invalid(21005):
            message = "The receipt server is not currently available."
        case .invalid(21006):
            message = "This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response."
        case .invalid(21007):
            message = "This receipt is from the test environment, but it was sent to the production environment for verification. Send it to the test environment instead."
        case .invalid(21008):
            message = "This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead."
        default:
            message = "Unknown error occured."
        }
        return message
    }
}

extension SKPaymentQueue {
    open func verifyReceipt() -> Observable<Any> {
        #if DEBUG
            let verifyReceiptURLString = "https://sandbox.itunes.apple.com/verifyReceipt"
        #else
            let verifyReceiptURLString = "https://buy.itunes.apple.com/verifyReceipt"
        #endif
        let url = URL(string: verifyReceiptURLString)!
        do {
            let receiptURL = Bundle.main.appStoreReceiptURL
            let data = try Data(contentsOf: receiptURL!, options: [])
            let base64 = data.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            let json = try JSONSerialization.data(withJSONObject: ["receipt-data": base64], options: [])
            
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = json
            let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
            return URLSession.shared.rx.json(request: request).timeout(30, scheduler: scheduler)
        } catch let error {
            return Observable.error(error)
        }
    }
}

extension Reactive where Base: SKPaymentQueue {
    
    var transactionObserver: RxSKPaymentTransactionObserver {
        return RxSKPaymentTransactionObserver.shared
    }
    
    
    public func restoreCompletedTransactions() -> Observable<SKPaymentQueue> {
        
        let success = transactionObserver.rx_paymentQueueRestoreCompletedTransactionsFinished

        let error = transactionObserver.rx_restoreCompletedTransactionsFailedWithError
            .map { (queue, error) -> SKPaymentQueue in
                throw SKError(_nsError: error as NSError)
            }
        
        let observable = Observable<SKPaymentQueue>.create { observer in
            
            let disposable = success.amb(error).subscribe(observer)
            
            self.base.restoreCompletedTransactions()
            
            return Disposables.create {
                disposable.dispose()
            }
        }
        
        return observable
    }
    
    public func add(product: SKProduct) -> Observable<SKPaymentTransaction> {
        
        let payment = SKPayment(product: product)
        
        let observable = Observable<SKPaymentTransaction>.create { observer in
            
            let update = self.transactionObserver.rx_updatedTransaction.do(onNext: { transaction in
                switch transaction.transactionState {
                case .purchasing:
                    print("in progress")
                case .purchased:
                    _ = self.base.verifyReceipt().subscribe(onNext: {response in
                        let json = response as! [String: AnyObject]
                        let state = json["status"] as! Int
                        if state == 0 {
                            print(json)
                            let receipt = json["receipt"]!
                            let inApp = receipt["in_app"] as! [[String: Any]]
                            let contains = inApp.contains { element -> Bool in
                                let productId = element["product_id"] as! String
                                return productId == transaction.payment.productIdentifier
                            }
                            if contains {
                                observer.onNext(transaction)
                            } else {
                                observer.onError(ReceiptError.illegal)
                            }
                        } else {
                            let error = ReceiptError.invalid(code: state)
                            observer.onError(error)
                        }
                    }, onError: { error in
                        observer.onError(error)
                    })
                case .restored:
                    print("restored")
                case .failed:
                    if let transactionError = transaction.error {
                        observer.onError(transactionError)
                    }
                case .deferred:
                    print("deferred")
                }
            })
            let remove = self.transactionObserver.rx_removedTransaction
            
            let disposable = Observable.of(update, remove)
                .merge()
                .subscribe(onNext: { transaction in
                    if self.base.transactions.count == 0 {
                        observer.onCompleted()
                    }
                })
            
            self.base.add(payment)
            
            return Disposables.create {
                disposable.dispose()
            }
        }
        
        return observable
    }
    
    public func start(downloads: [SKDownload]) -> Observable<SKDownload> {
        
        let observable = Observable<SKDownload>.create { observer in
            
            let disposable = self.transactionObserver.rx_updatedDownload.subscribe(onNext: { download in
                switch (download.downloadState) {
                case .waiting:
                    print("waiting")
                case .active:
                    print("active")
                case .finished:
                    observer.onNext(download)
                case .failed:
                    if let downloadError = download.error {
                        observer.onError(downloadError)
                    }
                case .cancelled:
                    observer.onCompleted()
                case .paused:
                    print("paused")
                }
            })
            
            self.base.start(downloads)
            
            return Disposables.create {
                disposable.dispose()
            }
        }
        
        return observable
    }
}
