import Foundation
import FoundationModels

/// Estado de disponibilidade do modelo on-device — regra 11.9 do spec.
enum DisponibilidadeDoModelo: Equatable, Sendable {
    case disponivel
    /// Qualquer motivo de indisponibilidade: aparelho sem suporte, Apple Intelligence
    /// desligada, modelo ainda baixando. O app **não distingue** para o usuário: os três
    /// caem no mesmo caminho manual (regra 11.9 e exceção 9.2.1).
    case indisponivel
}

/// Diz se dá para usar o modelo. Serviço da seção 13.
///
/// Regra 11.9: quando o modelo não está disponível, os pontos de entrada de IA são
/// **ocultados** — não desabilitados. Botão cinza é uma promessa quebrada na cara do
/// usuário; sumir com ele deixa o caminho manual parecer o caminho normal, que é o que é.
@MainActor
@Observable
final class ModelAvailabilityService {

    private(set) var estado: DisponibilidadeDoModelo

    init() {
        estado = Self.consultar()
    }

    /// `true` quando os pontos de IA devem aparecer na UI.
    var podeUsarIA: Bool { estado == .disponivel }

    /// Reconsulta o sistema. Vale chamar quando o app volta do background: o usuário pode
    /// ter ligado a Apple Intelligence nos Ajustes enquanto estava fora.
    func reconsultar() {
        estado = Self.consultar()
    }

    private static func consultar() -> DisponibilidadeDoModelo {
        switch SystemLanguageModel.default.availability {
        case .available: .disponivel
        // `.unavailable` cobre aparelho sem suporte, Apple Intelligence desligada e
        // modelo não baixado (premissa 4.3.3). Os três levam ao mesmo lugar.
        case .unavailable: .indisponivel
        @unknown default: .indisponivel
        }
    }
}
