import Foundation
import FoundationModels

/// Lê o registro pós-evento e devolve ajustes percentuais por categoria — épico 8.9.
///
/// O ajuste é aplicado **depois** do cálculo base (regra 11.14) e só vale para o churrasco
/// imediatamente seguinte, sem acumular: acúmulo entre eventos amplifica erro e vira um
/// número impossível de explicar ao usuário (assunção 24.7).
struct PostEventAdjustmentExtractor {

    private static let instrucoes = """
    Você lê o relato de alguém sobre o churrasco que acabou de acontecer e diz o quanto \
    ajustar a compra da próxima vez, por categoria.

    Categorias possíveis: carne, acompanhamento, bebida_alcoolica, bebida_nao_alcoolica, \
    carvao_e_utensilios, outro.

    Regras:
    - Sobrou muito de alguma coisa: percentual negativo. Faltou: percentual positivo.
    - A intensidade importa: "sobrou um pouco" é uns -10, "sobrou muito" é uns -25, \
    "sobrou pra caramba" é uns -35.
    - Só devolva categoria que o texto menciona. Não invente ajuste para o resto.
    - Nunca passe de -40 nem de +40.
    """

    /// - Parameter texto: o que o usuário escreveu na tela 10.14.
    /// - Returns: os ajustes já com o clamp de ±40% aplicado em código (guardrail 13.2.3).
    /// - Throws: `ErroDeIA.indisponivel` em qualquer falha. Nesse caso o texto é gravado
    ///   como simples anotação (`ajustes_json` nulo) e nenhum ajuste é aplicado (8.9).
    func extrair(de texto: String) async throws -> AjusteConsumo {
        let limpo = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpo.isEmpty else { throw ErroDeIA.naoEntendeu }

        let sessao = LanguageModelSession(instructions: Self.instrucoes)

        do {
            let resposta = try await sessao.respond(
                to: "Relato do churrasco: \(limpo)",
                generating: AjusteConsumoGerado.self
            )

            var percentuais: [String: Int] = [:]
            for ajuste in resposta.content.ajustes {
                // Categoria fora do enum é descartada em silêncio: melhor ignorar um ajuste
                // do que aplicar percentual numa categoria que não existe.
                guard let categoria = categoria_lista(rawValue: ajuste.categoria) else { continue }
                percentuais[categoria.rawValue] = ajuste.percentual
            }
            // O `init` de `AjusteConsumo` aplica o clamp de ±40% (13.2.3).
            return AjusteConsumo(percentuais: percentuais)
        } catch {
            throw ErroDeIA.indisponivel
        }
    }
}

extension AjusteConsumo {
    /// Serializa para o campo `ajustes_json` da entidade `registro_pos_evento` (7.8).
    var json: String? {
        guard let dados = try? JSONEncoder().encode(percentuais) else { return nil }
        return String(data: dados, encoding: .utf8)
    }

    /// Lê de volta do campo `ajustes_json`. JSON corrompido vira "sem ajuste", não erro:
    /// o pior caso aceitável aqui é a lista sair na quantidade base.
    static func doJSON(_ json: String?) -> AjusteConsumo? {
        guard let json, let dados = json.data(using: .utf8),
              let percentuais = try? JSONDecoder().decode([String: Int].self, from: dados)
        else { return nil }
        return AjusteConsumo(percentuais: percentuais)
    }
}
