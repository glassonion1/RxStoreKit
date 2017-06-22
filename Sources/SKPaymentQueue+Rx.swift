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

extension Reactive where Base: SKPaymentQueue {
    
    var transactionObserver: RxSKPaymentTransactionObserver {
        return RxSKPaymentTransactionObserver.shared
    }
    
    
    public func restoreCompletedTransactions() -> Observable<SKPaymentQueue> {
        
        let success = transactionObserver.rx_paymentQueueRestoreCompletedTransactionsFinished
            .do(onNext: { queue in
                for transaction in queue.transactions {
                    self.base.finishTransaction(transaction)
                }
            })
        
        let error = transactionObserver.rx_restoreCompletedTransactionsFailedWithError
            .map { (queue, error) -> SKPaymentQueue in
                for transaction in queue.transactions {
                    self.base.finishTransaction(transaction)
                }
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
                    observer.onNext(transaction)
                    //self.base.finishTransaction(transaction)
                    if transaction.downloads.count == 0 {
                        self.base.finishTransaction(transaction)
                    }
                case .restored:
                    print("restored")
                case .failed:
                    if let transactionError = transaction.error {
                        observer.onError(transactionError)
                        self.base.finishTransaction(transaction)
                    }
                case .deferred:
                    self.base.finishTransaction(transaction)
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
                if download.transaction.downloads.count == 0 {
                    self.base.finishTransaction(download.transaction)
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
