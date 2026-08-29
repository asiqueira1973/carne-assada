import Foundation
import FoundationModels

/// Erro único da camada de IA.
///
/// Guardrail 13.2.7: falha de geração, timeout ou guardrail do framework são **todos**
/// tratados como "modelo indisponível". O app nunca mostra erro técnico ao usuário (11.9).
enum ErroDeIA: Error {
    case indisponivel
    case naoEntendeu
}

/// Transforma a descrição livre da turma em parâmetros numéricos — épico 8.2.
///
/// É a **única** chamada de IA de texto puro do app (seção 13). O que ela devolve não é
/// gravado: vai para os steppers da tela 10.4, e só o toque em "Confirmar" grava (princípio 0.1).
struct CrowdParameterExtractor {

    private static let instrucoes = """
    Você lê a descrição de um churrasco escrita em português do Brasil e extrai só os números.

    Regras:
    - Vegetariano é um subconjunto dos adultos: se a pessoa disser "15 adultos, 3 vegetarianos", \
    são 15 adultos no total, dos quais 3 são vegetarianos. Nunca some.
    - Quem não bebe também é subconjunto dos adultos, pela mesma lógica.
    - Duração vem em horas inteiras. "Do meio-dia até a noite" são umas 10 horas; \
    "à tarde" são umas 5.
    - Se a descrição não menciona alguma coisa, devolva 0 para ela. Não chute.
    """

    /// Extrai os parâmetros de um texto livre.
    /// - Parameter texto: o que o usuário digitou na tela 10.3.
    /// - Returns: parâmetros já com os clamps da seção 13.2 aplicados **em código**.
    /// - Throws: `ErroDeIA.indisponivel` em qualquer falha — nunca o erro do framework.
    func extrair(de texto: String) async throws -> ParametrosTurma {
        let limpo = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpo.isEmpty else { throw ErroDeIA.naoEntendeu }

        let sessao = LanguageModelSession(instructions: Self.instrucoes)

        do {
            let resposta = try await sessao.respond(
                to: "Descrição do churrasco: \(limpo)",
                generating: ParametrosTurmaGerados.self
            )
            let g = resposta.content

            // Guardrails 13.2.2 e 13.2.4: os limites são aplicados **aqui**, em Swift.
            // O prompt pede bom comportamento; o código é quem garante.
            return ParametrosTurma(
                adultos: g.adultos,
                criancas: g.criancas,
                vegetarianos: g.vegetarianos,
                naoBebemAlcool: g.naoBebemAlcool,
                // Regra 11.4: sem informação de duração, vale o default 5 — não zero.
                duracaoHoras: g.duracaoHoras <= 0 ? 5 : g.duracaoHoras
            ).comClamp().valor
        } catch {
            // 13.2.7: qualquer erro do framework vira indisponibilidade. O usuário vê a
            // copy 15.8 e segue nos steppers, com o texto que digitou preservado.
            throw ErroDeIA.indisponivel
        }
    }
}
