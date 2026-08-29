import SwiftUI

/// Paleta do app — seção 16.1 do spec.
///
/// Duas famílias que nunca se misturam:
/// - **Cores de marca**: fundo, destaque, ilustração. Nunca carregam significado de estado.
/// - **Cores semânticas**: exclusivamente significado (sucesso, atenção, erro). Nunca decorativas.
///
/// Regra de conflito (16.1): `churrascoVermelho` (marca) e `erro` (semântica) nunca aparecem
/// na mesma tela em papéis confundíveis. Ação destrutiva usa **sempre** o vermelho do sistema.
enum Paleta {

    // MARK: - Cores de marca

    /// Cor primária. Botões principais, item ativo, acentos.
    static let brasaLaranja = Color(claro: 0xFF6B35, escuro: 0xFF7F4F)

    /// Texto principal (invertido no modo escuro).
    static let carvaoEscuro = Color(claro: 0x2B2118, escuro: 0xF2EDE7)

    /// Secundária. Categoria carne, ilustrações.
    static let churrascoVermelho = Color(claro: 0xC1443A, escuro: 0xD9584D)

    /// Terciária. Categoria acompanhamento, celebração.
    static let milhoAmarelo = Color(claro: 0xF2B134, escuro: 0xF7C25B)

    /// Categoria vegetariana e bebida não alcoólica.
    static let limaoVerde = Color(claro: 0x5FA83E, escuro: 0x77C155)

    /// Categoria bebida alcoólica.
    static let cervejaDourado = Color(claro: 0xE8A33D, escuro: 0xF0B45B)

    // MARK: - Fundos (paleta corrigida — v1.5 do spec)

    /// Fundo das telas. Chapado, **sem gradiente** (a antiga regra 16.5.8 foi revogada).
    static let fundoTela = Color(claro: 0xF2F2F7, escuro: 0x000000)

    /// Fundo de card. No claro vem com a sombra sutil de `.cartao()`; no escuro, sem sombra.
    static let fundoCartao = Color(claro: 0xFFFFFF, escuro: 0x1C1C1E)

    /// Texto secundário: data, legenda, explicação.
    static let textoSecundario = Color(claro: 0x6E6259, escuro: 0xA2958A)

    /// Preenchimento sutil: chip de status, separador, campo de formulário.
    static let preenchimentoSutil = Color(claro: 0xE5E5EA, escuro: 0x2C2C2E)

    // MARK: - Cores semânticas (só significado, nunca decoração)

    /// Confirmação, item comprado.
    static let sucesso = Color.green

    /// Divergência de valor, item pendente.
    static let atencao = Color.orange

    /// Falha e ação destrutiva. **Sempre** o vermelho do sistema, nunca o da marca.
    static let erro = Color.red
}

extension Color {
    /// Constrói uma cor que troca de valor entre claro e escuro, a partir de dois hexadecimais RGB.
    /// - Parameters:
    ///   - claro: valor `0xRRGGBB` usado no modo claro.
    ///   - escuro: valor `0xRRGGBB` usado no modo escuro.
    init(claro: UInt32, escuro: UInt32) {
        self.init(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hexadecimal: escuro)
                : UIColor(hexadecimal: claro)
        })
    }
}

extension UIColor {
    /// Converte `0xRRGGBB` em cor opaca no espaço sRGB.
    fileprivate convenience init(hexadecimal: UInt32) {
        self.init(
            red: CGFloat((hexadecimal >> 16) & 0xFF) / 255,
            green: CGFloat((hexadecimal >> 8) & 0xFF) / 255,
            blue: CGFloat(hexadecimal & 0xFF) / 255,
            alpha: 1
        )
    }
}
