<!-- i18n-source: README.md@bf610a4983a4fc55b272c414917e6ff504f5763f status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg" alt="MobileCI: Write, check and version the CI of iOS, Flutter and React Native apps."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml/badge.svg" alt="Status da CI"></a>
<a href="https://github.com/muhittincamdali/MobileCI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg" alt="Versão mais recente: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg" alt="Plataformas compatíveis: macOS 14+ · iOS 17+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg" alt="Versão da linguagem: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg" alt="Licença: MIT"></picture></a>
</p>

<p align="center">
<a href="#início-rápido"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-pt-BR-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-pt-BR-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-pt-BR-light.svg" alt="Começar"></picture></a>
<a href="https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-pt-BR-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-pt-BR-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-pt-BR-light.svg" alt="Documentação"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-pt-BR-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-pt-BR-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-pt-BR-light.svg" alt="Exemplos"></picture></a>
</p>

> Esta é uma tradução do README em inglês. Se houver diferença, vale a versão em inglês.

<!-- brand:end -->

O MobileCI é uma ferramenta de linha de comando, uma GitHub Action e uma biblioteca Swift para o
CI de apps iOS, Flutter e React Native. Ele lê seu repositório, escreve um workflow do GitHub
Actions que compila e testa cada app nas imagens de runner atuais, verifica os workflows
existentes em busca dos erros que deixam o CI mobile lento, caro ou inseguro e mantém a versão e
o número de build do app alinhados nos arquivos do Xcode, Flutter, Gradle e Expo. Ele é para
desenvolvedores de apps que querem um pipeline funcionando sem precisar aprender antes cada
detalhe dos runners.

## Destaques

- **Detecta o que o CI vai ver** — projetos do Xcode e seus schemes compartilhados, uso de
  CocoaPods e de pacotes Swift, pastas de plataforma do Flutter, o gerenciador de pacotes de um
  app React Native ou Expo e os problemas em que uma primeira execução tropeça, como um scheme
  que não está compartilhado.
- **Escreve workflows atuais e fixados** — cada action fixada no commit da sua versão,
  `macos-26` com o Xcode 26.6 selecionado, permissões `contents: read`, timeouts, caches e
  cancelamento de execuções que ficaram obsoletas; cada arquivo gerado passa no lint da própria
  ferramenta e no actionlint.
- **16 regras de lint para workflows mobile** — desvio de `macos-latest`, falta da seleção do
  Xcode, falhas de teste escondidas atrás de `| xcbeautify`, timeouts ausentes, actions não
  fixadas, injeção de script a partir de títulos de pull request e checkouts com
  `pull_request_target`, com saída em texto, JSON, annotations do GitHub e SARIF.
- **Um único comando de versão** — `mobileci version bump patch --build` atualiza juntos
  `MARKETING_VERSION`, `pubspec.yaml`, `package.json`, `app.json` e `build.gradle`, e recusa
  números de build acima do limite do Google Play em vez de estourá-lo.
- **Seguro com repositórios não confiáveis** — os arquivos são lidos com limites de tamanho, os
  aliases e o aninhamento de YAML são limitados, o `detect` não entra em pastas ligadas por
  links simbólicos, as mensagens nunca citam o conteúdo dos arquivos e a saída de annotations
  não consegue injetar comandos de workflow.
- **Testado e usado no próprio projeto** — 125 testes de Swift Testing rodam no macOS e em um
  simulador de iPhone; os workflows de iOS e Flutter dos exemplos deste repositório são escritos
  por `mobileci init`, e um job de CI falha quando eles se afastam do gerador.

## Início rápido

**1. Instale a ferramenta**

```sh
git clone https://github.com/muhittincamdali/MobileCI.git
cd MobileCI
swift build --configuration release --product mobileci
sudo install .build/release/mobileci /usr/local/bin/mobileci
```

**2. Escreva um workflow para o seu app**

Na raiz do repositório do seu app:

