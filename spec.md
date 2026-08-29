# Carne Assada — Especificação de Software (SDD)

| | |
|---|---|
| **Produto** | Carne Assada — planejador e divisor de conta de churrasco |
| **Versão do documento** | 1.7 |
| **Autor / responsável de produto** | Alexandre Siqueira (Dab Lab) |
| **Status** | implementado — MVP construído; pendências de validação em aparelho listadas na seção 26 |
| **Data** | 29 de agosto de 2026 |
| **Mudanças da v1.1** | Nome definitivo (Carne Assada); monetização definida — freemium por feature, R$ 19,90 vitalício; novo épico 8.10 (paywall); seções 3, 4, 13, 15, 18, 20, 21, 22, 23, 26, 28 propagadas |
| **Mudanças da v1.2** | Compra única cobre todas as releases futuras (regra 11.16.8); copy 15.36; pergunta 25.6 resolvida; seções 24 e 28.0 propagadas |
| **Mudanças da v1.3** | Ilustrações e ícone do app passam a ser assets fornecidos, não desenhados em código (nova seção 16.7); seções 16.3, 16.6, 17.7, 18.3, 26 e 27 propagadas |
| **Mudanças da v1.4** | Ilustrações passam de PNG para SVG (16.7, nova regra 16.7.1.1); alvo de binário volta a 30 MB (17.7) |
| **Mudanças da v1.7** | A aba Conta bloqueada **é** o paywall, não uma antessala dele (regra 11.16.2 reescrita, seção 10 propagada): as duas telas diziam a mesma coisa e tocar parecia não fazer nada |
| **Mudanças da v1.6** | Feedback do primeiro teste em aparelho. Sair do modo mercado **nunca** depende de ter marcado tudo, e o item vira removível ali mesmo (8.4, nova regra 11.17). Dica de uso na lista de compras (nova copy 15.37). Paywall deixa de virar beco sem saída quando o produto não carrega da App Store (8.10, nova regra 11.16.9, nova copy 15.38) |
| **Mudanças da v1.5** | **Paleta de fundo corrigida** (16.1): `fundoCreme`/`cartaoBranco` viram `fundoTela`/`fundoCartao`, com fundo chapado — a regra 16.5.8 (gradiente na Home) foi **revogada**. **Mínimo cai para iOS 26** e o épico 8.5 vai para Vision + texto: a premissa 4.3.1 falhou na validação (4.3, 4.1, 4.2, 23.6, 17.10). Perguntas 25.2, 25.3 e 25.5 resolvidas, com carne suína opcional entrando na tabela 11.1.1. Navegação do churrasco passa a ter 4 abas (seção 10). Seções 8.5, 16.7 e 26 propagadas |
| **Plataforma** | iOS nativo (SwiftUI), iOS 26+ |

---

## Como usar este documento

Este é o documento-fonte único do produto. Ele foi escrito para ser colado como input direto no **Claude Code**, que implementará o app sem precisar tomar decisões de produto por conta própria.

Antes de gerar qualquer código, **revise a seção 24 (Assunções declaradas)**. Toda assunção não revisada vira verdade no minuto em que o agente começa a codar. A seção 25 (Perguntas abertas) lista o que ninguém decidiu ainda: diante de qualquer item dela, o agente deve **perguntar, nunca assumir**.

**Estado na v1.5:** o MVP foi implementado. A seção 25 está vazia (as três últimas perguntas foram decididas antes do código) e a seção 26 marca o que está verificado e o que ainda depende de aparelho real. Para mudanças daqui em diante, siga o **protocolo da seção 29** — não cole este documento inteiro de novo.

A numeração das seções é estável e será referenciada em conversas futuras ("regra 11.3", "épico 8.4"). Não renumere.

---

## 0. Princípios não-negociáveis

Regras de desempate. Quando houver dúvida de UX, copy ou trade-off, resolva a favor destes.

| # | Princípio | O que significa na prática |
|---|---|---|
| 0.1 | **A IA sugere, o humano confirma** | Nenhum dado extraído por modelo é gravado sem passar por uma tela de revisão editável. O modelo nunca é a última palavra sobre um número. |
| 0.2 | **A aritmética é do código, não do modelo** | O modelo interpreta linguagem e imagem; todo cálculo de quantidade e de rateio é feito em Swift, de forma determinística e testável. Modelo de linguagem não soma dinheiro. |
| 0.3 | **Zero conta, zero nuvem, zero custo fixo** | Sem login, sem backend, sem sincronização. Todo dado vive no aparelho. O app funciona em modo avião. |
| 0.4 | **Um churrasco se planeja em menos de um minuto** | Do toque em "novo churrasco" até a lista de compras pronta: no máximo 3 telas e nenhuma digitação obrigatória além da descrição em linguagem livre. |
| 0.5 | **Divertido, mas nativo** | A personalidade vem de cor, ilustração e movimento — nunca de componentes customizados que quebrem gesto, acessibilidade ou Dynamic Type do iOS. |

---

## 1. Visão e problema

**Carne Assada** é um app iOS local-first que resolve as duas contas que todo organizador de churrasco faz na mão e erra: **quanto comprar** e **quanto cada um deve pagar**. O usuário descreve o evento em linguagem natural ("15 adultos, 4 crianças, 3 que não comem carne, começa meio-dia e vai até a noite") e o app devolve uma lista de compras estruturada por categoria. Depois do mercado, o usuário fotografa a nota fiscal (ou o cupom), o app extrai os itens e valores, e cada participante recebe seu valor calculado com regras justas — quem não bebe não paga a cerveja, criança paga meia na carne.

Toda a inteligência roda **no aparelho**, via Foundation Models framework: sem servidor, sem custo por uso, sem dado de compra saindo do celular.

**Anti-escopo — o que o Carne Assada explicitamente não é:**

- Não é um app social. Não existe conta, convite, feed, ou dois celulares conversando entre si.
- Não é um app de receitas ou de técnica de churrasco (ponto da carne, cortes, marinadas).
- Não é um app financeiro. Não movimenta dinheiro, não integra banco, não confirma pagamento.
- Não é um app de lista de compras genérica. A lista existe em função do churrasco, não como recurso avulso.
- Não é um app de rateio recorrente entre um grupo fixo (isso é Splitwise). Cada churrasco é um evento fechado.

---

## 2. Personas e cenários de uso

**Persona única: o organizador.** É a pessoa que faz a vaquinha, vai ao mercado e depois cobra todo mundo. Não é necessariamente quem assa.

**Momento 1 — planejamento (sofá, na véspera).** Calmo, com tempo, provavelmente no grupo de WhatsApp confirmando quem vai. Aqui a digitação em texto livre é natural e até prazerosa.

**Momento 2 — o mercado (em pé, carrinho na mão, pressa).** Precisa da lista legível de longe, marcável com o polegar, sem depender de rede — mercado grande costuma ter sinal ruim. Este é o momento mais difícil de uso e é ele que justifica o local-first.

**Momento 3 — a cobrança (depois do evento, com a nota amassada no bolso).** Baixa paciência, alta chance de erro manual. É o momento em que o app precisa parecer justo: se o número parecer arbitrário, o organizador não manda pro grupo.

---

## 3. Escopo do MVP

### Dentro

| # | Item |
|---|---|
| 3.1 | Criar churrasco com nome e data |
| 3.2 | Descrever a turma em linguagem natural e ter os parâmetros extraídos pelo modelo (nº de adultos, crianças, vegetarianos, quem bebe, duração) |
| 3.3 | Ajuste manual dos parâmetros extraídos, com controles simples (steppers) |
| 3.4 | Geração determinística da lista de compras a partir dos parâmetros, por categoria |
| 3.5 | Edição da lista: adicionar, remover, alterar quantidade de qualquer item |
| 3.6 | Modo mercado: lista marcável, com progresso |
| 3.7 | Cadastro de participantes nomeados (nome, criança sim/não, come carne sim/não, bebe álcool sim/não) |
| 3.8 | Leitura de nota fiscal por foto, com extração de itens e valores pelo modelo on-device |
| 3.9 | Tela de revisão editável dos itens extraídos, item a item |
| 3.10 | Classificação de cada item de compra em categoria de rateio (geral / álcool / não-alcoólica), sugerida pelo modelo e editável |
| 3.11 | Cálculo determinístico do valor devido por participante, com regras da seção 11 |
| 3.12 | Tela de resultado com o valor de cada um e explicação de como chegou nele |
| 3.13 | Compartilhamento do resultado como texto formatado (share sheet do iOS) |
| 3.14 | Histórico local de churrascos anteriores |
| 3.15 | Registro pós-evento em texto livre ("sobrou muita linguiça") e ajuste das quantidades no churrasco seguinte |
| 3.16 | Fallback completo sem IA: se o modelo estiver indisponível, todas as funções continuam acessíveis por entrada manual |
| 3.16.1 | Compra única no app (não-consumível), R$ 19,90, que libera permanentemente a leitura de nota fiscal e a divisão da conta — ver regra 11.16 e épico 8.10 |
| 3.16.2 | Restauração de compra (obrigatória pela App Store) |

### Fora

| # | Item | Destino | Motivo / dependência |
|---|---|---|---|
| 3.17 | Geração de cobrança PIX (QR e copia-e-cola) | **v2** | Decisão do usuário. Exige chave PIX do organizador, validação de formato BR Code e teste com bancos reais — escopo próprio. |
| 3.18 | Sincronização entre celulares / cada convidado marcando o que consumiu no próprio aparelho | **Descartado no MVP** | Exigiria backend, conta e autenticação, o que contraria o princípio 0.3. Ver seção 9.3 (marcação em aparelho único). |
| 3.19 | Timer de assado / ordem da grelha | **v2** | Feature de um terceiro momento do produto ("durante o churrasco"); não compartilha modelo de dados com o MVP. |
| 3.20 | Apple Watch, iPad, widgets, App Intents/Siri | **v2** | Sem valor até o fluxo principal estar validado no iPhone. |
| 3.21 | Foto de cada item / galeria do evento | **Descartado** | Aumenta o binário e o armazenamento sem resolver nenhuma das duas contas do produto. |
| 3.22 | Assinatura recorrente | **Descartado** | Churrasco é uso sazonal (2–4 vezes por ano) e o app não tem custo de servidor a cobrir. Assinatura não se sustenta em uso de evento; a compra única resolve. Ver 11.16 |
| 3.22.1 | Paywall por contagem de churrascos (ex.: liberar até o 3º) | **Descartado** | Uso sazonal faz o paywall aparecer 12–18 meses depois, quando o engajamento já esfriou — e entrega o produto inteiro de graça justo no momento de maior valor percebido. Substituído pelo paywall por feature (11.16) |
| 3.23 | Localização em outros idiomas | **Descartado no MVP** | Produto e regras de consumo são culturalmente brasileiros; pt-BR apenas. |

---

## 4. Arquitetura

### 4.1 Stack

| Camada | Escolha | Versão / observação |
|---|---|---|
| Linguagem | Swift | 6.x, concorrência estrita |
| UI | SwiftUI | iOS 26 SDK |
| Persistência | SwiftData | Store local, sem CloudKit |
| IA | Foundation Models framework | `SystemLanguageModel.default` (on-device) |
| OCR da nota | Vision (`RecognizeTextRequest`) | Passo 1 do épico 8.5; o texto reconhecido vai no prompt. Ver 4.2 e 4.3 |
| Compra no app | StoreKit 2 | Produto **não-consumível** único. Sem servidor de validação de recibo — o entitlement vem de `Transaction.currentEntitlements` do próprio StoreKit |
| Animação | SwiftUI nativo + Canvas/TimelineView; opcionalmente Rive ou Lottie **não** são usados | Ver 4.4 |
| Mínimo suportado | iOS 26.0 | Ver 4.3 |
| Distribuição | App Store, conta Apple Developer da Dab Lab | Sem backend, sem custo fixo de operação |

**Não há backend.** Não há servidor, banco remoto, autenticação, analytics de terceiros ou SDK de rede. A **única** comunicação de rede do app é a do StoreKit com a App Store, feita pelo próprio sistema — o app não faz nenhuma requisição HTTP própria e não possui código de rede.

### 4.2 Decisões e trade-offs

| Decisão | Por quê | Alternativa descartada |
|---|---|---|
| SwiftData em vez de Core Data ou arquivo JSON | Modelo relacional real (churrasco → itens → atribuições) com migração versionada, sem boilerplate | JSON em disco: simples no dia 1, insustentável no momento em que existir relação muitos-para-muitos entre item e participante |
| Foundation Models on-device, não Private Cloud Compute | Princípio 0.3 (custo zero, offline no mercado). Nota fiscal é dado financeiro do usuário — não deve sair do aparelho | PCC daria 32K de contexto, mas exige rede e quebra o uso offline |
| Cálculo em Swift, não no modelo | Princípio 0.2. Aritmética de modelo de linguagem é não-determinística e não testável | Pedir o rateio pronto ao modelo: resultado impossível de auditar e de cobrir por teste |
| **OCR do Vision + texto no prompt** para a nota fiscal | A premissa 4.3.1 **falhou**: o SDK do iOS 26 não expõe anexo de imagem no Foundation Models. Este é o caminho de contingência já previsto aqui e no risco 23.6 | Imagem direto no prompt: dependeria de um SDK que não existe no ciclo instalado |
| **iOS 26 como mínimo** | Consequência da linha acima: sem image input no prompt, não há motivo para exigir iOS 27, e o alcance no lançamento fica maior (risco 23.6) | iOS 27: base instalada menor sem ganho de feature |
| Compra única em vez de assinatura | Sem custo de servidor a cobrir e uso sazonal: ninguém assina o que usa 3 vezes por ano | Assinatura mensal/anual: receita recorrente maior no papel, churn quase certo na prática |
| Paywall por feature em vez de por contagem de uso | Converte no primeiro churrasco, no momento de maior valor percebido (a nota na mão, 30 itens para digitar). Contagem de uso só chega meses depois, com o usuário já frio | Liberar os 3 primeiros churrascos: entrega o produto inteiro de graça justo quando ele mais converteria |
| Entitlement direto do StoreKit, sem validação em servidor | Princípio 0.3. Recibo local do StoreKit 2 já é assinado pela Apple e verificado pelo sistema | Servidor de validação: mais seguro contra jailbreak, mas cria custo fixo e backend num app que não tem nenhum |

