//
//  SKPaymentQueue+Rx.swift
//  RxStoreKit
//
//  Created by taisuke fujita on 2017/06/21.
//  Copyright © 2017年 Taisuke Fujita. All rights reserved.
//

import StoreKit
#if !RX_NO_MODULE
    import RxSwift
    import RxCocoa
#endif

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
    func verifyReceipt(transaction: SKPaymentTransaction, excludeOldTransaction: Bool = false) -> Observable<SKPaymentTransaction> {
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
            let json = try JSONSerialization.data(withJSONObject:
                [
                    "receipt-data": base64,
                    "exclude-old-transactions": excludeOldTransaction
                ], options: [])
            
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = json
            let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
            return URLSession.shared.rx.json(request: request).timeout(30, scheduler: scheduler)
                .flatMapLatest({ [unowned self] response -> Observable<SKPaymentTransaction> in
                    self.verificationResult(for: transaction, response: response)
                })
        } catch let error {
            return Observable.error(error)
        }
    }
    
    func verificationResult(for transaction: SKPaymentTransaction, response: Any) -> Observable<SKPaymentTransaction> {
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
                return Observable.of(transaction)
            } else {
                return Observable.error(ReceiptError.illegal)
            }
        } else {
            let error = ReceiptError.invalid(code: state)
            return Observable.error(error)
        }
    }
}

extension Reactive where Base: SKPaymentQueue {
    
    public var transactionObserver: RxSKPaymentTransactionObserver {
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

    public func add(product: SKProduct, shouldVerify: Bool) -> Observable<SKPaymentTransaction> {

        let payment = SKPayment(product: product)

        if shouldVerify {
            let observable = Observable<SKPaymentTransaction>.create { observer in

                let disposable = self.transactionObserver.rx_updatedTransaction
                    .flatMapLatest({ transaction -> Observable<SKPaymentTransaction> in
                        switch transaction.transactionState {
                        case .purchased:
                            return self.base.verifyReceipt(transaction: transaction)
                        default: print("transaction state = \(transaction.transactionState)")
                        }
                        return Observable.of(transaction)
                    })
                    .bind(to: observer)

                self.base.add(payment)

                return Disposables.create {
                    disposable.dispose()
                }
            }

            return observable
        }

        return Observable<SKPaymentTransaction>.create { observer in

            let disposable = self.transactionObserver.rx_updatedTransaction
                .subscribe(onNext:{ transaction in


                    switch transaction.transactionState {
                    case .purchased:
                        SKPaymentQueue.default().finishTransaction(transaction)

                        observer.onNext(transaction)
                        observer.onCompleted()

                    case .failed:
                        SKPaymentQueue.default().finishTransaction(transaction)
                        if let err = transaction.error {

                            observer.onError(err)
                        } else {
                            observer.onNext(transaction)
                            observer.onCompleted()
                        }

                    case .restored:
                        SKPaymentQueue.default().finishTransaction(transaction)
                        observer.onNext(transaction)

                    default:
                        observer.onNext(transaction)
                    }
                })

            self.base.add(payment)

            return Disposables.create() {
                disposable.dispose()
            }
        }
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
