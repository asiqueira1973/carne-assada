import Testing
import Foundation
@testable import CarneAssada

/// Testes das regras 11.5 a 11.11 — rateio, peso da criança e arredondamento.

struct SplitCalculatorTests {

    // MARK: - Fixtures

    private func pessoa(_ nome: String, ordem: Int, crianca: Bool = false,
                        carne: Bool = true, alcool: Bool = true) -> ParticipanteParaRateio {
        ParticipanteParaRateio(id: UUID(), nome: nome, e_crianca: crianca,
                               come_carne: carne,
                               // 7.3: criança nunca bebe.
                               bebe_alcool: crianca ? false : alcool, ordem: ordem)
    }

    private func item(_ valor: Decimal, _ categoria: categoria_rateio,
                      para atribuidos: [UUID] = []) -> ItemParaRateio {
        ItemParaRateio(id: UUID(), descricao: "item", valor: valor,
                       categoria: categoria, atribuidosA: atribuidos)
    }

    // MARK: - 11.7 peso da criança

    @Test("Regra 11.7 — peso da criança por categoria")
    func pesoDaCrianca() {
        let crianca = pessoa("Bia", ordem: 0, crianca: true)
        #expect(SplitCalculator.peso(de: crianca, em: .geral) == 0.5)
        #expect(SplitCalculator.peso(de: crianca, em: .apenas_carne) == 0.5)
        #expect(SplitCalculator.peso(de: crianca, em: .bebida_nao_alcoolica) == 1)
        #expect(SplitCalculator.peso(de: crianca, em: .bebida_alcoolica) == 0)
    }

    @Test("Regra 11.5 — quem não come carne fica fora do rateio de carne")
    func vegetarianoForaDaCarne() {
        let veg = pessoa("Léo", ordem: 0, carne: false)
        #expect(SplitCalculator.peso(de: veg, em: .apenas_carne) == 0)
        // Mas continua no rateio geral: pão de alho e carvão são de todo mundo.
        #expect(SplitCalculator.peso(de: veg, em: .geral) == 1)
    }

    @Test("Regra 11.5 — quem não bebe fica fora da bebida alcoólica")
    func abstemioForaDoAlcool() {
        let abstemio = pessoa("Ana", ordem: 0, alcool: false)
        #expect(SplitCalculator.peso(de: abstemio, em: .bebida_alcoolica) == 0)
        #expect(SplitCalculator.peso(de: abstemio, em: .bebida_nao_alcoolica) == 1)
    }

    // MARK: - 11.13 exemplo de rateio

    /// Exemplo do spec: item de R$ 100,00 em `bebida_alcoolica`, 15 adultos que bebem e
    /// 4 crianças. Cada adulto R$ 6,67, criança R$ 0,00, e a sobra de R$ 0,05 sai do
    /// participante de maior valor — que fica com R$ 6,62.
    @Test("Regra 11.13 — exemplo de rateio de bebida alcoólica")
    func exemploDeRateio1113() {
        var pessoas = (0..<15).map { pessoa("Adulto \($0)", ordem: $0) }
        pessoas += (0..<4).map { pessoa("Criança \($0)", ordem: 15 + $0, crianca: true) }

        let resultado = SplitCalculator.calcular(itens: [item(100, .bebida_alcoolica)],
                                                 participantes: pessoas)

        // A invariante que importa: a soma bate exatamente com o total.
        let soma = resultado.porParticipante.reduce(Decimal(0)) { $0 + $1.valor }
        #expect(soma == 100)
        #expect(resultado.total == 100)

        // Criança não paga cerveja.
        let criancas = resultado.porParticipante.filter { $0.nome.hasPrefix("Criança") }
        #expect(criancas.allSatisfy { $0.valor == 0 })

        // 14 adultos ficam com R$ 6,67 e o que absorveu a sobra fica com R$ 6,62.
        let adultos = resultado.porParticipante.filter { $0.nome.hasPrefix("Adulto") }
        #expect(adultos.filter { $0.valor == Decimal(string: "6.67")! }.count == 14)
        #expect(adultos.filter { $0.valor == Decimal(string: "6.62")! }.count == 1)
        #expect(resultado.porParticipante.filter(\.absorveuArredondamento).count == 1)
    }