### 4.3 Premissas técnicas — **validar antes de codar**

| # | Premissa | Como validar |
|---|---|---|
| 4.3.1 | ~~Anexo de imagem no prompt disponível no SDK público do iOS 27~~ — **VALIDADA E REPROVADA (v1.5)**. O SDK instalado é o do iOS 26.1 e o módulo `FoundationModels` não expõe nenhum tipo de anexo de imagem | Feito: inspeção do `FoundationModels.swiftinterface` do SDK instalado. Consequência: épico 8.5 vai para Vision + texto (4.2) |
| 4.3.2 | ~~A janela de contexto comporta a foto do cupom~~ — **sem efeito depois de 4.3.1**. O que entra no prompt agora é o **texto** do OCR, muito menor que uma imagem. Cupom longo é fatiado em passadas (decisão 25.5) | Medir tokens com um cupom real de 30+ itens, na validação de 8.5 |
| 4.3.3 | `SystemLanguageModel.default.availability` cobre corretamente aparelho sem Apple Intelligence, Apple Intelligence desligada e modelo não baixado | Testar nos três estados; cada um cai no fallback da regra 11.9 |
| 4.3.4 | A qualidade de leitura de cupom fiscal térmico (impressão fraca, papel amassado) é aceitável | Testar com 10 cupons reais antes de fechar o épico 8.5 |

**4.3.1 falhou e a contingência foi aplicada:** o épico 8.5 usa OCR via Vision + texto no prompt. O resto do spec não mudou, exatamente como previsto aqui — a tela de revisão, os guardrails e as regras 11.6 e 11.10 seguem idênticos.

### 4.4 Sobre animação

Todo movimento é feito com **SwiftUI nativo** (`withAnimation`, `phaseAnimator`, `keyframeAnimator`, `matchedGeometryEffect`, `Canvas`, `TimelineView`, SF Symbols animados). **Nenhuma dependência externa de animação** (Lottie, Rive) entra no projeto: aumenta binário, cria risco de manutenção e não é necessário para o repertório descrito na seção 16.

### 4.5 Repositório

Repositório único, privado. Estrutura de pastas na seção 18.

---

## 5. Perfis de usuário e matriz de permissões

**Não se aplica.** O app tem um único usuário — o dono do aparelho — sem login, sem perfis, sem escopo de dados por organização. Todo dado do app é acessível a quem tem o aparelho desbloqueado.

Registrado explicitamente como decisão (não esquecimento): não existe matriz de permissões porque não existe segundo ator com acesso ao dado. Proteção de acesso fica a cargo do bloqueio do próprio iOS.

Participantes de um churrasco (seção 7) são **registros de dados**, não usuários: eles não acessam o app, não têm conta e não recebem nada de dentro dele — só o texto compartilhado pelo organizador.

---

## 6. Autenticação e identidade

**Não se aplica.** Não há login, conta, senha, recuperação de senha, sessão ou SSO. Registrado como decisão consciente, decorrente do princípio 0.3.

Consequência a escrever no app: **não há backup automático na nuvem**. Se o usuário trocar de aparelho sem backup do iPhone, os dados se perdem. Ver seção 20.4.

---

## 7. Modelo de dados

Persistência: **SwiftData**, store local. Nomes de entidades, propriedades e enums em **português**, `snake_case` — conforme a convenção da seção 18. Código, tipos Swift auxiliares e nomes de arquivo em inglês; a fronteira de idioma fica na camada de modelo.

### 7.1 Diagrama de relacionamento

```
churrasco 1 ──< participante
churrasco 1 ──< item_lista
churrasco 1 ──< compra
churrasco 1 ──< registro_pos_evento   (0 ou 1)
compra    1 ──< item_compra
item_compra >──< participante   (via atribuicao)
```

### 7.2 `churrasco`

| Campo | Tipo | Nulo? | Default | Observação |
|---|---|---|---|---|
| `id` | UUID | não | gerado | PK |
| `nome` | String | não | `"Churrasco"` | Editável; usado no histórico e no texto compartilhado |
| `data_evento` | Date | não | data de hoje | Só a data importa; hora é ignorada |
| `status` | `status_churrasco` | não | `planejando` | Ver 7.8 e seção 12 |
| `qtd_adultos` | Int | não | `0` | Parâmetro de cálculo (regra 11.1) |
| `qtd_criancas` | Int | não | `0` | Criança = até 12 anos (regra 11.2) |
| `qtd_vegetarianos` | Int | não | `0` | Subconjunto de `qtd_adultos`, não soma a ele (regra 11.3) |
| `qtd_nao_bebem_alcool` | Int | não | `0` | Subconjunto de `qtd_adultos` |
| `duracao_horas` | Int | não | `5` | Faixas na regra 11.4 |
| `descricao_livre` | String | **sim** | — | O texto que o usuário digitou. Nulo quando o churrasco foi criado só com steppers, sem IA. Guardado para auditoria da extração |
| `origem_parametros` | `origem_dado` | não | `manual` | Ver 7.8 |
| `criado_em` | Date | não | agora | |
| `atualizado_em` | Date | não | agora | |

**Exclusão:** hard delete, com cascata para participantes, itens de lista, compras e registro pós-evento. Não há histórico externo referenciando um churrasco, então soft delete não se justifica. Confirmação obrigatória na UI (regra 11.12).

### 7.3 `participante`

| Campo | Tipo | Nulo? | Default | Observação |
|---|---|---|---|---|
| `id` | UUID | não | gerado | PK |
| `churrasco_id` | UUID | não | — | FK → `churrasco.id` |
| `nome` | String | não | — | Livre; único dentro do churrasco (7.9) |
| `e_crianca` | Bool | não | `false` | Afeta o rateio (regra 11.7) |
| `come_carne` | Bool | não | `true` | |
| `bebe_alcool` | Bool | não | `true` | Criança nasce com `false` e o campo fica bloqueado na UI |
| `ordem` | Int | não | — | Ordem de exibição = ordem de cadastro |

**Exclusão:** hard delete. Ao excluir um participante, todas as suas `atribuicao` são removidas em cascata e o rateio é recalculado.

### 7.4 `item_lista` — lista de compras

| Campo | Tipo | Nulo? | Default | Observação |
|---|---|---|---|---|
| `id` | UUID | não | gerado | PK |
| `churrasco_id` | UUID | não | — | FK → `churrasco.id` |
| `categoria` | `categoria_lista` | não | — | Ver 7.8 |
| `nome` | String | não | — | Ex.: `"Picanha"`, `"Carvão"` |
| `quantidade` | Decimal | não | — | Sempre positivo |
| `unidade` | `unidade_medida` | não | — | Ver 7.8 |
| `comprado` | Bool | não | `false` | Marcação do modo mercado |
| `origem` | `origem_dado` | não | `calculado` | `calculado` = gerado pela regra 11.1; `manual` = adicionado pelo usuário |
| `ordem` | Int | não | — | Ordem dentro da categoria |

**Exclusão:** hard delete.

### 7.5 `compra` — uma nota/cupom fotografado

| Campo | Tipo | Nulo? | Default | Observação |
|---|---|---|---|---|
| `id` | UUID | não | gerado | PK |
| `churrasco_id` | UUID | não | — | FK → `churrasco.id` |
| `estabelecimento` | String | **sim** | — | Nulo quando o modelo não identifica o nome do mercado ou quando a compra foi lançada à mão |
| `data_compra` | Date | não | data de hoje | |
| `valor_total_informado` | Decimal | **sim** | — | Total lido da nota. Nulo quando não foi possível ler; nesse caso vale a soma dos itens (regra 11.10) |
| `origem` | `origem_dado` | não | `extraido` | `extraido` = veio de foto; `manual` = digitado |
| `criado_em` | Date | não | agora | |

Um churrasco pode ter **várias** compras (mercado + açougue + bebida). A imagem da nota **não é armazenada** (ver seção 20.3).

**Exclusão:** hard delete, cascata para `item_compra`.

### 7.6 `item_compra`

| Campo | Tipo | Nulo? | Default | Observação |
|---|---|---|---|---|
| `id` | UUID | não | gerado | PK |
| `compra_id` | UUID | não | — | FK → `compra.id` |
| `descricao` | String | não | — | Como aparece na nota, normalizada pelo modelo |
| `valor_total` | Decimal | não | — | Valor da linha, em reais. Sempre ≥ 0 |
| `categoria_rateio` | `categoria_rateio` | não | `geral` | Sugerida pelo modelo, editável (regra 11.6) |
| `confirmado` | Bool | não | `false` | Vira `true` quando o usuário passa pela tela de revisão. Item não confirmado não entra no rateio (regra 11.11) |
| `origem` | `origem_dado` | não | `extraido` | |
| `ordem` | Int | não | — | Ordem de leitura na nota |

### 7.7 `atribuicao` — quem consumiu o quê

| Campo | Tipo | Nulo? | Default | Observação |
|---|---|---|---|---|
| `id` | UUID | não | gerado | PK |
| `item_compra_id` | UUID | não | — | FK → `item_compra.id` |
| `participante_id` | UUID | não | — | FK → `participante.id` |

Tabela associativa do muitos-para-muitos. **Ausência de linhas para um `item_compra` significa "divide conforme a categoria de rateio"** (regra 11.5) — não significa "ninguém consumiu". Presença de linhas significa atribuição explícita e sobrepõe a categoria.

Constraint: `unique(item_compra_id, participante_id)`.

### 7.8 `registro_pos_evento`

| Campo | Tipo | Nulo? | Default | Observação |
|---|---|---|---|---|
| `id` | UUID | não | gerado | PK |
| `churrasco_id` | UUID | não | — | FK → `churrasco.id`, **unique** (no máximo um por churrasco) |
| `texto_livre` | String | não | — | O que o usuário escreveu ("sobrou linguiça, faltou cerveja") |
| `ajustes_json` | String | **sim** | — | JSON com os ajustes percentuais por categoria extraídos pelo modelo. Nulo quando o modelo estava indisponível e o texto ficou só como anotação |
| `criado_em` | Date | não | agora | |

Trade-off declarado: `ajustes_json` é um campo desnormalizado em vez de uma tabela `ajuste_categoria`. Motivo: é lido inteiro, escrito inteiro, nunca consultado por campo. Isso **impede** consulta agregada do tipo "média histórica de ajuste em bebida" — se essa necessidade aparecer, vira tabela.

### 7.9 Enums

```
enum status_churrasco:      planejando | comprando | fechando_conta | concluido
enum categoria_lista:       carne | acompanhamento | bebida_alcoolica | bebida_nao_alcoolica | carvao_e_utensilios | outro
enum categoria_rateio:      geral | bebida_alcoolica | bebida_nao_alcoolica | apenas_carne
enum unidade_medida:        kg | g | unidade | litro | ml | pacote
enum origem_dado:           calculado | extraido | manual
```

### 7.10 Constraints, índices e validações

| # | Regra |
|---|---|
| 7.10.1 | `participante.nome` único dentro do mesmo `churrasco_id`, case-insensitive. Colisão: sufixar com " (2)" e avisar |
| 7.10.2 | `qtd_vegetarianos` ≤ `qtd_adultos`; `qtd_nao_bebem_alcool` ≤ `qtd_adultos`. Validado na entrada, corrigido por clamp |
| 7.10.3 | Todos os campos `Decimal` de valor são ≥ 0. Valor negativo lido da nota (desconto) é somado como redução no total, nunca gravado como item negativo |
| 7.10.4 | `item_lista.quantidade` > 0. Zerar quantidade equivale a excluir o item |
| 7.10.5 | Índice em `churrasco_id` nas quatro entidades filhas |
| 7.10.6 | `registro_pos_evento.churrasco_id` unique |

### 7.11 Lógica no armazenamento

SwiftData não tem trigger nem política. **Toda regra de negócio vive em Swift**, em serviços nomeados, listados na seção 13. Registrado explicitamente para que o agente não procure equivalente de trigger.

### 7.12 Migrações e seed

- Versionamento via `VersionedSchema` / `SchemaMigrationPlan` do SwiftData, desde a v1. Nenhuma migração leve não versionada.
- **Seed:** nenhum dado inicial obrigatório. Na primeira abertura, o app mostra o estado vazio da Home (seção 15.6), não um churrasco de exemplo.

---

## 8. Épicos e critérios de aceite

Ordem de implementação obrigatória.

### 8.1 Fundação: modelo de dados, navegação e histórico

**Objetivo:** ter o esqueleto do app com persistência funcionando, sem nenhuma IA.

**Fluxo:** abrir o app → Home com lista de churrascos → criar churrasco (nome + data) → abrir detalhe → excluir churrasco.

**Estados:** vazio (nenhum churrasco), com lista, erro de persistência.

**Critérios de aceite:**
- [ ] Todas as entidades da seção 7 existem em SwiftData com os nomes e tipos escritos ali, sem sinônimo.
- [ ] Criar um churrasco, fechar o app completamente e reabrir: o churrasco continua lá.
- [ ] Excluir um churrasco com participantes e compras remove todos os registros filhos (verificável por consulta direta ao store).
- [ ] Excluir exige confirmação e a ação é destrutiva no menu (vermelho).
- [ ] Estado vazio da Home mostra a copy 15.6 e um botão único de criação.
- [ ] Nenhuma chamada a Foundation Models existe no código deste épico.

### 8.2 Parâmetros da turma por linguagem natural

**Objetivo:** transformar a descrição livre do usuário em parâmetros numéricos editáveis.

**Fluxo:** no churrasco recém-criado → campo de texto livre com placeholder → usuário escreve → toque em "Calcular" → indicador de processamento → tela de parâmetros preenchidos → usuário ajusta em steppers → confirma.

**Estados:** vazio (nenhum texto), processando, sucesso, erro do modelo, modelo indisponível.

