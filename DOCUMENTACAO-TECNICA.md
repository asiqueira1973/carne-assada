# Carne Assada — Documentação técnica

Descreve o sistema **como ele ficou**, não como foi planejado. Entregável da seção 19 do `spec.md`.

Regra de manutenção: qualquer mudança em modelo, serviço ou lógica de tela atualiza este documento **no mesmo commit**.

| | |
|---|---|
| Versão do spec implementada | 1.6 |
| Plataforma | iOS 26.0+, iPhone, retrato |
| Stack | Swift 6 (concorrência estrita), SwiftUI, SwiftData, Foundation Models, Vision, StoreKit 2 |
| Dependências externas | nenhuma |
| Tamanho do `.app` (Release) | 3,4 MB |

---

## 1. Modelo de dados explicado

Persistência em **SwiftData**, store local, sem CloudKit. Entidades, campos e enums em **português `snake_case`** (convenção 18.1 do spec).

Cada enum é persistido como `String` num campo `*_bruto` com uma propriedade computada tipada por cima. Isso é deliberado: guardar a `rawValue` faz de um renomeio futuro uma migração de dado visível, em vez de corrupção silenciosa.

### `churrasco`

O evento. Raiz do modelo — tudo pendura aqui.

| Campo | Significa |
|---|---|
| `nome` | Como o churrasco aparece no histórico e no texto compartilhado. Default `"Churrasco"`: ninguém é obrigado a digitar nada |
| `data_evento` | Só a data importa; a hora é ignorada |
| `status` | Onde está no fluxo. Ver a máquina de estados na seção 3 |
| `qtd_adultos` | Total de adultos, **incluindo** vegetarianos e abstêmios |
| `qtd_criancas` | Criança é marcador de consumo, não idade. O app nunca pergunta idade |
| `qtd_vegetarianos` | **Subconjunto** de `qtd_adultos`. Adultos que comem carne = adultos − vegetarianos |
| `qtd_nao_bebem_alcool` | Subconjunto de `qtd_adultos`, mesma lógica |
| `duracao_horas` | Governa o multiplicador de consumo. Default 5 |
| `descricao_livre` | O texto que o usuário digitou, guardado para auditoria da extração. Nulo quando o churrasco nasceu só com steppers |
| `origem_parametros` | `extraido` se veio de texto livre, `manual` se veio dos steppers |
| `inclui_carne_suina` | **Novo na v1.5.** Liga a linha opcional de suíno na tabela de consumo. Nasce desligado |
| `ajuste_historico_ligado` | **Novo na v1.5.** O usuário pode desligar o ajuste do churrasco anterior com um toque |

Exclusão: **hard delete com cascata** para participantes, itens de lista, compras (e seus itens e atribuições) e registro pós-evento.

### `participante`

Quem foi ao churrasco. **Não é usuário do app**: não acessa nada, não tem conta, é registro de dado no aparelho do organizador.

| Campo | Significa |
|---|---|
| `nome` | Único dentro do churrasco, case-insensitive. Colisão vira `" (2)"` e avisa |
| `e_crianca` | Paga meia no rateio geral e na carne |
| `come_carne` | Fica fora do rateio de itens marcados como `apenas_carne` |
| `bebe_alcool` | Fica fora do rateio de `bebida_alcoolica`. Criança nasce com `false` e o campo fica bloqueado na UI |
| `ordem` | Ordem de cadastro. Serve de desempate no rateio e no texto compartilhado |

### `item_lista`

Uma linha da lista de compras.

| Campo | Significa |
|---|---|
| `categoria` | Agrupa a lista e escolhe o ícone de categoria |
| `quantidade` / `unidade` | Já arredondadas na **unidade de compra real** — nunca "3,847 kg" |
| `comprado` | Marcação do modo mercado |
| `origem` | `calculado` = veio da regra 11.1; `manual` = o usuário adicionou **ou editou**. O recálculo preserva os `manual` e substitui os `calculado` |

Editar um item calculado o promove a `manual`. É o que impede o próximo recálculo de atropelar o ajuste que o usuário fez à mão.

### `compra`

Uma nota ou cupom. Um churrasco pode ter várias — mercado, açougue e bebida são compras separadas.

