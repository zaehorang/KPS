# Swift Style Guide

[StyleShare Swift Style Guide](https://github.com/StyleShare/swift-style-guide)를 기반으로 작성되었습니다.

본 문서에 나와있지 않은 규칙은 아래 문서를 따릅니다.

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines)

## 목차

- [코드 레이아웃](#코드-레이아웃)
- [네이밍](#네이밍)
- [클로저](#클로저)
- [타입](#타입)
- [주석](#주석)
- [프로그래밍 권장사항](#프로그래밍-권장사항)
- [Access Control](#access-control)
- [에러 처리](#에러-처리)
- [Concurrency](#concurrency)

## 코드 레이아웃

### 들여쓰기 및 띄어쓰기

- 들여쓰기에는 탭(tab) 대신 **4개의 space**를 사용합니다.
- 콜론(`:`)을 쓸 때에는 콜론의 오른쪽에만 공백을 둡니다.

```swift
let names: [String: String]?
```

### 줄바꿈

함수 정의가 최대 길이를 초과하는 경우:

```swift
func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
) -> UICollectionViewCell {
    // doSomething()
}
```

함수 호출이 최대 길이를 초과하는 경우:

```swift
let actionSheet = UIActionSheet(
    title: "정말 계정을 삭제하실 건가요?",
    delegate: self,
    cancelButtonTitle: "취소",
    destructiveButtonTitle: "삭제해주세요"
)
```

`if let` / `guard let` 구문이 길 경우:

```swift
if let user = self.veryLongFunctionNameWhichReturnsOptionalUser(),
   let name = user.veryLongFunctionNameWhichReturnsOptionalName() {
    // ...
}

guard let user = self.veryLongFunctionNameWhichReturnsOptionalUser(),
      let name = user.veryLongFunctionNameWhichReturnsOptionalName()
else {
    return
}
```

### 최대 줄 길이

- 한 줄은 최대 **120자**를 넘지 않아야 합니다.

### 빈 줄

- 빈 줄에는 공백이 포함되지 않도록 합니다.
- 모든 파일은 빈 줄로 끝나도록 합니다.
- MARK 구문 위와 아래에는 공백이 필요합니다.

### 임포트

모듈 임포트는 알파벳 순으로 정렬합니다. 내장 프레임워크를 먼저 임포트하고, 빈 줄로 구분합니다.

```swift
import Foundation

import RxSwift
import SnapKit
```

## 네이밍

### 클래스와 구조체

- UpperCamelCase를 사용합니다.
- 접두사(Prefix)를 붙이지 않습니다.

```swift
// Good
class SomeClass { }
struct SomeStructure { }

// Bad
class someClass { }
```

### 함수

- lowerCamelCase를 사용합니다.
- 함수 이름 앞에는 `get`을 붙이지 않습니다.

```swift
// Good
func name(for user: User) -> String?

// Bad
func getName(for user: User) -> String?
```

Action 함수의 네이밍은 **주어 + 동사 + 목적어** 형태를 사용합니다:

```swift
// Good
func backButtonDidTap() { }

// Bad
func back() { }
func pressBack() { }
```

### 변수와 상수

- lowerCamelCase를 사용합니다.

```swift
// Good
let maximumNumberOfLines = 3

// Bad
let MaximumNumberOfLines = 3
let MAX_LINES = 3
```

### 열거형

- enum 이름에는 UpperCamelCase를 사용합니다.
- 각 case에는 lowerCamelCase를 사용합니다.

```swift
// Good
enum Result {
    case success
    case failure
}

// Bad
enum Result {
    case Success
    case Failure
}
```

### 약어

- 약어로 시작하는 경우 소문자로, 그 외에는 대문자로 표기합니다.

```swift
// Good
let userID: Int?
let html: String?
let websiteURL: URL?
let urlString: String?

// Bad
let visitorId: Int?
let visitorHTML: String?
let websiteUrl: URL?
let URLString: String?
```

### Delegate

Delegate 메서드는 프로토콜명으로 네임스페이스를 구분합니다:

```swift
// Good
protocol UserCellDelegate {
    func userCellDidSetProfileImage(_ cell: UserCell)
    func userCell(_ cell: UserCell, didTapFollowButtonWith user: User)
}

// Bad
protocol UserCellDelegate {
    func didSetProfileImage()
    func followPressed(user: User)
}
```

## 클로저

파라미터와 리턴 타입이 없는 Closure 정의시에는 `() -> Void`를 사용합니다:

```swift
// Good
let completionBlock: (() -> Void)?

// Bad
let completionBlock: (() -> ())?
```

Closure 정의시 파라미터에는 괄호를 사용하지 않습니다:

```swift
// Good
{ operation, responseObject in
    // doSomething()
}

// Bad
{ (operation, responseObject) in
    // doSomething()
}
```

Trailing closure를 적극 활용합니다:

```swift
// Good
UIView.animate(withDuration: 0.5) {
    // doSomething()
}

// Bad
UIView.animate(withDuration: 0.5, animations: { () -> Void in
    // doSomething()
})
```

## 타입

`Array<T>`와 `Dictionary<T: U>` 보다는 `[T]`, `[T: U]`를 사용합니다:

```swift
// Good
var messages: [String]?
var names: [Int: String]?

// Bad
var messages: Array<String>?
var names: Dictionary<Int, String>?
```

## 주석

`///`를 사용해서 문서화에 사용되는 주석을 남깁니다:

```swift
/// 사용자 프로필을 그려주는 뷰
class ProfileView: UIView {
    /// 사용자 닉네임을 그려주는 라벨
    var nameLabel: UILabel!
}
```

`// MARK:`를 사용해서 연관된 코드를 구분짓습니다:

```swift
// MARK: - Properties

private let viewModel: SomeViewModel

// MARK: - Lifecycle

override func viewDidLoad() {
    super.viewDidLoad()
}

// MARK: - Actions

func buttonDidTap() {
    // doSomething()
}
```

## 프로그래밍 권장사항

### final 키워드

더이상 상속이 발생하지 않는 클래스는 항상 `final` 키워드로 선언합니다.

### Protocol Extension

프로토콜을 적용할 때에는 extension을 만들어서 관련된 메서드를 모아둡니다:

```swift
// Good
final class MyViewController: UIViewController {
    // ...
}

// MARK: - UITableViewDataSource

extension MyViewController: UITableViewDataSource {
    // ...
}

// MARK: - UITableViewDelegate

extension MyViewController: UITableViewDelegate {
    // ...
}

// Bad
final class MyViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // ...
}
```

### self 사용

클래스와 구조체 내부에서는 `self`를 명시적으로 사용합니다.

### 불변성 원칙

- 가능하면 `var`보다 `let`을 사용합니다.
- Class보다 Struct를 우선 고려합니다.

## Access Control

### 접근 제어자

| 접근 제어자 | 범위 |
|------------|------|
| `private` | 선언된 타입 내부 + 같은 파일의 extension |
| `fileprivate` | 같은 파일 내 |
| `internal` | 같은 모듈 내 (기본값) |
| `package` | 같은 패키지 내 (Swift 5.9+) |
| `public` | 외부 모듈에서 접근 가능 |
| `open` | 외부 모듈에서 상속/오버라이드 가능 |

### 사용 기준

- 기본적으로 가장 제한적인 접근 수준부터 시작합니다.
- `private`을 기본으로, 필요시 접근 범위를 넓힙니다.
- `fileprivate`는 같은 파일 내 여러 타입이 공유해야 할 때만 사용합니다.
- 프레임워크/라이브러리 개발 시에만 `public`, `open`을 사용합니다.

```swift
// Good
final class UserManager {
    private let storage: UserStorage
    private(set) var currentUser: User?
    
    func login() { }
}

// Bad - 불필요하게 넓은 접근 범위
final class UserManager {
    var storage: UserStorage
    var currentUser: User?
}
```

## 에러 처리

### 에러 타입 정의

에러는 `enum`으로 정의하고 `Error` 프로토콜을 채택합니다:

```swift
enum NetworkError: Error {
    case invalidURL
    case timeout
    case serverError(statusCode: Int)
}
```

### throws vs Result vs Optional

| 방식 | 사용 시점 |
|-----|----------|
| `throws` | 복구 가능한 에러, 에러 정보가 중요할 때 |
| `Result` | 비동기 콜백에서 성공/실패를 명시할 때 |
| `Optional` | 에러 원인이 중요하지 않을 때 |

### Typed Throws (Swift 6+)

에러 타입을 명시하여 컴파일 타임에 체크할 수 있습니다:

```swift
func validate(name: String) throws(ValidationError) {
    guard !name.isEmpty else {
        throw .emptyName
    }
}

do {
    try validate(name: "")
} catch {
    switch error {
    case .emptyName:
        print("Name is empty")
    case .tooShort:
        print("Name is too short")
    }
}
```

### try 사용 기준

```swift
// try - do-catch로 에러 처리
do {
    try riskyOperation()
} catch {
    // handle error
}

// try? - 실패 시 nil 반환 (에러 무시 가능할 때)
let result = try? optionalOperation()

// try! - 절대 실패하지 않는다고 확신할 때만 (지양)
let data = try! Data(contentsOf: bundledFileURL)
```

## Concurrency

### async/await

- 비동기 함수는 `async` 키워드를 사용합니다.
- 호출 시 `await`을 명시합니다.

```swift
func fetchUser(id: String) async throws -> User {
    let data = try await networkClient.request(endpoint: .user(id))
    return try decoder.decode(User.self, from: data)
}
```

### Actor

공유 상태를 안전하게 관리할 때 Actor를 사용합니다:

```swift
actor ImageCache {
    private var cache: [URL: UIImage] = [:]
    
    func image(for url: URL) -> UIImage? {
        cache[url]
    }
    
    func setImage(_ image: UIImage, for url: URL) {
        cache[url] = image
    }
}
```

### @MainActor

UI 업데이트가 필요한 코드에 사용합니다:

```swift
@MainActor
final class UserViewModel: ObservableObject {
    @Published var user: User?
    
    func loadUser() async {
        user = try? await userService.fetchCurrentUser()
    }
}
```

### Task 구조화

```swift
// 현재 컨텍스트 상속
Task {
    await loadData()
}

// 독립적인 Task (상위 취소 영향 없음)
Task.detached {
    await heavyComputation()
}
```

### Sendable

스레드 간 안전하게 전달할 수 있는 타입에 채택합니다:

```swift
// 값 타입은 보통 자동으로 Sendable
struct UserDTO: Sendable {
    let id: String
    let name: String
}

// 참조 타입은 명시적으로 체크 필요
final class ImmutableConfig: Sendable {
    let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
}