**Critérios de aceite:**
- [ ] A extração usa `@Generable` com um tipo `ParametrosTurma` contendo exatamente: adultos, crianças, vegetarianos, não bebem álcool, duração em horas.
- [ ] Para a entrada "15 adultos, 4 crianças, 3 vegetarianos, das 12h às 22h", o app preenche 15 / 4 / 3 / 0 / 10 e apresenta os cinco valores em steppers editáveis **antes** de gravar (princípio 0.1).
- [ ] Nenhum valor extraído é gravado sem o usuário tocar em "Confirmar".
- [ ] Se o modelo não identifica um parâmetro, o campo vem com o default da seção 7.2 e **não** com um chute.
- [ ] Se `SystemLanguageModel.default.availability` for diferente de `.available`, o campo de texto livre não aparece e o usuário vai direto para os steppers, com a copy 15.7.
- [ ] Erro de geração ou timeout mostra a copy 15.8 e mantém o usuário na tela, com o texto digitado preservado.
- [ ] O texto digitado é gravado em `descricao_livre`.

### 8.3 Geração da lista de compras

**Objetivo:** produzir a lista de compras a partir dos parâmetros, de forma 100% determinística.

**Fluxo:** parâmetros confirmados → lista gerada e exibida por categoria → usuário edita, adiciona, remove.

**Estados:** lista gerada, lista vazia (usuário apagou tudo), item em edição.

**Critérios de aceite:**
- [ ] A lista é calculada pelas tabelas da regra 11.1 em Swift puro, **sem nenhuma chamada ao modelo** (princípio 0.2).
- [ ] Para 15 adultos, 4 crianças, 3 vegetarianos, 0 abstêmios, 10 horas, a lista bate exatamente com o exemplo trabalhado da regra 11.13.
- [ ] Alterar um parâmetro e recalcular preserva os itens de `origem = manual` e substitui os de `origem = calculado`, com aviso (copy 15.9).
- [ ] Quantidades são arredondadas conforme a regra 11.1.4 e exibidas em unidades de compra reais (nunca "3,847 kg").
- [ ] Todo item é editável em nome, quantidade e unidade; todo item é removível por swipe.

### 8.4 Modo mercado

**Objetivo:** usar a lista no supermercado.

**Fluxo:** abrir modo mercado → lista agrupada por categoria → toque marca comprado → barra de progresso → todos marcados dispara a animação de conclusão (16.5.3).

**Estados:** nada marcado, parcial, tudo marcado.

**Critérios de aceite:**
- [ ] Área de toque de cada linha ≥ 44×44 pt.
- [ ] Marcar um item não recolhe nem reordena a lista; o item marcado fica riscado e permanece na posição.
- [ ] O progresso ("12 de 27") atualiza imediatamente e é lido corretamente pelo VoiceOver.
- [ ] Funciona integralmente em modo avião.
- [ ] Marcar o último item dispara a animação de conclusão uma única vez por churrasco por sessão.
- [ ] A tela impede o bloqueio automático da tela enquanto está aberta (`isIdleTimerDisabled = true`) e restaura ao sair.
- [ ] **Sair do modo mercado não depende de marcar tudo** (regra 11.17): a ação de saída está sempre disponível, e diz quantos itens ficaram por marcar sem impedir nada.
- [ ] **Item é removível por swipe dentro do modo mercado**, sem precisar voltar à lista.

### 8.5 Leitura da nota fiscal por foto

**Objetivo:** transformar a foto de um cupom em itens de compra estruturados.

**Arquitetura (v1.5):** dois passos, pela contingência declarada em 4.2. **(1)** Vision (`RecognizeTextRequest`, `.accurate`, correção de idioma **desligada** — corretor destrói abreviação de cupom) devolve as linhas de texto. **(2)** O texto vai no prompt e o Foundation Models devolve o `@Generable` `NotaExtraida`. Cupom longo é fatiado em blocos de 40 linhas e processado em passadas, concatenando os itens (decisão 25.5).

**Fluxo:** "Adicionar nota" → câmera ou biblioteca → recorte opcional → processamento → tela de revisão com um card por item → usuário corrige valores e categorias → "Confirmar todos" → itens gravados com `confirmado = true`.

**Estados:** aguardando foto, processando, revisão, erro de leitura, modelo indisponível, nenhum item reconhecido.

**Critérios de aceite:**
- [ ] O prompt envia **o texto reconhecido pelo Vision** junto com a instrução, usando o tipo `@Generable` `NotaExtraida` (estabelecimento, data, total, lista de itens com descrição, valor e categoria sugerida).
- [ ] **Nenhum item é gravado antes da confirmação do usuário** (princípio 0.1). O modelo grava com `confirmado = false`; só a confirmação vira `true`.
- [ ] Cada item na tela de revisão mostra descrição, valor e categoria, e os três são editáveis ali mesmo.
- [ ] Item cujo valor o modelo não conseguiu ler aparece com o campo em branco e marcado visualmente como pendente — **nunca** com valor estimado (regra 11.10.2).
- [ ] Se a soma dos itens diverge do total lido em mais de R$ 0,05, o app avisa com a copy 15.11 e não bloqueia — o usuário decide.
- [ ] Modelo indisponível: o botão de foto some e o usuário lança itens manualmente, com a copy 15.7.
- [ ] Nenhum item reconhecido: copy 15.12 e caminho direto para lançamento manual.
- [ ] A imagem da nota **não é gravada em disco** em nenhum momento (seção 20.3), incluindo cache temporário — verificável por inspeção do container do app após o fluxo.
- [ ] O processamento não bloqueia a UI e pode ser cancelado.

### 8.6 Participantes e atribuição de itens

**Objetivo:** cadastrar quem estava e, quando necessário, dizer quem consumiu o quê.

**Fluxo:** aba de participantes → adicionar por nome → marcar criança / não come carne / não bebe → no item de compra, opção "quem consumiu?" para atribuição explícita.

**Estados:** nenhum participante, lista, item com atribuição explícita, item sem atribuição (segue a categoria).

**Critérios de aceite:**
- [ ] Adicionar participante exige apenas o nome; os três toggles têm default da seção 7.3.
- [ ] Marcar "é criança" força `bebe_alcool = false` e desabilita o toggle correspondente.
- [ ] Nome duplicado aplica a regra 7.10.1.
- [ ] Um item sem nenhuma `atribuicao` é rateado pela categoria (regra 11.5); um item com atribuição é dividido igualmente **apenas** entre os atribuídos, ignorando a categoria.
- [ ] Excluir um participante com atribuições remove as atribuições e recalcula o rateio na mesma ação.

### 8.7 Cálculo e tela do resultado

**Objetivo:** dizer quanto cada um paga, de forma auditável.

**Fluxo:** "Fechar a conta" → cálculo → lista de participantes com valor → toque em um participante abre o detalhe da composição do valor dele.

**Estados:** sem itens confirmados, calculado, com divergência de arredondamento.

**Critérios de aceite:**
- [ ] O cálculo segue exatamente as regras 11.5 a 11.8, implementado em serviço puro, sem dependência de UI ou de modelo.
- [ ] A soma dos valores individuais é **exatamente igual** ao total dos itens confirmados, com a sobra de centavos tratada pela regra 11.8.
- [ ] O detalhe de cada participante mostra, linha a linha, quanto ele está pagando em cada categoria e por quê ("Não bebe: não entra no rateio de bebida alcoólica").
- [ ] Alterar a categoria de um item ou um toggle de participante recalcula tudo em menos de 300 ms para até 50 itens e 30 participantes.
- [ ] Sem itens confirmados: copy 15.13, com atalho para adicionar nota.
- [ ] Teste unitário cobrindo o exemplo trabalhado da regra 11.13.

### 8.8 Compartilhamento do resultado

**Objetivo:** tirar o número do app e colocar no grupo.

**Critérios de aceite:**
- [ ] Gera um texto no formato exato da seção 14.1 e abre a share sheet do iOS.
- [ ] O texto não contém nome de estabelecimento nem itens individuais — só nome do churrasco, data, total e o valor por pessoa (seção 20.2).
- [ ] Funciona sem rede (a share sheet não exige conexão).

### 8.9 Registro pós-evento e ajuste histórico

**Objetivo:** o próximo churrasco erra menos que este.

**Fluxo:** churrasco concluído → "Como foi?" → texto livre → modelo extrai ajustes percentuais por categoria → gravado → no próximo churrasco, as quantidades já saem ajustadas, com aviso visível.

**Critérios de aceite:**
- [ ] O modelo extrai um `@Generable` `AjusteConsumo` com percentual por `categoria_lista`, limitado a −40% … +40% (regra 11.14).
- [ ] O ajuste é aplicado **depois** do cálculo base, nunca dentro dele, e é sempre visível na lista gerada com a copy 15.14.
- [ ] O usuário pode desligar o ajuste com um toque, voltando à lista base.
- [ ] Sem registro anterior, nenhum ajuste é aplicado e nada é mencionado na UI.
- [ ] Modelo indisponível: o texto é gravado como anotação (`ajustes_json` nulo) e nenhum ajuste é aplicado.

### 8.10 Compra no app e paywall

**Objetivo:** liberar a área de conta mediante compra única, sem prejudicar quem não compra.

**Fluxo:** usuário toca em "Conta" no churrasco → se não comprou, vê a tela de paywall explicando o que a compra libera → toca em comprar → fluxo nativo do StoreKit → sucesso → cai direto na tela de conta, sem passo intermediário.

**Estados:** entitlement desconhecido (carregando), não comprado, comprando, comprado, compra cancelada pelo usuário, falha de compra, restauração em andamento, restauração sem compra encontrada.

**Critérios de aceite:**
- [ ] Produto não-consumível único, identificador `carne_assada_pro`, configurado em `.storekit` para desenvolvimento.
- [ ] O preço exibido no paywall vem de `Product.displayPrice` do StoreKit — **nenhuma string de preço existe no código** (regra 11.16.6). Verificável por busca por "19,90" no projeto: zero ocorrências.
- [ ] Enquanto o entitlement é desconhecido, a aba Conta mostra carregamento e **não** mostra paywall nem libera a feature (regra 11.16.4).
- [ ] Exatamente as funcionalidades marcadas como pagas na tabela 11.16 ficam bloqueadas; todas as marcadas como grátis permanecem acessíveis, sem limite de quantidade e sem cronômetro.
- [ ] O paywall lista o que a compra libera com a copy 15.28 a 15.31 e deixa explícito que é pagamento único, não assinatura.
- [ ] A aba Conta bloqueada **é** o paywall, com o botão de compra visível sem nenhum toque intermediário (regra 11.16.2).
- [ ] Produto que não carrega da App Store mostra a copy 15.38 e um botão de nova tentativa, nunca um botão desabilitado sem explicação (regra 11.16.9).
- [ ] Compra cancelada pelo usuário volta ao paywall sem mensagem de erro.
- [ ] Falha de compra mostra a copy 15.32 e mantém o usuário no paywall.
- [ ] "Restaurar compra" existe no paywall e em Ajustes; restauração sem compra encontrada mostra a copy 15.33 e não é tratada como erro.
- [ ] Após a compra, o app não faz nenhuma verificação adicional em nenhuma tela — o entitlement é lido uma vez e observado por `Transaction.updates`.
- [ ] Comprar em um aparelho e restaurar em outro com o mesmo Apple ID libera a feature (teste manual em sandbox).
- [ ] Dados já cadastrados antes da compra continuam intactos e acessíveis depois dela (regra 11.16.3).

### 8.11 Acabamento visual, movimento e acessibilidade

**Objetivo:** entregar a personalidade da seção 16 sem quebrar o nativo.

**Critérios de aceite:**
- [ ] Todas as animações da seção 16.5 implementadas com SwiftUI nativo, sem dependência externa.
- [ ] Com "Reduzir movimento" ligado, nenhuma animação decorativa toca; transições viram fade simples. Verificável em todas as telas.
- [ ] Dynamic Type até AX5 sem corte de texto nem sobreposição em todas as telas.
- [ ] Contraste mínimo 4.5:1 para texto em todas as combinações da paleta, verificado inclusive no modo escuro.
- [ ] Todo elemento interativo tem rótulo de acessibilidade em português.
- [ ] Modo escuro completo.

---

## 9. Fluxos principais ponta a ponta

### 9.1 Fluxo feliz completo

1. Usuário abre o app → Home → "Novo churrasco".
2. Dá nome e data → salva (`status = planejando`).
3. Descreve a turma em texto livre → confirma os parâmetros extraídos.
4. Recebe a lista de compras → edita o que quiser.
5. No mercado, abre o modo mercado → marca os itens (`status = comprando`).
6. Volta pra casa, fotografa a nota → revisa os itens extraídos → confirma (`status = fechando_conta`).
7. Cadastra os participantes → ajusta quem não bebe / criança.
8. Atribui explicitamente os poucos itens que não são de todo mundo.
9. "Fechar a conta" → vê o valor de cada um → compartilha no grupo (`status = concluido`).
10. Dias depois, registra "sobrou muita linguiça" → o próximo churrasco já nasce ajustado.

### 9.2 Caminhos de exceção obrigatórios

| # | Exceção | Comportamento |
|---|---|---|
| 9.2.1 | Aparelho sem Apple Intelligence, ou desligada | Todos os pontos de IA somem da UI (não ficam desabilitados) e o caminho manual equivalente assume. O app é 100% funcional. Copy 15.7 |
| 9.2.2 | Usuário nunca cadastra participantes | "Fechar a conta" mostra a copy 15.15 e leva ao cadastro. Não é possível ratear sem pelo menos 1 participante |
| 9.2.3 | Usuário fotografa a nota antes de cadastrar participantes | Permitido. A revisão dos itens não depende de participante |
| 9.2.4 | Churrasco sem nenhuma compra, só lista | "Fechar a conta" fica indisponível com a copy 15.13. A lista de compras continua utilizável |
| 9.2.5 | Duas notas fiscais no mesmo churrasco | Suportado: cada `compra` é independente e todos os itens confirmados entram no mesmo rateio |
| 9.2.6 | Participante que só chegou pra sobremesa | Resolvido por atribuição explícita nos itens que ele consumiu; itens sem atribuição continuam rateados pela categoria e ele participa deles. Limitação conhecida — ver 25.2 |
| 9.2.7 | Usuário exclui um participante depois de fechar a conta | Recalcula e mostra o novo valor, com aviso de que o resultado mudou (copy 15.16) |