    // MARK: - 11.8 arredondamento

    @Test("Regra 11.8 — a soma dos individuais é sempre exatamente igual ao total",
          arguments: 0..<100)
    func propriedadeDaSoma(semente: Int) {
        // Teste de propriedade exigido pela seção 22.1: 100 iterações com valores variados.
        // A variação vem da semente e não de `random`, para o teste ser reproduzível.
        var gerador = GeradorDeterministico(semente: UInt64(semente) &+ 1)

        let quantasPessoas = 1 + Int(gerador.proximo() % 12)
        let pessoas = (0..<quantasPessoas).map { indice in
            pessoa("P\(indice)", ordem: indice,
                   crianca: gerador.proximo() % 4 == 0,
                   carne: gerador.proximo() % 5 != 0,
                   alcool: gerador.proximo() % 3 != 0)
        }

        let quantosItens = 1 + Int(gerador.proximo() % 20)
        let categorias = categoria_rateio.allCases
        let itens = (0..<quantosItens).map { _ -> ItemParaRateio in
            // Centavos de propósito: é onde o arredondamento quebra.
            let centavos = Decimal(1 + gerador.proximo() % 50_000)
            let categoria = categorias[Int(gerador.proximo() % UInt64(categorias.count))]
            return item(centavos / 100, categoria)
        }

        let resultado = SplitCalculator.calcular(itens: itens, participantes: pessoas)
        let soma = resultado.porParticipante.reduce(Decimal(0)) { $0 + $1.valor }

        #expect(soma == resultado.total,
                "soma \(soma) != total \(resultado.total) na semente \(semente)")
    }

    @Test("Regra 11.8 — empate de valor resolve pela ordem do participante")
    func empateResolvePelaOrdem() {
        // R$ 10,00 divididos por 3 dá 3,3333… → 3,33 cada, sobra 1 centavo.
        let pessoas = [pessoa("A", ordem: 0), pessoa("B", ordem: 1), pessoa("C", ordem: 2)]
        let resultado = SplitCalculator.calcular(itens: [item(10, .geral)],
                                                 participantes: pessoas)

        let soma = resultado.porParticipante.reduce(Decimal(0)) { $0 + $1.valor }
        #expect(soma == 10)
        // Todos empatados em 3,33: o primeiro pela ordem absorve.
        #expect(resultado.porParticipante.first { $0.absorveuArredondamento }?.nome == "A")
    }

    // MARK: - Atribuição explícita (8.6)

    @Test("Épico 8.6 — atribuição explícita sobrepõe a categoria")
    func atribuicaoSobrepoeCategoria() {
        let a = pessoa("Ana", ordem: 0)
        let b = pessoa("Bruno", ordem: 1)
        let c = pessoa("Caio", ordem: 2)

        // Item de carne atribuído só a Ana e Bruno: Caio não paga, mesmo comendo carne.
        let resultado = SplitCalculator.calcular(
            itens: [item(30, .apenas_carne, para: [a.id, b.id])],
            participantes: [a, b, c]
        )

        #expect(resultado.porParticipante.first { $0.nome == "Ana" }?.valor == 15)
        #expect(resultado.porParticipante.first { $0.nome == "Bruno" }?.valor == 15)
        #expect(resultado.porParticipante.first { $0.nome == "Caio" }?.valor == 0)
    }

    @Test("Regra 11.5 — item com atribuição divide igualmente, ignorando peso de criança")
    func atribuicaoIgnoraPesoDeCrianca() {
        let adulto = pessoa("Ana", ordem: 0)
        let crianca = pessoa("Bia", ordem: 1, crianca: true)

        let resultado = SplitCalculator.calcular(
            itens: [item(20, .geral, para: [adulto.id, crianca.id])],
            participantes: [adulto, crianca]
        )

        // Dividido igualmente entre os atribuídos: R$ 10,00 cada, sem meia.
        #expect(resultado.porParticipante.allSatisfy { $0.valor == 10 })
    }

    @Test("Regra 11.5 — ausência de atribuição significa rateio por categoria")
    func semAtribuicaoUsaCategoria() {
        let adulto = pessoa("Ana", ordem: 0)
        let crianca = pessoa("Bia", ordem: 1, crianca: true)

        // Pesos 1 e 0,5 → total 1,5 → Ana paga 2/3 e Bia 1/3.
        let resultado = SplitCalculator.calcular(itens: [item(30, .geral)],
                                                 participantes: [adulto, crianca])

        #expect(resultado.porParticipante.first { $0.nome == "Ana" }?.valor == 20)
        #expect(resultado.porParticipante.first { $0.nome == "Bia" }?.valor == 10)
    }

    // MARK: - Casos de borda (22.3)

    @Test("Caso de borda 22.3 — churrasco com um participante só")
    func umParticipante() {
        let so = pessoa("Ana", ordem: 0)
        let resultado = SplitCalculator.calcular(
            itens: [item(Decimal(string: "33.33")!, .geral)], participantes: [so]
        )
        #expect(resultado.porParticipante.first?.valor == Decimal(string: "33.33")!)
    }

    @Test("Caso de borda 22.3 — item de R$ 0,00 não quebra o rateio")
    func itemZerado() {
        let pessoas = [pessoa("A", ordem: 0), pessoa("B", ordem: 1)]
        let resultado = SplitCalculator.calcular(itens: [item(0, .geral)],
                                                 participantes: pessoas)
        #expect(resultado.total == 0)
        #expect(resultado.porParticipante.allSatisfy { $0.valor == 0 })
    }

    @Test("Caso de borda — item de álcool sem ninguém que bebe cai no rateio geral")
    func ninguemBebe() {
        // O dinheiro não pode sumir: sem elegível, a soma tem de continuar batendo.
        let pessoas = [pessoa("A", ordem: 0, alcool: false),
                       pessoa("B", ordem: 1, alcool: false)]
        let resultado = SplitCalculator.calcular(itens: [item(10, .bebida_alcoolica)],
                                                 participantes: pessoas)

        let soma = resultado.porParticipante.reduce(Decimal(0)) { $0 + $1.valor }
        #expect(soma == 10)
    }

    @Test("Exceção 9.2.2 — sem participante não há rateio")
    func semParticipantes() {
        let resultado = SplitCalculator.calcular(itens: [item(50, .geral)], participantes: [])
        #expect(resultado.porParticipante.isEmpty)
    }

    // MARK: - Composição explicada (10.13)

    @Test("Tela 10.13 — a exclusão aparece explicada, com valor zero")
    func exclusaoEhExplicada() {
        let abstemio = pessoa("Ana", ordem: 0, alcool: false)
        let bebe = pessoa("Bruno", ordem: 1)

        let resultado = SplitCalculator.calcular(itens: [item(20, .bebida_alcoolica)],
                                                 participantes: [abstemio, bebe])

        let dela = resultado.porParticipante.first { $0.nome == "Ana" }
        let linha = dela?.composicao.first { $0.titulo == categoria_rateio.bebida_alcoolica.rotulo }
        #expect(linha?.valor == 0)
        #expect(linha?.explicacao == Copy.explicacaoNaoBebe)
    }
}

// MARK: - Apoio

/// Gerador pseudoaleatório determinístico (xorshift), para o teste de propriedade da 11.8
/// ser reproduzível: quando uma iteração falha, dá para rodar aquela semente de novo.
private struct GeradorDeterministico {
    private var estado: UInt64

    init(semente: UInt64) { estado = semente &* 2_862_933_555_777_941_757 &+ 3_037_000_493 }

    mutating func proximo() -> UInt64 {
        estado ^= estado << 13
        estado ^= estado >> 7
        estado ^= estado << 17
        return estado
    }
}
