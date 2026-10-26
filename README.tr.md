<!-- i18n-source: README.md@dd2916d8ed7ec53bff38f4304ac420eb57e36ab0 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg" alt="MobileCI: Write, check and version the CI of iOS, Flutter and React Native apps."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml/badge.svg" alt="CI durumu"></a>
<a href="https://github.com/muhittincamdali/MobileCI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg" alt="Son sürüm: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg" alt="Desteklenen platformlar: macOS 14+ · iOS 17+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg" alt="Dil sürümü: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg" alt="Lisans: MIT"></picture></a>
</p>

<p align="center">
<a href="#hızlı-başlangıç"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-tr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-tr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-tr-light.svg" alt="Başlayın"></picture></a>
<a href="https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-tr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-tr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-tr-light.svg" alt="Dokümantasyon"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-tr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-tr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-tr-light.svg" alt="Örnekler"></picture></a>
</p>

> Bu belge İngilizce README'nin çevirisidir. İkisi arasında fark varsa güncel olan İngilizce sürümdür.

<!-- brand:end -->

MobileCI; iOS, Flutter ve React Native uygulamalarının CI'ı için bir komut satırı aracı, bir
GitHub Action ve bir Swift kütüphanesidir. Deponuzu okur, her uygulamayı güncel runner
imajlarında derleyip test eden bir GitHub Actions workflow'u yazar, mevcut workflow'larda mobil
CI'ı yavaş, pahalı ya da güvensiz yapan hataları arar ve uygulamanın sürüm ile build numarasını
Xcode, Flutter, Gradle ve Expo dosyalarında birbiriyle uyumlu tutar. Her runner ayrıntısını
öğrenmeden çalışan bir pipeline isteyen uygulama geliştiricileri için hazırlanmıştır.

## Öne çıkanlar

- **CI'ın göreceğini tespit eder** — Xcode projeleri ve paylaşılan scheme'leri, CocoaPods ve
  Swift paket kullanımı, Flutter platform klasörleri, bir React Native ya da Expo uygulamasının
  paket yöneticisi ve ilk çalıştırmada karşılaşılan sorunlar (örneğin paylaşılmamış bir scheme).
- **Güncel, sabitlenmiş workflow'lar yazar** — her action kendi sürüm commit'ine sabitlenir,
  `macos-26` üzerinde Xcode 26.6 seçilir, izinler `contents: read` olur; zaman aşımları,
  önbellekler ve iptal edilen eski çalıştırmalar da ayarlanır. Üretilen her dosya aracın kendi
  lint'inden ve actionlint'ten geçer.
- **Mobil workflow'lar için 16 lint kuralı** — `macos-latest` kayması, eksik Xcode seçimi,
  `| xcbeautify` arkasında gizlenen test hataları, eksik zaman aşımları, sabitlenmemiş
  action'lar, pull request başlıklarından script enjeksiyonu ve `pull_request_target`
  checkout'ları; çıktı metin, JSON, GitHub annotation ve SARIF biçimlerinde alınabilir.
- **Tek bir sürüm komutu** — `mobileci version bump patch --build`; `MARKETING_VERSION`,
  `pubspec.yaml`, `package.json`, `app.json` ve `build.gradle` dosyalarını birlikte günceller,
  Google Play'in sınırını aşan build numaralarını taşırmak yerine reddeder.
- **Güvenilmeyen depolarda güvenli** — dosyalar boyut sınırıyla okunur, YAML alias'ları ve iç
  içe geçme sınırlıdır, `detect` sembolik bağlantılı klasörlere inmez, mesajlar dosya
  içeriğinden alıntı yapmaz ve annotation çıktısı workflow komutu enjekte edemez.
- **Test edilmiş ve kendi üzerinde denenmiş** — 121 Swift Testing testi macOS'ta ve bir
  iPhone simülatöründe çalışır; bu deponun örneklerindeki iOS ve Flutter workflow'ları
  `mobileci init` ile yazılır ve üreticiden saptıklarında bir CI işi başarısız olur.

## Hızlı başlangıç

**1. Aracı kurun**

```sh
git clone https://github.com/muhittincamdali/MobileCI.git
cd MobileCI
swift build --configuration release --product mobileci
sudo install .build/release/mobileci /usr/local/bin/mobileci
```

**2. Uygulamanız için bir workflow yazın**

Uygulamanızın deposunun kök dizininde:

```sh
mobileci detect   # what CI will see
mobileci init     # writes .github/workflows/ios.yml, flutter.yml or react-native.yml
```

