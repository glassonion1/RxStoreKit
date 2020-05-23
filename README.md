# RxStoreKit

RxStoreKit is lightweight and easy to use Rx support for StoreKit(In-App Purchases).

## Usage

### Request Products

```swift
import StoreKit
import RxSwift
import RxStoreKit

let disposeBag = DisposeBag()

let productRequest = SKProductsRequest(productIdentifiers: Set(["your app product id"]))
productRequest.rx.productsRequest
    .subscribe(onNext: { product in
        print(product)
    }).disposed(by: disposeBag)
productRequest.start()
```

### Restore Transactions

```swift
SKPaymentQueue.default().rx.restoreCompletedTransactions()
    .subscribe(onNext: { queue in
        // paymentQueueRestoreCompletedTransactionsFinished
        print(queue)
    }, onError: { error in
        // restoreCompletedTransactionsFailedWithError
        print(queue)
    }).disposed(by: disposeBag)
```

### Request payment

```swift
let productRequest = SKProductsRequest(productIdentifiers: Set(["xxx.xxx.xxx"]))
productRequest.rx.productsRequest
    .flatMap { response -> Observable<SKProduct> in
        return Observable.from(response.products)
    }
    .flatMap { product -> Observable<SKPaymentTransaction> in
        return SKPaymentQueue.default().rx.add(product: product)
    }
    .subscribe(onNext: { transaction in
        print(transaction)
    }).disposed(by: disposeBag)
productRequest.start()
```

### Request receipt refresh
```swift
let receiptRefreshRequest = SKReceiptRefreshRequest()
receiptRefreshRequest.rx.request
    .subscribe(onCompleted: {
        // Refreshed receipt is available
    }, onError: { error in
        print(error)
    }).disposed(by: disposeBag)
receiptRefreshRequest.start()
```

### Download hosting contents
Download In-App Purchase Contents
```swift
let productRequest = SKProductsRequest(productIdentifiers: Set(["xxx.xxx.xxx"]))
productRequest.rx.productsRequest
    .flatMap { response -> Observable<SKProduct> in
        return Observable.from(response.products)
    }
    .flatMap { product -> Observable<SKPaymentTransaction> in
        return SKPaymentQueue.default().rx.add(product: product)
    }
    .flatMap { transaction -> Observable<SKDownload> in
        return SKPaymentQueue.default().rx.start(downloads: transaction.downloads)
    }
    .subscribe(onNext: { download in
        print(download)
    }).disposed(by: disposeBag)
productRequest.start()
```

## Installation

This library depends on both __RxSwift__ and __RxCocoa__

### Swift Package Manager
Create a Package.swift file.
```swift
import PackageDescription

let package = Package(
  name: "RxTestProject",
  dependencies: [
    .package(url: "https://github.com/glassonion1/RxStoreKit.git", from: "1.3.0")
  ],
  targets: [
    .target(name: "RxTestProject", dependencies: ["RxStoreKit"])
  ]
)
```

## License

RxStoreKit is available under the MIT license. See the LICENSE file for more info.
