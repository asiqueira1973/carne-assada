import SwiftUI

/// Forma, densidade e tipografia compartilhadas — seções 16.2 e 16.3 do spec.

// MARK: - Métricas (16.3)

enum Metrica {
    /// Canto padrão de card (16.3).
    static let cantoCartao: CGFloat = 16
    /// Margem lateral mínima da tela (16.3).
    static let margemLateral: CGFloat = 20
    /// Espaço entre cards (16.3).
    static let entreCartoes: CGFloat = 12
    /// Área mínima de toque (17.6).
    static let toqueMinimo: CGFloat = 44
    /// Tamanho de renderização dos ícones de categoria (16.7.5).
    static let iconeCategoria: CGFloat = 28
    /// Folga no rodapé das telas que ficam dentro de uma aba.
    ///
    /// A tab bar flutuante do iOS 26 é desenhada **por cima** do fim do conteúdo. Sem esta
    /// folga o último controle da tela fica colado nela e o toque erra — foi o que
    /// aconteceu com o "Lançar itens à mão" da tela 10.7.
    static let folgaDaTabBar: CGFloat = 64
}

// MARK: - Card (16.3)

/// Aplica o fundo de card da paleta com canto arredondado e sombra sutil.
///
/// A sombra existe só no modo claro: no escuro o card se separa do fundo `#000000`
/// pela própria diferença de luminância (`#1C1C1E`), e sombra preta sobre preto é ruído.
private struct EstiloCartao: ViewModifier {
    @Environment(\.colorScheme) private var esquema

    func body(content: Content) -> some View {
        content
            .background(Paleta.fundoCartao, in: .rect(cornerRadius: Metrica.cantoCartao))
            .shadow(
                color: esquema == .dark ? .clear : Color.black.opacity(0.05),
                radius: 5, x: 0, y: 2
            )
    }
}

extension View {
    /// Fundo de card da seção 16.3: canto 16, sombra sutil no claro, sem borda pesada.
    func cartao() -> some View { modifier(EstiloCartao()) }
}

// MARK: - Tipografia (16.2)

extension Text {
    /// Valor monetário: `.title2` bold com `monospacedDigit()`.
    /// O dígito monoespaçado é **obrigatório** (16.2) — sem ele o número dança ao atualizar,
    /// e a animação 16.5.5 (contagem de 0 até o valor) faz o layout tremer.
    func estiloValor() -> some View {
        self.font(.title2.bold().monospacedDigit())
            .foregroundStyle(Paleta.carvaoEscuro)
    }

    /// Legenda / explicação: `.footnote` na cor secundária.
    func estiloLegenda() -> some View {
        self.font(.footnote)
            .foregroundStyle(Paleta.textoSecundario)
    }
}

// MARK: - Botão principal (16.1: brasaLaranja é a cor primária)

/// Botão de ação principal da tela: laranja cheio, largura total, canto arredondado.
struct BotaoPrincipal: ButtonStyle {
    @Environment(\.isEnabled) private var habilitado

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: Metrica.toqueMinimo)
            .background(Paleta.brasaLaranja.opacity(habilitado ? 1 : 0.4),
                        in: .rect(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

// MARK: - Linha de lista com cara de card

/// Faz uma linha de `List` parecer um card solto sobre o fundo da tela.
///
/// As telas usam `List` — e não `ScrollView` + `LazyVStack` — porque o swipe para excluir
/// (telas 10.1 e 10.5) **só funciona dentro de uma `List`**; fora dela `swipeActions` é
/// ignorado em silêncio. Este modificador devolve o visual da seção 16.3 por cima disso.
struct LinhaSemFundo: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(.init(top: Metrica.entreCartoes / 2,
                                 leading: Metrica.margemLateral,
                                 bottom: Metrica.entreCartoes / 2,
                                 trailing: Metrica.margemLateral))
    }
}

// MARK: - Chip de status (usado na Home, tela 10.1)

/// Etiqueta pequena de status, com o preenchimento sutil da paleta atrás.
struct Chip: View {
    let texto: String
    let cor: Color

    var body: some View {
        Text(texto)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(cor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Paleta.preenchimentoSutil, in: .rect(cornerRadius: 8))
    }
}

// MARK: - Ilustração (16.7)

/// Exibe uma ilustração fornecida do Asset Catalog, aplicando as regras da seção 16.7.
///
/// - 16.7.2: toda ilustração é decorativa (`accessibilityHidden`); a informação vive no texto ao lado.
/// - 16.7.4: ilustração grande some quando o Dynamic Type está em tamanho acessível —
///   o texto tem prioridade sobre a arte.
/// - 16.7.7: nenhuma tintura. Sem `.foregroundStyle`, sem `.renderingMode(.template)`.
struct Ilustracao: View {
    let asset: Ilustracoes
    var altura: CGFloat = 180

    @Environment(\.dynamicTypeSize) private var tamanhoTipografico

    var body: some View {
        if !tamanhoTipografico.isAccessibilitySize {
            Image(asset.rawValue)
                .resizable()
                .scaledToFit()
                .frame(height: altura)
                .accessibilityHidden(true)
        }
    }
}

/// Nomes dos assets de ilustração (16.7.1: constante tipada, nunca string literal solta).
enum Ilustracoes: String {
    case churrasqueira = "empty_grill"
    case tabuaDeCarnes = "meat_board"
    case carrinho = "shopping_cart"
    case churrasqueiraComemorando = "grill_celebrating"
    case notaEtelefone = "receipt_scan"
    case turmaDeAmigos = "people_group"
    case espetoEPrato = "empty_plate"
    case fotoIlegivel = "receipt_unreadable"
    case brasa1 = "ember_particle_1"
    case brasa2 = "ember_particle_2"
    case brasa3 = "ember_particle_3"
}