**3. Kontrol edin ve push'layın**

```sh
mobileci lint
git add .github/workflows && git commit -m "ci: build and test on GitHub Actions" && git push
```

## Kurulum

### Komut satırı aracı

Hızlı başlangıçta olduğu gibi kaynaktan derleyin; sonuç tek bir çalıştırılabilir dosyadır.
macOS 14 ve üzerinde, ayrıca Swift 6.2 veya üzeri bulunan Linux'ta çalışır.

### GitHub Action

Action, aracı runner üzerinde derler ve deponun workflow'larını lint'ler; bulgular pull
request üzerinde annotation olarak görünür:

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

Girdiler: `paths`, `format` (`github`, `text`, `json`, `sarif`), `fail-on`, `disable` ve
`output` ([action.yml](action.yml)).

### Swift paketi

Xcode'da **File › Add Package Dependencies…** menüsünü seçin ve depo adresini girin:

```text
https://github.com/muhittincamdali/MobileCI.git
```

Ya da `Package.swift` dosyanızdaki `dependencies` listesine ekleyin:

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

## Kullanım

### CI'ın göreceğini görün

`mobileci detect`, her projeyi workflow'un kullandığı ayrıntılarla listeler ve önce neyin
düzeltilmesi gerektiğini not eder:

![mobileci detect](docs/images/terminal-detect-light.png)

### Mevcut bir workflow'u kontrol edin

`mobileci lint`, `.github/workflows` içindeki her dosyayı kontrol eder ve bir bulgu `--fail-on`
düzeyine (varsayılan olarak warning) ulaştığında 1 koduyla çıkar. Birçok uygulamanın ilk
workflow'u şuna benzer:

![İlk iOS workflow'u üzerinde mobileci lint](docs/images/terminal-lint-light.png)

`mobileci rules` her kuralı çözümüyle birlikte listeler; her kuralın neden önemli olduğunu
[kural başvurusu](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)
açıklar. Bir kuralı geçerli olmadığı yerde, aynı satıra ya da bir üst satıra yorum yazarak
susturabilirsiniz:

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
  # mobileci-ignore MCI012: the release job pushes the version tag with this token
```

### Workflow yazın

`mobileci init` her proje için bir dosya yazar; `--stdout` dosya yazmak yerine ekrana basar,
`--xcode 26.4.1`, `--simulator "iPhone 17 Pro"` veya `--scheme` gibi seçenekler değerleri
değiştirir:

![mobileci init ve temiz bir lint](docs/images/terminal-init-light.png)

Üretilen workflow her kuraldan geçer:

![Üretilen workflow üzerinde mobileci lint](docs/images/terminal-lint-generated-light.png)

[Templates](Templates) klasörü, her türden bir örnek proje için üretilen çıktıyı içerir:
bir [iOS uygulaması](Templates/ios.yml), [CocoaPods'lu bir iOS uygulaması](Templates/ios-cocoapods.yml),
bir [macOS uygulaması](Templates/macos.yml), bir [Swift paketi](Templates/swift-package.yml),
bir [Flutter uygulaması](Templates/flutter.yml), bir [React Native uygulaması](Templates/react-native.yml)
ve bir [Expo uygulaması](Templates/expo.yml). Aracı kurmak istemezseniz birini kopyalayın.

### Sürümü yükseltin

![mobileci version bump](docs/images/terminal-version-light.png)

`mobileci version` bulduğu her sürümü ve build numarasını listeler; `bump`, `set` ve `build`
bunları tüm dosyalarda birden değiştirir, `--dry-run` ise sonucu yazmadan gösterir.

### Swift'ten lint

[Örnek uygulama](Examples/WorkflowCheck/WorkflowCheck/CheckModel.swift) bir workflow'u
iPhone üzerinde şu çağrıyla kontrol eder:

```swift
static func check(_ text: String) -> [Finding] {
    WorkflowLinter().lint(text: text, path: "workflow.yml")
}
```

ve `mobileci init`'in o proje için yazacağı workflow'u gösterir
([Samples.swift](Examples/WorkflowCheck/WorkflowCheck/Samples.swift)):

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

## Demo

Örnek uygulama, örnek workflow'ları MobileCIKit ile bir iPhone simülatöründe lint'ler;
ekran görüntüleri [`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh)
ile alınmıştır:

