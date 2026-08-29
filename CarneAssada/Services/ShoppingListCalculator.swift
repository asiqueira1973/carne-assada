import Foundation

/// Parâmetros da turma que alimentam o cálculo da lista (seções 7.2 e 13.1).
struct ParametrosTurma: Equatable, Sendable {
    var adultos: Int
    var criancas: Int
    var vegetarianos: Int
    var naoBebemAlcool: Int
    var duracaoHoras: Int
    /// Decisão 25.3: carne suína entra na tabela 11.1 mas é **opcional**, desligada por padrão.
    var incluiCarneSuina: Bool

    init(adultos: Int = 0, criancas: Int = 0, vegetarianos: Int = 0,
         naoBebemAlcool: Int = 0, duracaoHoras: Int = 5, incluiCarneSuina: Bool = false) {
        self.adultos = adultos
        self.criancas = criancas
        self.vegetarianos = vegetarianos
        self.naoBebemAlcool = naoBebemAlcool
        self.duracaoHoras = duracaoHoras
        self.incluiCarneSuina = incluiCarneSuina
    }

    /// Aplica os clamps da seção 13.2 — em **código**, nunca confiando no prompt.
    /// - 13.2.2: adultos 0–200, crianças 0–100, duração 1–24.
    /// - 13.2.4 / 7.10.2: vegetarianos e abstêmios são subconjuntos de adultos.
    /// - Returns: os parâmetros corrigidos e `true` se algo foi corrigido (a UI sinaliza).
    func comClamp() -> (valor: ParametrosTurma, corrigiu: Bool) {
        var p = self
        p.adultos = min(max(p.adultos, 0), 200)
        p.criancas = min(max(p.criancas, 0), 100)
        p.duracaoHoras = min(max(p.duracaoHoras, 1), 24)
        p.vegetarianos = min(max(p.vegetarianos, 0), p.adultos)
        p.naoBebemAlcool = min(max(p.naoBebemAlcool, 0), p.adultos)
        return (p, p != self)
    }

    /// Adultos que comem carne = adultos − vegetarianos (regra 11.3: vegetariano é
    /// subconjunto de adulto, não soma a ele).
    var adultosQueComemCarne: Int { max(0, adultos - vegetarianos) }

    /// Adultos que bebem álcool = adultos − abstêmios.
    var adultosQueBebem: Int { max(0, adultos - naoBebemAlcool) }

    var totalDePessoas: Int { adultos + criancas }
}

/// Ajuste histórico extraído do registro pós-evento (seções 8.9 e 13.1).
struct AjusteConsumo: Equatable, Sendable, Codable {
    /// Percentual por categoria, já limitado a −40…+40 (regra 11.14).
    var percentuais: [String: Int]

    init(percentuais: [String: Int] = [:]) {
        // 13.2.3: o clamp é feito em código, não confiando no modelo.
        self.percentuais = percentuais.mapValues { min(max($0, -40), 40) }
    }

    subscript(_ categoria: categoria_lista) -> Int {
        percentuais[categoria.rawValue] ?? 0
    }

    var vazio: Bool { percentuais.values.allSatisfy { $0 == 0 } }
}

/// Um item calculado pela regra 11.1, antes de virar `item_lista` no store.
struct ItemListaCalculado: Equatable, Sendable {
    var categoria: categoria_lista
    var nome: String
    var quantidade: Decimal
    var unidade: unidade_medida
}

/// Gera a lista de compras a partir dos parâmetros da turma.
///
/// Implementa as regras **11.1** (tabelas de consumo, itens fixos, multiplicador de duração
/// e arredondamento), **11.3** (vegetariano), **11.4** (duração) e **11.14** (ajuste histórico).
///
/// Princípio 0.2: nenhuma chamada ao modelo de linguagem acontece aqui. É Swift puro,
/// determinístico e testável — modelo de linguagem não soma nada neste app.
enum ShoppingListCalculator {

    // MARK: - Tabela 11.1.1 — consumo por pessoa (base, churrasco de até 5 horas)

    /// Uma linha da tabela 11.1.1.
    private struct LinhaDeConsumo {
        let categoria: categoria_lista
        let nome: String
        /// Unidade em que o consumo é somado (pode não ser a unidade de compra).
        let unidadeBase: unidade_medida
        let adultoQueComeCarne: Decimal
        let adultoVegetariano: Decimal
        let crianca: Decimal
        /// Só entra na lista se o usuário ligou (hoje: carne suína, decisão 25.3).
        let opcional: Bool

        init(_ categoria: categoria_lista, _ nome: String, _ unidadeBase: unidade_medida,
             adulto: Decimal, vegetariano: Decimal, crianca: Decimal, opcional: Bool = false) {
            self.categoria = categoria
            self.nome = nome
            self.unidadeBase = unidadeBase
            self.adultoQueComeCarne = adulto
            self.adultoVegetariano = vegetariano
            self.crianca = crianca
            self.opcional = opcional
        }
    }