| Campo | Significa |
|---|---|
| `estabelecimento` | Nulo quando o modelo não identifica ou a compra foi lançada à mão |
| `valor_total_informado` | O total impresso na nota. **O rateio nunca usa este campo** — usa sempre a soma dos itens confirmados. Ele existe só para o aviso de divergência |
| `origem` | `extraido` = veio de foto; `manual` = digitado |

**A imagem da nota não é armazenada em lugar nenhum.**

### `item_compra`

Uma linha da nota, depois da revisão.

| Campo | Significa |
|---|---|
| `valor_total` | **Opcional**. Nulo = o modelo não conseguiu ler. O item entra pendente e nunca com valor estimado |
| `categoria_rateio` | Sugerida pelo modelo, sempre editável |
| `confirmado` | Vira `true` quando o usuário passa pela revisão. Item não confirmado não entra em nenhum cálculo |

Duas propriedades computadas resumem as regras: `pendente` (sem valor) e `entra_no_rateio` (confirmado **e** com valor).

### `atribuicao`

Associativa de "quem consumiu o quê". A leitura correta é contraintuitiva e vale repetir:

> **Ausência de linhas para um item significa "divide conforme a categoria de rateio" — não "ninguém consumiu".**

Presença de linhas é atribuição explícita e **sobrepõe a categoria**: o item passa a ser dividido igualmente só entre os marcados, ignorando peso de criança.

### `registro_pos_evento`

O relato do que sobrou e do que faltou. No máximo um por churrasco.

`ajustes_json` guarda os percentuais por categoria como JSON — desnormalizado de propósito, porque é lido inteiro, escrito inteiro e nunca consultado por campo. Nulo quando o modelo estava indisponível e o texto ficou só como anotação. **Consequência:** não dá para fazer consulta agregada do tipo "média histórica de ajuste em bebida"; se essa necessidade aparecer, vira tabela.

### Enums

| Enum | Valores |
|---|---|
| `status_churrasco` | `planejando`, `comprando`, `fechando_conta`, `concluido` |
| `categoria_lista` | `carne`, `acompanhamento`, `bebida_alcoolica`, `bebida_nao_alcoolica`, `carvao_e_utensilios`, `outro` |
| `categoria_rateio` | `geral`, `bebida_alcoolica`, `bebida_nao_alcoolica`, `apenas_carne` |
| `unidade_medida` | `kg`, `g`, `unidade`, `litro`, `ml`, `pacote` |
| `origem_dado` | `calculado`, `extraido`, `manual` |

### Versionamento

`EsquemaV1` (`VersionedSchema`) + `PlanoDeMigracao` (`SchemaMigrationPlan`) desde a v1, sem nenhum degrau ainda. Nenhuma migração leve não versionada. Não há seed: na primeira abertura o usuário vê o estado vazio da Home, não um churrasco de exemplo.

---

## 2. Relacionamentos

```
churrasco 1 ──< participante
churrasco 1 ──< item_lista
churrasco 1 ──< compra
churrasco 1 ──  registro_pos_evento   (0 ou 1)
compra    1 ──< item_compra
item_compra >──< participante          (via atribuicao)
```

No vocabulário do produto:

- Um churrasco tem **vários** participantes; um participante pertence a **um** churrasco. Não existe "pessoa" global entre eventos: cada churrasco é fechado em si.
- Um churrasco tem **vários** itens de lista.
- Um churrasco tem **várias** compras — mercado, açougue e bebida entram separados.
- Uma compra tem **vários** itens; cada item pertence a **uma** compra.
- Um churrasco tem **no máximo um** registro pós-evento.
- Um item de compra pode ser atribuído a **vários** participantes, e um participante pode ter **vários** itens atribuídos.

---

## 3. Máquina de estados do churrasco

| Estado | Significa | Vai para |
|---|---|---|
| `planejando` | Criado; a lista ainda não foi usada no mercado | `comprando`, `fechando_conta` |
| `comprando` | Modo mercado foi aberto | `fechando_conta`, `planejando` |
| `fechando_conta` | Existe pelo menos um item de compra confirmado | `concluido`, `comprando` |
| `concluido` | Resultado compartilhado | `fechando_conta` |

