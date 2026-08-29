import Foundation

/// Formatação pt-BR — vírgula decimal, duas casas, separador de milhar (seção 14.1).
///
/// Centralizado num lugar só para que o valor exibido na tela e o valor que vai no texto
/// compartilhado sejam produzidos pelo mesmo código. Duas formatações diferentes para o
/// mesmo número é como se cria a reclamação da métrica 21.2.
enum Formatacao {

    static let localeBR = Locale(identifier: "pt_BR")

    /// "R$ 1.240,00"
    static func moeda(_ valor: Decimal) -> String {
        valor.formatted(.currency(code: "BRL").locale(localeBR))
    }

    /// "1.240,00" — sem o símbolo, para quando o "R$" já está no layout.
    static func numeroMonetario(_ valor: Decimal) -> String {
        valor.formatted(.number.precision(.fractionLength(2)).locale(localeBR))
    }

    /// Quantidade da lista de compras: inteiro sem casas, fracionário com até 3.
    /// "7 kg", "1,5 kg", "78 un" — nunca "7,000 kg".
    static func quantidade(_ valor: Decimal, _ unidade: unidade_medida) -> String {
        let numero = valor.formatted(
            .number.precision(.fractionLength(0...3)).locale(localeBR)
        )
        return "\(numero) \(unidade.abreviacao)"
    }

    /// "14 de setembro" — usado no card da Home e no cabeçalho do churrasco.
    static func dataPorExtenso(_ data: Date) -> String {
        data.formatted(.dateTime.day().month(.wide).locale(localeBR))
    }

    /// "14/09/2026" — formato do texto compartilhado (14.1).
    static func dataCurta(_ data: Date) -> String {
        data.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().locale(localeBR))
    }
}
