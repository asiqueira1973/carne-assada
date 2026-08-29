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

    /// Um `.sheet` só, escolhido por item.
    ///
    /// Dois `.sheet(isPresented:)` empilhados na **mesma** view é fragilidade conhecida do
    /// SwiftUI: um deles pode simplesmente não apresentar, sem erro nenhum. Com um item
    /// enumerado existe uma apresentação só, e ela sempre sabe o que mostrar.
    private enum FolhaDaConta: Identifiable {
        case camera, manual
        var id: Self { self }
    }

    @State private var folha: FolhaDaConta?

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
            .sheet(item: $folha) { qual in
                switch qual {
                case .camera: CapturarNotaView(evento: evento)
                case .manual: LancamentoManualView(evento: evento)
                }
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

    /// A aba bloqueada **é** o paywall (tela 10.16), não uma antessala dele.
    ///
    /// Antes eram duas telas dizendo a mesma coisa: a aba mostrava título, subtítulo e
    /// ilustração, e o botão abria uma folha com título, subtítulo e ilustração idênticos.
    /// Tocar parecia não fazer nada. O bloqueio acontece na entrada desta tela (regra
    /// 11.16.2), então é aqui que a compra tem de estar — a um toque, não a dois.
    ///
    /// O cadeado no ícone da aba continua aparecendo desde o início, que é a mitigação do
    /// risco 23.9: ninguém pode descobrir o paywall com a nota amassada na mão.
    private var bloqueada: some View {
        PaywallView()
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
        // A tab bar flutuante do iOS 26 passa por cima do fim do conteúdo. Sem esta
        // folga o aviso e o botão de lançamento manual ficam colados nela, e o toque erra.
        .padding(.bottom, Metrica.folgaDaTabBar)
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
            .padding(.bottom, Metrica.folgaDaTabBar)
        }
    }

    /// Os dois caminhos de entrada de compra. Regra 11.9: com o modelo indisponível o botão
    /// de foto **some** — não fica desabilitado — e sobra o lançamento manual, com a copy 15.7.
    private var botoesDeEntrada: some View {
        VStack(spacing: 10) {
            if disponibilidade.podeUsarIA {
                Button {
                    folha = .camera
                } label: {
                    Label("Ler a nota por foto", systemImage: "camera.fill")
                }
                .buttonStyle(BotaoPrincipal())
            } else {
                Aviso(texto: Copy.modeloIndisponivel, cor: Paleta.brasaLaranja)
            }

            // Botão de texto puro tem como área de toque só o retângulo das letras —
            // uns 18 pt de altura, colado na tab bar flutuante. Na prática o toque
            // errava. `frame` + `contentShape` devolvem os 44 pt do requisito 17.6.
            Button("Lançar itens à mão") { folha = .manual }
                .font(.subheadline)
                .frame(maxWidth: .infinity, minHeight: Metrica.toqueMinimo)
                .contentShape(.rect)
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
