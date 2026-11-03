# Mistura

App iOS em UIKit para buscar receitas por nome ou ingrediente, usando a API pública [TheMealDB](https://www.themealdb.com/api.php).

## Funcionalidades

- Busca por nome ou ingrediente, com debounce
- Histórico das últimas 10 receitas vistas, salvo com Core Data
- Detalhe da receita com ingredientes, modo de preparo e vídeo no YouTube
- Checklist de ingredientes, com link para o iFood Mercado usando os itens não marcados

## Requisitos

- Xcode 26 (o projeto usa isolamento padrão em `MainActor`)
- iOS 15 ou superior

Não há chaves nem configuração adicional. As dependências são baixadas pelo Swift Package Manager ao abrir o projeto.

## Como rodar

Abra `Mistura.xcodeproj`, selecione o scheme `Mistura` e um simulador, e rode com `Cmd+R`.

Na primeira abertura, o Xcode pede para confiar no plugin do SwiftLint.

## Testes

Rode pelo Xcode com `Cmd+U` ou pelo terminal:

```bash
xcodebuild test -project Mistura.xcodeproj -scheme Mistura -destination 'platform=iOS Simulator,name=iPhone 17' -enableCodeCoverage YES
```

Os testes usam Quick e Nimble, com dependências substituídas por doubles, nas pastas `Doubles` de `MisturaTests`. Classes e arquivos de teste terminam em `Tests`.

Use `QuickSpec` por padrão, porque seus closures já rodam na main actor. Use `AsyncSpec` apenas em arquivos com `await` ou `toEventually`, que exigem `@MainActor in` nos closures e `nonisolated(unsafe)` nas variáveis compartilhadas. Nos dois casos a classe é declarada como `nonisolated`, pois o target usa isolamento padrão em `MainActor`.

### Snapshots

As imagens de referência ficam em `__Snapshots__`, ao lado de cada arquivo de teste. `assertRenderSnapshot` fixa modo claro, tamanho de fonte e escala, para que o resultado não dependa dos ajustes do simulador.

Uma referência que não existe é gravada na primeira execução, e o teste falha para que ela seja revisada. Para regravar as referências que estão falhando depois de uma mudança visual intencional:

```bash
TEST_RUNNER_SNAPSHOT_TESTING_RECORD=failed xcodebuild test -project Mistura.xcodeproj -scheme Mistura -destination 'platform=iOS Simulator,name=iPhone 17'
```

Revise as imagens alteradas no diff antes de fazer o commit.

## Arquitetura

O app usa MVP com Coordinator, e as telas são escritas em View Code.

| Componente | Responsabilidade |
| --- | --- |
| `View` | Desenha o estado recebido em `render(_:)` e repassa as ações por closures |
| `ViewController` | Faz a ponte entre a View e o Presenter e cuida do ciclo de vida |
| `Presenter` | Concentra a lógica da tela e transforma dados de domínio em estados da View |
| `Repository` | Expõe os dados por protocolo (`RemoteMealRepository`, `CoreDataHistoryRepository`) |
| `AppCoordinator` | Controla a navegação |
| `AppSceneFactory` | Monta cada tela e injeta as dependências |

```
Mistura/
├── App/        Ciclo de vida, Coordinator e SceneFactory
├── Core/       Rede, persistência, carregamento de imagens e View Code
├── Data/       DTOs, modelos de domínio, endpoints e repositórios
└── Scenes/     Telas (Search, Detail) e textos compartilhados (Common)

MisturaTests/   Testes na mesma estrutura do app, mais Doubles e Helpers
```

## Dependências

Todas são usadas apenas em desenvolvimento. O app não tem dependências de terceiros em produção.

- [Quick](https://github.com/Quick/Quick) e [Nimble](https://github.com/Quick/Nimble): escrita dos testes
- [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing): testes de snapshot
- [SwiftLintPlugins](https://github.com/SimplyDanny/SwiftLintPlugins): lint durante o build, configurado em `.swiftlint.yml`