    private static let tabelaDeConsumo: [LinhaDeConsumo] = [
        .init(.carne, "Carne bovina", .kg, adulto: 0.400, vegetariano: 0, crianca: 0.200),
        .init(.carne, "Linguiça", .kg, adulto: 0.150, vegetariano: 0, crianca: 0.075),
        .init(.carne, "Frango", .kg, adulto: 0.150, vegetariano: 0, crianca: 0.100),
        // Decisão 25.3: suíno cobre o churrasco com costelinha/pernil, mas só quando ligado.
        .init(.carne, "Carne suína", .kg, adulto: 0.150, vegetariano: 0, crianca: 0.075, opcional: true),
        .init(.carne, "Espeto vegetariano / legumes", .kg, adulto: 0, vegetariano: 0.350, crianca: 0),
        .init(.acompanhamento, "Pão de alho", .unidade, adulto: 1.5, vegetariano: 1.5, crianca: 1),
        .init(.acompanhamento, "Farofa", .g, adulto: 80, vegetariano: 80, crianca: 40),
        .init(.acompanhamento, "Vinagrete", .g, adulto: 100, vegetariano: 100, crianca: 50),
        .init(.acompanhamento, "Arroz", .g, adulto: 80, vegetariano: 80, crianca: 40),
        .init(.acompanhamento, "Queijo coalho", .unidade, adulto: 1, vegetariano: 1, crianca: 0.5),
        .init(.bebida_alcoolica, "Cerveja", .ml, adulto: 1200, vegetariano: 1200, crianca: 0),
        .init(.bebida_nao_alcoolica, "Refrigerante / suco", .ml, adulto: 500, vegetariano: 500, crianca: 600),
        .init(.bebida_nao_alcoolica, "Água", .ml, adulto: 500, vegetariano: 500, crianca: 500),
        .init(.carvao_e_utensilios, "Carvão", .kg, adulto: 0.150, vegetariano: 0.150, crianca: 0.050),
        .init(.carvao_e_utensilios, "Gelo", .kg, adulto: 0.300, vegetariano: 0.300, crianca: 0.150),
    ]

    // MARK: - Tabela 11.1.2 — itens de quantidade fixa

    private struct ItemFixo {
        let nome: String
        let quantidade: Decimal
        let unidade: unidade_medida
        /// `nil` = sempre entra. Caso contrário, entra só se o total de pessoas passar do limite.
        let minimoDePessoas: Int?
    }

    private static let itensFixos: [ItemFixo] = [
        .init(nome: "Acendedor", quantidade: 1, unidade: .pacote, minimoDePessoas: nil),
        .init(nome: "Papel toalha", quantidade: 2, unidade: .unidade, minimoDePessoas: nil),
        .init(nome: "Guardanapo", quantidade: 1, unidade: .pacote, minimoDePessoas: nil),
        .init(nome: "Sal grosso", quantidade: 1, unidade: .pacote, minimoDePessoas: nil),
        .init(nome: "Copo descartável (50)", quantidade: 1, unidade: .pacote, minimoDePessoas: 10),
        .init(nome: "Prato descartável (20)", quantidade: 1, unidade: .pacote, minimoDePessoas: 10),
    ]

    // MARK: - Regra 11.1.3 — multiplicador por duração

    /// Multiplicadores por faixa de duração. Bebida e carvão sobem mais rápido que comida:
    /// churrasco longo não faz ninguém comer o dobro, mas faz beber muito mais.
    static func multiplicadores(paraDuracao horas: Int) -> (bebidaECarvao: Decimal, comida: Decimal) {
        switch horas {
        case ..<5: (0.85, 0.90)
        case 5...6: (1.00, 1.00)
        case 7...9: (1.25, 1.10)
        default: (1.50, 1.20)
        }
    }

    // MARK: - Entrada pública

