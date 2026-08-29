import Testing
import Foundation
@testable import CarneAssada

/// Testes da regra 11.1 — tabelas de consumo, itens fixos, multiplicador e arredondamento.
/// Exigência 22.1: **toda** a seção 11 coberta.
struct ShoppingListCalculatorTests {

    // MARK: - Exemplo trabalhado (regra 11.13)

    /// Teste de regressão nomeado, exigido pelo critério 8.3 e pela seção 22.1.
    /// Entrada: 15 adultos, 4 crianças, 3 vegetarianos, 0 abstêmios, 10 horas.
    @Test("Regra 11.13 — exemplo trabalhado bate item a item")
    func exemploTrabalhado1113() {
        let itens = ShoppingListCalculator.calcular(
            ParametrosTurma(adultos: 15, criancas: 4, vegetarianos: 3,
                            naoBebemAlcool: 0, duracaoHoras: 10)
        )

        func quantidade(_ nome: String) -> Decimal? {
            itens.first { $0.nome == nome }?.quantidade
        }
        func unidade(_ nome: String) -> unidade_medida? {
            itens.first { $0.nome == nome }?.unidade
        }

        // (12 × 0,400 + 4 × 0,200) × 1,20 = 6,72 → múltiplo de 0,5 kg
        #expect(quantidade("Carne bovina") == 7.0)
        // (12 × 0,150 + 4 × 0,075) × 1,20 = 2,52 → 3,0 kg
        #expect(quantidade("Linguiça") == 3.0)
        // (12 × 0,150 + 4 × 0,100) × 1,20 = 2,64 → 3,0 kg
        #expect(quantidade("Frango") == 3.0)
        // (3 × 0,350) × 1,20 = 1,26 → 1,5 kg
        #expect(quantidade("Espeto vegetariano / legumes") == 1.5)
        // (15 × 1.200) × 1,50 = 27.000 ml ÷ 350 = 77,14 → múltiplo de 6 → 78 latas
        #expect(quantidade("Cerveja") == 78)
        #expect(unidade("Cerveja") == .unidade)
        // (15 × 0,150 + 4 × 0,050) × 1,50 = 3,675 → múltiplo de 1 kg
        #expect(quantidade("Carvão") == 4)
    }

    // MARK: - 11.1.3 multiplicador por duração

    @Test("Regra 11.1.3 — faixas de duração",
          arguments: [(3, Decimal(0.85), Decimal(0.90)),
                      (5, Decimal(1.00), Decimal(1.00)),
                      (6, Decimal(1.00), Decimal(1.00)),
                      (8, Decimal(1.25), Decimal(1.10)),
                      (12, Decimal(1.50), Decimal(1.20))])
    func multiplicadorPorDuracao(caso: (Int, Decimal, Decimal)) {
        let m = ShoppingListCalculator.multiplicadores(paraDuracao: caso.0)
        #expect(m.bebidaECarvao == caso.1)
        #expect(m.comida == caso.2)
    }

    // MARK: - 11.1.4 arredondamento

    @Test("Regra 11.1.4 — carne arredonda para múltiplo de 0,5 kg, sempre para cima")
    func arredondamentoDeCarne() {
        // 10 adultos onívoros × 0,400 = 4,0 kg exatos, duração neutra: não sobe para 4,5.
        let exato = ShoppingListCalculator.calcular(
            ParametrosTurma(adultos: 10, duracaoHoras: 5)
        ).first { $0.nome == "Carne bovina" }
        #expect(exato?.quantidade == 4.0)

        // 11 adultos × 0,400 = 4,4 kg → sobe para 4,5.
        let comSobra = ShoppingListCalculator.calcular(
            ParametrosTurma(adultos: 11, duracaoHoras: 5)
        ).first { $0.nome == "Carne bovina" }
        #expect(comSobra?.quantidade == 4.5)
    }

