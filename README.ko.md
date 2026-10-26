<!-- i18n-source: README.md@ad7225472d3417634cddc96fcda1069257fc82f5 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg" alt="MobileCI: Write, check and version the CI of iOS, Flutter and React Native apps."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml/badge.svg" alt="CI 상태"></a>
<a href="https://github.com/muhittincamdali/MobileCI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg" alt="최신 버전: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg" alt="지원 플랫폼: macOS 14+ · iOS 17+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg" alt="언어 버전: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg" alt="라이선스: MIT"></picture></a>
</p>

<p align="center">
<a href="#빠른-시작"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-ko-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-ko-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-ko-light.svg" alt="시작하기"></picture></a>
<a href="https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-ko-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-ko-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-ko-light.svg" alt="문서"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-ko-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-ko-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-ko-light.svg" alt="예제"></picture></a>
</p>

> 이 문서는 영어 README의 번역본입니다. 내용이 다를 경우 영어 버전이 최신입니다.

<!-- brand:end -->

MobileCI는 iOS, Flutter, React Native 앱의 CI를 위한 커맨드 라인 도구이자 GitHub Action이며 Swift 라이브러리입니다. 저장소를 읽어 최신 runner 이미지에서 각 앱을 빌드하고 테스트하는 GitHub Actions workflow를 작성하고, 모바일 CI를 느리게, 비싸게, 또는 안전하지 않게 만드는 실수가 기존 workflow에 있는지 검사하며, 앱의 버전과 빌드 번호를 Xcode, Flutter, Gradle, Expo 파일 전반에서 일치하도록 관리합니다. runner의 세부 사항을 일일이 배우지 않고도 동작하는 파이프라인을 원하는 앱 개발자를 위한 도구입니다.

## 주요 기능

- **CI가 보게 될 내용을 감지** — Xcode 프로젝트와 공유된 scheme, CocoaPods 및 Swift 패키지 사용 여부, Flutter 플랫폼 폴더, React Native 또는 Expo 앱의 패키지 매니저, 그리고 공유되지 않은 scheme처럼 첫 실행에서 걸리기 쉬운 문제를 감지합니다.
- **최신 상태로 고정된 workflow 작성** — 모든 action을 릴리스 commit에 고정하고, `macos-26`에서 Xcode 26.6을 선택하며, 권한은 `contents: read`로 두고, 타임아웃과 캐시를 설정하며 대체된 이전 실행은 취소합니다. 생성된 파일은 모두 이 도구 자체의 lint와 actionlint를 통과합니다.
- **모바일 workflow용 lint 규칙 16개** — `macos-latest` 드리프트, 누락된 Xcode 선택, `| xcbeautify` 뒤에 가려진 테스트 실패, 누락된 타임아웃, 고정되지 않은 action, pull request 제목을 통한 스크립트 인젝션, `pull_request_target` 체크아웃을 검사하며 출력은 텍스트, JSON, GitHub annotation, SARIF 형식을 지원합니다.
- **하나의 버전 명령** — `mobileci version bump patch --build`가 `MARKETING_VERSION`, `pubspec.yaml`, `package.json`, `app.json`, `build.gradle`을 한꺼번에 업데이트하며, Google Play의 한도를 넘는 빌드 번호는 넘치게 두지 않고 거부합니다.
- **신뢰할 수 없는 저장소에서도 안전** — 파일은 크기 제한을 두고 읽고, YAML 별칭과 중첩 깊이에는 한도가 있으며, 심볼릭 링크는 따라가지 않고, 메시지에는 파일 내용을 인용하지 않으며, annotation 출력으로는 workflow 명령을 주입할 수 없습니다.
- **테스트를 거쳐 직접 사용 중** — 108개의 Swift Testing 테스트가 macOS와 iPhone 시뮬레이터에서 실행됩니다. 이 저장소 예제의 iOS 및 Flutter workflow는 `mobileci init`으로 작성되며, 생성기의 결과와 달라지면 CI 작업이 실패합니다.

## 빠른 시작

**1. 도구 설치**

```sh
git clone https://github.com/muhittincamdali/MobileCI.git
cd MobileCI
swift build --configuration release --product mobileci
sudo install .build/release/mobileci /usr/local/bin/mobileci
```

**2. 앱용 workflow 작성**

앱 저장소의 루트에서 실행하세요.

```sh
mobileci detect   # what CI will see
mobileci init     # writes .github/workflows/ios.yml, flutter.yml or react-native.yml
```

**3. 검사하고 push**

```sh
mobileci lint
git add .github/workflows && git commit -m "ci: build and test on GitHub Actions" && git push
```

## 설치

### 커맨드 라인 도구

빠른 시작에서처럼 소스에서 빌드하세요. 결과물은 실행 파일 하나입니다. macOS 14 이상, 그리고 Swift 6.2 이상이 설치된 Linux에서 실행됩니다.

