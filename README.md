# Carne Assada

App iOS que resolve as duas contas que todo organizador de churrasco faz na mão e erra: **quanto comprar** e **quanto cada um deve pagar**.

Você descreve a turma em linguagem natural ("15 adultos, 4 crianças, 3 que não comem carne, do meio-dia até a noite") e o app devolve a lista de compras por categoria. Depois do mercado, você fotografa a nota, confere os itens, e cada participante recebe seu valor — quem não bebe não paga a cerveja, criança paga meia na carne.

Tudo roda **no aparelho**. Sem conta, sem backend, sem sincronização, sem custo por uso. O app funciona em modo avião.

---

## Requisitos

| | |
|---|---|
| Xcode | 26.1 ou mais novo |
| iOS | 26.0 ou mais novo (iPhone, retrato) |
| Ferramentas | [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen` |
| Dependências externas | **nenhuma** |

O projeto Xcode **não é versionado**: ele é gerado a partir de `project.yml`.

---

## Rodar

```bash
cd ~/"Carne Assada" && xcodegen generate && open CarneAssada.xcodeproj
```

Ou pela linha de comando:

```bash
xcodebuild -project CarneAssada.xcodeproj -scheme CarneAssada -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build CODE_SIGNING_ALLOWED=NO
```

## Testar

```bash
xcodebuild -project CarneAssada.xcodeproj -scheme CarneAssada -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' test CODE_SIGNING_ALLOWED=NO
```

Os testes cobrem toda a seção 11 do spec: as tabelas de consumo, os multiplicadores, os arredondamentos e as regras de rateio. Inclui o exemplo trabalhado da regra 11.13 como regressão nomeada e um teste de propriedade que verifica, em 100 iterações, que **a soma dos valores individuais é sempre exatamente igual ao total**.

---

## Em aparelho sem Apple Intelligence

O app é **100% funcional** sem o modelo on-device. Não existe função exclusiva de IA: a IA só encurta caminho.

Quando `SystemLanguageModel.default.availability` não é `.available`, os pontos de entrada de IA **somem da interface** — não ficam desabilitados — e o caminho manual assume:

| Com o modelo | Sem o modelo |
|---|---|
| Descrever a turma em texto livre | Steppers direto, com a copy "Vamos no modo manual — é rapidinho também." |
| Fotografar a nota do mercado | Lançar os itens à mão |
| Ajuste automático a partir do "como foi?" | O texto fica gravado como anotação, sem ajuste |

O simulador não tem Apple Intelligence, então é nele que se testa esse caminho por padrão. Para testar o caminho **com** modelo é preciso um iPhone real com Apple Intelligence ligada.

---

## Compras no app

Produto não-consumível único, `carne_assada_pro`: libera a área de conta (leitura da nota, lançamento manual, rateio, atribuição e compartilhamento). Planejar o churrasco é grátis e ilimitado.

Para desenvolvimento, `CarneAssada/Store/CarneAssada.storekit` já está ligado ao scheme — rode pelo Xcode para o paywall exibir o preço. Rodando por `simctl` fora do Xcode a configuração não é aplicada e o botão aparece sem preço.

**Nenhum preço existe no código.** O valor sempre vem de `Product.displayPrice`.

---

## Estrutura

Ver `CLAUDE.md` para o mapa da arquitetura, a convenção de idioma e as armadilhas conhecidas.

| Arquivo | O que é |
|---|---|
| `spec.md` | Documento-fonte do produto (v1.5). Vence qualquer outro documento |
| `CLAUDE.md` | Contexto para agentes: convenções, arquitetura, pegadinhas |
| `DOCUMENTACAO-TECNICA.md` | O sistema como ele ficou, não como foi planejado |
| `modelo-carne-assada.dbml` | O modelo de dados em formato relacional, para dbdiagram.io |
| `handoff-claude-design/` | As 16 telas desenhadas no Claude Design, em claro e escuro |

---

## Privacidade

- Nenhum dado sai do aparelho, exceto o texto que **você** compartilha pela share sheet — que contém só nome do churrasco, data, total e valor por pessoa. Nunca itens nem nome do mercado.
- **A foto da nota nunca é salva.** É processada em memória e descartada.
- Sem analytics, sem crash reporter, sem SDK de terceiro, sem código de rede próprio. O único tráfego é o do StoreKit com a App Store, feito pelo sistema.
- Os dados ficam no store local do SwiftData, protegidos pelo Data Protection do iOS, e entram no backup do iPhone. **Sem backup, trocar de aparelho perde os dados** — o app diz isso na tela de Ajustes.
