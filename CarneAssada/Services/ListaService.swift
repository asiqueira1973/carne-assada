import Foundation
import SwiftData

/// Materializa a lista calculada dentro do store — apoio ao épico 8.3.
///
/// Separado do `ShoppingListCalculator` de propósito: o calculador é puro e testável sem
/// SwiftData; este daqui é quem sabe gravar. Misturar os dois tornaria a regra 11.1
/// impossível de testar sem container.
enum ListaService {

    /// Regera os itens `calculado` do churrasco, **preservando os `manual`** (épico 8.3).
    ///
    /// É a diferença entre recalcular e apagar o trabalho do usuário: quem adicionou
    /// "gelo de coco" à mão não pode perder isso porque mexeu num stepper.
    /// - Parameters:
    ///   - evento: o churrasco a regerar.
    ///   - ajuste: ajuste histórico do churrasco anterior (regra 11.14), ou `nil`.
    static func regerar(_ evento: churrasco, ajuste: AjusteConsumo?, contexto: ModelContext) {
        let parametros = ParametrosTurma(
            adultos: evento.qtd_adultos,
            criancas: evento.qtd_criancas,
            vegetarianos: evento.qtd_vegetarianos,
            naoBebemAlcool: evento.qtd_nao_bebem_alcool,
            duracaoHoras: evento.duracao_horas,
            incluiCarneSuina: evento.inclui_carne_suina
        )

        // Fora os manuais, tudo que era calculado sai.
        let manuais = evento.itens_lista.filter { $0.origem == .manual }
        for item in evento.itens_lista where item.origem != .manual {
            contexto.delete(item)
        }
        evento.itens_lista = manuais

        let calculados = ShoppingListCalculator.calcular(parametros, ajuste: ajuste)
        for (indice, calculado) in calculados.enumerated() {
            let item = item_lista(
                categoria: calculado.categoria,
                nome: calculado.nome,
                quantidade: calculado.quantidade,
                unidade: calculado.unidade,
                origem: .calculado,
                ordem: indice
            )
            item.evento = evento
            contexto.insert(item)
        }

        evento.atualizado_em = Date()
    }

    /// O ajuste histórico que vale para este churrasco (regra 11.14).
    ///
    /// Vem do registro do churrasco **imediatamente anterior**, e só dele: o ajuste não
    /// acumula entre eventos (assunção 24.7). Volta `nil` quando o usuário desligou o
    /// ajuste com um toque (épico 8.9) ou quando não há registro anterior.
    static func ajusteAplicavel(para evento: churrasco, contexto: ModelContext) -> AjusteConsumo? {
        guard evento.ajuste_historico_ligado else { return nil }

        let data = evento.data_evento
        let idAtual = evento.id
        var descritor = FetchDescriptor<churrasco>(
            predicate: #Predicate { $0.data_evento < data && $0.id != idAtual },
            sortBy: [SortDescriptor(\.data_evento, order: .reverse)]
        )
        descritor.fetchLimit = 1

        guard let anterior = try? contexto.fetch(descritor).first,
              let registro = anterior.registro
        else { return nil }

        guard let ajuste = AjusteConsumo.doJSON(registro.ajustes_json), !ajuste.vazio else {
            return nil
        }
        return ajuste
    }

    /// Agrupa os itens por categoria, na ordem de exibição da lista (10.5 e 10.6).
    static func porCategoria(_ itens: [item_lista]) -> [(categoria_lista, [item_lista])] {
        Dictionary(grouping: itens, by: \.categoria)
            .sorted { $0.key.ordem < $1.key.ordem }
            .map { ($0.key, $0.value.sorted { $0.ordem < $1.ordem }) }
    }
}