### GitHub Action

이 action은 runner에서 도구를 빌드하고 저장소의 workflow를 lint합니다. 발견된 항목은 pull request에 annotation으로 표시됩니다.

```yaml
jobs:
  workflows:
    runs-on: ubuntu-24.04
    timeout-minutes: 15
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: muhittincamdali/MobileCI@main # pin to a release commit, as MCI001 asks
        with:
          fail-on: warning
```

입력값: `paths`, `format`(`github`, `text`, `json`, `sarif`), `fail-on`, `disable`, `output`([action.yml](action.yml)).

### Swift 패키지

Xcode에서 **File › Add Package Dependencies…**를 선택하고 저장소 URL을 입력하세요.

```text
https://github.com/muhittincamdali/MobileCI.git
```

또는 `Package.swift`의 `dependencies`에 추가하세요.

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/MobileCI.git", branch: "main")
],
targets: [
    .target(name: "YourTool", dependencies: [
        .product(name: "MobileCIKit", package: "MobileCI")
    ])
]
```

## 사용법

### CI가 보게 될 내용 확인

`mobileci detect`는 각 프로젝트를 workflow가 사용하는 세부 정보와 함께 나열하고, 먼저 고쳐야 할 점을 알려 줍니다.

![mobileci detect](docs/images/terminal-detect-light.png)

### 기존 workflow 검사

`mobileci lint`는 `.github/workflows`의 모든 파일을 검사하고, 발견된 항목이 `--fail-on`(기본값은 warning) 수준에 이르면 종료 상태 1로 끝납니다. 많은 앱이 처음에 갖게 되는 workflow는 다음과 같은 모습입니다.

![첫 iOS workflow에 대한 mobileci lint](docs/images/terminal-lint-light.png)

`mobileci rules`는 각 규칙과 해결 방법을 나열합니다. 각 규칙이 왜 중요한지는 [규칙 레퍼런스](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)에 설명되어 있습니다. 해당하지 않는 곳에서는 같은 줄이나 바로 윗줄의 주석으로 규칙을 끌 수 있습니다.

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
  # mobileci-ignore MCI012: the release job pushes the version tag with this token
```

### workflow 작성

`mobileci init`은 프로젝트마다 파일 하나를 작성합니다. `--stdout`을 쓰면 파일 대신 출력하고, `--xcode 26.4.1`, `--simulator "iPhone 17 Pro"`, `--scheme` 같은 옵션으로 값을 바꿀 수 있습니다.

![mobileci init과 문제없는 lint](docs/images/terminal-init-light.png)

생성된 workflow는 모든 규칙을 통과합니다.

![생성된 workflow에 대한 mobileci lint](docs/images/terminal-lint-generated-light.png)

[Templates](Templates) 폴더에는 종류별 샘플 프로젝트 하나씩에 대한 출력이 들어 있습니다. [iOS 앱](Templates/ios.yml), [CocoaPods를 쓰는 iOS 앱](Templates/ios-cocoapods.yml), [macOS 앱](Templates/macos.yml), [Swift 패키지](Templates/swift-package.yml), [Flutter 앱](Templates/flutter.yml), [React Native 앱](Templates/react-native.yml), [Expo 앱](Templates/expo.yml)입니다. 도구를 설치하고 싶지 않다면 이 중 하나를 복사해서 쓰세요.

### 버전 올리기

![mobileci version bump](docs/images/terminal-version-light.png)

`mobileci version`은 찾은 모든 버전과 빌드 번호를 나열합니다. `bump`, `set`, `build`는 모든 파일에서 한 번에 값을 바꾸며, `--dry-run`은 쓰지 않고 결과만 보여 줍니다.

### Swift에서 lint

[예제 앱](Examples/WorkflowCheck/WorkflowCheck/CheckModel.swift)은 다음 호출로 iPhone에서 workflow를 검사합니다.

```swift
static func check(_ text: String) -> [Finding] {
    WorkflowLinter().lint(text: text, path: "workflow.yml")
}
```

그리고 `mobileci init`이 해당 프로젝트에 대해 작성할 workflow도 보여 줍니다([Samples.swift](Examples/WorkflowCheck/WorkflowCheck/Samples.swift)).

```swift
let project = DetectedProject(directory: ".", kind: .xcode(XcodeProject(
    projectFile: "WorkflowCheck.xcodeproj",
    workspaceFile: nil,
    schemes: [XcodeScheme(name: "WorkflowCheck", hasTests: true)],
    platform: .iOS,
    usesCocoaPods: false,
    usesBundler: false,
    usesSwiftPackages: false
)))
return try WorkflowGenerator().workflow(for: project).contents
```

## 데모

