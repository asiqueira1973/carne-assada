import Foundation
import FoundationModels

/// Tipos `@Generable` — seção 13.1 do spec.
///
/// **Todo campo opcional aqui existe porque o modelo pode não saber** — e nesse caso vem
/// nulo, nunca preenchido por chute (princípio 0.1 e guardrail 13.2.1). É a diferença entre
/// um campo em branco que o usuário preenche e um número inventado que ele não confere.

// MARK: - Parâmetros da turma (épico 8.2)

@Generable
struct ParametrosTurmaGerados: Equatable {
    @Guide(description: "Quantos adultos vão ao churrasco, contando vegetarianos e quem não bebe.")
    var adultos: Int

    @Guide(description: "Quantas crianças vão. Criança é até uns 12 anos.")
    var criancas: Int

    @Guide(description: "Quantos dos adultos não comem carne (vegetarianos ou veganos).")
    var vegetarianos: Int

    @Guide(description: "Quantos dos adultos não bebem bebida alcoólica.")
    var naoBebemAlcool: Int

    @Guide(description: "Duração do churrasco em horas inteiras. Se disser 'do meio-dia às 22h', são 10.")
    var duracaoHoras: Int
}

// MARK: - Nota fiscal (épico 8.5)

@Generable
struct ItemNotaExtraido: Equatable {
    @Guide(description: "A descrição do produto como aparece na nota, com as abreviações resolvidas.")
    var descricao: String

    @Guide(description: "O valor total desta linha em reais. Deixe nulo se não conseguir ler com certeza — nunca estime.")
    var valor: Double?

    @Guide(description: "Como este item deve ser dividido: geral, bebida_alcoolica, bebida_nao_alcoolica ou apenas_carne.")
    var categoriaSugerida: CategoriaRateioGerada
}

@Generable
enum CategoriaRateioGerada: String, Equatable {
    case geral
    case bebida_alcoolica
    case bebida_nao_alcoolica
    case apenas_carne

    /// Guardrail 13.2.5: o enum tipado já impede valor inválido; esta é a ponte para o modelo.
    var comoCategoria: categoria_rateio {
        categoria_rateio(rawValue: rawValue) ?? .geral
    }
}

@Generable
struct NotaExtraida: Equatable {
    @Guide(description: "Nome do mercado ou estabelecimento. Nulo se não aparecer na nota.")
    var estabelecimento: String?

    @Guide(description: "Data da compra no formato dd/MM/aaaa. Nulo se não aparecer.")
    var dataCompra: String?

    @Guide(description: "O valor total impresso na nota, em reais. Nulo se não conseguir ler.")
    var valorTotal: Double?

    @Guide(description: "Cada produto comprado, uma entrada por linha da nota.")
    var itens: [ItemNotaExtraido]
}

// MARK: - Ajuste pós-evento (épico 8.9)

@Generable
struct AjusteCategoriaGerado: Equatable {
    @Guide(description: "Uma de: carne, acompanhamento, bebida_alcoolica, bebida_nao_alcoolica, carvao_e_utensilios, outro.")
    var categoria: String

    @Guide(description: "Quanto ajustar da próxima vez, em porcento. Negativo se sobrou, positivo se faltou. Entre -40 e 40.")
    var percentual: Int
}

@Generable
struct AjusteConsumoGerado: Equatable {
    @Guide(description: "Um ajuste por categoria mencionada. Categoria que o texto não menciona fica de fora.")
    var ajustes: [AjusteCategoriaGerado]
}
