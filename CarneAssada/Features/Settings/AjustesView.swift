import SwiftUI
import SwiftData

/// Tela 10.15 — Ajustes.
///
/// Sobre, privacidade, restaurar compra e apagar todos os dados.
/// Regra 11.16.5: "Restaurar compra" é obrigatório e fica visível **aqui e no paywall**.
struct AjustesView: View {

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var fechar
    @Environment(EntitlementService.self) private var entitlement

    @Query private var churrascos: [churrasco]

    @State private var mensagemDaRestauracao: String?
    @State private var restaurando = false
    @State private var confirmandoApagarTudo = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Compra
                Section {
                    HStack {
                        Text("Divisão da conta")
                        Spacer()
                        switch entitlement.estado {
                        case .desconhecido:
                            ProgressView()
                        case .comprado:
                            Label("Liberada", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(Paleta.limaoVerde)
                                .labelStyle(.titleAndIcon)
                        case .naoComprado:
                            Text("Bloqueada").foregroundStyle(Paleta.textoSecundario)
                        }
                    }

                    Button(Copy.botaoRestaurar) { restaurar() }
                        .disabled(restaurando)

                    if let mensagemDaRestauracao {
                        Text(mensagemDaRestauracao)
                            .font(.footnote)
                            .foregroundStyle(Paleta.textoSecundario)
                    }
                } header: {
                    Text("Compra")
                } footer: {
                    Text(Copy.promessaDeCompraUnica)
                }

#if DEBUG
                // Atalho de teste, ausente do binário de Release. Some quando o produto
                // `carne_assada_pro` existir no App Store Connect.
                Section {
                    Button(entitlement.liberado
                           ? "Trancar a conta de novo"
                           : "Liberar a conta sem comprar") {
                        entitlement.alternarLiberacaoDeTeste()
                    }
                } header: {
                    Text("Só em teste")
                } footer: {
                    Text("Atalho de desenvolvimento para exercitar o rateio sem passar pela loja. Não existe na versão publicada.")
                }
#endif

                // MARK: Privacidade
                Section {
                    Label("Nada sai deste aparelho", systemImage: "iphone")
                    Label("A foto da nota nunca é salva", systemImage: "camera.badge.ellipsis")
                    Label("Sem conta, sem login, sem rastreamento", systemImage: "hand.raised")
                } header: {
                    Text("Privacidade")
                } footer: {
                    // Seção 20.4: dito claramente, não escondido na política.
                    Text(Copy.avisoDeBackup)
                }

                // MARK: Dados
                Section {
                    HStack {
                        Text("Churrascos guardados")
                        Spacer()
                        Text("\(churrascos.count)")
                            .foregroundStyle(Paleta.textoSecundario)
                            .monospacedDigit()
                    }

                    Button("Apagar todos os dados", role: .destructive) {
                        confirmandoApagarTudo = true
                    }
                } header: {
                    Text("Dados")
                }

                // MARK: Sobre
                Section {
                    HStack {
                        Text("Versão")
                        Spacer()
                        Text(versao).foregroundStyle(Paleta.textoSecundario)
                    }
                    HStack {
                        Text("Feito por")
                        Spacer()
                        Text("Dab Lab").foregroundStyle(Paleta.textoSecundario)
                    }
                } header: {
                    Text("Sobre")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Paleta.fundoTela)
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pronto") { fechar() }
                }
            }
            // Regra 11.12: "apagar todos os dados" exige confirmação explícita.
            .confirmationDialog(Copy.apagarTodosOsDados,
                                isPresented: $confirmandoApagarTudo,
                                titleVisibility: .visible) {
                Button("Apagar tudo", role: .destructive) { apagarTudo() }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }

    private var versao: String {
        let numero = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(numero) (\(build))"
    }

    private func restaurar() {
        restaurando = true
        mensagemDaRestauracao = nil
        Task {
            switch await entitlement.restaurar() {
            case .restaurou: mensagemDaRestauracao = Copy.restauracaoComSucesso
            case .nadaEncontrado: mensagemDaRestauracao = Copy.restauracaoSemCompra
            case .falhou: mensagemDaRestauracao = Copy.falhaNaCompra
            }
            restaurando = false
        }
    }

    /// Zera o store (seção 20.5). A cascata de cada churrasco (7.2) leva junto participantes,
    /// itens, compras, atribuições e registros — não sobra órfão.
    private func apagarTudo() {
        for evento in churrascos { contexto.delete(evento) }
        try? contexto.save()
    }
}