예제 앱은 iPhone 시뮬레이터에서 MobileCIKit으로 샘플 workflow를 lint합니다. 스크린샷은 [`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh)로 촬영했습니다.

| 첫 iOS workflow                                                     | `WorkflowGenerator`가 작성한 workflow                               |
| ------------------------------------------------------------------- | ------------------------------------------------------------------- |
| ![첫 workflow, 라이트](docs/images/example-firstWorkflow-light.png) | ![생성된 workflow, 라이트](docs/images/example-generated-light.png) |
| ![첫 workflow, 다크](docs/images/example-firstWorkflow-dark.png)    | ![생성된 workflow, 다크](docs/images/example-generated-dark.png)    |

사용법 섹션의 터미널 이미지는 샘플 저장소에서 도구를 실제로 실행한 결과이며 [`scripts/capture-terminal.sh`](scripts/capture-terminal.sh)로 렌더링했습니다(다크 버전은 [docs/images](docs/images)에 있습니다).

앱을 실행하려면 Xcode로 [Examples/WorkflowCheck](Examples/WorkflowCheck)의 `WorkflowCheck.xcodeproj`를 열고, iPhone 시뮬레이터를 선택한 뒤 **Run**을 누르세요. [Examples/README.md](Examples/README.md)에는 Flutter 예제도 설명되어 있습니다.

## 문서

API 레퍼런스와 문서:

- [MobileCIKit 레퍼런스](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/)
- [Lint 규칙](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)
- [한계와 안전성](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/limitsandsafety)

## 가이드

- [시작하기](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/gettingstarted) — 설치, detect, init, lint, version을 단계별로 안내합니다.
- [workflow 생성](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/generatingworkflows) — 생성된 각 job이 하는 일과 모든 옵션.
- [버전 관리](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/versionmanagement) — 대상 파일, 규칙, 한계.

## 요구 사항

| 플랫폼                   | 최소 버전              |
| ------------------------ | ---------------------- |
| macOS(도구와 라이브러리) | 14                     |
| iOS(라이브러리)          | 17                     |
| Linux(도구와 라이브러리) | Swift 6.2 툴체인       |
| 툴체인                   | Swift 6.2+ (Xcode 26+) |

생성된 workflow는 GitHub의 `macos-26`(Xcode 26.6) 및 `ubuntu-24.04` runner를 대상으로 합니다. 모든 값은 옵션으로 바꿀 수 있습니다.

## 아키텍처

- `Sources/MobileCIKit/Detection` — `ProjectDetector`가 저장소를 탐색하며(3단계, 심볼릭 링크 제외) `.xcodeproj` 번들, `pubspec.yaml`, `package.json`, `Package.swift`를 텍스트로 읽습니다.
- `Sources/MobileCIKit/Generation` — `WorkflowGenerator`는 검증된 값으로 YAML을 한 줄씩 작성하고, `PinnedAction`은 action commit을 보관합니다.
- `Sources/MobileCIKit/Lint` — `YAMLValue`는 모든 노드의 위치를 유지하고([Yams](https://github.com/jpsim/Yams)로 노드 수와 깊이 제한을 두어 큰 스택을 가진 스레드에서 파싱합니다), `Workflow`는 job과 step을 제공하며, 규칙마다 함수 하나가 `Finding`을 보고합니다.
- `Sources/MobileCIKit/Reporting` — 텍스트, JSON, GitHub annotation, SARIF 출력.
- `Sources/MobileCIKit/Versioning` — `VersionFile`은 버전 필드를 찾아 그 자리에서 바꾸고, `VersionManager`는 여러 파일에 걸친 변경을 계획하고 적용합니다.
- `Sources/mobileci` — 커맨드 라인 인터페이스([swift-argument-parser](https://github.com/apple/swift-argument-parser)).

[`scripts/generate-workflows.sh`](scripts/generate-workflows.sh)는 `Templates/`와 예제 workflow를 다시 생성합니다. `--check`를 붙이면 생성기의 출력과 다를 때 실패합니다.

## 로드맵

- 릴리스에 미리 빌드된 바이너리를 첨부해, action이 실행할 때마다 도구를 컴파일하지 않도록 합니다.
- 네이티브 Android 프로젝트(React Native나 Flutter가 없는 Gradle) 감지.
- 선택한 runner 이미지에 없는 시뮬레이터 대상에 대한 규칙.

## 기여하기

기여를 환영합니다. pull request를 열기 전에 [기여 가이드](CONTRIBUTING.md)와 [행동 강령](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md)을 읽어 주세요. 보안 문제는 [보안 정책](SECURITY.md)에 따라 비공개로 제보해 주세요.

## 라이선스

MIT 라이선스로 배포됩니다. 자세한 내용은 [LICENSE](LICENSE)를 참고하세요.
