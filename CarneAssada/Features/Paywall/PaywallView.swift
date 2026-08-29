import SwiftUI
import StoreKit

/// Tela 10.16 — Paywall.
///
/// Épico 8.10. Fronteira da regra 11.16: **planejar é grátis, dividir a conta é pago**.
///
/// Regra 11.16.6: **nenhuma string de preço existe aqui**. O valor vem de
/// `Product.displayPrice` do StoreKit — é isso que faz o preço funcionar em promoção,
/// em outra moeda e em mudança futura sem tocar no binário.
struct PaywallView: View {

    @Environment(EntitlementService.self) private var entitlement
    @Environment(\.dismiss) private var fechar

    @State private var mensagem: String?
    @State private var corDaMensagem: Color = Paleta.erro
    @State private var disparoDoShake = 0
    @State private var restaurando = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Ilustracao(asset: .notaEtelefone, altura: 200)
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    Text(Copy.tituloDoPaywall)
                        .font(.title.bold())
                        .foregroundStyle(Paleta.carvaoEscuro)
                        .multilineTextAlignment(.center)

                    Text(Copy.subtituloDoPaywall)
                        .font(.body)
                        .foregroundStyle(Paleta.textoSecundario)
                        .multilineTextAlignment(.center)
                }

                // Copy 15.30 — o que a compra libera.
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Copy.itensDoPaywall, id: \.self) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Paleta.limaoVerde)
                            Text(item)
                                .font(.body)
                                .foregroundStyle(Paleta.carvaoEscuro)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(18)
                .cartao()

                // Copies 15.31 e 15.36. A promessa de compra única é o principal argumento
                // de compra (regra 11.16.8) e precisa estar escrita, não subentendida.
                VStack(spacing: 6) {
                    Text(Copy.reforcoDePagamentoUnico)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Paleta.carvaoEscuro)
                    Text(Copy.promessaDeCompraUnica)
                        .font(.footnote)
                        .foregroundStyle(Paleta.textoSecundario)
                }
                .multilineTextAlignment(.center)

                if let mensagem {
                    Text(mensagem)
                        .font(.footnote)
                        .foregroundStyle(corDaMensagem)
                        .multilineTextAlignment(.center)
                        .shakeDeErro(disparo: disparoDoShake)
                }

                botaoDeCompra

                Button(Copy.botaoRestaurar) { restaurar() }
                    .font(.subheadline)
                    .disabled(restaurando)

                Spacer(minLength: 8)
            }
            .padding(.horizontal, Metrica.margemLateral)
            .padding(.bottom, 20)
        }
        .background(Paleta.fundoTela)
        .task {
            // Se o produto falhou na abertura do app, esta é a hora natural de tentar
            // de novo — o usuário acabou de demonstrar interesse em comprar.
            if entitlement.produto == nil { await entitlement.carregarProduto() }
        }
        .navigationTitle("Dividir a conta")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fechar") { fechar() }
            }
        }
    }

    /// Botão de compra, em três situações bem diferentes.
    ///
    /// A terceira — **o produto não carregou** — é a que importa aqui: acontece com o
    /// aparelho offline, com o produto ainda não aprovado na loja ou num build sem
    /// configuração de StoreKit. Antes ela virava um botão cinza sem explicação nenhuma,
    /// e o usuário ficava preso no paywall sem saber por quê. Agora ela se explica e
    /// oferece uma segunda tentativa.
    @ViewBuilder
    private var botaoDeCompra: some View {
        if entitlement.produto == nil && !entitlement.carregandoProduto {
            VStack(spacing: 10) {
                Text("Não consegui falar com a App Store agora. Confere a conexão e tenta de novo.")
                    .font(.footnote)
                    .foregroundStyle(Paleta.atencao)
                    .multilineTextAlignment(.center)

                Button("Tentar de novo") {
                    Task { await entitlement.carregarProduto() }
                }
                .buttonStyle(BotaoPrincipal())
            }
        } else {
            Button {
                comprar()
            } label: {
                if entitlement.comprando || entitlement.carregandoProduto {
                    ProgressView().tint(.white)
                } else if let produto = entitlement.produto {
                    // Preço direto do StoreKit — nunca escrito no código (regra 11.16.6).
                    Text("Liberar por \(produto.displayPrice)")
                } else {
                    // Enquanto carrega, o rótulo vai sem preço em vez de inventar um:
                    // preço errado no botão é pior que nenhum preço.
                    Text("Liberar")
                }
            }
            .buttonStyle(BotaoPrincipal())
            .disabled(entitlement.comprando || entitlement.produto == nil)
        }
    }

    // MARK: - Ações

    private func comprar() {
        mensagem = nil
        Task {
            switch await entitlement.comprar() {
            case .comprou:
                // Critério 8.10: cai direto na tela de conta, sem passo intermediário.
                fechar()
            case .cancelou:
                // Cancelamento volta ao paywall **sem mensagem de erro** (épico 8.10).
                break
            case .pendente:
                corDaMensagem = Paleta.atencao
                mensagem = "A compra ficou pendente de aprovação. Assim que liberar, a conta abre sozinha."
            case .falhou:
                corDaMensagem = Paleta.erro
                mensagem = Copy.falhaNaCompra
                disparoDoShake += 1
            }
        }
    }

    private func restaurar() {
        mensagem = nil
        restaurando = true
        Task {
            switch await entitlement.restaurar() {
            case .restaurou:
                corDaMensagem = Paleta.limaoVerde
                mensagem = Copy.restauracaoComSucesso
                try? await Task.sleep(for: .seconds(1))
                fechar()
            case .nadaEncontrado:
                // Não é erro (épico 8.10): é informação, e sai na cor de atenção.
                corDaMensagem = Paleta.atencao
                mensagem = Copy.restauracaoSemCompra
            case .falhou:
                corDaMensagem = Paleta.erro
                mensagem = Copy.falhaNaCompra
                disparoDoShake += 1
            }
            restaurando = false
        }
    }
}
