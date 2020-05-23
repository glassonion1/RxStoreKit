//
//  RxSKPaymentTransactionObserver.swift
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

public class RxSKPaymentTransactionObserver {
    
    static let shared = RxSKPaymentTransactionObserver()
    
    private init() {
        SKPaymentQueue.default().add(observer)
    }
    
    deinit {
        SKPaymentQueue.default().remove(observer)
    }
    
    let observer = Observer()
    
    class Observer: NSObject, SKPaymentTransactionObserver {
        
        let updatedTransactionSubject = PublishSubject<SKPaymentTransaction>()
        let removedTransactionSubject = PublishSubject<SKPaymentTransaction>()
        let restoreCompletedTransactionsFailedWithErrorSubject = PublishSubject<(SKPaymentQueue, Error)>()
        let paymentQueueRestoreCompletedTransactionsFinishedSubject = PublishSubject<SKPaymentQueue>()
        let updatedDownloadSubject = PublishSubject<SKDownload>()
        
        public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
            transactions.forEach({ transaction in
                updatedTransactionSubject.onNext(transaction)
            })
        }
        
        public func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
            transactions.forEach({ transaction in
                removedTransactionSubject.onNext(transaction)
            })
        }
        
        public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
            restoreCompletedTransactionsFailedWithErrorSubject.onNext((queue, error))
        }
        
        public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
            paymentQueueRestoreCompletedTransactionsFinishedSubject.onNext(queue)
        }
        
        public func paymentQueue(_ queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {
            downloads.forEach({ download in
                updatedDownloadSubject.onNext(download)
            })
        }
        
    }
    
    public var rx_updatedTransaction: Observable<SKPaymentTransaction> {
        return observer.updatedTransactionSubject
    }
    
    var rx_removedTransaction: Observable<SKPaymentTransaction> {
        return observer.removedTransactionSubject
    }
    
    var rx_restoreCompletedTransactionsFailedWithError: Observable<(SKPaymentQueue, Error)> {
        return observer.restoreCompletedTransactionsFailedWithErrorSubject
    }
    
    var rx_paymentQueueRestoreCompletedTransactionsFinished: Observable<SKPaymentQueue> {
        return observer.paymentQueueRestoreCompletedTransactionsFinishedSubject
    }
    
    var rx_updatedDownload: Observable<SKDownload> {
        return observer.updatedDownloadSubject
    }
}