`planejando → concluido` é **proibido**. Nenhuma transição apaga dado.

Implementado em `status_churrasco.permiteIrPara(_:)` e `churrasco.irPara(_:)`. Transição não permitida é ignorada em silêncio e devolve `false` — o app nunca muda de status por conta própria fora do que a máquina autoriza.

Disparos:

| Onde | Transição |
|---|---|
| `ModoMercadoView.onAppear` | → `comprando` |
| `RevisaoDaLeitura.confirmar()` e `LancamentoManualView.criar()` | → `fechando_conta` |
| `ResultadoView`, ao concluir o compartilhamento | → `concluido` |

---

## 4. Regras de negócio implementadas em código

SwiftData não tem trigger nem política: **toda regra vive em Swift**, nos serviços abaixo.

### `ShoppingListCalculator` (enum, sem estado)

`calcular(_ parametros: ParametrosTurma, ajuste: AjusteConsumo?) -> [ItemListaCalculado]`

Implementa as regras **11.1** (tabelas, itens fixos, multiplicador, arredondamento), **11.3**, **11.4** e **11.14**.

Ordem exata dos passos — a ordem importa e é testada:

1. Clamp dos parâmetros (`ParametrosTurma.comClamp()`).
2. Consumo bruto por linha da tabela, somado sobre a turma (`consumoBruto`).
3. Multiplicador de duração, por categoria: bebida e carvão sobem mais rápido que comida.
4. **Só então** o ajuste histórico (regra 11.14) — nunca dentro do passo 2 ou 3.
5. Arredondamento para cima na unidade de compra (`arredondar` + `tetoMultiplo`).
6. Item que dá zero é **omitido**.
7. Itens de quantidade fixa entram no fim, **sem** ajuste histórico: "sobrou guardanapo" não é sinal de consumo.

Exceções da tabela que valem registrar:
- Abstêmio usa a coluna do adulto, mas **cerveja = 0** e **refrigerante ×1,5**.
- Carne suína é **opcional** e só entra com `inclui_carne_suina = true` (decisão 25.3).
- Cerveja é convertida de ml para **latas de 350 ml em múltiplos de 6** — é como se compra.
- Carvão e gelo arredondam em múltiplo de 1 kg; as demais carnes, em 0,5 kg.

`tetoMultiplo` usa `NSDecimalRound(.up)` sobre `Decimal`. Não é preciosismo: em `Double`, 3,0 kg viraria 3,5 kg por causa de um 3,0000000001.

Chamado por: `ListaService.regerar`.

### `SplitCalculator` (enum, sem estado)

`calcular(itens:participantes:pendentes:) -> ResultadoDoRateio`

Implementa **11.5**, **11.7**, **11.8**, **11.10.1** e **11.11**.

Recebe structs puras (`ItemParaRateio`, `ParticipanteParaRateio`), não os `@Model`. É o que o torna testável sem container SwiftData.

Ordem dos passos:

1. Para cada item: se há atribuição explícita, divide **igualmente** entre os atribuídos e ignora a categoria. Senão, distribui por peso segundo a categoria.
2. Se nenhum participante é elegível na categoria (cerveja num churrasco em que ninguém bebe), o item **cai no rateio geral** — o dinheiro não pode sumir, senão a soma deixa de bater com o total.
3. Acumula em precisão cheia; só arredonda no fim, a 2 casas com `.bankers`.
4. A sobra de centavos vai **integralmente** ao participante de maior valor; empate resolve pela `ordem`.
5. Monta a composição explicada, **incluindo as exclusões** com valor zero e o motivo.

`peso(de:em:)` é a regra 11.7 isolada: criança vale 0,5 em `geral` e `apenas_carne`, 1 em `bebida_nao_alcoolica`, 0 em `bebida_alcoolica`.

A invariante **"soma dos individuais == total"** é verificada por teste de propriedade com 100 iterações.

Chamado por: `ResultadoView`, a cada leitura. O rateio **nunca é gravado**.

### `ShareTextBuilder`

`montar(nome:data:resultado:) -> String` — formato exato da seção 14.1. Não inclui itens, estabelecimento nem categorias (seção 20.2). Há teste verificando que uma descrição de item não vaza para o texto.

### `ListaService`

