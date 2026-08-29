import SwiftUI
import SwiftData

/// Tela 10.9 — Revisar itens da nota.
///
/// É a tela que faz valer o princípio 0.1: o modelo sugere, o humano confirma. Um card por
/// item, com descrição, valor e categoria **editáveis ali mesmo**.

// MARK: - Revisão logo após a leitura (ainda não gravado)

/// Mostra o que o modelo leu **sem ter gravado nada**. Só "Confirmar todos" grava.
struct RevisaoDaLeitura: View {

    let lida: NotaLida
    let evento: churrasco
    let aoConcluir: () -> Void

    @Environment(\.modelContext) private var contexto

    /// Rascunho editável. Vive em memória até a confirmação — princípio 0.1.
    @State private var rascunho: [ItemRascunho] = []
    @State private var carregou = false

    struct ItemRascunho: Identifiable {
        let id = UUID()
        var descricao: String
        var valorTexto: String
        var categoria: categoria_rateio

        var valor: Decimal? {
            let limpo = valorTexto.trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
            guard !limpo.isEmpty, let d = Decimal(string: limpo), d >= 0 else { return nil }
            return d
        }
    }

    private var soma: Decimal {
        rascunho.compactMap(\.valor).reduce(Decimal(0), +)
    }

    /// Regra 11.10.1: divergência acima de R$ 0,05 avisa, mas **não bloqueia**.
    private var divergente: Bool {
        guard let total = lida.valorTotal else { return false }
        let diferenca = abs(total - soma)
        return diferenca > Decimal(string: "0.05")!
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: Metrica.entreCartoes) {
                    if let estabelecimento = lida.estabelecimento {
                        HStack {
                            Text(estabelecimento)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Paleta.carvaoEscuro)
                            Spacer()
                            if let total = lida.valorTotal {
                                Text("Nota: \(Formatacao.moeda(total))").estiloLegenda()
                            }
                        }
                        .padding(.horizontal, 18).padding(.vertical, 14)
                        .cartao()
                    }

                    if divergente {
                        Aviso(texto: Copy.divergenciaDeTotal)
                    }

                    ForEach($rascunho) { $item in
                        CardDeItemEditavel(
                            descricao: $item.descricao,
                            valorTexto: $item.valorTexto,
                            categoria: $item.categoria,
                            pendente: item.valor == nil,
                            aoRemover: { rascunho.removeAll { $0.id == item.id } }
                        )
                    }

                    Button {
                        rascunho.append(.init(descricao: "", valorTexto: "", categoria: .geral))
                    } label: {
                        Label("Adicionar item", systemImage: "plus")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .cartao()
                }
                .padding(.horizontal, Metrica.margemLateral)
                .padding(.vertical, 8)
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Soma dos itens").font(.subheadline)
                    Spacer()
                    Text(Formatacao.moeda(soma)).estiloValor()
                }
                Button("Confirmar todos") { confirmar() }
                    .buttonStyle(BotaoPrincipal())
                    .disabled(rascunho.isEmpty)
            }
            .padding(.horizontal, Metrica.margemLateral)
            .padding(.bottom, 4)
        }
        .onAppear {
            guard !carregou else { return }
            carregou = true
            rascunho = lida.itens.map {
                ItemRascunho(
                    descricao: $0.descricao,
                    // Valor ilegível vem **em branco**, nunca estimado (regra 11.10.2).
                    valorTexto: $0.valor.map(Formatacao.numeroMonetario) ?? "",
                    categoria: $0.categoria
                )
            }
        }
    }

    /// Grava a compra e os itens, todos com `confirmado = true` (princípio 0.1).
    private func confirmar() {
        let nota = compra(
            estabelecimento: lida.estabelecimento,
            data_compra: lida.dataCompra ?? Date(),
            valor_total_informado: lida.valorTotal,
            origem: .extraido
        )
        nota.evento = evento
        contexto.insert(nota)

        for (indice, item) in rascunho.enumerated() {
            let descricao = item.descricao.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !descricao.isEmpty else { continue }
            let gravado = item_compra(
                descricao: descricao,
                valor_total: item.valor,
                categoria: item.categoria,
                // A revisão aconteceu: é isto que vira `true` (regra 11.11).
                confirmado: true,
                origem: .extraido,
                ordem: indice
            )
            gravado.nota = nota
            contexto.insert(gravado)
        }

        // Seção 12: confirmar a primeira nota leva o churrasco a `fechando_conta`.
        evento.irPara(.fechando_conta)
        try? contexto.save()
        aoConcluir()
    }
}

