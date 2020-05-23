//
//  SKReceiptRefreshRequestDelegateProxy.swift
//  Pods-Example
//
//  Created by François Boulais on 16/12/2017.
//

import StoreKit
#if !RX_NO_MODULE
    import RxSwift
    import RxCocoa
#endif

public class SKReceiptRefreshRequestDelegateProxy
    : DelegateProxy<SKReceiptRefreshRequest, SKRequestDelegate>
    , DelegateProxyType
    , SKRequestDelegate {
    
    public init(parentObject: SKReceiptRefreshRequest) {
        super.init(parentObject: parentObject, delegateProxy: SKReceiptRefreshRequestDelegateProxy.self)
    }
    
    public static func registerKnownImplementations() {
        self.register { SKReceiptRefreshRequestDelegateProxy(parentObject: $0) }
    }
    
    public static func currentDelegate(for object: SKReceiptRefreshRequest) -> SKRequestDelegate? {
        return object.delegate
    }
    
    public static func setCurrentDelegate(_ delegate: SKRequestDelegate?, to object: SKReceiptRefreshRequest) {
        object.delegate = delegate
    }
    
    let responseSubject = PublishSubject<SKProductsResponse>()
    
    public func requestDidFinish(_ request: SKRequest) {
        _forwardToDelegate?.requestDidFinish?(request)
        responseSubject.onCompleted()
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        _forwardToDelegate?.request?(request, didFailWithError: error)
        responseSubject.onError(error)
    }

    deinit {
        responseSubject.on(.completed)
    }
}