- `regerar(_:ajuste:contexto:)` — apaga os `item_lista` de origem `calculado`, preserva os `manual`, e grava a lista nova.
- `ajusteAplicavel(para:contexto:)` — busca o churrasco **imediatamente anterior** por data e lê o `ajustes_json` do registro dele. Devolve `nil` se o usuário desligou o ajuste ou se não há registro. O ajuste **não acumula** entre eventos.
- `porCategoria(_:)` — agrupa e ordena para exibição.

### `Formatacao`

pt-BR num lugar só, para que o valor da tela e o valor do texto compartilhado saiam do mesmo código. Duas formatações do mesmo número é como nasce a reclamação da métrica 21.2.

### `ModelAvailabilityService` (`@Observable`, main actor)

Lê `SystemLanguageModel.default.availability` e reduz a dois estados. O app **não distingue** para o usuário aparelho sem suporte, Apple Intelligence desligada e modelo não baixado: os três caem no mesmo caminho manual. Reconsulta quando o app volta ao primeiro plano.

### `EntitlementService` (`@Observable`, main actor)

Única dependência de StoreKit. Três estados: `desconhecido`, `naoComprado`, `comprado`.

Dois detalhes que existem por causa de bugs previstos no spec:

- No `init`, se o cache local diz que já comprou, o estado nasce `comprado`. Sem isso, abrir o app em modo avião mostraria paywall a quem já pagou (risco 23.11).
- Em `atualizarEntitlement`, só se cai para `naoComprado` **se ainda não sabíamos** que ele comprou. Um entitlement conhecido nunca é rebaixado por falta de rede.

Observa `Transaction.updates` para pegar compra feita em outro aparelho ou reembolso, sem que nenhuma tela precise consultar nada.

### Camada de IA

| Serviço | Faz |
|---|---|
| `CrowdParameterExtractor` | Texto livre → `ParametrosTurma`. Única chamada de IA de texto puro |
| `ReceiptExtractor` | Imagem → OCR (Vision) → texto no prompt → `NotaLida`. Fatia cupom longo em blocos de 40 linhas |
| `PostEventAdjustmentExtractor` | Relato pós-evento → `AjusteConsumo` |

**Todos** convertem qualquer erro em `ErroDeIA.indisponivel`. O usuário nunca vê erro técnico do framework.

Guardrails aplicados **em código**, não no prompt:

| # | Garantia | Onde |
|---|---|---|
| 13.2.1 | Nenhum valor monetário estimado | `ItemNotaExtraido.valor` é opcional; nulo continua nulo |
| 13.2.2 | Parâmetros em faixa sã | `ParametrosTurma.comClamp()` |
| 13.2.3 | Ajuste limitado a ±40% | `init` de `AjusteConsumo` |
| 13.2.4 | Vegetarianos/abstêmios ≤ adultos | `comClamp()` |
| 13.2.5 | Categoria de rateio válida | Enum `@Generable` tipado; inválido cai em `geral` |
| 13.2.6 | Nenhuma saída gravada direto | Tela de revisão obrigatória |
| 13.2.7 | Falha, timeout ou guardrail | Vira "modelo indisponível" |

---

## 5. Mapa tela → entidades