### 9.3 Marcação em aparelho único — decisão de produto

Não existe sincronização entre celulares (3.18). Toda a marcação de "quem consumiu o quê" acontece no aparelho do organizador, de duas formas suportadas:

- **Padrão:** o organizador percorre os poucos itens não-coletivos e marca por todos. Na prática, a maioria dos itens fica sem atribuição e cai no rateio por categoria, que é o comportamento correto para churrasco.
- **Alternativa:** o aparelho passa de mão em mão e cada um marca os próprios itens. A UI de atribuição deve funcionar bem nesse uso — cards grandes, um item por vez, sem menu escondido.

O resultado final sai pela share sheet como texto, o que dispensa qualquer app do lado de quem paga.

---

## 10. Inventário de telas

Perfil único; sem rótulo de perfil. Navegação: `NavigationStack` com Home na raiz e `TabView` dentro do churrasco com **quatro abas: Lista / Mercado / Conta / Turma**.

**Mudança da v1.5:** o modo mercado (10.6) virou aba própria, em vez de tela empilhada atrás da lista. Ele é o momento 2 da seção 2 — em pé, no corredor do mercado — e merece estar a um toque. A tela 10.5 continua com o botão "Abrir o modo mercado". A aba **Conta** exibe o cadeado desde o início quando o entitlement é `naoComprado`, o que é a mitigação do risco 23.9 pedida ali.

| # | Tela | O que mostra | Ações | Lê | Escreve |
|---|---|---|---|---|---|
| 10.1 | **Home / Meus churrascos** | Lista de churrascos por data desc., com nome, data, status e total (quando houver) | Criar, abrir, excluir (swipe) | `churrasco`, `item_compra` | `churrasco` |
| 10.2 | **Novo churrasco** | Nome e data | Salvar, cancelar | — | `churrasco` |
| 10.3 | **Descrever a turma** | Campo de texto livre com placeholder e exemplos | Calcular, pular para manual | `churrasco` | `churrasco` |
| 10.4 | **Parâmetros da turma** | Cinco steppers (adultos, crianças, vegetarianos, não bebem, duração) | Ajustar, confirmar, voltar | `churrasco` | `churrasco` |
| 10.5 | **Lista de compras** | Itens agrupados por categoria, com quantidade e unidade | Editar, adicionar, remover, recalcular, abrir modo mercado | `item_lista` | `item_lista` |
| 10.6 | **Modo mercado** | Mesma lista, marcável, com progresso | Marcar/desmarcar, sair | `item_lista` | `item_lista` |
| 10.7 | **Conta do churrasco** | Compras cadastradas e total; botão de fechar a conta | Adicionar nota, abrir compra, fechar a conta | `compra`, `item_compra` | — |
| 10.8 | **Capturar nota** | Câmera / biblioteca, com moldura de enquadramento | Fotografar, escolher, cancelar | — | — |
| 10.9 | **Revisar itens da nota** | Um card por item extraído: descrição, valor, categoria, estado pendente | Editar item, excluir item, adicionar item, confirmar todos | `item_compra` | `compra`, `item_compra` |
| 10.10 | **Turma / participantes** | Lista de participantes com seus três marcadores | Adicionar, editar, excluir | `participante` | `participante` |
| 10.11 | **Quem consumiu** | Um item de compra e a lista de participantes marcável | Marcar/desmarcar, limpar atribuição | `participante`, `atribuicao` | `atribuicao` |
| 10.12 | **Resultado do rateio** | Valor por participante, ordenado por valor desc., e total geral | Abrir detalhe, compartilhar, recalcular | tudo | `churrasco` (status) |
| 10.13 | **Detalhe do participante** | Composição do valor dele, linha a linha, com o motivo de cada inclusão/exclusão | Voltar | tudo | — |
| 10.14 | **Como foi?** | Campo de texto livre pós-evento | Salvar, pular | `registro_pos_evento` | `registro_pos_evento` |
| 10.15 | **Ajustes** | Sobre, política de privacidade, restaurar compra, apagar todos os dados | Restaurar compra, apagar tudo (com dupla confirmação) | — | todas |
| 10.16 | **Paywall** | O que a compra libera, preço vindo do StoreKit, botão de compra e restaurar. **É o conteúdo da aba Conta** quando o entitlement é `naoComprado` (regra 11.16.2), não uma folha por cima dela | Comprar, restaurar | — | — |

---

## 11. Regras de negócio

Toda regra abaixo é implementada **em Swift**, na camada de serviço (seção 13). Nenhuma é delegada ao modelo de linguagem.

### 11.1 Cálculo base da lista de compras

**11.1.1 — Consumo por pessoa (base, para churrasco de até 5 horas):**

| Categoria | Item | Adulto que come carne | Adulto vegetariano | Criança |
|---|---|---|---|---|
| carne | Carne bovina (kg) | 0,400 | 0 | 0,200 |
| carne | Linguiça (kg) | 0,150 | 0 | 0,075 |
| carne | Frango (kg) | 0,150 | 0 | 0,100 |
| carne | Carne suína (kg) — **opcional** | 0,150 | 0 | 0,075 |
| carne | Espeto vegetariano / legumes (kg) | 0 | 0,350 | 0 |
| acompanhamento | Pão de alho (unidade) | 1,5 | 1,5 | 1 |
| acompanhamento | Farofa (g) | 80 | 80 | 40 |
| acompanhamento | Vinagrete (g) | 100 | 100 | 50 |
| acompanhamento | Arroz (g, cru) | 80 | 80 | 40 |
| acompanhamento | Queijo coalho (unidade) | 1 | 1 | 0,5 |
| bebida_alcoolica | Cerveja (ml) | 1.200 | 1.200 | 0 |
| bebida_nao_alcoolica | Refrigerante / suco (ml) | 500 | 500 | 600 |
| bebida_nao_alcoolica | Água (ml) | 500 | 500 | 500 |
| carvao_e_utensilios | Carvão (kg) | 0,150 | 0,150 | 0,050 |
| carvao_e_utensilios | Gelo (kg) | 0,300 | 0,300 | 0,150 |

Adulto que não bebe álcool: usa a coluna do adulto, mas **cerveja = 0** e **refrigerante ×1,5**.

**Carne suína é opcional (decisão 25.3, v1.5).** A linha só entra na lista quando o usuário liga o marcador "vai ter carne suína" na tela 10.4; nasce desligada. Motivo: cobre o churrasco com costelinha ou pernil sem inflar a lista de quem não faz nenhum dos dois.

**11.1.2 — Itens de quantidade fixa (independem do número de pessoas):**

| Categoria | Item | Quantidade | Condição |
|---|---|---|---|
| carvao_e_utensilios | Acendedor | 1 pacote | sempre |
| carvao_e_utensilios | Papel toalha | 2 unidades | sempre |
| carvao_e_utensilios | Guardanapo | 1 pacote | sempre |
| carvao_e_utensilios | Sal grosso | 1 pacote | sempre |
| carvao_e_utensilios | Copo descartável | 1 pacote de 50 | se total de pessoas > 10 |
| carvao_e_utensilios | Prato descartável | 1 pacote de 20 | se total de pessoas > 10 |

**11.1.3 — Multiplicador por duração:**

| Duração | Multiplicador em bebida e carvão | Multiplicador em carne e acompanhamento |
|---|---|---|
| até 4 h | 0,85 | 0,90 |
| 5 a 6 h | 1,00 | 1,00 |
| 7 a 9 h | 1,25 | 1,10 |
| 10 h ou mais | 1,50 | 1,20 |

**11.1.4 — Arredondamento (sempre para cima, na unidade de compra):**

| Unidade | Regra |
|---|---|
| kg (carne) | múltiplo de 0,5 kg |
| kg (carvão, gelo) | múltiplo de 1 kg |
| g | múltiplo de 100 g |
| unidade | inteiro |
| ml → litro | múltiplo de 0,5 L; cerveja em múltiplo de 6 latas de 350 ml |
| pacote | inteiro |

Nenhum item calculado entra na lista com quantidade zero — é omitido.

### 11.2 Definição de criança
Criança = pessoa que consome porção reduzida, na prática até ~12 anos. O app **não pergunta idade**; usa o marcador booleano.

### 11.3 Vegetariano
`qtd_vegetarianos` é subconjunto de `qtd_adultos`, não soma. Adultos que comem carne = `qtd_adultos − qtd_vegetarianos`.

### 11.4 Duração
Extraída como número inteiro de horas. Faixas na 11.1.3. Sem informação, default 5.

### 11.5 Rateio por categoria (item sem atribuição explícita)

| `categoria_rateio` | Quem paga |
|---|---|
| `geral` | Todos os participantes, com criança pagando meia (11.7) |
| `bebida_alcoolica` | Apenas participantes com `bebe_alcool = true` |
| `bebida_nao_alcoolica` | Todos os participantes, criança pagando inteiro |
| `apenas_carne` | Apenas participantes com `come_carne = true`, criança pagando meia |

**11.5.1 — Todo participante conta inteiro (decisão 25.2, v1.5).** Não existe peso proporcional por tempo de permanência. Quem chegou no meio do churrasco entra no rateio como todo mundo; a saída para corrigir isso é a **atribuição explícita** dos itens que ele de fato consumiu (exceção 9.2.6). Fração de presença foi descartada por exigir do organizador um número arbitrário que ele não tem como saber, e por adicionar campo, controle e linha de explicação a troco de pouca justiça a mais.

**11.5.2 — Categoria sem nenhum elegível cai no rateio geral.** Se um item de `bebida_alcoolica` aparece num churrasco em que ninguém bebe, o valor **não some**: ele passa a ser dividido pela regra `geral`. É o que preserva a invariante da regra 11.8 (a soma dos individuais é exatamente igual ao total).

### 11.6 Classificação de item de compra
A `categoria_rateio` é **sugerida pelo modelo** na leitura da nota e **sempre editável**. Default quando o modelo não classifica: `geral`. O app não mantém dicionário de palavras-chave — classificação é tarefa de linguagem, correção é do usuário.

### 11.7 Peso da criança
Criança conta como **0,5** no rateio de `geral` e `apenas_carne`; como **1** em `bebida_nao_alcoolica`; como **0** em `bebida_alcoolica`.

### 11.8 Arredondamento do rateio
Valores calculados em `Decimal`, arredondados a 2 casas com `.bankers`. A diferença de centavos entre a soma dos individuais e o total vai **integralmente para o participante de maior valor**; havendo empate, para o primeiro pela `ordem`. Regra escrita para ser testável: a soma dos individuais é sempre exatamente igual ao total.

### 11.9 Indisponibilidade do modelo
Se `availability != .available`, todos os pontos de entrada de IA são **ocultados** (não desabilitados) e o caminho manual assume. O app nunca exibe erro técnico do framework ao usuário.

### 11.10 Divergência de valores na nota
- **11.10.1** Divergência entre soma dos itens e total lido acima de R$ 0,05: avisa, não bloqueia. O rateio usa **sempre a soma dos itens confirmados**, nunca o total lido.
- **11.10.2** Item sem valor legível entra com valor vazio, marcado como pendente. **Nunca** com valor estimado pelo modelo. Item pendente não entra no rateio até receber valor.

### 11.11 Itens não confirmados
`item_compra.confirmado = false` não entra em nenhum cálculo, não aparece no total e não aparece no resultado.

### 11.12 Exclusões destrutivas
Excluir churrasco e "apagar todos os dados" exigem confirmação explícita. Excluir participante, item de lista e item de compra são reversíveis por re-adição e **não** pedem confirmação.

### 11.13 Exemplo trabalhado (caso de teste obrigatório)

Entrada: 15 adultos, 4 crianças, 3 vegetarianos, 0 abstêmios, 10 horas.
Adultos que comem carne = 12.

Carne bovina: (12 × 0,400 + 4 × 0,200) × 1,20 = (4,8 + 0,8) × 1,20 = 6,72 → **7,0 kg**
Linguiça: (12 × 0,150 + 4 × 0,075) × 1,20 = (1,8 + 0,3) × 1,20 = 2,52 → **3,0 kg**
Frango: (12 × 0,150 + 4 × 0,100) × 1,20 = (1,8 + 0,4) × 1,20 = 2,64 → **3,0 kg**
Espeto vegetariano: (3 × 0,350) × 1,20 = 1,26 → **1,5 kg**
Cerveja: (15 × 1.200) × 1,50 = 27.000 ml = 27 L → em latas de 350 ml = 77,1 → arredonda para múltiplo de 6 → **78 latas**
Carvão: (15 × 0,150 + 4 × 0,050) × 1,50 = (2,25 + 0,2) × 1,50 = 3,675 → **4 kg**

Rateio, exemplo: item de R$ 100,00 em `bebida_alcoolica`, com 15 adultos que bebem, 4 crianças → divide por 15 → R$ 6,67 cada adulto; criança R$ 0,00. Soma = R$ 100,05 → aplica 11.8: o participante de maior valor paga R$ 6,62. Total exato: R$ 100,00.

### 11.14 Ajuste histórico
Percentual por categoria, limitado a **−40% a +40%**. Aplicado após o cálculo base e o multiplicador de duração. Aplica-se apenas ao churrasco imediatamente seguinte ao registro; não acumula entre eventos.

### 11.15 O que **não** é automático
- O app **não** sugere cortes de carne específicos nem marcas.
- O app **não** estima preço de nada. Preço só existe quando veio da nota.
- O app **não** decide sozinho a categoria de rateio de um item já confirmado — mudança é sempre manual.
- O app **não** muda o status do churrasco sozinho, exceto na transição descrita na seção 12.
- O app **não** cobra por nada além do descrito em 11.16, e nunca cobra pelo que já foi liberado.

