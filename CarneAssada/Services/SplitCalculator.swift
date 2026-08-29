import Foundation

// MARK: - Entradas puras

/// Um participante, reduzido ao que o rateio precisa saber.
///
/// O serviço não recebe o `@Model` de propósito: assim ele é puro, `Sendable` e testável
/// sem container SwiftData (exigência da seção 13).
struct ParticipanteParaRateio: Equatable, Sendable, Identifiable {
    let id: UUID
    let nome: String
    let e_crianca: Bool
    let come_carne: Bool
    let bebe_alcool: Bool
    let ordem: Int
}

/// Um item de compra confirmado e com valor, pronto para entrar no rateio.
struct ItemParaRateio: Equatable, Sendable, Identifiable {
    let id: UUID
    let descricao: String
    let valor: Decimal
    let categoria: categoria_rateio
    /// IDs dos participantes com atribuição explícita.
    /// **Vazio significa "divide conforme a categoria"** (regra 11.5) — não "ninguém consumiu".
    let atribuidosA: [UUID]
}

// MARK: - Saídas

/// Uma linha da composição do valor de um participante (tela 10.13).
struct LinhaDaComposicao: Equatable, Sendable, Identifiable {
    let id = UUID()
    /// O que agrupou estes itens ("Todo mundo", "Quem bebe", "Marcado pra você").
    let titulo: String
    let valor: Decimal
    /// Por que ele entrou ou ficou de fora. Copies 15.21 a 15.23.
    let explicacao: String?

    static func == (a: LinhaDaComposicao, b: LinhaDaComposicao) -> Bool {
        a.titulo == b.titulo && a.valor == b.valor && a.explicacao == b.explicacao
    }
}

/// Quanto um participante deve, e por quê.
struct ResultadoParticipante: Equatable, Sendable, Identifiable {
    let id: UUID
    let nome: String
    let valor: Decimal
    let composicao: [LinhaDaComposicao]
    /// `true` quando este foi o participante que absorveu a sobra de centavos (regra 11.8).
    let absorveuArredondamento: Bool
}

/// O rateio inteiro, pronto para a tela 10.12 e para o texto da 14.1.
struct ResultadoDoRateio: Equatable, Sendable {
    /// Ordenado por valor decrescente; empate resolvido pela `ordem` do participante (14.1).
    let porParticipante: [ResultadoParticipante]
    /// Soma dos itens confirmados **com valor**. É sempre exatamente igual à soma
    /// dos valores individuais (regra 11.8).
    let total: Decimal
    /// Itens confirmados que ficaram de fora por não terem valor legível (regra 11.10.2).
    let itensPendentes: Int
}

// MARK: - Serviço

/// Divide a conta entre os participantes.
///
/// Implementa as regras **11.5** (rateio por categoria), **11.7** (peso da criança),
/// **11.8** (arredondamento e sobra de centavos), **11.10.1** (usa a soma dos itens,
/// nunca o total lido da nota) e **11.11** (item não confirmado fica fora de tudo).
///
/// Princípio 0.2: aritmética é do código. Nenhuma chamada ao modelo de linguagem aqui.
enum SplitCalculator {

    /// Peso de um participante em uma categoria de rateio — regras 11.5 e 11.7.
    ///
    /// Criança conta **0,5** em `geral` e `apenas_carne`, **1** em `bebida_nao_alcoolica`
    /// e **0** em `bebida_alcoolica`.
    static func peso(de p: ParticipanteParaRateio, em categoria: categoria_rateio) -> Decimal {
        switch categoria {
        case .geral:
            return p.e_crianca ? 0.5 : 1
        case .bebida_alcoolica:
            // Criança nasce com `bebe_alcool = false`, então já cai fora por aqui.
            return p.bebe_alcool ? 1 : 0
        case .bebida_nao_alcoolica:
            // Criança paga inteiro: refrigerante é justamente o que ela mais consome.
            return 1
        case .apenas_carne:
            guard p.come_carne else { return 0 }
            return p.e_crianca ? 0.5 : 1
        }
    }