| İlk iOS workflow'u                                                  | `WorkflowGenerator` tarafından yazılan                                   |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| ![İlk workflow, açık tema](docs/images/example-firstWorkflow-light.png) | ![Üretilen workflow, açık tema](docs/images/example-generated-light.png) |
| ![İlk workflow, koyu tema](docs/images/example-firstWorkflow-dark.png)  | ![Üretilen workflow, koyu tema](docs/images/example-generated-dark.png)  |

Kullanım bölümündeki terminal görselleri, aracın örnek bir depo üzerindeki gerçek
çalıştırmalarıdır ve [`scripts/capture-terminal.sh`](scripts/capture-terminal.sh) ile
oluşturulmuştur (koyu temalı sürümler [docs/images](docs/images) içindedir).

Uygulamayı çalıştırmak için [Examples/WorkflowCheck](Examples/WorkflowCheck) içindeki
`WorkflowCheck.xcodeproj` dosyasını Xcode ile açın, bir iPhone simülatörü seçin ve **Run**'a
basın. [Examples/README.md](Examples/README.md) Flutter örneğini de anlatır.

## Dokümantasyon

API başvuru belgeleri ve makaleler:

- [MobileCIKit başvurusu](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/)
- [Lint kuralları](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)
- [Sınırlar ve güvenlik](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/limitsandsafety)

## Rehberler

- [Başlangıç](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/gettingstarted) — kurulum, detect, init, lint ve version, adım adım.
- [Workflow üretme](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/generatingworkflows) — üretilen her işin ne yaptığı ve tüm seçenekler.
- [Sürüm yönetimi](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/versionmanagement) — dosyalar, kurallar ve sınırlar.

## Gereksinimler

| Platform                  | En düşük sürüm         |
| ------------------------- | ---------------------- |
| macOS (araç ve kütüphane) | 14                     |
| iOS (kütüphane)           | 17                     |
| Linux (araç ve kütüphane) | Swift 6.2 araç zinciri |
| Araç zinciri              | Swift 6.2+ (Xcode 26+) |

Üretilen workflow'lar GitHub'ın `macos-26` (Xcode 26.6) ve `ubuntu-24.04` runner'larını
hedefler; her değer bir seçenekle değiştirilebilir.

## Mimari

- `Sources/MobileCIKit/Detection` — `ProjectDetector` depoyu gezer (3 seviye, sembolik
  bağlantılı klasörlere inmeden) ve `.xcodeproj` paketlerini, `pubspec.yaml`, `package.json` ve
  `Package.swift` dosyalarını metin olarak okur.
- `Sources/MobileCIKit/Generation` — `WorkflowGenerator` YAML'ı doğrulanmış değerlerden satır
  satır yazar; `PinnedAction` action commit'lerini tutar.
- `Sources/MobileCIKit/Lint` — `YAMLValue` her düğümün konumunu korur
  ([Yams](https://github.com/jpsim/Yams) ile, düğüm ve derinlik sınırlarıyla, geniş yığınlı
  bir thread üzerinde ayrıştırılır), `Workflow` job'ları ve adımları sunar, her kural için
  bir fonksiyon `Finding` bildirir.
- `Sources/MobileCIKit/Reporting` — metin, JSON, GitHub annotation ve SARIF çıktısı.
- `Sources/MobileCIKit/Versioning` — `VersionFile` sürüm alanlarını bulur ve yerinde
  değiştirir; `VersionManager` bir değişikliği dosyalar arasında planlar ve uygular.
- `Sources/mobileci` — komut satırı arayüzü
  ([swift-argument-parser](https://github.com/apple/swift-argument-parser)).

[`scripts/generate-workflows.sh`](scripts/generate-workflows.sh) `Templates/` klasörünü ve
örnek workflow'ları yeniden üretir; `--check` ile çalıştırıldığında üreticinin çıktısından
farklıysa başarısız olur.

## Yol haritası

- Sürümlere eklenmiş derlenmiş binary'ler; böylece action aracı her çalıştırmada derlemez.
- Yerel Android projelerinin (React Native veya Flutter olmayan Gradle) tespiti.
- Seçilen runner imajında bulunmayan simülatör hedefleri için bir kural.

## Katkıda bulunma

Katkılarınızı bekliyoruz. Pull request açmadan önce [katkı rehberini](CONTRIBUTING.md) ve [davranış kurallarını](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) okuyun. Güvenlik açıklarını [güvenlik politikasında](SECURITY.md) anlatıldığı gibi gizli olarak bildirin.

## Lisans

MIT lisansıyla yayımlanmıştır. Ayrıntılar için [LICENSE](LICENSE) dosyasına bakın.
