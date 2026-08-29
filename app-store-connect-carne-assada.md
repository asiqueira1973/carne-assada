# App Store Connect — Carne Assada

Pacote pronto para colar. Gerado a partir do `spec.md` v1.8.
Bundle ID: `com.dablab.carneassada` · Team `XGZW6Y6K25`

---

## 1. App Information

| Campo | Valor |
|---|---|
| **Name** | `Carne Assada` |
| **Subtitle** | `Churrasco: lista e vaquinha` |
| **Primary Category** | Food & Drink |
| **Secondary Category** | Utilities |
| **Copyright** | `© 2026 Alexandre Siqueira` |
| **Bundle ID** | `com.dablab.carneassada` |
| **SKU** | `carneassada001` |
| **Primary Language** | Portuguese (Brazil) |

---

## 2. Version Information

### Promotional Text

```
Chega de errar a conta do churrasco. O app calcula quanto comprar e quanto cada um paga — quem não bebe não paga a cerveja.
```

### Description

```
O CHURRASCO MAIS BEM RESOLVIDO DO BRASIL COMEÇA AQUI

Todo churrasco tem duas contas que alguém faz de cabeça e erra: quanto comprar e quanto cada um deve pagar. O Carne Assada resolve as duas.

Você conta quem vai — do jeito que você falaria com um amigo. "15 adultos, 4 crianças, 3 que não comem carne, do meio-dia até a noite." A inteligência artificial do seu próprio iPhone entende a frase e transforma em números. A lista de compras sai pronta, separada por categoria, na quantidade certa de carne, cerveja, carvão e tudo mais.

Depois do mercado, você fotografa a nota fiscal. O app lê os itens e os valores, você confere, e cada pessoa recebe o valor dela — com a regra justa que todo mundo aceita.

FEITO PARA O CHURRASCO DE VERDADE

• Lista calculada na quantidade certa, com o que ninguém lembra: sal grosso, acendedor, gelo, carvão
• Modo mercado: lista grande, marcável com o polegar, funciona sem sinal nenhum
• Quem não bebe não paga a cerveja
• Criança paga meia na carne
• Quem não come carne fica fora do rateio da carne
• Item que foi só de uma pessoa? Marca e só ela paga
• O resultado sai pronto pra colar no grupo do WhatsApp

A CONTA É EXATA, NÃO É CHUTE

Aqui a inteligência artificial faz o que ela faz bem: entender o que você escreveu e ler a sua nota fiscal. A conta em si é matemática pura, feita com precisão de centavo — a soma do que cada um paga bate exatamente com o total, sempre. E cada valor abre e mostra, linha por linha, de onde ele veio. Ninguém no grupo vai discutir um número que dá pra conferir.

TUDO ACONTECE NO SEU IPHONE

Sem cadastro. Sem senha. Sem nuvem. Sem anúncio.

A inteligência artificial roda dentro do seu aparelho — sua nota fiscal não vai para servidor nenhum, porque não existe servidor nenhum. A foto da nota é lida na hora e descartada: ela nunca é salva, nem no app, nem no seu álbum.

E funciona em modo avião, porque mercado grande costuma ter sinal ruim justo no corredor da carne.

O QUE É GRÁTIS

Planejar o churrasco inteiro é de graça, sem limite e sem pegadinha:

• Quantos churrascos você quiser
• Descrever a turma em texto livre
• Lista de compras calculada, editável do jeito que você quiser
• Modo mercado
• Cadastro de quem foi
• Histórico dos churrascos anteriores
• O app aprende: você conta que sobrou linguiça e o próximo já sai ajustado

O QUE É PAGO

Dividir a conta é a parte paga: ler a nota por foto, lançar itens, calcular o rateio, marcar quem consumiu o quê e mandar o resultado pro grupo.

PAGAMENTO ÚNICO. SEM ASSINATURA.

Você paga uma vez e pronto. Nada de mensalidade para um app que você usa três vezes por ano. E tudo que vier nas próximas versões já está incluído — quem compra hoje não paga de novo, nunca.

BOM CHURRASCO.

Observações: os recursos de inteligência artificial usam o Apple Intelligence e exigem um iPhone compatível com ele. Em aparelhos sem Apple Intelligence o app funciona por completo no modo manual — nenhuma função fica indisponível, você só digita os números em vez de escrever a frase. Disponível apenas em português do Brasil.
```