    @Test("Regra 11.1.4 — gramas arredondam para múltiplo de 100 g")
    func arredondamentoEmGramas() {
        // 10 adultos × 80 g = 800 g exatos.
        let farofa = ShoppingListCalculator.calcular(
            ParametrosTurma(adultos: 10, duracaoHoras: 5)
        ).first { $0.nome == "Farofa" }
        #expect(farofa?.quantidade == 800)
        #expect(farofa?.unidade == .g)
    }

    @Test("Regra 11.1.4 — nenhum item calculado entra com quantidade zero")
    func itemZeroEOmitido() {
        // Turma só de crianças: cerveja dá 0 e não pode aparecer na lista.
        let itens = ShoppingListCalculator.calcular(
            ParametrosTurma(adultos: 0, criancas: 5, duracaoHoras: 5)
        )
        #expect(!itens.contains { $0.nome == "Cerveja" })
        #expect(itens.allSatisfy { $0.quantidade > 0 })
    }

    // MARK: - 11.1.1 exceções da tabela

    @Test("Regra 11.1.1 — abstêmio não gera cerveja e bebe 1,5× de refrigerante")
    func abstemioNaoGeraCerveja() {
        let todosAbstemios = ShoppingListCalculator.calcular(
            ParametrosTurma(adultos: 10, naoBebemAlcool: 10, duracaoHoras: 5)
        )
        #expect(!todosAbstemios.contains { $0.nome == "Cerveja" })

        // 10 abstêmios × 500 × 1,5 = 7.500 ml = 7,5 L
        let refri = todosAbstemios.first { $0.nome == "Refrigerante / suco" }
        #expect(refri?.quantidade == 7.5)
        #expect(refri?.unidade == .litro)
    }

    @Test("Regra 11.3 — vegetariano é subconjunto de adulto, não soma")
    func vegetarianoESubconjunto() {
        let p = ParametrosTurma(adultos: 15, vegetarianos: 3)
        #expect(p.adultosQueComemCarne == 12)
        #expect(p.totalDePessoas == 15)

        // Todos vegetarianos: nenhuma carne bovina na lista, mas espeto sim.
        let itens = ShoppingListCalculator.calcular(
            ParametrosTurma(adultos: 8, vegetarianos: 8, duracaoHoras: 5)
        )
        #expect(!itens.contains { $0.nome == "Carne bovina" })
        #expect(itens.contains { $0.nome == "Espeto vegetariano / legumes" })
    }

    // MARK: - 11.1.2 itens fixos

    @Test("Regra 11.1.2 — descartáveis só entram acima de 10 pessoas")
    func descartaveisAcimaDeDezPessoas() {
        let pequeno = ShoppingListCalculator.calcular(
            ParametrosTurma(adultos: 10, duracaoHoras: 5)
        )
        #expect(!pequeno.contains { $0.nome.hasPrefix("Copo descartável") })

        let grande = ShoppingListCalculator.calcular(
            ParametrosTurma(adultos: 10, criancas: 1, duracaoHoras: 5)
        )
        #expect(grande.contains { $0.nome.hasPrefix("Copo descartável") })
        #expect(grande.contains { $0.nome.hasPrefix("Prato descartável") })
    }

    @Test("Regra 11.1.2 — itens sempre presentes independem do tamanho da turma")
    func itensFixosSempre() {
        let itens = ShoppingListCalculator.calcular(ParametrosTurma(adultos: 1))
        for nome in ["Acendedor", "Papel toalha", "Guardanapo", "Sal grosso"] {
            #expect(itens.contains { $0.nome == nome }, "faltou \(nome)")
        }
    }

    // MARK: - Decisão 25.3 — carne suína opcional

