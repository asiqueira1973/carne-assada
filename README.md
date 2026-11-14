# Carne Assada

App iOS que resolve as duas contas que todo organizador de churrasco faz na mão e erra: **quanto comprar** e **quanto cada um deve pagar**.

[Baixar na App Store](https://apps.apple.com/br/app/carne-assada/id6806629747)

<p>
  <img src="prints%20para%20a%20appstore/6.5/02-home-lista.png" width="160" alt="Lista de churrascos">
  <img src="prints%20para%20a%20appstore/6.5/03-descrever-turma.png" width="160" alt="Descrever a turma">
  <img src="prints%20para%20a%20appstore/6.5/04-lista-compras.png" width="160" alt="Lista de compras">
  <img src="prints%20para%20a%20appstore/6.5/08-conta-compras.png" width="160" alt="Conta do mercado">
  <img src="prints%20para%20a%20appstore/6.5/11-resultado.png" width="160" alt="Resultado do rateio">
</p>

Você descreve a turma em linguagem natural ("15 adultos, 4 crianças, 3 que não comem carne, do meio-dia até a noite") e o app devolve a lista de compras por categoria. Depois do mercado, você fotografa a nota, confere os itens, e cada participante recebe seu valor — quem não bebe não paga a cerveja, criança paga meia na carne.

Tudo roda **no aparelho**. Sem conta, sem backend, sem sincronização, sem custo por uso. O app funciona em modo avião.

## Principais funcionalidades

- Lista de compras por categoria a partir da descrição da turma (texto livre ou ajuste manual).
- Modo mercado para ir marcando o que já está no carrinho.
- Leitura da nota do mercado por foto, com revisão dos itens antes de gravar; ou lançamento manual.
- Rateio por participante considerando quem consumiu o quê (criança, quem não bebe, quem não come carne).
- Compartilhamento do resultado em texto pela share sheet.
- "Como foi?" depois do churrasco, para ajustar as próximas estimativas.
- Planejar é grátis e ilimitado; uma compra única libera a área de conta (nota, rateio, compartilhamento).

## Stack técnica

- Swift + SwiftUI, iOS 26+ (iPhone, retrato)
- SwiftData (armazenamento local)
- Foundation Models (modelo de linguagem on-device da Apple Intelligence) e Vision (leitura da nota)
- StoreKit 2 (compra única não-consumível)
- XcodeGen (`project.yml` gera o projeto Xcode)
- Swift Testing (testes unitários)
- Nenhuma dependência externa

## Como foi construído

Desenvolvido com Claude (Anthropic) a partir de uma especificação SDD: [spec.md](spec.md). A spec é o documento-fonte do produto e define princípios, modelo de dados, regras de negócio, critérios de aceite e um protocolo de mudanças incrementais. O repositório tem estes guardrails:

- [`CLAUDE.md`](CLAUDE.md) com o contexto obrigatório para agentes: "sete pegadinhas que não podem ser quebradas" (por exemplo, nenhuma saída de modelo gravada sem revisão do usuário, nenhum cálculo dentro do prompt, nenhuma imagem de nota em disco, nenhum preço no código), convenção de idioma e mapa da arquitetura.
- Testes em [`CarneAssadaTests/`](CarneAssadaTests/) cobrindo a seção 11 da spec: tabelas de consumo, multiplicadores, arredondamentos e regras de rateio. Inclui o exemplo trabalhado da regra 11.13 como regressão nomeada e um teste de propriedade que verifica, em 100 iterações, que **a soma dos valores individuais é sempre exatamente igual ao total**.
- Quantidade e rateio são Swift puro (`ShoppingListCalculator`, `SplitCalculator`), sem dependência de SwiftUI/SwiftData — o modelo de linguagem só extrai parâmetros, nunca soma dinheiro.

Documentação complementar:

| Arquivo | O que é |
|---|---|
| [`spec.md`](spec.md) | Documento-fonte do produto. Vence qualquer outro documento |
| [`CLAUDE.md`](CLAUDE.md) | Contexto para agentes: convenções, arquitetura, pegadinhas |
| [`DOCUMENTACAO-TECNICA.md`](DOCUMENTACAO-TECNICA.md) | O sistema como ele ficou, não como foi planejado |
| [`modelo-carne-assada.dbml`](modelo-carne-assada.dbml) | O modelo de dados em formato relacional, para dbdiagram.io |
| [`telas-png/`](telas-png/) | As telas de referência visual, em PNG |

## Status

Publicado na App Store (iOS).

## Licença

O código está disponível apenas para leitura e estudo. Veja [LICENSE](LICENSE).

## Contribuições

Issues são bem-vindas; pull requests não são aceitos. Veja [CONTRIBUTING.md](CONTRIBUTING.md).

## Como rodar

| | |
|---|---|
| Xcode | 26.1 ou mais novo |
| iOS | 26.0 ou mais novo (iPhone, retrato) |
| Ferramentas | [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen` |
| Dependências externas | **nenhuma** |

O projeto Xcode **não é versionado**: ele é gerado a partir de `project.yml`.

```bash
xcodegen generate && open CarneAssada.xcodeproj
```

Ou pela linha de comando:

```bash
xcodebuild -project CarneAssada.xcodeproj -scheme CarneAssada -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build CODE_SIGNING_ALLOWED=NO
```

Testes:

```bash
xcodebuild -project CarneAssada.xcodeproj -scheme CarneAssada -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' test CODE_SIGNING_ALLOWED=NO
```

### Em aparelho sem Apple Intelligence

O app é **100% funcional** sem o modelo on-device. Não existe função exclusiva de IA: a IA só encurta caminho.

Quando `SystemLanguageModel.default.availability` não é `.available`, os pontos de entrada de IA **somem da interface** — não ficam desabilitados — e o caminho manual assume:

| Com o modelo | Sem o modelo |
|---|---|
| Descrever a turma em texto livre | Steppers direto, com a copy "Vamos no modo manual — é rapidinho também." |
| Fotografar a nota do mercado | Lançar os itens à mão |
| Ajuste automático a partir do "como foi?" | O texto fica gravado como anotação, sem ajuste |

O simulador não tem Apple Intelligence, então é nele que se testa esse caminho por padrão. Para testar o caminho **com** modelo é preciso um iPhone real com Apple Intelligence ligada.

### Compras no app

Produto não-consumível único, `carne_assada_pro`: libera a área de conta (leitura da nota, lançamento manual, rateio, atribuição e compartilhamento). Planejar o churrasco é grátis e ilimitado.

Para desenvolvimento, `CarneAssada/Store/CarneAssada.storekit` já está ligado ao scheme — rode pelo Xcode para o paywall exibir o preço. Rodando por `simctl` fora do Xcode a configuração não é aplicada e o botão aparece sem preço.

**Nenhum preço existe no código.** O valor sempre vem de `Product.displayPrice`.

### Privacidade

- Nenhum dado sai do aparelho, exceto o texto que **você** compartilha pela share sheet — que contém só nome do churrasco, data, total e valor por pessoa. Nunca itens nem nome do mercado.
- **A foto da nota nunca é salva.** É processada em memória e descartada.
- Sem analytics, sem crash reporter, sem SDK de terceiro, sem código de rede próprio. O único tráfego é o do StoreKit com a App Store, feito pelo sistema.
- Os dados ficam no store local do SwiftData, protegidos pelo Data Protection do iOS, e entram no backup do iPhone. **Sem backup, trocar de aparelho perde os dados** — o app diz isso na tela de Ajustes.

---

Feito pela [Dab Lab](https://www.dablab.com.br/) — agência de inovação no-code para startups e PMEs, com automações usando IA.