### Keywords

```
rateio,dividir,conta,racha,compras,mercado,festa,picanha,cerveja,amigos,espeto,nota,fiscal,churras
```

> Nenhuma palavra repete o Name ou o Subtitle (carne, assada, churrasco, lista, vaquinha já são indexadas por eles). Sem acento, para não gastar 2 bytes por letra. "churras" está aí de propósito: é como muita gente escreve na busca. "nota" e "fiscal" entram separados para a Apple poder combinar os dois.

### What's New in This Version (1.0)

```
Primeira versão do Carne Assada.

Conte quem vai, receba a lista de compras na quantidade certa, marque tudo no mercado e divida a conta fotografando a nota fiscal. Quem não bebe não paga a cerveja, criança paga meia na carne, e a soma sempre bate com o total.

Bom churrasco.
```

---

## 3. App Privacy

**Resposta: `Data Not Collected`.**

Marcar "No, we do not collect data from this app" no questionário e não preencher nenhuma categoria.

Base no spec (seção 20): o app não tem backend, não tem conta, não tem analytics, não tem crash reporter, não tem SDK de terceiro e **não possui código de rede próprio** — verificado por busca no projeto (`URLSession`, `URLRequest`, `dataTask`: zero ocorrências). O único tráfego é o do StoreKit com a App Store, feito pelo sistema operacional, e o app não guarda nem transmite dado de pagamento.

Pontos que costumam confundir e **não** mudam a resposta:

- **Foto da nota fiscal** — processada em memória e descartada. Nunca gravada em disco, cache ou álbum (seção 20.3). Não sai do aparelho, portanto não é coleta.
- **Nomes dos participantes** — dado pessoal de terceiro digitado pelo usuário, que permanece exclusivamente no aparelho dele (seção 20.8).
- **Marcador "é criança"** — não é idade nem data de nascimento; é um marcador de consumo, sem identificador (seção 20.9).
- **Texto compartilhado** — sai por ação explícita do usuário, pela share sheet do iOS, e contém apenas nome do churrasco, data, total e valor por pessoa. Nunca itens nem nome do estabelecimento (seção 20.2).

**Tracking:** `NSPrivacyTracking = false` no manifesto de privacidade. Nenhum domínio de tracking. Sem ATT.

---

## 4. URLs obrigatórias

| Campo | Valor |
|---|---|
| **Support URL** | `https://suportedablab.carrd.co/` |
| **Marketing URL** | (deixar em branco) |
| **Privacy Policy URL** | link público do Notion "Política de Privacidade — Aplicativos da Dab Lab" |

### Seção nova para adicionar ao documento de Política de Privacidade

> **Colar dentro do documento do Notion, como uma seção própria do Carne Assada.**
>
> O texto genérico da Dab Lab menciona Firebase Authentication, Crashlytics/Analytics e permissões de notificação. **Nada disso se aplica a este app**, e deixar o genérico valendo criaria contradição direta com a resposta "Data Not Collected" da App Store — duas fontes dizendo coisas diferentes sobre o mesmo app é atrito garantido na revisão. Por isso a seção abaixo nega essas afirmações explicitamente.