```sh
mobileci detect   # what CI will see
mobileci init     # writes .github/workflows/ios.yml, flutter.yml or react-native.yml
```

**3. Verifique e faça o push**

```sh
mobileci lint
git add .github/workflows && git commit -m "ci: build and test on GitHub Actions" && git push
```

## Instalação

### Ferramenta de linha de comando

Compile a partir do código-fonte como no início rápido; o resultado é um único executável.
Ela roda no macOS 14 ou posterior e no Linux com Swift 6.2 ou posterior.

### GitHub Action

A action compila a ferramenta no runner e faz o lint dos workflows do repositório; os achados
aparecem como annotations no pull request:

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

Entradas: `paths`, `format` (`github`, `text`, `json`, `sarif`), `fail-on`, `disable` e
`output` ([action.yml](action.yml)).

### Pacote Swift

No Xcode, escolha **File › Add Package Dependencies…** e informe a URL do repositório:

```text
https://github.com/muhittincamdali/MobileCI.git
```

Ou adicione-o às `dependencies` do seu `Package.swift`:

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

## Uso

### Veja o que o CI vai ver

O `mobileci detect` lista cada projeto com os detalhes que o workflow usa e aponta o que
corrigir primeiro:

![mobileci detect](docs/images/terminal-detect-light.png)

### Verifique um workflow existente

O `mobileci lint` verifica cada arquivo em `.github/workflows` e termina com status 1 quando um
achado atinge o nível de `--fail-on` (warning por padrão). Este é o tipo de primeiro workflow
com que muitos apps começam:

![mobileci lint em um primeiro workflow de iOS](docs/images/terminal-lint-light.png)

O `mobileci rules` lista cada regra com sua correção; a
[referência das regras](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)
explica por que cada uma importa. Silencie uma regra onde ela não se aplica com um comentário na
mesma linha ou na linha de cima:

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
  # mobileci-ignore MCI012: the release job pushes the version tag with this token
```

### Escreva um workflow

O `mobileci init` escreve um arquivo por projeto; `--stdout` imprime em vez de escrever, e opções
como `--xcode 26.4.1`, `--simulator "iPhone 17 Pro"` ou `--scheme` mudam os valores:

![mobileci init e um lint sem problemas](docs/images/terminal-init-light.png)

O workflow gerado passa em todas as regras:

![mobileci lint no workflow gerado](docs/images/terminal-lint-generated-light.png)

A pasta [Templates](Templates) contém a saída para um projeto de exemplo de cada tipo: um
[app iOS](Templates/ios.yml), um [app iOS com CocoaPods](Templates/ios-cocoapods.yml), um
[app macOS](Templates/macos.yml), um [pacote Swift](Templates/swift-package.yml), um
[app Flutter](Templates/flutter.yml), um [app React Native](Templates/react-native.yml) e um
[app Expo](Templates/expo.yml). Copie um deles se preferir não instalar a ferramenta.

### Aumente a versão

![mobileci version bump](docs/images/terminal-version-light.png)

O `mobileci version` lista todas as versões e números de build que encontra; `bump`, `set` e
`build` os alteram em todos os arquivos de uma vez, e `--dry-run` mostra o resultado sem
escrever nada.

### Lint a partir do Swift

O [app de exemplo](Examples/WorkflowCheck/WorkflowCheck/CheckModel.swift) verifica um workflow
em um iPhone com esta chamada:

```swift
static func check(_ text: String) -> [Finding] {
    WorkflowLinter().lint(text: text, path: "workflow.yml")
}
```

e mostra o workflow que o `mobileci init` escreveria para ele
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

## Demonstração

O app de exemplo faz o lint dos workflows de amostra com o MobileCIKit em um simulador de
iPhone; as capturas são feitas por
[`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh):