### 11.17 Marcar tudo é o caso feliz, não um pedágio

Sair do modo mercado **nunca** exige ter marcado todos os itens. No meio da compra alguém liga dizendo que já tem carvão em casa, o organizador desiste de um item, o mercado não tinha outro — e nada disso pode prender ninguém na tela.

Duas saídas, e as duas existem:
- **Seguir com item por marcar.** A ação de saída está sempre disponível e informa quantos faltaram, sem bloquear e sem pedir confirmação.
- **Tirar o item da lista**, por swipe, ali mesmo no modo mercado. É hard delete, reversível por re-adição na tela 10.5, e por isso não pede confirmação (regra 11.12).

A animação de conclusão (16.5.3 e 16.5.4) e a copy 15.19 continuam valendo **apenas** quando tudo foi marcado de verdade — comemorar carrinho incompleto é mentira, e mentira pequena estraga a confiança no resto do app.

### 11.16 Monetização — o que é grátis e o que é pago

Modelo: **freemium por feature**, com **compra única não-consumível de R$ 19,90** (`carne_assada_pro`), vitalícia, sem assinatura.

| Funcionalidade | Grátis | Pago |
|---|---|---|
| Criar churrascos (quantos quiser) | ✅ ilimitado | — |
| Descrever a turma em linguagem natural (IA) | ✅ ilimitado | — |
| Lista de compras calculada, editar, adicionar, remover | ✅ ilimitado | — |
| Modo mercado | ✅ ilimitado | — |
| Histórico de churrascos | ✅ ilimitado | — |
| Registro pós-evento e ajuste histórico (IA) | ✅ ilimitado | — |
| Cadastro de participantes | ✅ ilimitado | — |
| **Leitura de nota fiscal por foto (IA)** | ❌ | ✅ |
| **Lançamento manual de itens de compra** | ❌ | ✅ |
| **Cálculo e tela do resultado do rateio** | ❌ | ✅ |
| **Atribuição de itens a participantes** | ❌ | ✅ |
| **Compartilhamento do resultado** | ❌ | ✅ |

**11.16.1** — A fronteira é exatamente esta: **planejar é grátis, dividir a conta é pago**. A parte grátis é um produto completo e útil sozinho; ela existe para gerar uso e boca a boca, não como demonstração mutilada.

**11.16.2** — O bloqueio acontece **na entrada da tela 10.7 (Conta do churrasco)**. Toda a área de conta fica atrás do paywall, incluindo o lançamento manual — senão o usuário digita os itens à mão e a feature paga perde o sentido.

Com o entitlement `naoComprado`, a aba Conta **é** a tela 10.16: o paywall inteiro, com o botão de compra à vista. Não existe tela intermediária de teaser. A versão anterior tinha uma, e ela mostrava o mesmo título, o mesmo subtítulo e a mesma ilustração do paywall que abria em seguida — tocar em "ver o que a compra libera" parecia não fazer nada. Tela que só repete a anterior é passo de navegação sem função.

**11.16.3** — Nenhum dado é destruído ou escondido pela falta de compra. Se o usuário comprar depois, tudo que ele já tinha cadastrado continua lá.

**11.16.4** — O entitlement é lido de `Transaction.currentEntitlements` do StoreKit 2. Sem validação em servidor (decisão 4.2). Enquanto o StoreKit não responde na abertura do app, o estado é **"desconhecido"**, e nesse estado a UI **não** mostra paywall nem libera a feature: mostra carregamento. Nunca assuma "não comprado" por falta de resposta.

**11.16.5** — "Restaurar compra" é obrigatório e fica visível na tela de Ajustes (10.15) e no próprio paywall.

**11.16.6** — Preço e nome do produto vêm **sempre** do StoreKit, nunca escritos no código ou na copy. O "R$ 19,90" deste spec é a configuração no App Store Connect, não uma string do app — isso é o que faz o preço funcionar em promoção, em outra moeda e em mudança futura.

**11.16.7** — Não há período de teste, desconto de lançamento nem preço promocional no MVP.

**11.16.9 — Produto que não carrega não vira beco sem saída.** Se `Product.products(for:)` não devolver o produto — aparelho offline, produto ainda não aprovado na loja, build sem configuração de StoreKit — o paywall **não** exibe um botão desabilitado e mudo. Ele explica o que houve com a copy 15.38 e oferece uma segunda tentativa. O paywall também reconsulta o produto ao ser aberto: quem chegou até ali acabou de demonstrar interesse em comprar, e é o momento certo para tentar de novo. "Carregando" e "não deu para carregar" são estados distintos e a UI precisa distinguir os dois.

**11.16.8 — Compra única e definitiva.** `carne_assada_pro` libera, além do escopo do MVP, **todas as funcionalidades pagas das releases futuras** (seção 28: PIX, exportação completa, iPad, widgets, App Intents). Não haverá segundo produto de compra, nem upgrade, nem "pro plus". Quem comprar hoje recebe tudo o que vier depois, sem pagar de novo.

Consequências obrigatórias:
- O paywall e a ficha da App Store **afirmam isso explicitamente** (copy 15.36) — é o principal argumento de compra e precisa estar escrito, não subentendido.
- Nenhuma feature futura pode ser condicionada a um entitlement diferente. Se um dia surgir necessidade de cobrar por algo novo, isso é uma decisão de produto que quebra uma promessa pública, e exige spec própria — não é ajuste de implementação.
- Isso é o argumento a favor de subir o preço com o tempo (28.0), não de criar uma segunda compra.

---

## 12. Máquina de estados do churrasco

| Estado | Significa | Transições permitidas |
|---|---|---|
| `planejando` | Criado, lista ainda não usada no mercado | → `comprando` (ao abrir o modo mercado pela 1ª vez), → `fechando_conta` (ao confirmar a 1ª nota) |
| `comprando` | Modo mercado em uso | → `fechando_conta` (ao confirmar a 1ª nota), → `planejando` (manual, pelo menu) |
| `fechando_conta` | Existe pelo menos um item de compra confirmado | → `concluido` (ao compartilhar o resultado), → `comprando` (manual) |
| `concluido` | Resultado compartilhado | → `fechando_conta` (ao adicionar ou editar qualquer item) |

**Proibido:** `planejando` → `concluido` diretamente. **Nenhuma** transição apaga dado.

Falhas: erro de persistência mantém o estado anterior e mostra a copy 15.17; nenhuma transição de estado ocorre parcialmente.

---

## 13. Contratos dos módulos internos

Sem backend e sem API. Os contratos abaixo são de **serviços Swift puros**, sem dependência de SwiftUI, todos testáveis isoladamente.

| Serviço | Entrada | Saída | Regras que implementa |
|---|---|---|---|
| `ShoppingListCalculator` | `ParametrosTurma`, `AjusteConsumo?` | `[ItemListaCalculado]` | 11.1, 11.3, 11.4, 11.14 |
| `SplitCalculator` | `[ItemCompra]`, `[Participante]`, `[Atribuicao]` | `[ResultadoParticipante]` (valor + composição explicada) | 11.5, 11.7, 11.8, 11.10.1, 11.11 |
| `CrowdParameterExtractor` | `String` (texto livre) | `ParametrosTurma` | 8.2, 11.9 — **única** chamada de IA de texto |
| `ReceiptExtractor` | imagem | `NotaLida` | 8.5, 11.6, 11.9, 11.10.2 e decisão 25.5 — faz o OCR com Vision e manda o **texto** ao modelo; a imagem nunca sai da memória (20.3) |
| `PostEventAdjustmentExtractor` | `String` | `AjusteConsumo` | 8.9, 11.14 |
| `ShareTextBuilder` | resultado do rateio | `String` | 14.1, 20.2 |
| `ModelAvailabilityService` | — | estado de disponibilidade | 11.9 |
| `EntitlementService` | — | estado do entitlement (`desconhecido` / `naoComprado` / `comprado`) | 11.16.4, 11.16.5 — única dependência de StoreKit; observa `Transaction.updates` |

### 13.1 Tipos `@Generable`

```
ParametrosTurma:  adultos, criancas, vegetarianos, naoBebemAlcool, duracaoHoras  (todos Int)
NotaExtraida:     estabelecimento (String?), dataCompra (String?), valorTotal (Decimal?),
                  itens: [ItemNotaExtraido]
ItemNotaExtraido: descricao (String), valor (Decimal?), categoriaSugerida (categoria_rateio)
AjusteConsumo:    ajustes: [AjusteCategoria(categoria, percentual: Int)]
```

Todo campo opcional acima existe **porque o modelo pode não saber** — e nesse caso o campo vem nulo, nunca preenchido por chute (princípio 0.1).

### 13.2 Guardrails de IA

| # | Guardrail | Como é garantido **sem depender do modelo** |
|---|---|---|
| 13.2.1 | Nenhum valor monetário estimado | `ItemNotaExtraido.valor` é opcional; nulo vira campo vazio pendente na UI. Validação em código, não no prompt |
| 13.2.2 | Parâmetros de turma dentro de faixa sã | Clamp em código: adultos 0–200, crianças 0–100, duração 1–24. Fora da faixa, aplica o limite e sinaliza na UI |
| 13.2.3 | Ajuste histórico limitado | Clamp em código a ±40% (11.14) |
| 13.2.4 | Vegetarianos/abstêmios ≤ adultos | Clamp em código (7.10.2) |
| 13.2.5 | Categoria de rateio válida | Enum tipado; valor inválido cai em `geral` |
| 13.2.6 | Nenhuma saída de modelo é gravada direto | Toda escrita passa por tela de revisão (princípio 0.1) |
| 13.2.7 | Falha, timeout ou guardrail do framework | Trata como "modelo indisponível" (11.9); nunca mostra erro técnico |

Nenhum guardrail depende do modelo julgar a si mesmo.

---

## 14. Exportação

### 14.1 Texto de compartilhamento (formato exato)

```
🔥 {nome do churrasco} — {dd/MM/yyyy}

Total: R$ {total}

{Nome}: R$ {valor}
{Nome}: R$ {valor}
...

Contas feitas no Carne Assada 🍖
```

- Ordem: valor decrescente; empate resolvido pela `ordem` do participante.
- Valores em `pt-BR`: vírgula decimal, duas casas, separador de milhar.
- **Não inclui** itens, estabelecimento nem categorias (seção 20.2).
- Encoding UTF-8. Não há arquivo — o conteúdo vai como `String` para a share sheet.

Não há importação de arquivo no MVP.

---

## 15. Copy e tom de voz

**Tom:** brasileiro, direto, de amigo que organiza. Nunca infantil, nunca corporativo, sem gíria datada. Emoji só onde está escrito abaixo. Trata o usuário por "você". **Conteúdo final, não placeholder.**

| # | Contexto | Texto |
|---|---|---|
| 15.1 | Título da Home | Meus churrascos |
| 15.2 | Botão criar | Novo churrasco |
| 15.3 | Placeholder do texto livre | Conta pra mim: quantas pessoas, tem criança, tem quem não come carne, e quanto tempo vai durar. |
| 15.4 | Exemplo abaixo do campo | Ex.: "15 adultos, 4 crianças, 3 não comem carne, do meio-dia até a noite" |
| 15.5 | Botão calcular | Calcular a lista |
| 15.6 | Estado vazio da Home | Nenhum churrasco por aqui ainda. Bora marcar o primeiro? |
| 15.7 | Modelo indisponível | Vamos no modo manual — é rapidinho também. |
| 15.8 | Erro na extração de texto | Não consegui entender dessa vez. Ajusta os números aqui embaixo que já resolve. |
| 15.9 | Aviso de recálculo | Recalculando a lista. O que você adicionou à mão continua aí. |
| 15.10 | Título da revisão da nota | Confere pra mim |
| 15.11 | Divergência de total | A soma dos itens deu diferente do total da nota. Dá uma olhada — mas se estiver certo, pode seguir. |
| 15.12 | Nenhum item reconhecido | Não deu pra ler essa foto. Tenta de novo com mais luz, ou lança os itens à mão. |
| 15.13 | Sem itens para ratear | Ainda não tem nada pra dividir. Adiciona a nota do mercado primeiro. |
| 15.14 | Ajuste histórico aplicado | Ajustei com base no último churrasco. |
| 15.15 | Sem participantes | Quem foi no churrasco? Preciso dos nomes pra dividir a conta. |
| 15.16 | Resultado mudou | Os valores mudaram. Vale reenviar pro pessoal. |
| 15.17 | Erro ao salvar | Não consegui salvar agora. Tenta de novo. |
| 15.18 | Progresso do mercado | {n} de {total} no carrinho |
| 15.19 | Tudo comprado | Carrinho completo. Bom churrasco! 🔥 |
| 15.20 | Título do resultado | A conta |
| 15.21 | Explicação (não bebe) | Não bebe: fora do rateio das bebidas alcoólicas |
| 15.22 | Explicação (criança) | Criança: paga meia na carne e nos acompanhamentos |
| 15.23 | Explicação (não come carne) | Não come carne: fora do rateio da carne |
| 15.24 | Botão compartilhar | Mandar pro grupo |
| 15.25 | Pós-evento | Como foi? Sobrou muito? Faltou alguma coisa? |
| 15.26 | Confirmar exclusão de churrasco | Apagar este churrasco? Não dá pra desfazer. |
| 15.27 | Apagar todos os dados | Isso apaga todos os seus churrascos deste aparelho. Não dá pra desfazer. |
| 15.28 | Título do paywall | Divida a conta sem digitar nada |
| 15.29 | Subtítulo do paywall | Fotografe a nota do mercado e o Carne Assada calcula quanto cada um deve. |
| 15.30 | Itens do paywall | Leitura da nota fiscal por foto · Conta dividida com regra justa · Quem não bebe não paga a cerveja · Pronto pra mandar no grupo |
| 15.31 | Reforço de pagamento único | Pagamento único. Sem assinatura, sem mensalidade. |
| 15.32 | Falha na compra | Não deu pra concluir a compra. Tenta de novo daqui a pouco. |
| 15.33 | Restauração sem compra | Não encontrei nenhuma compra anterior nesta conta. |
| 15.34 | Restauração com sucesso | Tudo certo, compra restaurada. |
| 15.35 | Botão restaurar | Já comprei, restaurar |
| 15.36 | Promessa de compra única (paywall e ficha da loja) | Pagamento único. Tudo que vier depois já está incluído. |
| 15.37 | Dica de uso da lista de compras | Toque num item pra mudar a quantidade. Arraste pro lado pra tirar da lista. |
| 15.38 | Produto não carregou da App Store | Não consegui falar com a App Store agora. Confere a conexão e tenta de novo. |