| Tela | Arquivo | Lê | Escreve | Serviços |
|---|---|---|---|---|
| 10.1 Home | `HomeView` | `churrasco`, `item_compra` | `churrasco` (exclusão) | `Formatacao` |
| 10.2 Novo churrasco | `NovoChurrascoView` | — | `churrasco` | — |
| 10.3/10.4 Turma | `DescreverTurmaView` | `churrasco` | `churrasco`, `item_lista` | `CrowdParameterExtractor`, `ListaService`, `ShoppingListCalculator` |
| 10.5 Lista de compras | `ListaDeComprasView` | `item_lista` | `item_lista` | `ListaService` |
| 10.6 Modo mercado | `ModoMercadoView` | `item_lista` | `item_lista`, `churrasco` (status) | `ListaService` |
| 10.7 Conta | `ContaView` | `compra`, `item_compra` | `compra` (exclusão) | `EntitlementService`, `ModelAvailabilityService` |
| 10.8 Capturar nota | `CapturarNotaView` | — | `compra` (só no caminho manual) | `ReceiptExtractor` |
| 10.9 Revisar itens | `RevisaoDaLeitura` / `RevisarItensView` | `item_compra` | `compra`, `item_compra`, `churrasco` (status) | — |
| 10.10 Turma | `TurmaView` | `participante` | `participante` | — |
| 10.11 Quem consumiu | `QuemConsumiuView` | `participante`, `atribuicao` | `atribuicao` | — |
| 10.12 Resultado | `ResultadoView` | tudo | `churrasco` (status) | `SplitCalculator`, `ShareTextBuilder` |
| 10.13 Detalhe | `DetalheDoParticipanteView` | — (recebe pronto) | — | — |
| 10.14 Como foi? | `ComoFoiView` | `registro_pos_evento` | `registro_pos_evento` | `PostEventAdjustmentExtractor` |
| 10.15 Ajustes | `AjustesView` | `churrasco` | todas (apagar tudo) | `EntitlementService` |
| 10.16 Paywall | `PaywallView` | — | — | `EntitlementService` |

---

## 6. Lógica das principais funcionalidades por tela

### Home (10.1)

Lista por `data_evento` decrescente. O total do card é a soma dos itens **confirmados e com valor**; quando não há nenhum, o card simplesmente não mostra valor — "R$ 0,00" pareceria uma conta zerada.

Excluir pede confirmação (é destrutivo, regra 11.12) e cascateia. Erro de persistência mostra a copy 15.17 e mantém o estado anterior.

Em Dynamic Type acessível o card troca de `HStack` para `VStack`, para o nome não truncar.

### Descrever a turma (10.3/10.4)

Três etapas internas: descrever → processando → parâmetros.

Com o modelo indisponível, a etapa "descrever" **não existe**: entra direto em parâmetros com a copy 15.7.

O que o modelo devolve vai para os steppers e **não é gravado**. Só "Confirmar" grava, e é só aí que a lista é regerada. Erro de extração mostra a copy 15.8, dá um shake, e devolve o usuário à tela **com o texto preservado**.

O toggle de carne suína é escolha do usuário, não do modelo: é preservado através da extração.

### Lista de compras (10.5)

Agrupada por categoria, com o ícone SVG a 28 pt e o título na cor da categoria. Toque edita, swipe remove (sem confirmação — é reversível por re-adição).

Uma dica de uso (copy 15.37) explica os dois gestos, porque num **card** eles não são óbvios: o usuário reconhece "toque para editar, arraste para excluir" numa linha de tabela, não num card solto. Ela some para sempre no primeiro "Entendi", guardado em `AppStorage` — dica permanente vira ruído em quem já aprendeu.

O aviso de recálculo (15.9) só aparece quando **já havia** lista antes: na primeira geração não há nada sendo recalculado.

Quando há ajuste histórico ativo, mostra a copy 15.14 com um botão que o desliga e regera a lista base.

### Modo mercado (10.6)

Única tela com densidade alta. Usa `List` com `.listStyle(.insetGrouped)`: o card arredondado por categoria com divisores entre linhas sai de graça do estilo, e é ele que habilita o swipe.

Marcar **não recolhe nem reordena** — lista que se reorganiza embaixo do polegar faz perder o lugar.

Impede o bloqueio automático da tela enquanto aberta e restaura ao sair.

**Sair nunca depende de marcar tudo** (regra 11.17). O botão de saída está sempre disponível e leva à aba Conta; quando falta item, ele diz quantos, sem bloquear e sem pedir confirmação. Para o caso "não precisa comprar carvão, eu tenho em casa", o item sai por swipe ali mesmo — hard delete, reversível por re-adição na aba Lista.

Marcar o último item dispara as brasas (16.5.4) e o háptico de sucesso, **uma vez por churrasco por sessão**. A comemoração continua valendo só para carrinho de fato completo.

### Conta (10.7)

Três estados, nesta ordem de verificação:

1. `desconhecido` → carregamento. **Não** mostra paywall e **não** libera a feature.
2. `naoComprado` → tela de bloqueio, com "Tudo que você já cadastrou continua aqui" (regra 11.16.3).
3. `comprado` → compras, total e "Fechar a conta".