    /// Calcula quanto cada participante deve.
    /// - Parameters:
    ///   - itens: **apenas** itens confirmados e com valor. Filtrar antes é responsabilidade
    ///     de quem chama; ver `entra_no_rateio` em `item_compra` (regras 11.11 e 11.10.2).
    ///   - participantes: pelo menos um, senão não há rateio possível (exceção 9.2.2).
    ///   - pendentes: quantos itens confirmados ficaram sem valor, só para a UI avisar.
    static func calcular(itens: [ItemParaRateio],
                         participantes: [ParticipanteParaRateio],
                         pendentes: Int = 0) -> ResultadoDoRateio {
        guard !participantes.isEmpty else {
            return ResultadoDoRateio(porParticipante: [], total: 0, itensPendentes: pendentes)
        }

        let total = itens.reduce(Decimal(0)) { $0 + $1.valor }

        // Acumuladores em precisão cheia: só se arredonda no fim (regra 11.8).
        var bruto: [UUID: Decimal] = [:]
        var porGrupo: [UUID: [String: Decimal]] = [:]
        // Quais categorias apareceram e de quais o participante ficou de fora — vira explicação.
        var categoriasVistas: Set<categoria_rateio> = []
        var teveAtribuicaoExplicita: Set<UUID> = []

        for item in itens {
            let explicitos = participantes.filter { item.atribuidosA.contains($0.id) }

            if !explicitos.isEmpty {
                // Atribuição explícita **sobrepõe a categoria** e divide igualmente
                // apenas entre os atribuídos (épico 8.6).
                let quota = item.valor / Decimal(explicitos.count)
                for p in explicitos {
                    bruto[p.id, default: 0] += quota
                    porGrupo[p.id, default: [:]]["Marcado pra você", default: 0] += quota
                    teveAtribuicaoExplicita.insert(p.id)
                }
                continue
            }

            // Sem atribuição: divide conforme a categoria (regra 11.5).
            categoriasVistas.insert(item.categoria)
            let pesos = participantes.map { (p: $0, peso: peso(de: $0, em: item.categoria)) }
            let somaDosPesos = pesos.reduce(Decimal(0)) { $0 + $1.peso }

            // Nenhum elegível (ex.: cerveja num churrasco onde ninguém bebe): o dinheiro
            // não pode sumir, senão a soma dos individuais deixa de bater com o total.
            // Cai para o rateio geral, que é o comportamento menos surpreendente.
            let (pesosFinais, somaFinal, rotulo): ([(p: ParticipanteParaRateio, peso: Decimal)], Decimal, String) =
                somaDosPesos > 0
                ? (pesos, somaDosPesos, item.categoria.rotulo)
                : (participantes.map { ($0, peso(de: $0, em: .geral)) },
                   participantes.reduce(Decimal(0)) { $0 + peso(de: $1, em: .geral) },
                   categoria_rateio.geral.rotulo)

            guard somaFinal > 0 else { continue }

            for (p, w) in pesosFinais where w > 0 {
                let quota = item.valor * w / somaFinal
                bruto[p.id, default: 0] += quota
                porGrupo[p.id, default: [:]][rotulo, default: 0] += quota
            }
        }

        // Arredonda a 2 casas com `.bankers` (regra 11.8).
        var arredondado: [UUID: Decimal] = bruto.mapValues { duasCasas($0) }
        for p in participantes where arredondado[p.id] == nil { arredondado[p.id] = 0 }

        // Regra 11.8: a sobra de centavos vai **integralmente** para o participante de maior
        // valor; empate resolvido pela `ordem`. É o que garante que a soma dos individuais
        // seja sempre exatamente igual ao total — invariante testada na seção 22.1.
        let somaArredondada = arredondado.values.reduce(Decimal(0), +)
        let sobra = duasCasas(total - somaArredondada)
        var absorveu: UUID?
        if sobra != 0 {
            let alvo = participantes
                .sorted { a, b in
                    let va = arredondado[a.id] ?? 0, vb = arredondado[b.id] ?? 0
                    return va == vb ? a.ordem < b.ordem : va > vb
                }
                .first
            if let alvo {
                arredondado[alvo.id, default: 0] += sobra
                absorveu = alvo.id
            }
        }

        let resultados = participantes.map { p -> ResultadoParticipante in
            ResultadoParticipante(
                id: p.id,
                nome: p.nome,
                valor: arredondado[p.id] ?? 0,
                composicao: composicao(de: p,
                                       grupos: porGrupo[p.id] ?? [:],
                                       categorias: categoriasVistas,
                                       temExplicita: teveAtribuicaoExplicita.contains(p.id)),
                absorveuArredondamento: p.id == absorveu
            )
        }

        return ResultadoDoRateio(
            // 14.1: valor decrescente; empate pela ordem de cadastro.
            porParticipante: resultados.sorted { a, b in
                if a.valor != b.valor { return a.valor > b.valor }
                let oa = participantes.first { $0.id == a.id }?.ordem ?? 0
                let ob = participantes.first { $0.id == b.id }?.ordem ?? 0
                return oa < ob
            },
            total: total,
            itensPendentes: pendentes
        )
    }