**Regra de copy para o preço:** o valor exibido no paywall vem sempre do StoreKit (`Product.displayPrice`). Nenhuma copy deste documento contém preço, de propósito (regra 11.16.6).

---

## 16. Direção visual

**Referência:** o rigor estrutural de um app nativo da Apple (Lembretes, Atalhos, Fitness) com a temperatura de um app de comida bem feito (Kitchen Stories, Mercado Libre no acerto de cor). O app é **colorido e alegre na cor, na ilustração e no movimento — e absolutamente convencional na estrutura**. Nada de tab bar customizada, nada de gesto inventado, nada de fonte exótica.

### 16.1 Paleta

**Cores de marca** (usadas em fundo, destaque, ilustração — nunca para significado de estado):

| Nome | Claro | Escuro | Uso |
|---|---|---|---|
| `brasaLaranja` | `#FF6B35` | `#FF7F4F` | Cor primária. Botões principais, item ativo, acentos |
| `carvaoEscuro` | `#2B2118` | `#F2EDE7` | Texto principal (invertido no escuro) |
| `churrascoVermelho` | `#C1443A` | `#D9584D` | Secundária. Categoria carne, ilustrações |
| `milhoAmarelo` | `#F2B134` | `#F7C25B` | Terciária. Categoria acompanhamento, celebração |
| `limaoVerde` | `#5FA83E` | `#77C155` | Categoria vegetariana, bebida não alcoólica |
| `cervejaDourado` | `#E8A33D` | `#F0B45B` | Categoria bebida alcoólica |
| `fundoTela` | `#F2F2F7` | `#000000` | Fundo das telas. **Chapado, sem gradiente** |
| `fundoCartao` | `#FFFFFF` | `#1C1C1E` | Fundo de card. Sombra sutil no claro; sem sombra no escuro |
| `textoSecundario` | `#6E6259` | `#A2958A` | Data, legenda, explicação |
| `preenchimentoSutil` | `#E5E5EA` | `#2C2C2E` | Chip de status, separador, campo de formulário |

**Nota da v1.5 — fundos corrigidos.** Até a v1.4 os fundos eram `fundoCreme` (`#FDF8F2` / `#161310`) e `cartaoBranco` (`#FFFFFF` / `#221D18`). Os nomes foram trocados junto com os valores porque tinham deixado de descrever a cor: `#F2F2F7` não é creme e o card do modo escuro não é branco. Nenhuma **cor de marca** mudou.

**Cores semânticas** (reservadas exclusivamente para significado — nunca decorativas):

| Nome | Valor | Uso |
|---|---|---|
| `sucesso` | verde do sistema | Confirmação, item comprado |
| `atencao` | âmbar do sistema | Divergência de valor, item pendente |
| `erro` | vermelho do sistema | Falha, ação destrutiva |

**Regra de conflito:** `churrascoVermelho` (marca) e `erro` (semântica) nunca aparecem na mesma tela em papéis que possam ser confundidos. Ação destrutiva usa **sempre** o vermelho do sistema, nunca o da marca.

### 16.2 Tipografia

**SF Pro exclusivamente** (fonte do sistema), com Dynamic Type completo. Nenhuma fonte customizada — é o principal fator de "cara de nativo".

- Títulos de tela: `.largeTitle`, bold
- Título de seção/categoria: `.title3`, semibold, na cor da categoria
- Corpo: `.body`
- Valores monetários: `.title2`, bold, com `monospacedDigit()` — obrigatório, para os números não dançarem ao atualizar
- Legenda/explicação: `.footnote`, na cor `textoSecundario` (16.1)

### 16.3 Forma e densidade

- Cards com canto `.rounded(16)`, sombra sutil, sem borda pesada.
- Espaçamento generoso: mínimo 16 pt de margem lateral, 12 pt entre cards.
- Densidade **baixa** — este não é um app de tabela. Card em vez de linha compacta, exceto no modo mercado, onde a lista é densa de propósito (mais itens visíveis de uma vez).
- Ícones de interface (navegação, ações, estados): **SF Symbols apenas** (`flame.fill`, `cart.fill`, `fork.knife`, `takeoutbag.and.cup.and.straw.fill`, `person.2.fill`, `checkmark.circle.fill`). Nenhum asset para ícone de interface.
- **Ilustrações e ícones de categoria: assets SVG fornecidos** (ver 16.7). Não são desenhados em código e não devem ser substituídos por SF Symbols nem redesenhados pelo agente.
- O ícone do app é asset fornecido.

### 16.4 Onde entra a personalidade

Concentrada em **cinco momentos**, e em nenhum outro lugar:

1. Estado vazio da Home
2. Transição de "calcular" para a lista pronta
3. Marcação de item no modo mercado
4. Conclusão do carrinho
5. Revelação do resultado da conta

O resto do app é deliberadamente sóbrio. Personalidade espalhada por igual vira ruído.

### 16.5 Repertório de movimento

Todo movimento em SwiftUI nativo. Duração padrão 0,3 s, `.spring(response: 0.4, dampingFraction: 0.75)` como curva base.

| # | Momento | Movimento |
|---|---|---|
| 16.5.1 | Processando a descrição da turma | Chama animada: `flame.fill` em `Canvas` com três línguas de fogo em `phaseAnimator`, oscilando em escala e opacidade. Substitui o spinner padrão. Máximo 3 s visível; depois vira spinner comum |
| 16.5.2 | Lista pronta | Itens entram em cascata de cima para baixo, 40 ms de atraso entre linhas, fade + deslocamento de 12 pt |
| 16.5.3 | Marcar item no mercado | Checkmark com `symbolEffect(.bounce)`, texto riscando da esquerda para a direita em 0,25 s, feedback háptico `.light` |
| 16.5.4 | Carrinho completo | Brasas subindo: 12 partículas em `Canvas` + `TimelineView`, laranja e amarelo, 1,5 s, uma única vez. Háptico `.success` |
| 16.5.5 | Revelar a conta | Valores contam de 0 até o valor final em 0,6 s (`monospacedDigit` impede o layout de tremer); cards entram em cascata |
| 16.5.6 | Trocar de aba dentro do churrasco | Transição padrão do sistema, sem customização |
| 16.5.7 | Erro | Shake horizontal de 6 pt, duas oscilações, háptico `.error` |
| 16.5.8 | ~~Fundo da Home~~ | **REVOGADA na v1.5.** Não há gradiente em lugar nenhum: o fundo de toda tela é `fundoTela` chapado |

**Regra absoluta:** com `accessibilityReduceMotion` ligado, 16.5.1 a 16.5.7 são substituídos por fade de 0,2 s ou por nada. O háptico permanece.

### 16.6 Livre para o agente escolher

- Arranjo exato das partículas em 16.5.4, a partir do asset de brasa fornecido.
- Disposição interna dos cards de participante.

Fora isso, siga o escrito.

### 16.7 Assets de ilustração fornecidos

As ilustrações **já existem** e estão no repositório. O agente de código **não desenha, não gera e não substitui** nenhuma delas — apenas as consome. Se um asset esperado não existir, pare e avise; não improvise com SF Symbols.

**Origem e formato:** as **17** ilustrações são **SVG** com fundo transparente (8 ilustrações de tela, 6 ícones de categoria e 3 partículas de brasa), geradas a partir do guia de arte do produto na paleta da seção 16.1. O **ícone do app** é a exceção: PNG opaco, como a Apple exige.

Por que SVG: escala sem perda em qualquer tamanho e densidade de tela, dispensa exportação em 1×/2×/3×, tem transparência nativa e pesa uma fração de um PNG equivalente — o que devolve o orçamento de binário ao patamar original (17.7).

**Onde cada uma é usada:**

| Asset | Tela / momento |
|---|---|
| Churrasqueira | Estado vazio da Home (15.6) |
| Tábua de carnes | Lista de compras pronta (10.5) |
| Carrinho de mercado | Modo mercado (10.6) |
| Churrasqueira comemorando | Carrinho completo (15.19) |
| Nota fiscal e telefone | Paywall (10.16) |
| Turma de amigos | Sem participantes (15.15) |
| Espeto vazio e prato | Como foi? (10.14) |
| Foto ilegível | Erro de leitura da nota (15.12) |
| 6 ícones de categoria | Cabeçalho de cada categoria em 10.5 e 10.6 |
| Partícula de brasa | Animação 16.5.4 |

**Regras de uso:**

- **16.7.1** — Assets entram em **Asset Catalog** (`Assets.xcassets`), nunca soltos no bundle, com nome em inglês `snake_case` (`empty_grill`, `meat_board`, `category_meat`…), acessados por constante tipada — nunca por string literal espalhada pelo código.
- **16.7.1.1** — Cada SVG entra como **Single Scale** com **Preserve Vector Data** ligado. Sem isso o Xcode rasteriza no import e a vantagem do vetor se perde.
- **16.7.2** — Toda ilustração é **decorativa**: `.accessibilityHidden(true)`. A informação vive no texto ao lado, nunca só na imagem. Ilustração sem texto ao lado é bug de acessibilidade.
- **16.7.3** — As ilustrações têm fundo transparente e paleta própria; elas **não** têm variante de modo escuro. Verifique cada uma sobre `fundoTela` claro e escuro; se alguma sumir ou ficar ilegível no escuro, resolva com um fundo circular sutil atrás dela, nunca alterando a arte.
- **16.7.4** — Ilustração grande ocupa no máximo **40% da altura útil** da tela, e encolhe (ou some) quando o Dynamic Type está em tamanho acessível — o texto tem prioridade sobre a arte.
- **16.7.5** — Os 6 ícones de categoria são renderizados a ~28 pt. Se algum não estiver legível nesse tamanho no aparelho, reporte — é problema de arte a corrigir na origem, não de código.
- **16.7.7** — Os SVG não usam variável CSS nem `currentColor`: as cores são literais e **não** devem ser tingidas por código. Não aplique `.foregroundStyle` nem `.renderingMode(.template)` sobre eles — isso apagaria a arte multicolorida.
- **16.7.6** — Nenhuma ilustração contém texto. Se alguma contiver letra ou número, reporte antes de usar: é retrabalho de arte, não algo a contornar.

---

## 17. Requisitos não-funcionais

| # | Requisito | Alvo |
|---|---|---|
| 17.1 | Abertura a frio até a Home interativa | < 1,0 s no iPhone 15 |
| 17.2 | Extração de parâmetros da turma | < 4 s no iPhone 15; acima disso, oferecer o caminho manual |
| 17.3 | Extração da nota fiscal | < 12 s para cupom de até 30 itens; cancelável a qualquer momento |
| 17.4 | Recálculo do rateio | < 300 ms para 50 itens × 30 participantes |
| 17.5 | Offline | 100% das funções operam em modo avião, sem exceção |
| 17.6 | Acessibilidade | Dynamic Type até AX5; contraste ≥ 4,5:1; VoiceOver em todos os elementos interativos; toque ≥ 44×44 pt; Reduzir Movimento respeitado |
| 17.7 | Tamanho do binário | < 30 MB. **Medido na v1.5: 3,4 MB** no `.app` de Release, sendo 2,1 MB de `Assets.car` e 1,3 MB de binário |
| 17.8 | Bateria | Nenhum processamento em background; nenhuma inferência sem ação explícita do usuário |
| 17.9 | Volume de dados | Até 200 churrascos, 100 participantes e 300 itens por churrasco sem degradação perceptível |
| 17.10 | Compatibilidade | iPhone com iOS 26+. Em aparelho sem Apple Intelligence, o app funciona integralmente em modo manual |
| 17.11 | Idioma | pt-BR apenas |
| 17.12 | Orientação | Retrato apenas |

---

## 18. Convenções de código, documentação e repositório

### 18.1 Idioma
- **Modelo de dados em português**, `snake_case`: entidades, propriedades, enums e seus valores, exatamente como na seção 7.
- **Código em inglês**: tipos de serviço, funções, variáveis, nomes de arquivo, views.
- A fronteira fica na camada de modelo: os tipos SwiftData espelham o banco e mantêm os nomes em português; tudo acima deles é inglês.

### 18.2 Comentários obrigatórios
Toda função, serviço, view model e extensão leva comentário de cabeçalho **em português** dizendo o que faz, o que recebe, o que devolve e **qual regra do spec implementa, com o número da seção**. Lógica não óbvia leva comentário inline explicando a intenção.

Ruim: `// soma os valores`
Bom: `// criança entra com peso 0,5 no rateio geral para não pagar como adulto (regra 11.7)`

### 18.3 Estrutura de pastas

```
CarneAssada/
  App/                    entrada do app, navegação raiz
  Models/                 entidades SwiftData (nomes em português)
  Features/
    Home/                 telas 10.1, 10.2
    CrowdSetup/           telas 10.3, 10.4
    ShoppingList/         telas 10.5, 10.6
    Receipt/              telas 10.7, 10.8, 10.9
    Participants/         telas 10.10, 10.11
    Split/                telas 10.12, 10.13
    PostEvent/            tela 10.14
    Settings/             tela 10.15
  Services/               serviços da seção 13 (puros, testáveis)
  AI/                     wrappers de Foundation Models e tipos @Generable
  Store/                  EntitlementService e configuração do StoreKit
  DesignSystem/           cores, tipografia, animações reutilizáveis
  Resources/
    Assets.xcassets/      ícone do app, ilustrações e ícones de categoria (16.7)
    Localizable/          strings pt-BR
CarneAssadaTests/             testes das seções 11 e 13
```

Cada pasta de feature contém suas views, view models e tipos.

