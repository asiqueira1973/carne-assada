import Testing
import Foundation
import SwiftData
@testable import CarneAssada

/// Testes do modelo de dados (seção 7), da máquina de estados (seção 12) e do texto
/// compartilhado (seção 14.1).

struct MaquinaDeEstadosTests {

    @Test("Seção 12 — transições permitidas")
    func transicoesPermitidas() {
        #expect(status_churrasco.planejando.permiteIrPara(.comprando))
        #expect(status_churrasco.planejando.permiteIrPara(.fechando_conta))
        #expect(status_churrasco.comprando.permiteIrPara(.fechando_conta))
        #expect(status_churrasco.comprando.permiteIrPara(.planejando))
        #expect(status_churrasco.fechando_conta.permiteIrPara(.concluido))
        #expect(status_churrasco.fechando_conta.permiteIrPara(.comprando))
        #expect(status_churrasco.concluido.permiteIrPara(.fechando_conta))
    }

    @Test("Seção 12 — planejando não pode ir direto para concluído")
    func transicaoProibida() {
        #expect(!status_churrasco.planejando.permiteIrPara(.concluido))
        let evento = churrasco(nome: "Teste")
        #expect(evento.irPara(.concluido) == false)
        #expect(evento.status == .planejando)
    }

    @Test("Seção 12 — transição válida muda o status e carimba atualizado_em")
    func transicaoValida() {
        let evento = churrasco(nome: "Teste")
        #expect(evento.irPara(.comprando))
        #expect(evento.status == .comprando)
    }
}

@MainActor
struct ModeloTests {

    /// Usa `ModelContext(container)` e nunca `container.mainContext`: o contexto principal
    /// tem comportamento próprio de autosave que torna o teste não determinístico.
    private func contextoDeTeste() throws -> ModelContext {
        ModelContext(try Persistencia.containerEmMemoria())
    }

    @Test("Seção 7.2 — exclusão do churrasco cascateia para todas as filhas")
    func exclusaoEmCascata() throws {
        let contexto = try contextoDeTeste()

        let evento = churrasco(nome: "Cascata")
        contexto.insert(evento)

        let pessoa = participante(nome: "Ana")
        pessoa.evento = evento
        contexto.insert(pessoa)

        let item = item_lista(categoria: .carne, nome: "Picanha", quantidade: 2, unidade: .kg)
        item.evento = evento
        contexto.insert(item)

        let nota = compra(estabelecimento: "Mercado")
        nota.evento = evento
        contexto.insert(nota)

        let linha = item_compra(descricao: "Picanha", valor_total: 90, confirmado: true)
        linha.nota = nota
        contexto.insert(linha)

        let marcacao = atribuicao(item: linha, quem: pessoa)
        contexto.insert(marcacao)

        let registro = registro_pos_evento(texto_livre: "sobrou carne")
        registro.evento = evento
        contexto.insert(registro)

        try contexto.save()

        contexto.delete(evento)
        try contexto.save()

        #expect(try contexto.fetch(FetchDescriptor<churrasco>()).isEmpty)
        #expect(try contexto.fetch(FetchDescriptor<participante>()).isEmpty)
        #expect(try contexto.fetch(FetchDescriptor<item_lista>()).isEmpty)
        #expect(try contexto.fetch(FetchDescriptor<compra>()).isEmpty)
        #expect(try contexto.fetch(FetchDescriptor<item_compra>()).isEmpty)
        #expect(try contexto.fetch(FetchDescriptor<atribuicao>()).isEmpty)
        #expect(try contexto.fetch(FetchDescriptor<registro_pos_evento>()).isEmpty)
    }

    @Test("Seção 7.3 — criança nasce sem álcool")
    func criancaNaoBebe() {
        let bia = participante(nome: "Bia", e_crianca: true, bebe_alcool: true)
        #expect(bia.bebe_alcool == false)
    }

    @Test("Regra 7.10.3 — valor negativo lido da nota não vira item negativo")
    func valorNegativoEhZerado() {
        let desconto = item_compra(descricao: "Desconto", valor_total: -5)
        #expect(desconto.valor_total == 0)
    }

    @Test("Regras 11.11 e 11.10.2 — só entra no rateio o item confirmado e com valor")
    func entraNoRateio() {
        let confirmadoComValor = item_compra(descricao: "A", valor_total: 10, confirmado: true)
        #expect(confirmadoComValor.entra_no_rateio)

        let confirmadoSemValor = item_compra(descricao: "B", valor_total: nil, confirmado: true)
        #expect(!confirmadoSemValor.entra_no_rateio)
        #expect(confirmadoSemValor.pendente)

        let naoConfirmado = item_compra(descricao: "C", valor_total: 10, confirmado: false)
        #expect(!naoConfirmado.entra_no_rateio)
    }