| Um primeiro workflow de iOS                                              | Escrito pelo `WorkflowGenerator`                                   |
| ------------------------------------------------------------------------ | ------------------------------------------------------------------ |
| ![Primeiro workflow, claro](docs/images/example-firstWorkflow-light.png) | ![Workflow gerado, claro](docs/images/example-generated-light.png) |
| ![Primeiro workflow, escuro](docs/images/example-firstWorkflow-dark.png) | ![Workflow gerado, escuro](docs/images/example-generated-dark.png) |

As imagens de terminal da seção Uso são execuções reais da ferramenta em um repositório de
amostra, renderizadas por [`scripts/capture-terminal.sh`](scripts/capture-terminal.sh) (as
versões escuras estão em [docs/images](docs/images)).

Para rodar o app, abra o `WorkflowCheck.xcodeproj` em [Examples/WorkflowCheck](Examples/WorkflowCheck)
com o Xcode, escolha um simulador de iPhone e pressione **Run**.
[Examples/README.md](Examples/README.md) também descreve o exemplo em Flutter.

## Documentação

Referência da API e artigos:

- [Referência do MobileCIKit](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/)
- [Regras de lint](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)
- [Limites e segurança](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/limitsandsafety)

## Guias

- [Primeiros passos](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/gettingstarted) — instalar, detect, init, lint e version, passo a passo.
- [Gerando workflows](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/generatingworkflows) — o que cada job gerado faz e todas as opções.
- [Gerenciamento de versões](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/versionmanagement) — os arquivos, as regras e os limites.

## Requisitos

| Plataforma                      | Versão mínima          |
| ------------------------------- | ---------------------- |
| macOS (ferramenta e biblioteca) | 14                     |
| iOS (biblioteca)                | 17                     |
| Linux (ferramenta e biblioteca) | Toolchain do Swift 6.2 |
| Ferramentas                     | Swift 6.2+ (Xcode 26+) |

Os workflows gerados têm como alvo os runners `macos-26` (Xcode 26.6) e `ubuntu-24.04` do
GitHub; todos os valores podem ser alterados com uma opção.

## Arquitetura

- `Sources/MobileCIKit/Detection` — o `ProjectDetector` percorre o repositório (3 níveis, sem
  entrar em pastas ligadas por links simbólicos) e lê como texto os bundles `.xcodeproj`,
  `pubspec.yaml`, `package.json` e `Package.swift`.
- `Sources/MobileCIKit/Generation` — o `WorkflowGenerator` escreve o YAML linha a linha a partir
  de valores validados; o `PinnedAction` guarda os commits das actions.
- `Sources/MobileCIKit/Lint` — o `YAMLValue` guarda a posição de cada nó (analisado com o
  [Yams](https://github.com/jpsim/Yams) em uma thread de pilha grande, com limites de nós e de
  profundidade), o `Workflow` expõe jobs e steps, e uma função por regra reporta `Finding`s.
- `Sources/MobileCIKit/Reporting` — saída em texto, JSON, annotations do GitHub e SARIF.
- `Sources/MobileCIKit/Versioning` — o `VersionFile` localiza os campos de versão e os substitui
  no próprio lugar; o `VersionManager` planeja e aplica uma mudança em vários arquivos.
- `Sources/mobileci` — a interface de linha de comando
  ([swift-argument-parser](https://github.com/apple/swift-argument-parser)).

O [`scripts/generate-workflows.sh`](scripts/generate-workflows.sh) regenera `Templates/` e os
workflows de exemplo; com `--check`, ele falha quando eles diferem da saída do gerador.

## Roteiro

- Binários pré-compilados anexados às versões, para que a action não compile a ferramenta a
  cada execução.
- Detecção de projetos Android nativos (Gradle sem React Native nem Flutter).
- Uma regra para destinos de simulador que não existem na imagem de runner selecionada.

## Como contribuir

Contribuições são bem-vindas. Leia o [guia de contribuição](CONTRIBUTING.md) e o [código de conduta](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) antes de abrir um pull request. Relate problemas de segurança de forma privada, como descrito na [política de segurança](SECURITY.md).

## Licença

Publicado sob a licença MIT. Veja [LICENSE](LICENSE).
