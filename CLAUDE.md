# CLAUDE.md — Carne Assada

Contexto obrigatório para qualquer agente que mexer neste projeto.
O documento-fonte é `spec.md` (v1.5). Quando este arquivo e o spec discordarem, **o spec vence** — e o desacordo é bug de documentação, a corrigir no mesmo commit.

---

## As sete pegadinhas que não podem ser quebradas

Regra 18.4 do spec. Cada uma existe porque quebrá-la destrói uma promessa do produto.

1. **Nenhuma saída de modelo é gravada sem revisão do usuário.** O modelo grava com `confirmado = false`; só o toque em "Confirmar todos" vira `true`. Princípio 0.1.
2. **Nenhum cálculo dentro do prompt.** Quantidade e rateio são Swift puro, em `ShoppingListCalculator` e `SplitCalculator`. Modelo de linguagem não soma dinheiro. Princípio 0.2.
3. **Nenhuma dependência externa.** Nem de animação, nem de nada. Não existe `Package.resolved` neste projeto e não deve passar a existir.
4. **Nenhuma imagem de nota gravada em disco.** Nem em cache temporário, nem no álbum. A `UIImage` vive no escopo de `ReceiptExtractor.ler(imagem:)` e morre com ele. Seção 20.3.
5. **Reduzir Movimento sempre respeitado.** As animações 16.5.1 a 16.5.7 viram fade de 0,2 s ou nada. **O háptico permanece.**
6. **Nenhum preço escrito no código.** O valor vem de `Product.displayPrice`. Busca por `19,90` no projeto tem de continuar retornando zero. Regra 11.16.6.
7. **Entitlement `desconhecido` nunca é tratado como "não comprado".** Nesse estado a área de conta mostra carregamento — não paywall e não a feature liberada. E um entitlement já conhecido **nunca** é rebaixado por falta de rede. Regras 11.16.4 e 23.11.

---

## Convenção de idioma (seção 18.1)

A fronteira fica na camada de modelo:

- **Modelo de dados em português `snake_case`**: `churrasco`, `item_compra`, `qtd_vegetarianos`, `categoria_rateio.bebida_alcoolica`. Exatamente como na seção 7 do spec, sem sinônimo.
- **Código em inglês**: tipos de serviço, funções, variáveis, nomes de arquivo, views.
- **Comentários e copy em português.** Todo serviço, função e view leva cabeçalho em português dizendo o que faz e **qual regra do spec implementa, com o número**.

Ruim: `// soma os valores`
Bom: `// criança entra com peso 0,5 no rateio geral para não pagar como adulto (regra 11.7)`

---

## Mapa da arquitetura

```
CarneAssada/
  App/              CarneAssadaApp — entrada, ModelContainer, environment dos serviços
  Models/           entidades SwiftData (português) + enums + esquema versionado
  Services/         puros e testáveis, sem SwiftUI:
                      ShoppingListCalculator  regra 11.1, 11.3, 11.4, 11.14
                      SplitCalculator         regras 11.5, 11.7, 11.8, 11.10.1, 11.11
                      ShareTextBuilder        seção 14.1 e 20.2
                      ListaService            grava a lista calculada no store
                      Formatacao              pt-BR num lugar só
  AI/               Foundation Models e Vision:
                      ModelAvailabilityService   regra 11.9
                      CrowdParameterExtractor    épico 8.2
                      ReceiptExtractor           épico 8.5 (Vision + texto)
                      PostEventAdjustmentExtractor épico 8.9
                      TiposGeneraveis            seção 13.1
  Store/            EntitlementService + CarneAssada.storekit
  DesignSystem/     Paleta, Estilos, Movimento
  Features/         uma pasta por área, telas da seção 10
  Resources/        Info.plist, PrivacyInfo.xcprivacy, Copy.swift, Assets.xcassets
```

Os serviços de `Services/` **não importam SwiftUI nem SwiftData** — é isso que os deixa testáveis sem container. `SplitCalculator` recebe `ItemParaRateio` e `ParticipanteParaRateio` (structs puras), não os `@Model`. Se você for tentado a passar a entidade direto, não passe: isso arrasta o container inteiro para dentro do teste.

---

## Build e teste

O projeto é gerado por **XcodeGen**. Depois de adicionar ou remover arquivo:

```bash
cd ~/"Carne Assada" && xcodegen generate
```

Build:

```bash
xcodebuild -project CarneAssada.xcodeproj -scheme CarneAssada -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build CODE_SIGNING_ALLOWED=NO
```

Testes:

```bash
xcodebuild -project CarneAssada.xcodeproj -scheme CarneAssada -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' test CODE_SIGNING_ALLOWED=NO
```

---

## Armadilhas conhecidas

- **`swipeActions` só funciona dentro de uma `List`.** Fora dela é ignorado em silêncio, sem erro e sem aviso. As telas 10.1, 10.5, 10.7 e 10.10 usam `List` por causa disso, com `LinhaSemFundo()` devolvendo o visual de card. Não troque por `ScrollView` + `LazyVStack`.
- **Em teste com SwiftData, use `ModelContext(container)`, nunca `container.mainContext`.** O contexto principal tem autosave próprio e torna o teste não determinístico.
- **Anexo de imagem no prompt não existe no SDK do iOS 26.** A premissa 4.3.1 do spec foi reprovada. Não tente "voltar" o épico 8.5 para imagem direto sem antes conferir o `FoundationModels.swiftinterface` do Xcode instalado.
- **`Info.plist` é manual**, então `CFBundleIconName` precisa estar declarado nele à mão — sem isso a App Store rejeita o binário.
- **`TARGETED_DEVICE_FAMILY: "1"`** está declarado em cada target, não só no projeto. Sem isso a validação da loja passa a exigir as orientações de iPad.
- **O rateio nunca é gravado.** É recalculado a cada leitura de `ResultadoView`. Não crie cache disso: é o que garante a exceção 9.2.7.

---

## Antes de abrir um PR

- `DOCUMENTACAO-TECNICA.md` atualizado **no mesmo commit**, incluindo a seção de divergências (seção 19 do spec).
- Testes passando.
- `grep -rn "19,90" CarneAssada/` retorna vazio.
- `grep -rnE "URLSession|URLRequest|dataTask" CarneAssada/` retorna vazio.