O cadeado aparece no ícone da aba desde o início — não só ao tocar (mitigação do risco 23.9). No estado `desconhecido` o cadeado **não** aparece: o app não afirma que a feature está trancada antes de saber.

"Fechar a conta" fica desabilitado sem item confirmado (exceção 9.2.4).

### Capturar e revisar nota (10.8/10.9)

A `UIImage` existe apenas dentro do escopo de processamento. Nada é escrito em disco, em cache ou no álbum.

O rascunho da revisão vive em `@State`, fora do store. Valor ilegível vem **em branco** e o card ganha uma faixa de atenção na lateral. Divergência acima de R$ 0,05 com o total da nota mostra a copy 15.11 e **não bloqueia**.

Só "Confirmar todos" cria a `compra` e os `item_compra`, todos com `confirmado = true`.

Numa nota já gravada, apagar o campo de valor devolve o item a `nil` — ele volta a ser pendente e sai do rateio, em vez de virar R$ 0,00 e entrar como se fosse de graça.

### Turma (10.10)

Adicionar exige só o nome. Nome duplicado vira `" (2)"` com aviso: dois "João" no rateio é erro garantido na hora de cobrar.

Marcar "é criança" força `bebe_alcool = false` e desabilita o toggle.

### Quem consumiu (10.11)

Cards grandes, um por pessoa — a seção 9.3 prevê o celular passando de mão em mão.

O aviso no topo muda conforme o estado, porque a regra 11.5 é contraintuitiva: sem ninguém marcado, diz que o item segue a categoria; com alguém marcado, diz que só os marcados pagam.

### Resultado e detalhe (10.12/10.13)

O rateio é recalculado a cada leitura, nunca gravado. É o que garante que excluir um participante depois do fechamento (exceção 9.2.7) mostre o valor novo, com o aviso 15.16.

O detalhe mostra linha a linha, **incluindo as exclusões** com valor zero e o motivo ("Não bebe: fora do rateio das bebidas alcoólicas"). Quem absorveu a sobra de centavos vê a explicação disso.

Compartilhar abre a share sheet e, ao concluir, leva o churrasco a `concluido`.

### Como foi? (10.14)

Com o modelo disponível, extrai os ajustes e grava. Sem ele, grava o texto com `ajustes_json` nulo e **diz isso ao usuário**, em vez de prometer um ajuste que não vai acontecer.

### Ajustes (10.15)

Estado da compra, restaurar (obrigatório, regra 11.16.5), o aviso de backup da seção 20.4, contagem de churrascos e "apagar todos os dados" com confirmação.

### Paywall (10.16)

Copies 15.28 a 15.31 e 15.36. O botão exibe `Product.displayPrice`; enquanto o produto carrega, mostra "Liberar" **sem preço** — preço errado no botão é pior que nenhum preço.

`EntitlementService` expõe `carregandoProduto` justamente para o paywall separar dois estados que pareciam um só: **carregando** mostra progresso; **não carregou** mostra a copy 15.38 e um botão de nova tentativa (regra 11.16.9). Antes os dois viravam o mesmo botão cinza, sem explicação — e o usuário ficava preso no paywall sem saber por quê. O paywall também reconsulta o produto ao abrir.

Cancelamento volta ao paywall **sem mensagem**. Restauração sem compra não é erro: sai em cor de atenção com a copy 15.33.

---

## 7. Design system

`Paleta` traz os tokens da seção 16.1 do spec, cada um com valor de claro e escuro resolvido por `UIColor` dinâmico. Os fundos são **chapados** — não há gradiente em lugar nenhum (a regra 16.5.8 foi revogada na v1.5).

`cartao()` aplica canto 16, fundo `fundoCartao` e sombra sutil **só no claro**: no escuro o card já se separa do preto pela luminância, e sombra preta sobre preto é ruído.

`Movimento` implementa o repertório 16.5 em SwiftUI nativo. Com `accessibilityReduceMotion` ligado, tudo vira fade de 0,2 s ou nada — **e o háptico permanece**, porque quem desliga movimento não está pedindo para deixar de sentir a confirmação.

`Ilustracao` aplica as três regras que a arte exige: decorativa (`accessibilityHidden`), some em Dynamic Type acessível (o texto tem prioridade) e **nunca é tingida**.

