<!-- i18n-source: README.md@67cfc454ddfa4fddc18761183ca2883266d9be65 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg" alt="MobileCI: Write, check and version the CI of iOS, Flutter and React Native apps."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml/badge.svg" alt="CI ステータス"></a>
<a href="https://github.com/muhittincamdali/MobileCI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg" alt="最新バージョン: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg" alt="対応プラットフォーム: macOS 14+ · iOS 17+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg" alt="言語バージョン: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg" alt="ライセンス: MIT"></picture></a>
</p>

<p align="center">
<a href="#クイックスタート"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-ja-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-ja-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-ja-light.svg" alt="はじめる"></picture></a>
<a href="https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-ja-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-ja-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-ja-light.svg" alt="ドキュメント"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-ja-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-ja-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-ja-light.svg" alt="サンプル"></picture></a>
</p>

> このドキュメントは英語版 README の翻訳です。内容が異なる場合は英語版が最新です。

<!-- brand:end -->

MobileCI は、iOS、Flutter、React Native アプリの CI のためのコマンドラインツール、GitHub Action、Swift ライブラリです。リポジトリを読み取り、現行の runner イメージで各アプリをビルドしてテストする GitHub Actions workflow を書き出します。さらに、モバイル CI を遅く、高価に、または危険にしてしまう既存 workflow の誤りを検査し、アプリのバージョンとビルド番号を Xcode、Flutter、Gradle、Expo のファイル間で揃えて管理します。runner の細部をひとつずつ学ばなくても動くパイプラインがほしい、アプリ開発者のためのツールです。

## 主な特長

- **CI から見えるものを検出** — Xcode プロジェクトとその共有 scheme、CocoaPods と Swift パッケージの利用状況、Flutter のプラットフォームフォルダ、React Native や Expo アプリのパッケージマネージャ、そして共有されていない scheme のように初回実行でつまずく問題を検出します。
- **最新でピン留めされた workflow を生成** — すべての action をリリース commit にピン留めし、`macos-26` で Xcode 26.6 を選択、権限は `contents: read`、さらにタイムアウト、キャッシュ、置き換えられた実行のキャンセルも設定します。生成されたファイルはすべて、このツール自身の lint と actionlint を通過します。
- **モバイル workflow 向けの 16 個の lint ルール** — `macos-latest` のずれ、Xcode の選択漏れ、`| xcbeautify` に隠れたテスト失敗、タイムアウトの欠落、ピン留めされていない action、pull request タイトルからのスクリプトインジェクション、`pull_request_target` のチェックアウトなどを検出します。出力はテキスト、JSON、GitHub annotation、SARIF に対応しています。
- **ひとつのバージョンコマンド** — `mobileci version bump patch --build` が `MARKETING_VERSION`、`pubspec.yaml`、`package.json`、`app.json`、`build.gradle` をまとめて更新します。Google Play の上限を超えるビルド番号はオーバーフローさせず、拒否します。
- **信頼できないリポジトリでも安全** — ファイルはサイズ制限付きで読み込み、YAML のエイリアスとネストには上限があり、`detect` はシンボリックリンク先のフォルダには入らず、メッセージにファイルの内容を引用せず、annotation 出力から workflow コマンドを注入することもできません。
- **テスト済みで、自分たちでも使用** — 119 個の Swift Testing テストが macOS と iPhone シミュレータで動作します。このリポジトリのサンプルの iOS と Flutter の workflow は `mobileci init` で書き出されており、ジェネレータの出力とずれると CI ジョブが失敗します。

## クイックスタート

**1. ツールをインストールする**

```sh
git clone https://github.com/muhittincamdali/MobileCI.git
cd MobileCI
swift build --configuration release --product mobileci
sudo install .build/release/mobileci /usr/local/bin/mobileci
```

**2. アプリ用の workflow を書き出す**

アプリのリポジトリのルートで実行します。

```sh
mobileci detect   # what CI will see
mobileci init     # writes .github/workflows/ios.yml, flutter.yml or react-native.yml
```

**3. 検査して push する**

