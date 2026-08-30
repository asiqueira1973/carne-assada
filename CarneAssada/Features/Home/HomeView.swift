import SwiftUI
import SwiftData

/// Tela 10.1 — Home / Meus churrascos.
///
/// Raiz da navegação (`NavigationStack`). Lista os churrascos por data decrescente, com
/// nome, data e total quando houver. Estado vazio com a copy 15.6.
struct HomeView: View {

    @Environment(\.modelContext) private var contexto
    @Query(sort: \churrasco.data_evento, order: .reverse) private var churrascos: [churrasco]

    @State private var criandoChurrasco = false
    @State private var abrindoAjustes = false
    @State private var churrascoParaExcluir: churrasco?
    @State private var erroAoSalvar = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Fundo chapado, **sem gradiente** (a regra 16.5.8 foi revogada na v1.5 do spec).
                Paleta.fundoTela.ignoresSafeArea()

                if churrascos.isEmpty {
                    estadoVazio
                } else {
                    lista
                }
            }
            .navigationTitle(Copy.tituloHome)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { abrindoAjustes = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Ajustes")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { criandoChurrasco = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Copy.botaoCriar)
                }
            }
            .sheet(isPresented: $criandoChurrasco) { NovoChurrascoView() }
            .sheet(isPresented: $abrindoAjustes) { AjustesView() }
            // Regra 11.12: excluir churrasco é destrutivo e exige confirmação explícita.
            .confirmationDialog(
                Copy.confirmarExclusaoDeChurrasco,
                isPresented: .init(get: { churrascoParaExcluir != nil },
                                   set: { if !$0 { churrascoParaExcluir = nil } }),
                titleVisibility: .visible
            ) {
                Button("Apagar", role: .destructive) { excluir() }
                Button("Cancelar", role: .cancel) { churrascoParaExcluir = nil }
            }
            .alert(Copy.erroAoSalvar, isPresented: $erroAoSalvar) {
                Button("Ok", role: .cancel) {}
            }
        }
    }

    // MARK: - Estado vazio (15.6)

    private var estadoVazio: some View {
        VStack(spacing: 26) {
            Spacer()

            // Regra 16.7.3: fundo circular sutil atrás da ilustração, para ela não sumir
            // sobre o fundo claro nem sobre o preto do modo escuro. A arte não é alterada.
            ZStack {
                Circle()
                    .fill(Paleta.fundoCartao)
                    .frame(width: 306, height: 306)
                Ilustracao(asset: .churrasqueira, altura: 250)
            }
            .accessibilityHidden(true)

            Text(Copy.homeVazia)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Paleta.carvaoEscuro)
                .multilineTextAlignment(.center)

            Spacer()

            Button(Copy.botaoCriar) { criandoChurrasco = true }
                .buttonStyle(BotaoPrincipal())
        }
        .padding(.horizontal, Metrica.margemLateral)
        .padding(.bottom, 14)
    }

    // MARK: - Lista

    /// `List` e não `ScrollView` + `LazyVStack`: o swipe para excluir (tela 10.1) só existe
    /// dentro de uma `List`. Fora dela, `swipeActions` é ignorado em silêncio.
    /// O visual de card vem de esconder o fundo e o separador de cada linha.
    private var lista: some View {
        List {
            ForEach(churrascos) { evento in
                ZStack {
                    CartaoDeChurrasco(evento: evento)
                    // O `NavigationLink` vazio some com o chevron do sistema, para o card
                    // continuar sendo o desenho da seção 16.3 e não uma linha de tabela.
                    NavigationLink { ChurrascoView(evento: evento) } label: { EmptyView() }
                        .opacity(0)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: Metrica.entreCartoes / 2,
                                     leading: Metrica.margemLateral,
                                     bottom: Metrica.entreCartoes / 2,
                                     trailing: Metrica.margemLateral))
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        churrascoParaExcluir = evento
                    } label: {
                        Label("Excluir", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Ações

    /// Hard delete com cascata (7.2): apagar o churrasco apaga participantes, itens de lista,
    /// compras, itens de compra, atribuições e o registro pós-evento.
    private func excluir() {
        guard let alvo = churrascoParaExcluir else { return }
        contexto.delete(alvo)
        do {
            try contexto.save()
        } catch {
            erroAoSalvar = true
        }
        churrascoParaExcluir = nil
    }
}

// MARK: - Card da lista

/// Uma linha da Home: nome, total (quando houver) e data.
private struct CartaoDeChurrasco: View {
    let evento: churrasco

    @Environment(\.dynamicTypeSize) private var tamanhoTipografico

    /// Total dos itens confirmados e com valor (regras 11.11 e 11.10.2).
    /// `nil` quando ainda não há nada fechado — e aí o card simplesmente não mostra valor,
    /// em vez de mostrar "R$ 0,00", que pareceria uma conta zerada.
    private var total: Decimal? {
        let itens = evento.compras.flatMap(\.itens).filter(\.entra_no_rateio)
        guard !itens.isEmpty else { return nil }
        return itens.reduce(Decimal(0)) { $0 + ($1.valor_total ?? 0) }
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 7) {
                // Critério 8.11: em tamanho acessível o nome e o valor empilham em vez de
                // truncar. Lado a lado, "Aniversário do Léo" viraria "Aniversar…" em AX5,
                // e nome cortado num histórico é justamente o que impede reconhecer o item.
                let layout = tamanhoTipografico.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                    : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 14))

                layout {
                    Text(evento.nome)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Paleta.carvaoEscuro)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let total {
                        Text(Formatacao.moeda(total)).estiloValor()
                    }
                }

                // O card não mostra mais o status (decisão de produto, v1.1).
                //
                // Ele era informação derivada que ninguém usava para decidir nada: o sinal
                // que importa no histórico é o total, e ele já aparece quando a conta fecha.
                // O status continua existindo no modelo e governando a máquina de estados
                // da seção 12 — só deixou de ser exibido aqui.
                Text(Formatacao.dataPorExtenso(evento.data_evento))
                    .estiloLegenda()
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
        .accessibilityLabel(
            "\(evento.nome), \(Formatacao.dataPorExtenso(evento.data_evento))"
            + (total.map { ", total \(Formatacao.moeda($0))" } ?? "")
        )
    }
}

#Preview {
    HomeView()
        .modelContainer(try! Persistencia.containerEmMemoria())
        .environment(EntitlementService())
        .environment(ModelAvailabilityService())
}