    @Test("Decisão 25.3 — carne suína só entra quando ligada")
    func carneSuinaEOpcional() {
        let sem = ShoppingListCalculator.calcular(ParametrosTurma(adultos: 10))
        #expect(!sem.contains { $0.nome == "Carne suína" })

        let com = ShoppingListCalculator.calcular(
            ParametrosTurma(adultos: 10, duracaoHoras: 5, incluiCarneSuina: true)
        )
        // 10 × 0,150 = 1,5 kg
        #expect(com.first { $0.nome == "Carne suína" }?.quantidade == 1.5)
    }

    // MARK: - 11.14 ajuste histórico

    @Test("Regra 11.14 — ajuste entra depois do cálculo base e do multiplicador")
    func ajusteHistoricoEAplicadoPorUltimo() {
        let base = ShoppingListCalculator.calcular(
            ParametrosTurma(adultos: 10, duracaoHoras: 5)
        ).first { $0.nome == "Carne bovina" }?.quantidade
        #expect(base == 4.0)

        // −25% sobre 4,0 kg = 3,0 kg exatos.
        let comAjuste = ShoppingListCalculator.calcular(
            ParametrosTurma(adultos: 10, duracaoHoras: 5),
            ajuste: AjusteConsumo(percentuais: ["carne": -25])
        ).first { $0.nome == "Carne bovina" }?.quantidade
        #expect(comAjuste == 3.0)
    }

    @Test("Guardrail 13.2.3 — ajuste é limitado a ±40% em código")
    func ajusteEhLimitado() {
        let ajuste = AjusteConsumo(percentuais: ["carne": 300, "acompanhamento": -999])
        #expect(ajuste[.carne] == 40)
        #expect(ajuste[.acompanhamento] == -40)
    }

    @Test("Regra 11.1.2 — item fixo não recebe ajuste histórico")
    func itemFixoIgnoraAjuste() {
        let com = ShoppingListCalculator.calcular(
            ParametrosTurma(adultos: 10),
            ajuste: AjusteConsumo(percentuais: ["carvao_e_utensilios": -40])
        )
        // Guardanapo é quantidade fixa: continua 1 pacote, ajuste ou não.
        #expect(com.first { $0.nome == "Guardanapo" }?.quantidade == 1)
    }

    // MARK: - Clamps da seção 13.2

    @Test("Guardrails 13.2.2 e 13.2.4 — clamps são aplicados em código")
    func clampsDeParametros() {
        let (p, corrigiu) = ParametrosTurma(
            adultos: 5_000, criancas: -3, vegetarianos: 900,
            naoBebemAlcool: 40, duracaoHoras: 99
        ).comClamp()

        #expect(corrigiu)
        #expect(p.adultos == 200)
        #expect(p.criancas == 0)
        // 7.10.2: vegetarianos e abstêmios nunca passam do número de adultos.
        #expect(p.vegetarianos == 200)
        #expect(p.naoBebemAlcool == 40)
        #expect(p.duracaoHoras == 24)
    }

    @Test("Guardrail 13.2.2 — duração mínima é 1 hora")
    func duracaoMinima() {
        #expect(ParametrosTurma(duracaoHoras: 0).comClamp().valor.duracaoHoras == 1)
    }

    // MARK: - Casos de borda (22.3)

    @Test("Caso de borda 22.3 — churrasco só de crianças gera lista coerente")
    func somenteCriancas() {
        let itens = ShoppingListCalculator.calcular(
            ParametrosTurma(adultos: 0, criancas: 6, duracaoHoras: 5)
        )
        #expect(itens.contains { $0.nome == "Carne bovina" })
        #expect(!itens.contains { $0.nome == "Cerveja" })
        #expect(itens.contains { $0.nome == "Refrigerante / suco" })
    }

    @Test("Caso de borda 22.3 — turma vazia não gera item de consumo")
    func turmaVazia() {
        let itens = ShoppingListCalculator.calcular(ParametrosTurma())
        // Sobram só os itens de quantidade fixa da tabela 11.1.2.
        #expect(itens.allSatisfy { $0.categoria == .carvao_e_utensilios })
        #expect(!itens.contains { $0.nome == "Carne bovina" })
    }
}