```sh
mobileci lint
git add .github/workflows && git commit -m "ci: build and test on GitHub Actions" && git push
```

## インストール

### コマンドラインツール

クイックスタートのとおりソースからビルドします。成果物は単一の実行ファイルです。macOS 14 以降、および Swift 6.2 以降を備えた Linux で動作します。

### GitHub Action

この action は runner 上でツールをビルドし、リポジトリの workflow を lint します。検出結果は pull request 上に annotation として表示されます。

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

入力: `paths`、`format`（`github`、`text`、`json`、`sarif`）、`fail-on`、`disable`、`output`（[action.yml](action.yml)）。

### Swift パッケージ

Xcode で **File › Add Package Dependencies…** を選び、リポジトリの URL を入力します。

```text
https://github.com/muhittincamdali/MobileCI.git
```

または `Package.swift` の `dependencies` に追加します。

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

## 使い方

### CI から見えるものを確認する

`mobileci detect` は、各プロジェクトを workflow が使う詳細とともに一覧表示し、最初に直すべき点を示します。

![mobileci detect](docs/images/terminal-detect-light.png)

### 既存の workflow を検査する

`mobileci lint` は `.github/workflows` 内のすべてのファイルを検査し、検出結果が `--fail-on`（既定は warning）に達するとステータス 1 で終了します。多くのアプリが最初に持つのは、たとえば次のような workflow です。

![最初の iOS workflow に対する mobileci lint](docs/images/terminal-lint-light.png)

`mobileci rules` は各ルールと修正方法を一覧表示します。それぞれのルールがなぜ重要かは、[ルールリファレンス](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)で説明しています。当てはまらない箇所では、その行または直前の行のコメントでルールを無効にできます。

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
  # mobileci-ignore MCI012: the release job pushes the version tag with this token
```

### workflow を書き出す

`mobileci init` はプロジェクトごとにファイルをひとつ書き出します。`--stdout` を付けると書き出さずに表示し、`--xcode 26.4.1`、`--simulator "iPhone 17 Pro"`、`--scheme` などのオプションで値を変更できます。

![mobileci init と問題のない lint](docs/images/terminal-init-light.png)

生成された workflow はすべてのルールを通過します。

![生成された workflow に対する mobileci lint](docs/images/terminal-lint-generated-light.png)

[Templates](Templates) フォルダには、各種類のサンプルプロジェクトに対する出力が入っています。[iOS アプリ](Templates/ios.yml)、[CocoaPods を使う iOS アプリ](Templates/ios-cocoapods.yml)、[macOS アプリ](Templates/macos.yml)、[Swift パッケージ](Templates/swift-package.yml)、[Flutter アプリ](Templates/flutter.yml)、[React Native アプリ](Templates/react-native.yml)、[Expo アプリ](Templates/expo.yml)です。ツールをインストールしたくない場合は、どれかをコピーして使えます。

### バージョンを上げる

![mobileci version bump](docs/images/terminal-version-light.png)

`mobileci version` は見つかったすべてのバージョンとビルド番号を一覧表示します。`bump`、`set`、`build` はそれらをすべてのファイルで一度に変更し、`--dry-run` は書き込まずに結果だけを表示します。

### Swift から lint する

[サンプルアプリ](Examples/WorkflowCheck/WorkflowCheck/CheckModel.swift)は、次の呼び出しで iPhone 上の workflow を検査します。

```swift
static func check(_ text: String) -> [Finding] {
    WorkflowLinter().lint(text: text, path: "workflow.yml")
}
```

また、`mobileci init` が書き出す workflow も表示します（[Samples.swift](Examples/WorkflowCheck/WorkflowCheck/Samples.swift)）。

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

## デモ

サンプルアプリは、iPhone シミュレータ上で MobileCIKit を使ってサンプルの workflow を lint します。スクリーンショットは [`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh) で撮影しています。

