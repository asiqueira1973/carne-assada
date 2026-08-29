import SwiftUI
import SwiftData

/// Tela 10.7 — Conta do churrasco.
///
/// **Toda a área de conta fica atrás do paywall** (regra 11.16.2), inclusive o lançamento
/// manual: se o manual fosse grátis, o usuário digitaria os itens à mão e a feature paga
/// perderia o sentido (assunção 24.11).
///
/// Regra 11.16.4: enquanto o entitlement é `desconhecido`, esta tela mostra **carregamento**
/// — não paywall e não a feature liberada. Nunca assuma "não comprado" por falta de resposta.
struct ContaView: View {

    @Bindable var evento: churrasco

    @Environment(\.modelContext) private var contexto
    @Environment(EntitlementService.self) private var entitlement
    @Environment(ModelAvailabilityService.self) private var disponibilidade

    @State private var capturandoNota = false
    @State private var lancandoManual = false
    @State private var abrindoPaywall = false

    private var itensConfirmados: [item_compra] {
        evento.compras.flatMap(\.itens).filter(\.entra_no_rateio)
    }

    private var total: Decimal {
        itensConfirmados.reduce(Decimal(0)) { $0 + ($1.valor_total ?? 0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Paleta.fundoTela.ignoresSafeArea()

                switch entitlement.estado {
                case .desconhecido:
                    carregando
                case .naoComprado:
                    bloqueada
                case .comprado:
                    liberada
                }
            }
            .navigationTitle("A conta")
            .sheet(isPresented: $capturandoNota) {
                CapturarNotaView(evento: evento)
            }
            .sheet(isPresented: $lancandoManual) {
                LancamentoManualView(evento: evento)
            }
            .sheet(isPresented: $abrindoPaywall) {
                NavigationStack { PaywallView() }
            }
        }
    }

    // MARK: - Estado desconhecido (11.16.4)

    private var carregando: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large).tint(Paleta.brasaLaranja)
            Text("Um segundo…").estiloLegenda()
        }
        .accessibilityLabel("Carregando")
    }

    // MARK: - Bloqueada

    /// O cadeado aparece **desde o início**, não só no momento do toque — mitigação do
    /// risco 23.9 (ninguém pode descobrir o paywall com a nota amassada na mão).
    private var bloqueada: some View {
        VStack(spacing: 22) {
            Spacer()
            Ilustracao(asset: .notaEtelefone, altura: 190)

            VStack(spacing: 8) {
                Text(Copy.tituloDoPaywall)
                    .font(.title2.bold())
                    .foregroundStyle(Paleta.carvaoEscuro)
                Text(Copy.subtituloDoPaywall)
                    .font(.body)
                    .foregroundStyle(Paleta.textoSecundario)
            }
            .multilineTextAlignment(.center)

            Spacer()

            // Regra 11.16.3: nada do que ele já cadastrou some por não ter comprado.
            Text("Tudo que você já cadastrou continua aqui.")
                .estiloLegenda()

            Button("Ver o que a compra libera") { abrindoPaywall = true }
                .buttonStyle(BotaoPrincipal())
        }
        .padding(.horizontal, Metrica.margemLateral)
        .padding(.bottom, 14)
    }

    // MARK: - Liberada

    private var liberada: some View {
        VStack(spacing: 0) {
            if evento.compras.isEmpty {
                semCompras
            } else {
                comCompras
            }
        }
    }

    private var semCompras: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(Paleta.fundoCartao).frame(width: 250, height: 250)
                Ilustracao(asset: .notaEtelefone, altura: 190)
            }
            Text(Copy.semItensParaRatear)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Paleta.carvaoEscuro)
                .multilineTextAlignment(.center)
            Spacer()
            botoesDeEntrada
        }
        .padding(.horizontal, Metrica.margemLateral)
        .padding(.bottom, 14)
    }

    private var comCompras: some View {
        VStack(spacing: 0) {
            List {
                ForEach(evento.compras.sorted { $0.criado_em < $1.criado_em }) { nota in
                    ZStack {
                        CartaoDeCompra(nota: nota)
                        NavigationLink {
                            RevisarItensView(nota: nota, evento: evento)
                        } label: { EmptyView() }
                            .opacity(0)
                    }
                    .modifier(LinhaSemFundo())
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { remover(nota) } label: {
                            Label("Excluir", systemImage: "trash")
                        }
                    }
                }

                HStack {
                    Text("Total").font(.headline)
                    Spacer()
                    Text(Formatacao.moeda(total)).estiloValor()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .cartao()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Total, \(Formatacao.moeda(total))")
                .modifier(LinhaSemFundo())
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            VStack(spacing: 10) {
                botoesDeEntrada

                NavigationLink {
                    ResultadoView(evento: evento)
                } label: {
                    Text("Fechar a conta")
                }
                .buttonStyle(BotaoPrincipal())
                // Exceção 9.2.4: sem item confirmado, fechar a conta fica indisponível.
                .disabled(itensConfirmados.isEmpty)
            }
            .padding(.horizontal, Metrica.margemLateral)
            .padding(.bottom, 4)
        }
    }

    /// Os dois caminhos de entrada de compra. Regra 11.9: com o modelo indisponível o botão
    /// de foto **some** — não fica desabilitado — e sobra o lançamento manual, com a copy 15.7.
    private var botoesDeEntrada: some View {
        VStack(spacing: 10) {
            if disponibilidade.podeUsarIA {
                Button {
                    capturandoNota = true
                } label: {
                    Label("Ler a nota por foto", systemImage: "camera.fill")
                }
                .buttonStyle(BotaoPrincipal())
            } else {
                Aviso(texto: Copy.modeloIndisponivel, cor: Paleta.brasaLaranja)
            }

            Button("Lançar itens à mão") { lancandoManual = true }
                .font(.subheadline)
        }
    }

    private func remover(_ nota: compra) {
        contexto.delete(nota)
        try? contexto.save()
    }
}

// MARK: - Card de uma nota

private struct CartaoDeCompra: View {
    let nota: compra

    private var somaConfirmada: Decimal {
        nota.itens.filter(\.entra_no_rateio).reduce(Decimal(0)) { $0 + ($1.valor_total ?? 0) }
    }

    private var pendentes: Int { nota.itens.filter { $0.confirmado && $0.pendente }.count }
    private var naoConfirmados: Int { nota.itens.filter { !$0.confirmado }.count }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(nota.estabelecimento ?? "Compra")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Paleta.carvaoEscuro)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(Formatacao.moeda(somaConfirmada)).estiloValor()
                }

                HStack(spacing: 8) {
                    Text("\(nota.itens.count) itens · \(Formatacao.dataPorExtenso(nota.data_compra))")
                        .estiloLegenda()
                    if naoConfirmados > 0 {
                        Chip(texto: "\(naoConfirmados) a conferir", cor: Paleta.atencao)
                    } else if pendentes > 0 {
                        Chip(texto: "\(pendentes) sem valor", cor: Paleta.atencao)
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Paleta.textoSecundario)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(minHeight: Metrica.toqueMinimo)
        .cartao()
        .accessibilityElement(children: .combine)
    }
}