// MARK: - Revisão de uma nota já gravada

/// Reabre uma compra existente para editar itens, valores e categorias.
struct RevisarItensView: View {

    @Bindable var nota: compra
    let evento: churrasco

    @Environment(\.modelContext) private var contexto

    private var soma: Decimal {
        nota.itens.filter(\.entra_no_rateio).reduce(Decimal(0)) { $0 + ($1.valor_total ?? 0) }
    }

    private var divergente: Bool {
        guard let total = nota.valor_total_informado else { return false }
        return abs(total - soma) > Decimal(string: "0.05")!
    }

    var body: some View {
        ZStack {
            Paleta.fundoTela.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: Metrica.entreCartoes) {
                        if divergente { Aviso(texto: Copy.divergenciaDeTotal) }

                        ForEach(nota.itens.sorted { $0.ordem < $1.ordem }) { item in
                            CardDeItemGravado(item: item, evento: evento)
                        }

                        Button {
                            adicionarItem()
                        } label: {
                            Label("Adicionar item", systemImage: "plus")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .cartao()
                    }
                    .padding(.horizontal, Metrica.margemLateral)
                    .padding(.vertical, 8)
                }

                HStack {
                    Text("Soma dos itens").font(.subheadline)
                    Spacer()
                    Text(Formatacao.moeda(soma)).estiloValor()
                }
                .padding(.horizontal, Metrica.margemLateral)
                .padding(.bottom, 10)
            }
        }
        .navigationTitle(nota.estabelecimento ?? Copy.tituloRevisaoDaNota)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func adicionarItem() {
        let novo = item_compra(descricao: "", valor_total: nil, categoria: .geral,
                               confirmado: true, origem: .manual, ordem: nota.itens.count)
        novo.nota = nota
        contexto.insert(novo)
        try? contexto.save()
    }
}

// MARK: - Cards

/// Card de item ainda não gravado (rascunho da revisão pós-leitura).
private struct CardDeItemEditavel: View {
    @Binding var descricao: String
    @Binding var valorTexto: String
    @Binding var categoria: categoria_rateio
    let pendente: Bool
    let aoRemover: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LinhaDeDescricao(descricao: $descricao, pendente: pendente, aoRemover: aoRemover)
            Divider()
            LinhaDeValor(valorTexto: $valorTexto)
            Divider()
            LinhaDeCategoria(categoria: $categoria)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .cartao()
        .overlay(alignment: .leading) {
            if pendente {
                Rectangle().fill(Paleta.atencao)
                    .frame(width: 4)
                    .clipShape(.rect(topLeadingRadius: Metrica.cantoCartao,
                                     bottomLeadingRadius: Metrica.cantoCartao))
            }
        }
    }
}

/// Card de item já no store. Edita direto na entidade — cada toque é uma gravação.
private struct CardDeItemGravado: View {
    @Bindable var item: item_compra
    let evento: churrasco

    @Environment(\.modelContext) private var contexto
    @State private var valorTexto = ""
    @State private var abrindoAtribuicao = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LinhaDeDescricao(descricao: $item.descricao, pendente: item.pendente) {
                contexto.delete(item)
                try? contexto.save()
            }
            Divider()
            LinhaDeValor(valorTexto: $valorTexto)
                .onChange(of: valorTexto) { _, novo in gravarValor(novo) }
            Divider()
            LinhaDeCategoria(categoria: $item.categoria)
            Divider()