| 最初の iOS workflow                                                       | `WorkflowGenerator` が書き出した workflow                                 |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| ![最初の workflow（ライト）](docs/images/example-firstWorkflow-light.png) | ![生成された workflow（ライト）](docs/images/example-generated-light.png) |
| ![最初の workflow（ダーク）](docs/images/example-firstWorkflow-dark.png)  | ![生成された workflow（ダーク）](docs/images/example-generated-dark.png)  |

「使い方」のターミナル画像は、サンプルリポジトリでツールを実際に実行したもので、[`scripts/capture-terminal.sh`](scripts/capture-terminal.sh) で描画しています（ダーク版は [docs/images](docs/images) にあります）。

アプリを実行するには、Xcode で [Examples/WorkflowCheck](Examples/WorkflowCheck) の `WorkflowCheck.xcodeproj` を開き、iPhone シミュレータを選んで **Run** を押します。Flutter のサンプルについては [Examples/README.md](Examples/README.md) でも説明しています。

## ドキュメント

API リファレンスと解説記事：

- [MobileCIKit リファレンス](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/)
- [Lint ルール](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)
- [制限と安全性](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/limitsandsafety)

## ガイド

- [はじめに](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/gettingstarted) — インストール、detect、init、lint、version を順を追って説明します。
- [workflow の生成](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/generatingworkflows) — 生成される各 job の内容と、すべてのオプション。
- [バージョン管理](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/versionmanagement) — 対象ファイル、ルール、制限。

## 動作要件

| プラットフォーム            | 最小バージョン           |
| --------------------------- | ------------------------ |
| macOS（ツールとライブラリ） | 14                       |
| iOS（ライブラリ）           | 17                       |
| Linux（ツールとライブラリ） | Swift 6.2 ツールチェーン |
| ツールチェーン              | Swift 6.2+（Xcode 26+）  |

生成される workflow は、GitHub の `macos-26`（Xcode 26.6）と `ubuntu-24.04` の runner を対象としています。すべての値はオプションで変更できます。

## アーキテクチャ

- `Sources/MobileCIKit/Detection` — `ProjectDetector` がリポジトリをたどり（3 階層、シンボリックリンク先のフォルダには入らない）、`.xcodeproj` バンドル、`pubspec.yaml`、`package.json`、`Package.swift` をテキストとして読み取ります。
- `Sources/MobileCIKit/Generation` — `WorkflowGenerator` は検証済みの値から YAML を 1 行ずつ書き出します。`PinnedAction` は action の commit を保持します。
- `Sources/MobileCIKit/Lint` — `YAMLValue` はすべてのノードの位置を保持します（[Yams](https://github.com/jpsim/Yams) を使い、ノード数と深さの制限を設けて、大きなスタックを持つスレッド上で解析します）。`Workflow` は job と step を公開し、ルールごとにひとつの関数が `Finding` を報告します。
- `Sources/MobileCIKit/Reporting` — テキスト、JSON、GitHub annotation、SARIF の出力。
- `Sources/MobileCIKit/Versioning` — `VersionFile` はバージョンのフィールドを見つけてその場で置き換えます。`VersionManager` はファイルをまたぐ変更を計画し、適用します。
- `Sources/mobileci` — コマンドラインインターフェース（[swift-argument-parser](https://github.com/apple/swift-argument-parser)）。

[`scripts/generate-workflows.sh`](scripts/generate-workflows.sh) は `Templates/` とサンプルの workflow を再生成します。`--check` を付けると、ジェネレータの出力と異なる場合に失敗します。

## ロードマップ

- リリースにビルド済みバイナリを添付し、action が実行のたびにツールをコンパイルしなくて済むようにする。
- ネイティブ Android プロジェクト（React Native や Flutter を使わない Gradle）の検出。
- 選択した runner イメージに存在しないシミュレータの宛先に対するルール。

## コントリビューション

コントリビューションを歓迎します。pull request を作成する前に[コントリビューションガイド](CONTRIBUTING.md)と[行動規範](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md)をお読みください。セキュリティ上の問題は[セキュリティポリシー](SECURITY.md)に従って非公開で報告してください。

## ライセンス

MIT ライセンスで公開しています。詳細は [LICENSE](LICENSE) を参照してください。
