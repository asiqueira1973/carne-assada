import Foundation
import StoreKit

/// Estado da compra — regra 11.16.4 do spec.
enum EstadoDoEntitlement: Equatable, Sendable {
    /// O StoreKit ainda não respondeu. **Nunca** tratar como "não comprado":
    /// nesse estado a UI mostra carregamento, não paywall e não libera a feature.
    case desconhecido
    case naoComprado
    case comprado
}

/// Única dependência de StoreKit do app — serviço da seção 13.
///
/// Regra 11.16.4: o entitlement vem de `Transaction.currentEntitlements`, sem validação em
/// servidor (decisão 4.2). Regra 23.11: uma vez lido com sucesso, o entitlement fica em
/// cache local e **nunca é rebaixado para "não comprado" por falta de rede** — quem comprou
/// e abriu o app offline não pode encontrar a área de conta trancada.
@MainActor
@Observable
final class EntitlementService {

    /// Identificador do produto não-consumível único (épico 8.10).
    static let idDoProduto = "carne_assada_pro"

    /// Chave do cache local do entitlement. Guarda só um booleano — nenhum dado de
    /// pagamento é armazenado ou transmitido (seção 20.7.1).
    private static let chaveDeCache = "entitlement_carne_assada_pro"

    private(set) var estado: EstadoDoEntitlement = .desconhecido
    private(set) var produto: Product?
    private(set) var comprando = false
    /// `true` enquanto a consulta do produto à App Store está em andamento.
    /// Serve para o paywall distinguir "ainda carregando" de "não deu para carregar" —
    /// sem isso os dois estados são um botão morto, que não explica nada a ninguém.
    private(set) var carregandoProduto = false

    private var observador: Task<Void, Never>?

    init() {
        // Regra 23.11: se já sabíamos que ele comprou, entra direto como comprado.
        // Sem isto, abrir o app em modo avião mostraria paywall a quem já pagou.
        if UserDefaults.standard.bool(forKey: Self.chaveDeCache) {
            estado = .comprado
        }
        observarTransacoes()
    }

    /// Encerra a observação de `Transaction.updates`.
    ///
    /// Não existe `deinit` cancelando isto de propósito: o `deinit` roda fora do main actor
    /// e não pode tocar em estado isolado. Na prática o serviço vive o app inteiro, então
    /// o método existe só para os testes e os previews soltarem a tarefa.
    func encerrar() {
        observador?.cancel()
        observador = nil
    }

    var liberado: Bool { estado == .comprado }

    // MARK: - Leitura

    /// Lê o entitlement e carrega o produto. Chamada uma vez, na abertura do app.
    ///
    /// Critério do épico 8.10: depois da compra o app **não faz verificação adicional em
    /// nenhuma tela** — o entitlement é lido aqui e observado por `Transaction.updates`.
    func carregar() async {
        await atualizarEntitlement()
        await carregarProduto()
    }

    /// Consulta o produto na App Store. Falha aqui não é erro do usuário: acontece com o
    /// aparelho offline, com o produto ainda não aprovado na loja, ou num build de
    /// desenvolvimento sem configuração de StoreKit. O paywall precisa saber diferenciar.
    func carregarProduto() async {
        carregandoProduto = true
        defer { carregandoProduto = false }
        produto = try? await Product.products(for: [Self.idDoProduto]).first
    }

    private func atualizarEntitlement() async {
        var comprado = false
        for await resultado in Transaction.currentEntitlements {
            // `verified` é a verificação de assinatura feita pelo próprio sistema.
            // Transação não verificada é ignorada, não tratada como compra.
            guard case .verified(let transacao) = resultado else { continue }
            if transacao.productID == Self.idDoProduto, transacao.revocationDate == nil {
                comprado = true
            }
        }

        if comprado {
            estado = .comprado
            UserDefaults.standard.set(true, forKey: Self.chaveDeCache)
        } else if estado != .comprado {
            // Só cai para "não comprado" se ainda não sabíamos que ele tinha comprado.
            // Regra 23.11: nunca rebaixar um entitlement já conhecido.
            estado = .naoComprado
        }
    }

    /// Observa `Transaction.updates` para pegar compra feita fora do app (outro aparelho,
    /// Compartilhamento Familiar, reembolso) sem que nenhuma tela precise consultar nada.
    private func observarTransacoes() {
        observador = Task { [weak self] in
            for await resultado in Transaction.updates {
                guard case .verified(let transacao) = resultado else { continue }
                await transacao.finish()
                await self?.atualizarEntitlement()
            }
        }
    }

    // MARK: - Compra e restauração

    /// Resultado do fluxo de compra, do ponto de vista da UI do paywall (10.16).
    enum ResultadoDaCompra: Equatable {
        case comprou
        /// Cancelamento **não é erro**: volta ao paywall sem mensagem nenhuma (épico 8.10).
        case cancelou
        case pendente
        case falhou
    }

    func comprar() async -> ResultadoDaCompra {
        guard let produto else { return .falhou }
        comprando = true
        defer { comprando = false }

        do {
            switch try await produto.purchase() {
            case .success(let verificacao):
                guard case .verified(let transacao) = verificacao else { return .falhou }
                await transacao.finish()
                await atualizarEntitlement()
                return .comprou
            case .userCancelled:
                return .cancelou
            case .pending:
                return .pendente
            @unknown default:
                return .falhou
            }
        } catch {
            return .falhou
        }
    }

#if DEBUG
    /// Libera ou tranca a conta **sem passar pelo StoreKit**, só para teste manual.
    ///
    /// Existe porque o produto `carne_assada_pro` ainda não está no App Store Connect: sem
    /// isto não há como exercitar rateio, atribuição e compartilhamento num iPhone que não
    /// esteja plugado no Xcode com a configuração de StoreKit.
    ///
    /// Está dentro de `#if DEBUG`: **não existe no binário de Release**, então não há
    /// caminho para ela chegar à loja. Sai daqui assim que o produto existir de verdade.
    func alternarLiberacaoDeTeste() {
        let liberando = estado != .comprado
        estado = liberando ? .comprado : .naoComprado
        UserDefaults.standard.set(liberando, forKey: Self.chaveDeCache)
    }
#endif

    /// Resultado da restauração (regra 11.16.5).
    enum ResultadoDaRestauracao: Equatable {
        case restaurou
        /// Não é erro: mostra a copy 15.33 e pronto (épico 8.10).
        case nadaEncontrado
        case falhou
    }

    func restaurar() async -> ResultadoDaRestauracao {
        do {
            try await AppStore.sync()
            await atualizarEntitlement()
            return estado == .comprado ? .restaurou : .nadaEncontrado
        } catch {
            return .falhou
        }
    }
}