            // Regra 11.5: sem atribuição, o item segue a categoria. Com atribuição,
            // divide igualmente só entre os marcados.
            Button {
                abrindoAtribuicao = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.2")
                    Text(item.atribuicoes.isEmpty
                         ? "Quem consumiu?"
                         : "\(item.atribuicoes.count) marcado(s)")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Paleta.textoSecundario)
                }
                .font(.subheadline)
                .frame(minHeight: Metrica.toqueMinimo)
                .contentShape(.rect)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .cartao()
        .onAppear {
            valorTexto = item.valor_total.map(Formatacao.numeroMonetario) ?? ""
        }
        .sheet(isPresented: $abrindoAtribuicao) {
            QuemConsumiuView(item: item, evento: evento)
        }
    }

    /// Grava o valor digitado. Campo em branco volta a `nil` — o item vira pendente de
    /// novo e sai do rateio, em vez de virar R$ 0,00 e entrar como se fosse de graça.
    private func gravarValor(_ texto: String) {
        let limpo = texto.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
        if limpo.isEmpty {
            item.valor_total = nil
        } else if let valor = Decimal(string: limpo), valor >= 0 {
            item.valor_total = valor
        }
        try? contexto.save()
    }
}

// MARK: - Linhas do card de item

/// As três linhas do card de item de compra.
///
/// Elas existem separadas, empilhadas com divisor e com **altura mínima de toque**, porque
/// a versão anterior punha valor e categoria lado a lado num `HStack`: o `Picker` não tinha
/// largura para o rótulo, quebrava "Quem come" em quatro linhas verticais, e as linhas do
/// card acabavam se sobrepondo. Uma informação por linha resolve, e de quebra cada campo
/// passa a respeitar os 44 pt do requisito 17.6.

private struct LinhaDeDescricao: View {
    @Binding var descricao: String
    let pendente: Bool
    let aoRemover: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("Descrição do item", text: $descricao)
                .font(.body)

            // Item pendente é marcado **visualmente**, e nunca recebe valor estimado
            // (regra 11.10.2). Fica de fora do rateio até alguém digitar o número.
            if pendente {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Paleta.atencao)
                    .accessibilityLabel("Sem valor")
            }

            Button(role: .destructive, action: aoRemover) {
                Image(systemName: "trash")
                    .frame(width: 32, height: Metrica.toqueMinimo)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Paleta.erro)
            .accessibilityLabel("Remover item")
        }
        .frame(minHeight: Metrica.toqueMinimo)
    }
}

private struct LinhaDeValor: View {
    @Binding var valorTexto: String

    var body: some View {
        HStack(spacing: 12) {
            Text("Valor").font(.subheadline).foregroundStyle(Paleta.textoSecundario)
            Spacer()
            Text("R$").estiloLegenda()
            TextField("0,00", text: $valorTexto)
                .keyboardType(.decimalPad)
                .font(.body.monospacedDigit())
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 110)
        }
        .frame(minHeight: Metrica.toqueMinimo)
    }
}

private struct LinhaDeCategoria: View {
    @Binding var categoria: categoria_rateio

    var body: some View {
        HStack(spacing: 12) {
            Text("Divide entre").font(.subheadline).foregroundStyle(Paleta.textoSecundario)
            Spacer()
            Picker("Divide entre", selection: $categoria) {
                ForEach(categoria_rateio.allCases, id: \.self) {
                    Text($0.rotulo).tag($0)
                }
            }
            .labelsHidden()
            // `fixedSize` impede o rótulo do menu de quebrar em linhas verticais quando
            // o espaço aperta — era exatamente o que deformava o card.
            .fixedSize()
            .tint(categoria.cor)
        }
        .frame(minHeight: Metrica.toqueMinimo)
    }
}

// MARK: - Lançamento manual (regra 11.16.2: também é feature paga)

/// Cria uma compra do zero, sem foto. Fica atrás do paywall junto com o resto da área
/// de conta — senão o usuário digitaria os itens à mão e a feature paga perderia sentido.
struct LancamentoManualView: View {

    let evento: churrasco

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var fechar

    @State private var estabelecimento = ""
    @State private var data = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Mercado (opcional)", text: $estabelecimento)
                    DatePicker("Data da compra", selection: $data, displayedComponents: .date)
                } footer: {
                    Text("Depois de criar, você adiciona os itens um a um.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Paleta.fundoTela)
            .navigationTitle("Lançar à mão")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { fechar() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Criar") { criar() }
                }
            }
        }
    }

    private func criar() {
        let limpo = estabelecimento.trimmingCharacters(in: .whitespacesAndNewlines)
        let nota = compra(estabelecimento: limpo.isEmpty ? nil : limpo,
                          data_compra: data, origem: .manual)
        nota.evento = evento
        contexto.insert(nota)
        evento.irPara(.fechando_conta)
        try? contexto.save()
        fechar()
    }
}