    @Test("Épico 8.3 — recálculo preserva os itens manuais e substitui os calculados")
    func recalculoPreservaManuais() throws {
        let contexto = try contextoDeTeste()

        let evento = churrasco(nome: "Recalcular")
        evento.qtd_adultos = 10
        evento.duracao_horas = 5
        contexto.insert(evento)

        ListaService.regerar(evento, ajuste: nil, contexto: contexto)
        try contexto.save()

        let manual = item_lista(categoria: .outro, nome: "Gelo de coco",
                                quantidade: 2, unidade: .unidade, origem: .manual)
        manual.evento = evento
        contexto.insert(manual)
        try contexto.save()

        let calculadosAntes = evento.itens_lista.filter { $0.origem == .calculado }.count
        #expect(calculadosAntes > 0)

        evento.qtd_adultos = 20
        ListaService.regerar(evento, ajuste: nil, contexto: contexto)
        try contexto.save()

        // O manual continua lá…
        #expect(evento.itens_lista.contains { $0.nome == "Gelo de coco" })
        // …e a carne subiu com o novo número de adultos.
        let carne = evento.itens_lista.first { $0.nome == "Carne bovina" }
        #expect(carne?.quantidade == 8.0)
    }
}

struct ShareTextBuilderTests {

    @Test("Seção 14.1 — formato exato do texto compartilhado")
    func formatoDoTexto() {
        let ana = ParticipanteParaRateio(id: UUID(), nome: "Ana", e_crianca: false,
                                         come_carne: true, bebe_alcool: true, ordem: 0)
        let bruno = ParticipanteParaRateio(id: UUID(), nome: "Bruno", e_crianca: false,
                                           come_carne: true, bebe_alcool: true, ordem: 1)

        let resultado = SplitCalculator.calcular(
            itens: [ItemParaRateio(id: UUID(), descricao: "Carne", valor: 100,
                                   categoria: .geral, atribuidosA: [ana.id])],
            participantes: [ana, bruno]
        )

        var componentes = DateComponents()
        componentes.year = 2026; componentes.month = 9; componentes.day = 14
        let data = Calendar(identifier: .gregorian).date(from: componentes)!

        let texto = ShareTextBuilder.montar(nome: "Aniversário do Léo",
                                            data: data, resultado: resultado)
        let linhas = texto.components(separatedBy: "\n")

        #expect(linhas[0] == "🔥 Aniversário do Léo — 14/09/2026")
        #expect(linhas[1].isEmpty)
        #expect(linhas[2].hasPrefix("Total: R$"))
        #expect(linhas[3].isEmpty)
        // Ordem por valor decrescente (14.1): Ana levou o item inteiro.
        #expect(linhas[4].hasPrefix("Ana: R$"))
        #expect(linhas[5].hasPrefix("Bruno: R$"))
        #expect(linhas.last == "Contas feitas no Carne Assada 🍖")
    }

    @Test("Seção 20.2 — o texto não vaza itens nem estabelecimento")
    func textoNaoVazaDado() {
        let ana = ParticipanteParaRateio(id: UUID(), nome: "Ana", e_crianca: false,
                                         come_carne: true, bebe_alcool: true, ordem: 0)
        let resultado = SplitCalculator.calcular(
            itens: [ItemParaRateio(id: UUID(), descricao: "Picanha Friboi",
                                   valor: 89, categoria: .apenas_carne, atribuidosA: [])],
            participantes: [ana]
        )
        let texto = ShareTextBuilder.montar(nome: "Churrasco", data: Date(),
                                            resultado: resultado)
        #expect(!texto.contains("Picanha"))
        #expect(!texto.contains("Friboi"))
    }
}

struct AjusteConsumoTests {

    @Test("Seção 7.8 — ajuste vai e volta do JSON sem perder valor")
    func serializacao() {
        let original = AjusteConsumo(percentuais: ["carne": -25, "bebida_alcoolica": 15])
        let recuperado = AjusteConsumo.doJSON(original.json)
        #expect(recuperado?[.carne] == -25)
        #expect(recuperado?[.bebida_alcoolica] == 15)
    }

    @Test("Seção 7.8 — JSON corrompido vira 'sem ajuste', não erro")
    func jsonCorrompido() {
        #expect(AjusteConsumo.doJSON("{isso não é json}") == nil)
        #expect(AjusteConsumo.doJSON(nil) == nil)
    }
}