---

## 8. Testes

43 testes em 6 suítes.

| Suíte | Cobre |
|---|---|
| `ShoppingListCalculatorTests` | Exemplo trabalhado 11.13 item a item, multiplicadores, arredondamentos, exceção do abstêmio, vegetariano como subconjunto, itens fixos, suíno opcional, ajuste histórico e clamps |
| `SplitCalculatorTests` | Pesos por categoria, exemplo de rateio 11.13, **propriedade "soma == total" em 100 iterações**, atribuição explícita, empate por ordem e casos de borda |
| `MaquinaDeEstadosTests` | Transições permitidas e a proibida |
| `ModeloTests` | Cascata de exclusão, criança sem álcool, valor negativo zerado, `entra_no_rateio`, recálculo preservando manuais |
| `ShareTextBuilderTests` | Formato exato da 14.1 e não vazamento de item ou estabelecimento |
| `AjusteConsumoTests` | Serialização e JSON corrompido |

O teste de propriedade usa um gerador xorshift determinístico com semente: quando uma iteração falha, dá para rodar aquela semente de novo.

---

## 9. Divergências em relação ao spec

Sem esta seção o documento envelhece mentindo. Todas estão também na seção 24.14 do `spec.md`.

| # | Divergência | Por quê |
|---|---|---|
| 1 | **iOS 26**, não iOS 27; épico 8.5 com **Vision + texto**, não imagem no prompt | A premissa 4.3.1 foi validada e reprovada: o SDK do iOS 26.1 não expõe anexo de imagem no `FoundationModels`. É a contingência prevista na seção 4.2 e no risco 23.6 |
| 2 | **Quatro abas** (Lista / Mercado / Conta / Turma), não três | Mercado é o momento de uso mais difícil do produto e não podia ficar atrás de outra tela. A tela 10.5 manteve o botão para ele |
| 3 | Tokens `fundoTela` / `fundoCartao` em vez de `fundoCreme` / `cartaoBranco` | Os nomes antigos deixaram de descrever a cor depois da correção de paleta |
| 4 | Tokens novos `textoSecundario` e `preenchimentoSutil` | Já existiam no design entregue; faltavam no spec |
| 5 | Dois campos novos em `churrasco`: `inclui_carne_suina`, `ajuste_historico_ligado` | Consequências diretas da decisão 25.3 e do critério "desligar o ajuste com um toque" do épico 8.9 |
| 6 | Telas de lista usam `List`, não `ScrollView` + `LazyVStack` | `swipeActions` **só funciona dentro de uma `List`**; fora dela é ignorado em silêncio. O visual de card é preservado escondendo fundo e separador |
| 7 | O título grande da barra de navegação trunca em AX5 | Comportamento do próprio iOS, igual ao dos apps da Apple. Todo o **conteúdo** das telas respeita o critério 8.11 |
| 8 | O rateio não é gravado; é recalculado a cada leitura | Garante que a exceção 9.2.7 nunca deixe valor velho em tela |
| 10 | A dica de uso 15.37 aparece uma vez e some com "Entendi" | Os gestos padrão do iOS não se anunciam num card. Feedback do primeiro teste em aparelho |
| 9 | 17 SVG, não 15 | 8 ilustrações de tela + 6 ícones de categoria + 3 partículas de brasa. O spec contava só as ilustrações |

---

## 10. O que ainda não foi verificado

Depende de aparelho real, cupom real ou conta da loja:

- Fluxo 9.1 ponta a ponta em iPhone com Apple Intelligence ligada.
- Leitura de 10 cupons fiscais reais, incluindo térmico desbotado e nota com desconto (risco 23.1).
- Alvos de desempenho 17.1 a 17.4 medidos em aparelho.
- Modo avião ponta a ponta.
- Compra e restauração em sandbox do StoreKit, incluindo restaurar em outro aparelho com o mesmo Apple ID.
- Inspeção do container do app depois do fluxo com câmera, confirmando que nenhuma imagem ficou em disco.
- Network Instrument confirmando que o único tráfego é o do StoreKit.
- Cobertura de teste medida e registrada (alvo ≥ 90% nos dois calculadores).