```
CARNE ASSADA

O Carne Assada é um aplicativo local-first: ele não possui servidor, não
possui conta de usuário e não envia dados para lugar nenhum.

1. Coleta de Dados

O Carne Assada não coleta nenhum dado pessoal. Não há cadastro, login,
senha, e-mail ou qualquer forma de identificação do usuário.

Diferentemente do descrito nas seções gerais deste documento, o Carne
Assada NÃO utiliza Firebase Authentication, NÃO utiliza Firebase
Analytics, NÃO utiliza Crashlytics e NÃO envia notificações. O aplicativo
não possui nenhum SDK de terceiros e não faz nenhuma requisição de rede
própria.

Tudo o que você digita no aplicativo — o nome do churrasco, quantas
pessoas vão, os itens da lista, os nomes de quem participou, os valores
da compra e o relato de como foi o evento — fica armazenado exclusivamente
no seu iPhone.

2. Uso dos Dados

Os dados que você digita são usados apenas para as funções do próprio
aplicativo: calcular a lista de compras e dividir a conta entre os
participantes.

Os recursos de inteligência artificial (entender a descrição da turma,
ler a nota fiscal e interpretar o relato pós-evento) utilizam o Apple
Intelligence e são processados INTEIRAMENTE DENTRO DO SEU APARELHO. Nenhum
texto e nenhuma imagem são enviados para servidores da Dab Lab, da Apple
ou de qualquer terceiro.

Permissões solicitadas:

- Câmera: usada exclusivamente para fotografar a nota fiscal do mercado.
- Galeria de fotos: usada exclusivamente para você escolher uma foto de
  nota fiscal já existente.

A imagem da nota fiscal é lida na memória do aparelho e imediatamente
descartada. Ela NUNCA é gravada em disco, NUNCA é armazenada em cache e
NUNCA é salva no seu álbum de fotos.

3. Armazenamento e Segurança

Todos os dados ficam no armazenamento local do aplicativo, no seu iPhone,
protegidos pelo sistema de Data Protection do iOS.

Esses dados são incluídos no backup do seu iPhone (iCloud ou computador).
Se você trocar de aparelho sem restaurar um backup, os dados são perdidos
— o aplicativo avisa sobre isso na própria tela de Ajustes.

Você pode apagar um churrasco específico, ou todos os seus dados de uma
vez, a qualquer momento, pela tela de Ajustes do aplicativo.

4. Compartilhamento com Terceiros

Não há compartilhamento de dados com terceiros. Não há publicidade, não há
analytics e não há qualquer forma de rastreamento.

O único conteúdo que sai do aplicativo é o texto do resultado da divisão
da conta, e apenas quando VOCÊ toca em compartilhar. Esse texto contém
somente o nome do churrasco, a data, o valor total e o valor de cada
participante. Ele não contém os itens comprados nem o nome do
estabelecimento.

O aplicativo se comunica com a App Store apenas para processar a compra
única dentro do app, por meio do sistema operacional. A Dab Lab não recebe,
não vê e não armazena nenhum dado de pagamento.

5. Contato

Dúvidas sobre esta política ou sobre o Carne Assada:
alexandre@dablab.com.br
```

---

## 5. Pricing and Availability

| Campo | Valor |
|---|---|
| **Price** | Free (Tier 0) — a monetização é por compra dentro do app |
| **Availability** | All Countries or Regions |
| **Pre-Orders** | Não |

### In-App Purchase

| Campo | Valor |
|---|---|
| **Reference Name** | `Carne Assada Pro` |
| **Product ID** | `carne_assada_pro` |
| **Type** | Non-Consumable |
| **Price** | R$ 19,90 (tier correspondente no Brasil) |
| **Availability** | All Countries or Regions |
| **Family Sharing** | Desligado |

**Display Name (pt-BR):**
```
Dividir a conta
```

**Description (pt-BR):**
```
Libera a divisão da conta: leia a nota do mercado por foto, lance itens, marque quem consumiu o quê e mande o valor de cada um pro grupo. Pagamento único, sem assinatura — e tudo que vier nas próximas versões já está incluído.
```

**Review Screenshot:** obrigatória. Use a captura da tela de paywall (`prints para a appstore/6.5/09-paywall.png`).

**Review Notes do IAP:**
```
Compra única não-consumível que libera a aba "Conta" do aplicativo.
A parte gratuita (planejar o churrasco, lista de compras, modo mercado,
cadastro de participantes, histórico) permanece completa e sem limite.
```

