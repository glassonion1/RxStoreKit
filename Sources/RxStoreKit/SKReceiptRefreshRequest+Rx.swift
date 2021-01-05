//
//  SKReceiptRefreshRequest+Rx.swift
//  Pods-Example
//
//  Created by François Boulais on 16/12/2017.
//

import Foundation

import StoreKit
#if !RX_NO_MODULE
    import RxSwift
    import RxCocoa
#endif

extension SKReceiptRefreshRequest {
    
    public func createRxDelegateProxy() -> SKReceiptRefreshRequestDelegateProxy {
        return SKReceiptRefreshRequestDelegateProxy(parentObject: self)
    }
    
}

extension Reactive where Base: SKReceiptRefreshRequest {
    
    public var delegate: DelegateProxy<SKReceiptRefreshRequest, SKRequestDelegate> {
        return SKReceiptRefreshRequestDelegateProxy.proxy(for: base)
    }
    
    public var request: Completable {
        return SKReceiptRefreshRequestDelegateProxy.proxy(for: base).responseSubject.ignoreElements().asCompletable()
    }
    
}