    // MARK: - Composição explicada (tela 10.13)

    /// Monta as linhas que explicam o valor de um participante, incluindo **as exclusões**.
    ///
    /// Dizer "você não entra na cerveja porque não bebe" é o que faz o número parecer justo
    /// (momento 3 da seção 2). Sem isso o organizador não manda o resultado pro grupo.
    private static func composicao(de p: ParticipanteParaRateio,
                                   grupos: [String: Decimal],
                                   categorias: Set<categoria_rateio>,
                                   temExplicita: Bool) -> [LinhaDaComposicao] {
        var linhas: [LinhaDaComposicao] = []

        if temExplicita, let v = grupos["Marcado pra você"] {
            linhas.append(.init(titulo: "Marcado pra você", valor: duasCasas(v),
                                explicacao: "Itens que você marcou como seus"))
        }

        for categoria in [categoria_rateio.geral, .apenas_carne, .bebida_alcoolica, .bebida_nao_alcoolica] {
            guard categorias.contains(categoria) else { continue }

            if let v = grupos[categoria.rotulo], v > 0 {
                linhas.append(.init(titulo: categoria.rotulo, valor: duasCasas(v),
                                    explicacao: explicacaoDeInclusao(p, categoria)))
            } else if peso(de: p, em: categoria) == 0 {
                // Exclusão explicada: valor zero com o motivo (copies 15.21 e 15.23).
                linhas.append(.init(titulo: categoria.rotulo, valor: 0,
                                    explicacao: explicacaoDeExclusao(p, categoria)))
            }
        }

        return linhas
    }

    /// Copy 15.22: por que a criança paga menos nesta categoria.
    private static func explicacaoDeInclusao(_ p: ParticipanteParaRateio,
                                             _ categoria: categoria_rateio) -> String? {
        guard p.e_crianca else { return nil }
        switch categoria {
        case .geral, .apenas_carne:
            return "Criança: paga meia na carne e nos acompanhamentos"
        case .bebida_nao_alcoolica:
            return "Criança: paga inteiro na bebida sem álcool"
        case .bebida_alcoolica:
            return nil
        }
    }

    /// Copies 15.21 e 15.23: por que ele ficou de fora desta categoria.
    private static func explicacaoDeExclusao(_ p: ParticipanteParaRateio,
                                             _ categoria: categoria_rateio) -> String? {
        switch categoria {
        case .bebida_alcoolica:
            return p.e_crianca
                ? "Criança: fora do rateio das bebidas alcoólicas"
                : "Não bebe: fora do rateio das bebidas alcoólicas"
        case .apenas_carne:
            return "Não come carne: fora do rateio da carne"
        default:
            return nil
        }
    }

    /// Arredondamento a 2 casas com `.bankers` — regra 11.8.
    /// `.bankers` (metade para o par) evita o viés sistemático para cima que o
    /// arredondamento comum introduziria ao longo de dezenas de itens.
    static func duasCasas(_ valor: Decimal) -> Decimal {
        var entrada = valor
        var saida = Decimal()
        NSDecimalRound(&saida, &entrada, 2, .bankers)
        return saida
    }
}
