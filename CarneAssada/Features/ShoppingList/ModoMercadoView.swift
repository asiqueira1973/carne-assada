import SwiftUI
import SwiftData

/// Tela 10.6 — Modo mercado.
///
/// Épico 8.4. É o momento 2 da seção 2: em pé, carrinho na mão, com pressa e sem sinal.
/// Por isso esta é a única tela do app com densidade **alta** (16.3) — mais itens visíveis
/// de uma vez vale mais que ar entre os cards aqui.
struct ModoMercadoView: View {

    @Bindable var evento: churrasco

    @Environment(\.modelContext) private var contexto
    @Environment(\.accessibilityReduceMotion) private var reduzirMovimento

    @State private var mostrandoBrasas = false
    /// A animação de conclusão toca **uma única vez por churrasco por sessão** (8.4).
    @State private var jaComemorou = false

    private var itens: [item_lista] { evento.itens_lista }
    private var comprados: Int { itens.filter(\.comprado).count }
    private var tudoComprado: Bool { !itens.isEmpty && comprados == itens.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Paleta.fundoTela.ignoresSafeArea()

                if itens.isEmpty {
                    estadoVazio
                } else {
                    conteudo
                }

                // 16.5.4 — brasas subindo, 1,5 s, uma vez só.
                if mostrandoBrasas { BrasasSubindo() }
            }
            .navigationTitle("No mercado")
            .navigationBarTitleDisplayMode(.inline)
        }
        // Critério 8.4: a tela impede o bloqueio automático enquanto está aberta.
        // Ninguém quer destravar o celular a cada item no corredor do mercado.
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            // Seção 12: abrir o modo mercado pela primeira vez leva a `comprando`.
            if evento.irPara(.comprando) { try? contexto.save() }
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private var estadoVazio: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle().fill(Paleta.fundoCartao).frame(width: 240, height: 240)
                Ilustracao(asset: .carrinho, altura: 180)
            }
            Text("Sua lista está vazia. Volta na aba Lista pra montar ela.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Paleta.carvaoEscuro)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Metrica.margemLateral)
    }

    private var conteudo: some View {
        VStack(spacing: 0) {
            cabecalhoDeProgresso

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(ListaService.porCategoria(itens), id: \.0) { categoria, doGrupo in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 10) {
                                Image(categoria.icone)
                                    .resizable().scaledToFit()
                                    .frame(width: Metrica.iconeCategoria,
                                           height: Metrica.iconeCategoria)
                                    .accessibilityHidden(true)
                                Text(categoria.rotulo)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(categoria.cor)
                            }
                            .padding(.horizontal, 4)

                            VStack(spacing: 0) {
                                ForEach(doGrupo) { item in
                                    LinhaDeMercado(item: item) { marcar(item) }
                                    if item.id != doGrupo.last?.id {
                                        Divider().padding(.leading, 52)
                                    }
                                }
                            }
                            .cartao()
                        }
                    }
                }
                .padding(.horizontal, Metrica.margemLateral)
                .padding(.vertical, 10)
            }
        }
    }

    /// Progresso "12 de 27" — copy 15.18. Atualiza na hora e é lido pelo VoiceOver (8.4).
    private var cabecalhoDeProgresso: some View {
        VStack(spacing: 8) {
            HStack {
                Text(tudoComprado ? Copy.tudoComprado
                                  : Copy.progressoDoMercado(comprados, itens.count))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Paleta.carvaoEscuro)
                Spacer()
            }
            ProgressView(value: Double(comprados), total: Double(max(itens.count, 1)))
                .tint(Paleta.brasaLaranja)
        }
        .padding(.horizontal, Metrica.margemLateral)
        .padding(.bottom, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Copy.progressoDoMercado(comprados, itens.count))
    }

    /// Marca ou desmarca um item.
    ///
    /// Critério 8.4: marcar **não recolhe nem reordena** a lista. O item riscado fica onde
    /// está — lista que se reorganiza embaixo do polegar faz o usuário perder o lugar.
    private func marcar(_ item: item_lista) {
        withAnimation(Movimento.curva(reduzir: reduzirMovimento)) {
            item.comprado.toggle()
        }
        Haptico.leve()
        try? contexto.save()

        if tudoComprado && !jaComemorou {
            jaComemorou = true
            Haptico.sucesso()
            mostrandoBrasas = true
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.2))
                mostrandoBrasas = false
            }
        }
    }
}

// MARK: - Linha do mercado

/// Uma linha marcável. Toda a linha é área de toque, com no mínimo 44 pt de altura (8.4).
private struct LinhaDeMercado: View {
    let item: item_lista
    let aoTocar: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduzirMovimento

    var body: some View {
        Button(action: aoTocar) {
            HStack(spacing: 14) {
                Image(systemName: item.comprado ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.comprado ? Paleta.sucesso : Paleta.textoSecundario)
                    // 16.5.3: o checkmark quica ao ser marcado.
                    .symbolEffect(.bounce, value: item.comprado)

                Text(item.nome)
                    .font(.body)
                    .foregroundStyle(item.comprado ? Paleta.textoSecundario : Paleta.carvaoEscuro)
                    // 16.5.3: o texto risca ao marcar.
                    .strikethrough(item.comprado, color: Paleta.textoSecundario)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(Formatacao.quantidade(item.quantidade, item.unidade))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Paleta.textoSecundario)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: Metrica.toqueMinimo)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.nome), \(Formatacao.quantidade(item.quantidade, item.unidade))")
        .accessibilityValue(item.comprado ? "no carrinho" : "falta pegar")
        .accessibilityAddTraits(.isButton)
    }
}