> ⚠️ **O produto precisa estar em "Pronto para Enviar"** antes do teste em TestFlight ou da revisão. Em "Faltam metadados" o StoreKit não devolve o produto nem em sandbox, e o paywall mostra a mensagem de indisponibilidade.

---

## 6. App Review Information

| Campo | Valor |
|---|---|
| **Sign-in Required** | **Não** (o app não tem conta, login nem cadastro) |
| **First Name** | Alexandre |
| **Last Name** | Siqueira |
| **Phone Number** | (preencher com o telefone de contato) |
| **Email** | alexandre@dablab.com.br |

### Notes

```
Carne Assada é um app local-first para planejar um churrasco e dividir a
conta entre os participantes. Não há conta de usuário, login, cadastro ou
senha: o app abre direto na tela principal e todos os dados ficam apenas no
aparelho. Por isso não há credencial de teste a fornecer, nem opções de
excluir conta, trocar senha ou sair.

COMO TESTAR A COMPRA DENTRO DO APP

O app é gratuito. Planejar o churrasco é gratuito e ilimitado. A área de
divisão da conta é liberada por uma compra única não-consumível
(carne_assada_pro). Para chegar até ela:

1. Na tela inicial, toque em "Novo churrasco" e salve.
2. Abra o churrasco criado.
3. Toque na aba "Conta", a terceira da barra inferior (com o cadeado).
4. A tela de compra aparece com o botão de liberação.

A compra é processada em sandbox durante a revisão, sem cobrança. Depois
de comprar, a aba "Conta" libera imediatamente: adicionar nota, lançar
itens, calcular o rateio e compartilhar o resultado.

Existe também "Já comprei, restaurar", no próprio paywall e na tela de
Ajustes.

RECURSOS DE INTELIGÊNCIA ARTIFICIAL

Três recursos usam o Apple Intelligence, processado inteiramente no
aparelho (framework Foundation Models): entender a descrição da turma em
texto livre, ler a nota fiscal a partir de uma foto e interpretar o relato
pós-evento.

IMPORTANTE PARA A REVISÃO: em aparelhos sem Apple Intelligence, esses
pontos de entrada são OCULTADOS de propósito, e o caminho manual
equivalente assume — o app permanece 100% funcional. Se o aparelho de teste
não tiver Apple Intelligence, o campo de texto livre e o botão de foto da
nota não vão aparecer, e no lugar deles estarão os controles numéricos e o
botão "Lançar itens à mão". Isso é o comportamento pretendido, não um
recurso quebrado.

PERMISSÕES

O app pede Câmera e Galeria de Fotos, ambas apenas para o recurso de ler a
nota fiscal do mercado. As duas mensagens de permissão explicam o uso e
avisam que a imagem é processada no aparelho e descartada. A foto da nota
nunca é gravada em disco, em cache ou no álbum do usuário.

PRIVACIDADE

O app não possui servidor, não possui código de rede próprio, não usa
nenhum SDK de terceiros, não faz analytics e não rastreia nada. O único
tráfego é o do StoreKit com a App Store, feito pelo sistema. A resposta do
questionário de App Privacy é "Data Not Collected".

O app funciona por completo em modo avião.

CONTEÚDO

O app menciona bebida alcoólica apenas como categoria de item de compra
(por exemplo, "cerveja" na lista do mercado) e como regra de divisão de
conta — quem não bebe não paga pela bebida alcoólica. Não há incentivo ao
consumo, imagens de consumo, nem qualquer conteúdo dirigido a menores sobre
o assunto.

Support website: https://suportedablab.carrd.co/
Contato: alexandre@dablab.com.br
```

---

## 7. App Encryption Documentation

**Resposta: `None of the algorithms mentioned above`.**