    /// Calcula a lista de compras completa.
    /// - Parameters:
    ///   - parametros: adultos, crianças, vegetarianos, abstêmios, duração e a opção de suíno.
    ///   - ajuste: ajuste histórico do churrasco anterior (regra 11.14). `nil` = sem ajuste.
    /// - Returns: os itens já arredondados na unidade de compra, na ordem de exibição.
    ///            Item que dá zero é **omitido** (regra 11.1.4).
    static func calcular(_ parametros: ParametrosTurma,
                         ajuste: AjusteConsumo? = nil) -> [ItemListaCalculado] {
        let p = parametros.comClamp().valor
        let mult = multiplicadores(paraDuracao: p.duracaoHoras)
        var resultado: [ItemListaCalculado] = []

        for linha in tabelaDeConsumo {
            if linha.opcional && !p.incluiCarneSuina { continue }

            let bruto = consumoBruto(linha, p)
            guard bruto > 0 else { continue }

            // O multiplicador de duração é de categoria, não de item (regra 11.1.3).
            let ehBebidaOuCarvao = linha.categoria == .bebida_alcoolica
                || linha.categoria == .bebida_nao_alcoolica
                || linha.categoria == .carvao_e_utensilios
            var comDuracao = bruto * (ehBebidaOuCarvao ? mult.bebidaECarvao : mult.comida)

            // Regra 11.14: o ajuste histórico entra **depois** do cálculo base e do
            // multiplicador de duração — nunca dentro deles.
            if let ajuste {
                let percentual = Decimal(ajuste[linha.categoria])
                if percentual != 0 { comDuracao *= (1 + percentual / 100) }
            }

            let (quantidade, unidade) = arredondar(comDuracao, de: linha.unidadeBase, item: linha.nome)
            // "Nenhum item calculado entra na lista com quantidade zero — é omitido" (11.1.4).
            guard quantidade > 0 else { continue }

            resultado.append(ItemListaCalculado(categoria: linha.categoria, nome: linha.nome,
                                                quantidade: quantidade, unidade: unidade))
        }

        // Itens fixos não escalam com pessoas nem com duração, e por isso também não
        // recebem ajuste histórico: "sobrou guardanapo" não é sinal de consumo.
        for fixo in itensFixos {
            if let minimo = fixo.minimoDePessoas, p.totalDePessoas <= minimo { continue }
            resultado.append(ItemListaCalculado(categoria: .carvao_e_utensilios, nome: fixo.nome,
                                                quantidade: fixo.quantidade, unidade: fixo.unidade))
        }

        return resultado.sorted { $0.categoria.ordem < $1.categoria.ordem }
    }

    // MARK: - Passos internos

    /// Soma o consumo de uma linha da tabela sobre toda a turma, antes de duração e ajuste.
    ///
    /// O tratamento do abstêmio é a exceção da 11.1.1: ele usa a coluna do adulto, mas com
    /// **cerveja = 0** e **refrigerante ×1,5** — quem não bebe álcool bebe mais refrigerante.
    private static func consumoBruto(_ linha: LinhaDeConsumo, _ p: ParametrosTurma) -> Decimal {
        let vegetarianos = Decimal(p.vegetarianos)
        let criancas = Decimal(p.criancas)

        switch linha.categoria {
        case .bebida_alcoolica:
            // Só quem bebe entra na conta da cerveja.
            return Decimal(p.adultosQueBebem) * linha.adultoQueComeCarne

        case .bebida_nao_alcoolica where linha.nome == "Refrigerante / suco":
            let bebem = Decimal(p.adultosQueBebem) * linha.adultoQueComeCarne
            let abstemios = Decimal(p.naoBebemAlcool) * linha.adultoQueComeCarne * 1.5
            return bebem + abstemios + criancas * linha.crianca

        default:
            // Nas demais linhas, vegetariano e onívoro só diferem pelas colunas da tabela.
            let onivoros = Decimal(p.adultosQueComemCarne) * linha.adultoQueComeCarne
            return onivoros + vegetarianos * linha.adultoVegetariano + criancas * linha.crianca
        }
    }

    /// Aplica a regra 11.1.4 — arredondamento **sempre para cima**, na unidade de compra real.
    /// Ninguém compra 3,847 kg de picanha: o app fala na unidade da prateleira.
    private static func arredondar(_ valor: Decimal, de unidade: unidade_medida,
                                   item: String) -> (Decimal, unidade_medida) {
        switch unidade {
        case .kg:
            // Carvão e gelo se compram em saco de 1 kg; carne, em múltiplos de meio quilo.
            let passo: Decimal = (item == "Carvão" || item == "Gelo") ? 1 : 0.5
            return (tetoMultiplo(valor, de: passo), .kg)

        case .g:
            return (tetoMultiplo(valor, de: 100), .g)

        case .unidade, .pacote:
            return (tetoMultiplo(valor, de: 1), unidade)

        case .ml:
            if item == "Cerveja" {
                // Cerveja se compra em fardo: latas de 350 ml, em múltiplos de 6.
                let latas = tetoMultiplo(valor / 350, de: 6)
                return (latas, .unidade)
            }
            // O resto vira litro, em múltiplos de meio litro.
            return (tetoMultiplo(valor / 1000, de: 0.5), .litro)

        case .litro:
            return (tetoMultiplo(valor, de: 0.5), .litro)
        }
    }

    /// Menor múltiplo de `passo` que é ≥ `valor`. Base do "sempre para cima" da regra 11.1.4.
    private static func tetoMultiplo(_ valor: Decimal, de passo: Decimal) -> Decimal {
        guard passo > 0, valor > 0 else { return 0 }
        var divisao = valor / passo
        var teto = Decimal()
        // `.up` em Decimal é teto exato, sem o erro de ponto flutuante que faria
        // 3,0 kg virar 3,5 kg por causa de um 3,0000000001.
        NSDecimalRound(&teto, &divisao, 0, .up)
        return teto * passo
    }
}