### 18.4 Documentação viva
- `README.md`: setup, requisitos de Xcode/iOS, como rodar os testes, o que fazer em aparelho sem Apple Intelligence.
- `CLAUDE.md` na raiz — obrigatório. Conteúdo mínimo: convenção de idioma, mapa da arquitetura, comandos de build e teste, e as pegadinhas que **não podem ser quebradas**:
  1. nenhuma saída de modelo é gravada sem revisão do usuário;
  2. nenhum cálculo dentro do prompt;
  3. nenhuma dependência externa;
  4. nenhuma imagem de nota gravada em disco;
  5. Reduzir Movimento sempre respeitado;
  6. nenhum preço escrito no código — sempre do StoreKit;
  7. entitlement desconhecido nunca é tratado como "não comprado".
- `DOCUMENTACAO-TECNICA.md` conforme a seção 19.

`CLAUDE.md`, `README.md` e `DOCUMENTACAO-TECNICA.md` são atualizados **no mesmo commit** da mudança.

### 18.5 Variáveis de ambiente
Nenhuma. Sem chave, sem segredo, sem endpoint. Se alguma aparecer em uma release futura (v2 com PIX), entra documentada aqui.

---

## 19. Documento de documentação técnica (entregável final)

Ao fim da implementação, gerar `DOCUMENTACAO-TECNICA.md` na raiz, em português, descrevendo o sistema **como ele ficou**, não como foi planejado. Conteúdo mínimo, nesta ordem:

1. **Modelo de dados explicado** — cada entidade: para que serve, o que cada campo significa em linguagem de negócio, o que cada valor de enum quer dizer.
2. **Relacionamentos** — diagrama em texto e uma frase de cardinalidade por relação, no vocabulário do produto.
3. **Regras de negócio implementadas em código** — como não há trigger, listar cada serviço da seção 13 com nome exato do tipo e do método, o que ele calcula, quais regras da seção 11 implementa e onde é chamado.
4. **Mapa tela → entidades** — para cada tela da seção 10, o que lê, o que escreve, por quais serviços passa.
5. **Lógica das principais funcionalidades por tela** — o que é validado, gravado, calculado, e onde; o que o usuário vê em caso de erro.
6. **Divergências em relação ao spec** — o que ficou diferente e por quê. Sem esta seção o documento envelhece mentindo.

Regra de manutenção: qualquer mudança em modelo, serviço ou lógica de tela atualiza este documento no mesmo commit.

---

## 20. Privacidade, segurança e conformidade

| # | Item | Decisão |
|---|---|---|
| 20.1 | Dados coletados | Nome do churrasco, data, parâmetros da turma, lista de compras, nomes de participantes e seus marcadores, itens e valores de compra, texto pós-evento. **Nada mais.** |
| 20.2 | Dado que sai do aparelho | Apenas o texto de compartilhamento da seção 14.1, por ação explícita do usuário, e sem itens nem estabelecimento. Nenhum outro dado sai por nenhum meio |
| 20.3 | Imagem da nota fiscal | Processada em memória e **descartada**. Nunca gravada em disco, nunca em cache, nunca no álbum do usuário. É o dado mais sensível do app (revela hábitos de consumo e localização de compra) |
| 20.4 | Onde os dados ficam | Store local do SwiftData, no container do app, protegido pelo `Data Protection` do iOS. Incluído no backup do iPhone; **sem backup, troca de aparelho perde os dados** — dito claramente na tela de Ajustes |
| 20.5 | Retenção | Indefinida, sob controle do usuário. Excluir churrasco apaga tudo dele; "Apagar todos os dados" zera o store |
| 20.6 | Exportação pelo titular | O texto da seção 14.1 por churrasco. Exportação completa dos dados fica para v2 |
| 20.7 | Terceiros | **Nenhum SDK de terceiro**. Sem analytics, sem crash reporter, sem publicidade, sem rede própria. A única comunicação externa é a do StoreKit com a App Store, feita pelo sistema |
| 20.7.1 | Dado da compra | O app não guarda nem transmite dado de pagamento. Não vê cartão, não vê Apple ID, não vê identificador de transação além do que o StoreKit expõe localmente. Nenhum dado do usuário é enviado à Apple pelo app |
| 20.8 | LGPD | O app é controlador de nada: não há tratamento remoto, não há transferência, não há compartilhamento automático. Nome de participante é dado pessoal de terceiro inserido pelo usuário e permanece exclusivamente no aparelho dele |
| 20.9 | Menores | O app registra que um participante "é criança" — marcador de consumo, sem idade, sem data de nascimento, sem qualquer identificador além do nome que o usuário digitou |
| 20.10 | Segredos e chaves | Não existem. Nenhuma credencial no binário |
| 20.11 | Rastreamento | Nenhum. `NSPrivacyTracking = false` no manifesto de privacidade; nenhuma API de "required reason" usada além do necessário |
| 20.12 | Ficha da App Store | Declarar "Compras no app" e a categoria de dado "Compras" apenas no que o StoreKit exige. Nenhuma outra categoria de dado é coletada |

---

## 21. Métricas de sucesso

Sem telemetria (20.7), portanto medidas fora do app, via App Store Connect e feedback direto:

| # | Métrica | Alvo | Prazo |
|---|---|---|---|
| 21.1 | Avaliação média na App Store | ≥ 4,5 | 90 dias após o lançamento |
| 21.2 | Reclamação recorrente sobre valor errado no rateio | zero ocorrências | contínuo — é o risco reputacional do produto |
| 21.3 | Crash-free sessions (métrica nativa da App Store Connect) | ≥ 99,5% | contínuo |
| 21.4 | Taxa de conversão para a compra (compras ÷ downloads, App Store Connect) | ≥ 3% | 90 dias após o lançamento |
| 21.5 | Pedidos de reembolso | < 2% das compras | contínuo — reembolso alto indica paywall confuso sobre o que é grátis |

Se 21.4 ficar muito abaixo do alvo, a hipótese a testar primeiro é a **fronteira** do paywall (regra 11.16), não o preço.

Nenhum evento de analytics é implementado. Decisão consciente, não esquecimento.

---

## 22. Estratégia de teste

### 22.1 Testes automatizados obrigatórios
- **Toda** a seção 11: cada tabela de consumo, cada multiplicador, cada arredondamento, cada regra de rateio.
- O exemplo trabalhado 11.13, como teste de regressão nomeado.
- Regra 11.8: propriedade "soma dos individuais == total", verificada com valores aleatórios (100 iterações).
- `ShoppingListCalculator` e `SplitCalculator` com cobertura ≥ 90%.
- Clamps da seção 13.2 (entrada fora de faixa é sempre corrigida).
- Migração do SwiftData da v1 para a v2 quando existir.
- `EntitlementService`: cada um dos três estados leva ao comportamento correto da UI, com atenção ao estado `desconhecido` (regra 11.16.4).

### 22.2 Testes manuais obrigatórios
- Os três estados de `availability` (disponível, Apple Intelligence desligada, aparelho sem suporte).
- 10 cupons fiscais reais, incluindo térmico desbotado e com desconto (7.10.3).
- Dynamic Type em AX5 em todas as telas.
- Reduzir Movimento ligado, em todas as telas.
- Modo avião no fluxo completo, ponta a ponta.
- Modo escuro em todas as telas.
- Compra completa em **sandbox** do StoreKit: comprar, cancelar no meio, falhar, restaurar em outro aparelho com o mesmo Apple ID, e restaurar sem compra existente.
- Uso completo do app **sem comprar**: todas as funções grátis da tabela 11.16 acessíveis, sem limite e sem insistência de paywall fora da área de conta.

### 22.3 Casos de borda a cobrir
Churrasco com 1 participante; churrasco com 0 adultos e só crianças; todos vegetarianos; todos abstêmios; item de R$ 0,00; nota com desconto; nota com 50+ itens; participante excluído após o fechamento; dois churrascos no mesmo dia.

---

## 23. Riscos e mitigação

| # | Risco | Impacto | Prob. | Mitigação |
|---|---|---|---|---|
| 23.1 | Leitura de cupom fiscal térmico com erro em valores (vírgula, coluna trocada) | **Alto** — valor errado destrói a confiança no app (métrica 21.2) | Alta | Tela de revisão obrigatória (0.1); valor ilegível vem vazio, nunca estimado (11.10.2); aviso de divergência com o total (11.10.1); validação com 10 cupons reais antes de fechar 8.5 |
| 23.2 | Extração da nota estourar a janela de contexto do modelo on-device com cupom longo | Médio — feature falha em compra grande, justo a que mais precisa | Média | Medir tokens (4.3.2); se estourar, dividir a foto em faixas e processar em duas passadas, concatenando os itens; fallback manual sempre presente |
| 23.3 | Inferência acima de 12 s em iPhone de entrada, quebrando 17.3 | Médio — abandono na etapa mais valiosa | Média | Progresso visível e cancelável desde o primeiro segundo; caminho manual a um toque de distância |
| 23.4 | Guardrail do framework recusar conteúdo inocente (nome de bebida alcoólica, valor) | Baixo | Baixa | Falha tratada como indisponibilidade (13.2.7); nunca mostra erro técnico; caminho manual assume |
| 23.5 | Tabela de consumo (11.1) não bater com a realidade regional | Médio — lista errada é o produto errado | Média | Números são a base declarada, editável pelo usuário em qualquer item; ajuste histórico (8.9) corrige ao longo do uso; revisar após feedback real |
| 23.6 | ~~Base instalada de iOS 27 pequena no lançamento~~ | — | — | **Resolvido na v1.5**: a mitigação prevista foi executada por outro motivo (a premissa 4.3.1 falhou). O mínimo é iOS 26 e o épico 8.5 usa Vision + texto |
| 23.7 | Perda de dados em troca de aparelho sem backup | Baixo | Média | Aviso explícito na tela de Ajustes (20.4); exportação completa entra na v2 |
| 23.9 | Fronteira do paywall frustrar o usuário: ele planeja o churrasco inteiro de graça e só descobre o bloqueio com a nota na mão | Médio — sensação de armadilha, reembolso e avaliação ruim | Média | A ficha da App Store diz claramente o que é grátis e o que é pago; a aba Conta mostra o cadeado desde o início, não só no momento do toque; copy do paywall enfatiza pagamento único (15.31) |
| 23.10 | Conversão abaixo do alvo por o produto grátis ser bom demais | Médio — receita zero com base instalada boa | Média | Aceito conscientemente: a parte grátis é a que gera boca a boca. Se 21.4 falhar, mover a atribuição de itens ou o modo mercado para o lado pago é reversível; mudar preço, não |
| 23.11 | StoreKit sem resposta (offline na primeira abertura) travar a área de conta de quem já comprou | Baixo | Média | Estado `desconhecido` mostra carregamento e reconsulta; entitlement fica em cache local após a primeira leitura bem-sucedida, e nunca é rebaixado para "não comprado" por falta de rede |
| 23.8 | Usuário interpretar o valor sugerido como cobrança oficial | Baixo | Baixa | O app não movimenta dinheiro e não afirma exatidão fiscal; a tela de detalhe (10.13) mostra a composição, deixando a conta auditável |

---

## 24. Assunções declaradas

**Assunção não revisada vira verdade no minuto em que o agente começa a codar.** Revise esta seção antes de gerar código.

| # | Assumi que… | Porque | Se você discordar |
|---|---|---|---|
| 24.1 | O nome do app é **Carne Assada** | Definido por você na v1.1 | — |
| 24.2 | Um único usuário, sem login, sem perfis (seções 5 e 6 vazias) | Decorre do princípio 0.3, que você já aplica nos outros apps standalone | Se quiser convidado com acesso próprio, isso exige backend e muda a arquitetura inteira |
| 24.3 | As quantidades da tabela 11.1 são o padrão do produto | Baseadas em consumo típico de churrasco brasileiro; são o número que o app precisa ter para funcionar no dia 1 | Ajuste qualquer célula da tabela — é edição local, não muda arquitetura |
| 24.4 | Criança paga meia no rateio geral | É a convenção social mais comum em vaquinha de churrasco | Se preferir criança sem custo, muda só a regra 11.7 |
| 24.5 | A imagem da nota nunca é gravada em disco | É o dado mais sensível e não tem uso posterior no produto | Se quiser reprocessar a foto depois, precisa gravar — e aí a seção 20 muda |
| 24.6 | Um churrasco pode ter várias notas | Mercado + açougue + bebida é o caso comum | — |
| 24.7 | O ajuste histórico só vale para o churrasco seguinte, sem acumular | Acúmulo entre eventos amplifica erro e fica impossível de explicar ao usuário | Se quiser média móvel, vira outra regra e outro campo |
| 24.8 | Retrato apenas, iPhone apenas | Todas as telas são listas verticais; paisagem e iPad não agregam | iPad entra na v2 se você quiser |
| 24.9 | A fronteira do paywall é "planejar grátis, dividir pago" (11.16) | O momento de maior valor percebido é a nota na mão com 30 itens para digitar; e a parte grátis precisa ser boa sozinha para gerar boca a boca | Mover a atribuição de itens ou o modo mercado para o lado pago é uma mudança local na tabela 11.16 |
| 24.11 | O lançamento manual de itens de compra também é pago (11.16.2) | Se ficasse grátis, o usuário digitaria os itens à mão e a feature paga perderia sentido | Se preferir manual grátis e só a foto paga, diga — muda só a 11.16.2 |
| 24.13 | O PIX da v2 (28.1) é feature paga, incluída na compra já feita | Coerente com 11.16.8 e com a fronteira "dividir a conta é pago" | Se quiser PIX grátis para todos, muda só a linha correspondente na tabela 11.16 |
| 24.12 | Sem validação de recibo em servidor (4.2) | Não vale criar backend num app que não tem nenhum, para um produto de R$ 19,90 | Aceita-se que jailbreak burle a compra; é o trade-off padrão de app pequeno |
| 24.10 | Nenhuma dependência externa, inclusive de animação | Mantém binário pequeno e manutenção por prompt viável | Lottie/Rive dariam ilustração mais rica ao custo de dependência |

