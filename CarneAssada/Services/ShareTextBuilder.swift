import Foundation

/// Monta o texto que vai para a share sheet — seção 14.1 do spec.
///
/// Restrição de privacidade (seção 20.2): o texto **não contém** nome de estabelecimento,
/// itens individuais nem categorias. Só nome do churrasco, data, total e valor por pessoa.
/// O que sai do aparelho é exatamente isto, e nada mais.
enum ShareTextBuilder {

    /// Formato exato da seção 14.1.
    /// - Parameters:
    ///   - nome: nome do churrasco.
    ///   - data: data do evento.
    ///   - resultado: o rateio já calculado, na ordem de exibição (valor decrescente).
    static func montar(nome: String, data: Date, resultado: ResultadoDoRateio) -> String {
        var linhas: [String] = []
        linhas.append("🔥 \(nome) — \(Formatacao.dataCurta(data))")
        linhas.append("")
        linhas.append("Total: \(Formatacao.moeda(resultado.total))")
        linhas.append("")

        for p in resultado.porParticipante {
            linhas.append("\(p.nome): \(Formatacao.moeda(p.valor))")
        }

        linhas.append("")
        linhas.append("Contas feitas no Carne Assada 🍖")

        return linhas.joined(separator: "\n")
    }
}