O app não implementa criptografia própria. Não há sequer código de rede: o único tráfego é o do StoreKit, feito pelo sistema operacional. A chave `ITSAppUsesNonExemptEncryption = false` já está no `Info.plist`, então o App Store Connect não deve nem exibir o prompt de "Missing Compliance" a cada build.

---

## 8. Content Rights

**Resposta: `No, it does not contain, show, or access third-party content`.**

Todo o conteúdo é próprio: ilustrações e ícone criados para o produto, tabelas de consumo definidas pelo produto, tipografia do sistema (SF Pro). Zero dependências externas no projeto — não há sequer `Package.resolved`. Nenhuma base de dados ou biblioteca de terceiros é redistribuída.

---

## 9. Classificação etária (expectativa)

**Não é 4+ automático — há uma decisão a tomar.** Ver a nota de atenção no fim.

| Pergunta do questionário | Resposta esperada |
|---|---|
| Violência (cartunizada, realista) | Nenhuma |
| Conteúdo sexual ou nudez | Nenhum |
| Linguagem imprópria | Nenhuma |
| Terror / medo | Nenhum |
| Apostas / jogos de azar | Nenhum |
| Temas maduros/sugestivos | Nenhum |
| Conteúdo gerado por usuário visível a terceiros | Não — nada sai do aparelho |
| Recursos de rede social / chat | Não |
| Chatbot ou IA generativa livre | Não — a IA só preenche campos estruturados, e nunca escreve texto livre para o usuário |
| Compras dentro do app | **Sim** — uma compra única |
| **Álcool, tabaco ou drogas: referências** | **Sim, "Infrequente/Leve"** — ver abaixo |

**A pergunta do álcool.** O app cita bebida alcoólica como categoria de compra ("cerveja" na lista) e como regra do rateio ("quem não bebe não paga a cerveja"). Não há consumo retratado nem incentivo. Duas leituras defensáveis:

- **"Nenhuma"** → resultado 4+. Argumento: é item de supermercado numa lista de compras, do mesmo jeito que num app de receitas ou de mercado, e a Apple aceita 4+ para esses.
- **"Infrequente/Leve"** → resultado provável **12+** (13+ na escala nova).

**Recomendação:** responder **"Infrequente/Leve"**. A diferença prática de 4+ para 12+ é pequena para o público-alvo — quem organiza churrasco e faz vaquinha é adulto — e responder por baixo numa pergunta sobre álcool é o tipo de coisa que gera pedido de reclassificação depois da publicação, com o app já no ar. É o risco assimétrico: pouco a ganhar em 4+, chateação real se a Apple discordar.

---

## Verificação de limites

Saída real do `scripts/check_limits.py`:

```
Nome: 12/30 caracteres [OK]
Subtítulo: 27/30 caracteres [OK]
Texto promocional: 123/170 caracteres [OK]
Descrição: 3051/4000 caracteres [OK]
Keywords: 98/100 bytes [OK]
Notas da versão (What's New): 276/4000 caracteres [OK]
Notas de revisão (App Review): 2768/4000 caracteres [OK]
```

Medido, não estimado.

---

## Pendências antes de submeter

| # | Item | Quem resolve |
|---|---|---|
| 1 | Telefone de contato nas App Review Information | Alexandre |
| 2 | Criar o IAP `carne_assada_pro` e levá-lo a **"Pronto para Enviar"** (nome, descrição e captura de revisão) | Alexandre |
| 3 | Colar a seção nova no documento de Política de Privacidade do Notion, **antes** de submeter | Alexandre |
| 4 | Decidir a resposta do álcool no questionário de idade (recomendação: "Infrequente/Leve") | Alexandre |
| 5 | Screenshots 6.5" — já existem em `prints para a appstore/6.5/`, conferir se cobrem as telas que a ficha promete | Alexandre |

**Não se aplica a este app** (do checklist de rejeições anteriores): Termos de Uso próprio, excluir conta, trocar senha, logout, modo convidado — nenhum se aplica porque o app não tem conta. O "Apple's Standard License Agreement" padrão basta.