---

### 24.14 Divergências da implementação (v1.5)

O que ficou diferente do escrito, e por quê. Sem esta lista o documento envelhece mentindo.

| # | Divergência | Motivo |
|---|---|---|
| 24.14.1 | **iOS 26 em vez de iOS 27**, e épico 8.5 com Vision + texto | A premissa 4.3.1 foi validada e reprovada: o SDK instalado não expõe anexo de imagem no Foundation Models. É a contingência já prevista em 4.2 e no risco 23.6 |
| 24.14.2 | **Quatro abas** no churrasco, não três (seção 10) | Mercado virou aba própria. É o momento de uso mais difícil (seção 2) e não podia estar atrás de outra tela |
| 24.14.3 | Nomes `fundoTela` / `fundoCartao` no lugar de `fundoCreme` / `cartaoBranco` | Os nomes antigos deixaram de descrever a cor depois da correção de paleta (16.1) |
| 24.14.4 | Novos tokens `textoSecundario` e `preenchimentoSutil` (16.1) | Já existiam de fato no design entregue; estavam faltando no spec |
| 24.14.5 | Dois campos novos em `churrasco`: `inclui_carne_suina` e `ajuste_historico_ligado` | Consequências diretas da decisão 25.3 e do critério "o usuário pode desligar o ajuste com um toque" do épico 8.9 |
| 24.14.6 | Telas de lista usam `List` do SwiftUI, não `ScrollView` + `LazyVStack` | O swipe para excluir (10.1, 10.5) **só funciona dentro de uma `List`**; fora dela `swipeActions` é ignorado em silêncio. O visual de card da seção 16.3 é preservado escondendo fundo e separador de linha |
| 24.14.7 | O título grande da barra de navegação ainda trunca em AX5 | Comportamento do próprio iOS para `.navigationTitle`, igual ao dos apps da Apple. **Todo o conteúdo** das telas respeita o critério 8.11 sem corte |
| 24.14.10 | Existe um atalho de liberação da conta em **`#if DEBUG`**, na tela de Ajustes | Sem ele não há como exercitar rateio, atribuição e compartilhamento em aparelho enquanto `carne_assada_pro` não existir no App Store Connect. Verificado por `strings` que não aparece no binário de Release. Sai do código quando o produto existir |
| 24.14.9 | A dica 15.37 aparece uma vez e some para sempre com "Entendi" (`AppStorage`) | Toque para editar e arrastar para excluir são gestos padrão do iOS, mas **não são óbvios num card** — o usuário reconhece o padrão numa linha de tabela, não num card solto. Dica permanente viraria ruído em quem já aprendeu |
| 24.14.8 | O rateio é recalculado a cada leitura, nunca gravado | Garante que a exceção 9.2.7 (participante excluído depois do fechamento) não deixe valor velho em tela |

---

## 25. Perguntas abertas

**O agente de código deve perguntar, nunca assumir, ao cruzar com qualquer item desta seção.**

**Na v1.5 não resta nenhuma pergunta aberta.** As três últimas (25.2, 25.3 e 25.5) foram decididas antes da implementação, na ordem exigida pela coluna "Quando".

| # | Pergunta | Quem decide | Quando |
|---|---|---|---|
| 25.1 | ~~Nome do app~~ — **resolvido na v1.1: Carne Assada** | — | — |
| 25.2 | ~~Peso proporcional para quem chegou no meio?~~ — **resolvido na v1.5: continua contando inteiro (regra 11.5.1)**. A correção fina se faz por atribuição explícita | — | — |
| 25.3 | ~~Incluir carne suína na tabela 11.1?~~ — **resolvido na v1.5: incluída como item opcional**, desligada por padrão (11.1.1) | — | — |
| 25.4 | ~~Modelo de monetização~~ — **resolvido na v1.1: compra única de R$ 19,90, paywall por feature (11.16)** | — | — |
| 25.6 | ~~As features da v2 entram na mesma compra ou viram uma segunda?~~ — **resolvido na v1.2: entram na mesma compra (regra 11.16.8)** | — | — |
| 25.5 | ~~Cupom longo: duas passadas ou limite de N itens?~~ — **resolvido na v1.5: fatiar em passadas**. Com a virada para OCR (4.2) o que entra no prompt é texto; o app fatia em blocos de 40 linhas e concatena os itens, sem teto de quantidade | — | — |

---

## 26. Definition of Done

**Legenda da v1.5:** `[x]` verificado nesta implementação · `[ ]` ainda depende de aparelho real, cupom real ou conta da loja.

**Funcional**
- [x] Épicos 8.1 a 8.11 implementados.
- [ ] Fluxo 9.1 executado ponta a ponta **em aparelho real** (o simulador não tem Apple Intelligence nem câmera).
- [ ] Os sete caminhos de exceção da 9.2 testados em aparelho.

**Não-funcional**
- [ ] Alvos 17.1 a 17.4 medidos em iPhone real e registrados.
- [x] Tamanho do binário (17.7): **3,4 MB**, contra o alvo de 30 MB.
- [ ] App 100% funcional em modo avião (17.5) — verificar em aparelho.
- [x] App funcional sem Apple Intelligence (17.10): verificado no simulador, que não tem o modelo. Os pontos de IA somem e o caminho manual assume (regra 11.9).
- [x] Dynamic Type em AX5 sem corte de conteúdo, modo claro e escuro (ver divergência 24.14.7).

**Privacidade**
- [x] Nenhuma escrita de imagem em disco no código (20.3): busca por `write(to:)`, `UIImageWriteToSavedPhotosAlbum` e afins retorna zero. **Falta** confirmar por inspeção do container depois do fluxo com câmera real.
- [x] Nenhum código de rede próprio (20.7): busca por `URLSession`, `URLRequest`, `import Network` e `dataTask` retorna zero. **Falta** a confirmação com o Network Instrument.
- [x] `PrivacyInfo.xcprivacy` preenchido, com `NSPrivacyTracking = false` e nenhuma categoria de dado coletada.

**Testes**
- [x] 43 testes em 6 suítes passando.
- [x] Teste de regressão do exemplo 11.13 passando, item a item.
- [x] Teste de propriedade da regra 11.8 passando com 100 iterações (gerador determinístico, para uma falha ser reproduzível).
- [ ] Cobertura ≥ 90% em `ShoppingListCalculator` e `SplitCalculator` — medir e registrar.
- [ ] Checklist manual 22.2 completo.

**Código e documentação**
- [x] Modelo de dados em português conforme a seção 7, mais os dois campos da divergência 24.14.5.
- [x] Funções e serviços comentados em português, com o número da regra do spec.
- [x] `DOCUMENTACAO-TECNICA.md` gerado.
- [x] `CLAUDE.md` criado com as **sete** pegadinhas da 18.4.
- [x] `README.md` em dia.
- [x] Zero dependência externa (não existe `Package.resolved` no projeto).
- [x] Busca por "19,90" no projeto: zero ocorrências (regra 11.16.6).

**Publicação**
- [x] Ícone do app no Asset Catalog a partir do PNG 1024 opaco fornecido, com `CFBundleIconName` declarado no `Info.plist`. **Falta** conferir na tela de início do aparelho.
- [x] As 17 ilustrações no Asset Catalog e usadas nas telas da tabela 16.7.
- [x] Ilustrações conferidas sobre fundo claro e escuro (16.7.3); as de estado vazio ganharam o fundo circular sutil que a própria regra prevê.
- [x] Os 17 SVG com `preserves-vector-representation` no `Contents.json` (16.7.1.1).
- [ ] Screenshots e ficha da App Store prontos.
- [ ] Testado em pelo menos um iPhone com Apple Intelligence e um sem.
- [x] `CarneAssada.storekit` criado e ligado ao scheme, para o desenvolvimento.
- [ ] Produto `carne_assada_pro` criado no App Store Connect, com nome e descrição revisados.
- [ ] Fluxo de compra e de restauração testado em sandbox, ponta a ponta.
- [ ] Ficha da App Store declara com clareza o que é grátis e o que exige a compra (mitigação do risco 23.9).

---

## 27. Próximos passos operacionais

Passos 1 a 6 concluídos na v1.5. O que resta depende de aparelho real e de conta da loja:

1. ~~Revisar a seção 24 e responder a seção 25.~~ **Feito** — 25.2, 25.3 e 25.5 decididas.
2. ~~Validar as premissas 4.3.1 e 4.3.2.~~ **Feito** — 4.3.1 reprovada, arquitetura do 8.5 ajustada conforme 4.2.
3. ~~Colocar os assets no Asset Catalog.~~ **Feito** — 17 SVG mais o ícone.
4. ~~Gerar as telas no Claude Design.~~ **Feito** — as 16 telas, em claro e escuro, guiaram a implementação.
5. ~~Criar o repositório e implementar.~~ **Feito** — épicos 8.1 a 8.11.
6. ~~Implementar na ordem dos épicos.~~ **Feito**, com os critérios de aceite conferidos no que o simulador alcança.
7. **Rodar em iPhone real com Apple Intelligence ligada**: extração de parâmetros (8.2), leitura de nota (8.5) e os alvos 17.1 a 17.4.
8. **Testar com 10 cupons reais**, incluindo térmico desbotado e nota com desconto, antes de dar 8.5 por fechado (risco 23.1).
9. Criar o produto `carne_assada_pro` no App Store Connect (R$ 19,90, não-consumível) e testar compra e restauração em sandbox.
10. Completar o checklist manual da seção 22.2.
11. Preparar a ficha da App Store, deixando explícito o que é grátis e o que é pago (mitigação do risco 23.9).

---

## 28. Roadmap: próximas releases

### 28.0 Preço e experimentos de monetização (pós-lançamento)
O preço de R$ 19,90 é o ponto de partida. Com preço vitalício é fácil subir e ruim descer, então qualquer ajuste é para cima e só depois de 90 dias de dado real (métrica 21.4).

**Todas as features abaixo entram na compra `carne_assada_pro` já existente** (regra 11.16.8). Não há segundo produto. Como cada release aumenta o valor entregue sem gerar nova receita da base já convertida, o instrumento de captura de valor é o **preço para novos compradores**, revisto a cada release relevante.

### 28.1 PIX (v2)
Geração de cobrança PIX para o valor de cada participante, em QR code e copia-e-cola, a partir da chave PIX do organizador guardada localmente. Exige: campo de chave PIX nos Ajustes, validação de formato de chave (CPF, e-mail, telefone, aleatória), montagem do BR Code conforme o padrão EMV do Banco Central com CRC16, renderização do QR local, e teste com pelo menos três bancos diferentes. O texto de compartilhamento da 14.1 ganha o copia-e-cola por participante. Nenhuma comunicação com banco — o app só monta o código; a confirmação de pagamento continua fora do escopo.

### 28.2 Momento "durante o churrasco" (v2)
Timer de assado e ordem sugerida de grelha. O usuário informa os cortes e os pesos; o app sugere a ordem de entrada na grelha e cronometra cada um, com notificação local. Compartilha o `churrasco` como pai, mas com entidade própria — não toca em nenhuma entidade do MVP.

### 28.3 Exportação completa (v2)
Exportação de todos os dados do aparelho em JSON, para backup manual e portabilidade (LGPD, art. 18). Mitiga o risco 23.7.

### 28.4 iPad e widgets (v2)
Layout de duas colunas no iPad; widget da lista de compras na tela de bloqueio para o momento mercado.

### 28.5 App Intents / Siri (v2)
"Ei Siri, marca a picanha como comprada." Exige mapear as ações do modo mercado como App Intents.

---

## 29. Protocolo de mudanças incrementais

Depois do v1 pronto, evite que um ajuste pequeno vire reescrita do app:

1. **Commit de checkpoint** antes de qualquer mudança, para ter um `git diff` confiável.
2. **Não cole o spec inteiro de novo.** Cole só o trecho alterado, ou um spec adicional da feature.
3. **Escreva como diff, não como recomeço** — deixe explícito que o projeto já existe e funciona.
4. **Delimite nominalmente o que não muda.**
5. **Peça a lista de arquivos** que serão criados/alterados antes do código, e aprove.
6. **Revise o `git diff`** contra o plano aprovado; reverta arquivo fora do escopo e refaça o pedido mais específico.
7. **Exija a atualização do `DOCUMENTACAO-TECNICA.md`** no mesmo commit.

### Modelo de prompt para mudança incremental

```
O projeto Carne Assada já existe, está implementado e funcionando. Não recomece nada.

Mudança pedida: [descreva a mudança em uma frase]
Regra do spec afetada: [número da seção]

NÃO ALTERE: modelo de dados (seção 7), serviços de cálculo (seção 13),
nem qualquer tela fora de [tela específica].

Antes de escrever código: liste os arquivos que você vai criar ou alterar
e o que muda em cada um. Espere minha aprovação.

Depois de implementar: atualize DOCUMENTACAO-TECNICA.md no mesmo commit,
incluindo a seção de divergências.
```

---

## Anexo — Fontes

Consultadas em 28 de agosto de 2026:

- Apple Developer — "Meet the Foundation Models framework", WWDC25: https://developer.apple.com/videos/play/wwdc2025/286/
- Apple Developer — "What's new in the Foundation Models framework", WWDC26: https://developer.apple.com/videos/play/wwdc2026/241/
- Apple Developer — "Bring an LLM provider to the Foundation Models framework", WWDC26: https://developer.apple.com/videos/play/wwdc2026/339/
- Apple Developer — "Meet Core AI", WWDC26: https://developer.apple.com/videos/play/wwdc2026/324/
- Apple Developer — Guia de Machine Learning WWDC26: https://developer.apple.com/wwdc26/guides/machine-learning/
- Referência de terceiros sobre janela de contexto, anexos de imagem e disponibilidade por aparelho: https://blakecrosley.com/blog/apple-foundation-models-framework

Nota: os números de janela de contexto e os nomes de tipo de anexo de imagem citados na seção 4.3 vêm de material de terceiros e de sessões da WWDC26 — por isso estão registrados como **premissas a validar**, não como fato verificado no SDK instalado.
