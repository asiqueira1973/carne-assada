import SwiftUI
import SwiftData

/// Tela 10.5 — Lista de compras.
///
/// Épico 8.3. A lista é gerada pelas tabelas da regra 11.1 em Swift puro (princípio 0.2) e
/// é inteiramente editável: nome, quantidade e unidade de qualquer item, e remoção por swipe.
struct ListaDeComprasView: View {

    @Bindable var evento: churrasco
    let irParaMercado: () -> Void

    @Environment(\.modelContext) private var contexto

    @State private var editandoTurma = false
    @State private var itemEmEdicao: item_lista?
    @State private var adicionandoItem = false
    @State private var mostrarAvisoDeRecalculo = false
    /// Guardado antes de abrir a tela da turma, para distinguir "gerou" de "regerou".
    @State private var tinhaListaAntes = false
    /// A dica de uso da lista some para sempre depois do primeiro "Entendi".
    @AppStorage("dica_lista_vista") private var dicaJaVista = false

    private var mostrarDica: Bool { !dicaJaVista && !evento.itens_lista.isEmpty }

    /// Ajuste histórico em vigor (regra 11.14). Quando existe, a lista mostra a copy 15.14
    /// e o usuário pode desligar com um toque.
    private var ajusteAtivo: AjusteConsumo? {
        ListaService.ajusteAplicavel(para: evento, contexto: contexto)
    }

    private var grupos: [(categoria_lista, [item_lista])] {
        ListaService.porCategoria(evento.itens_lista)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Paleta.fundoTela.ignoresSafeArea()

                if evento.itens_lista.isEmpty {
                    estadoVazio
                } else {
                    conteudo
                }
            }
            .navigationTitle("Lista de compras")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { adicionandoItem = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Adicionar item")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { abrirTurma() } label: { Image(systemName: "person.2") }
                        .accessibilityLabel("Ajustar a turma")
                }
            }
            .sheet(isPresented: $editandoTurma) {
                DescreverTurmaView(evento: evento)
                    .onDisappear {
                        // Copy 15.9 só faz sentido quando já existia uma lista antes:
                        // na primeira geração não há nada sendo recalculado, e o aviso
                        // viraria ruído logo na tela mais importante do fluxo.
                        if tinhaListaAntes {
                            withAnimation { mostrarAvisoDeRecalculo = true }
                        }
                    }
            }
            .sheet(item: $itemEmEdicao) { EditarItemView(item: $0) }
            .sheet(isPresented: $adicionandoItem) { EditarItemView(item: nil, evento: evento) }
        }
    }

    // MARK: - Estado vazio

    private var estadoVazio: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(Paleta.fundoCartao).frame(width: 260, height: 260)
                Ilustracao(asset: .tabuaDeCarnes, altura: 200)
            }
            Text("A lista sai assim que você contar quem vai.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Paleta.carvaoEscuro)
                .multilineTextAlignment(.center)
            Spacer()
            Button("Contar a turma") { abrirTurma() }
                .buttonStyle(BotaoPrincipal())
        }
        .padding(.horizontal, Metrica.margemLateral)
        .padding(.bottom, 14)
    }

    // MARK: - Conteúdo

    /// `List` com seções: é o que dá o swipe para excluir item (critério 8.3). O visual de
    /// card vem de esconder o fundo e o separador de cada linha.
    private var conteudo: some View {
        VStack(spacing: 0) {
            List {
                if mostrarDica {
                    dicaDeUso
                }
                if mostrarAvisoDeRecalculo {
                    Aviso(texto: Copy.avisoDeRecalculo, cor: Paleta.brasaLaranja)
                        .modifier(LinhaSemFundo())
                }
                if ajusteAtivo != nil {
                    avisoDeAjusteHistorico.modifier(LinhaSemFundo())
                }

                ForEach(Array(grupos.enumerated()), id: \.element.0) { indiceGrupo, grupo in
                    secao(grupo.0, itens: grupo.1, deslocamento: indiceGrupo * 3)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            // `safeAreaInset` e não um `VStack`: assim a lista rola por baixo do botão
            // sem que o último card fique escondido atrás dele.
            .safeAreaInset(edge: .bottom) {
                Button {
                    irParaMercado()
                } label: {
                    Label("Abrir o modo mercado", systemImage: "cart.fill")
                }
                .buttonStyle(BotaoPrincipal())
                .padding(.horizontal, Metrica.margemLateral)
                .padding(.top, 6)
                .padding(.bottom, 4)
                .background(.bar)
            }
        }
    }

    /// Abre a tela da turma, lembrando se já havia lista — o aviso 15.9 depende disso.
    private func abrirTurma() {
        tinhaListaAntes = !evento.itens_lista.isEmpty
        editandoTurma = true
    }

    /// Dica de uso da lista.
    ///
    /// Toque para editar e arrastar para excluir são gestos padrão do iOS, mas **não são
    /// óbvios num card** — o usuário reconhece o padrão numa linha de tabela, não aqui.
    /// Aparece uma vez e some para sempre com um toque em "Entendi": dica que fica para
    /// sempre vira ruído em quem já aprendeu.
    private var dicaDeUso: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "hand.tap")
                .foregroundStyle(Paleta.brasaLaranja)
            VStack(alignment: .leading, spacing: 6) {
                Text("Toque num item pra mudar a quantidade. Arraste pro lado pra tirar da lista.")
                    .font(.footnote)
                    .foregroundStyle(Paleta.carvaoEscuro)
                Button("Entendi") {
                    withAnimation { dicaJaVista = true }
                }
                .font(.footnote.weight(.semibold))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Paleta.brasaLaranja.opacity(0.12), in: .rect(cornerRadius: 12))
        .modifier(LinhaSemFundo())
        .accessibilityElement(children: .combine)
    }

    /// Copy 15.14 mais o desligamento do ajuste com um toque (épico 8.9).
    private var avisoDeAjusteHistorico: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "wand.and.sparkles").foregroundStyle(Paleta.limaoVerde)
            VStack(alignment: .leading, spacing: 6) {
                Text(Copy.ajusteHistoricoAplicado)
                    .font(.footnote)
                    .foregroundStyle(Paleta.carvaoEscuro)
                Button("Usar a lista sem ajuste") {
                    evento.ajuste_historico_ligado = false
                    ListaService.regerar(evento, ajuste: nil, contexto: contexto)
                    try? contexto.save()
                }
                .font(.footnote.weight(.semibold))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Paleta.limaoVerde.opacity(0.12), in: .rect(cornerRadius: 12))
    }

    /// Uma categoria: ícone de 28 pt (16.7.5), título na cor da categoria (16.2), e os itens.
    private func secao(_ categoria: categoria_lista, itens: [item_lista],
                       deslocamento: Int) -> some View {
        Section {
            ForEach(Array(itens.enumerated()), id: \.element.id) { indice, item in
                LinhaDeItem(item: item)
                    .contentShape(.rect)
                    .onTapGesture { itemEmEdicao = item }
                    // 16.5.2: cascata de cima para baixo, 40 ms entre linhas.
                    .cascata(indice: deslocamento + indice)
                    .modifier(LinhaSemFundo())
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { remover(item) } label: {
                            Label("Excluir", systemImage: "trash")
                        }
                    }
            }
        } header: {
            HStack(spacing: 10) {
                // 16.7.7: o ícone não é tingido. Cores literais, sem `renderingMode(.template)`.
                Image(categoria.icone)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrica.iconeCategoria, height: Metrica.iconeCategoria)
                    .accessibilityHidden(true)
                Text(categoria.rotulo)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(categoria.cor)
            }
            .textCase(nil)
            .padding(.vertical, 4)
            .listRowInsets(.init(top: 8, leading: Metrica.margemLateral,
                                 bottom: 4, trailing: Metrica.margemLateral))
        }
    }

    /// Regra 11.12: item de lista é reversível por re-adição e **não** pede confirmação.
    private func remover(_ item: item_lista) {
        contexto.delete(item)
        try? contexto.save()
    }
}

// MARK: - Linha

private struct LinhaDeItem: View {
    let item: item_lista

    var body: some View {
        HStack(spacing: 12) {
            Text(item.nome)
                .font(.body)
                .foregroundStyle(Paleta.carvaoEscuro)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(Formatacao.quantidade(item.quantidade, item.unidade))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(Paleta.textoSecundario)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(minHeight: Metrica.toqueMinimo)
        .cartao()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.nome), \(Formatacao.quantidade(item.quantidade, item.unidade))")
        .accessibilityHint("Toque para editar")
    }
}

// MARK: - Edição de item (8.3: nome, quantidade e unidade são editáveis)

private struct EditarItemView: View {
    let item: item_lista?
    var evento: churrasco?

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var fechar

    @State private var nome = ""
    @State private var quantidade = ""
    @State private var unidade: unidade_medida = .unidade
    @State private var categoria: categoria_lista = .outro

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nome", text: $nome)
                HStack {
                    Text("Quantidade")
                    Spacer()
                    TextField("0", text: $quantidade)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                }
                Picker("Unidade", selection: $unidade) {
                    ForEach(unidade_medida.allCases, id: \.self) {
                        Text($0.abreviacao).tag($0)
                    }
                }
                Picker("Categoria", selection: $categoria) {
                    ForEach(categoria_lista.allCases, id: \.self) {
                        Text($0.rotulo).tag($0)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Paleta.fundoTela)
            .navigationTitle(item == nil ? "Novo item" : "Editar item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { fechar() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { salvar() }.disabled(!valido)
                }
            }
            .onAppear(perform: carregar)
        }
    }

    /// 7.10.4: quantidade tem de ser maior que zero. Zerar equivale a excluir, e para isso
    /// existe o swipe — não faz sentido ter dois caminhos para a mesma coisa.
    private var valido: Bool {
        !nome.trimmingCharacters(in: .whitespaces).isEmpty && (decimalDigitado ?? 0) > 0
    }

    private var decimalDigitado: Decimal? {
        Decimal(string: quantidade.replacingOccurrences(of: ",", with: "."))
    }

    private func carregar() {
        guard let item else { return }
        nome = item.nome
        quantidade = Formatacao.numeroMonetario(item.quantidade)
            .replacingOccurrences(of: ",00", with: "")
        unidade = item.unidade
        categoria = item.categoria
    }

    private func salvar() {
        guard let valor = decimalDigitado, valor > 0 else { return }
        let limpo = nome.trimmingCharacters(in: .whitespaces)

        if let item {
            item.nome = limpo
            item.quantidade = valor
            item.unidade = unidade
            item.categoria = categoria
            // Item tocado pelo usuário vira `manual`: o próximo recálculo não pode
            // atropelar o que ele ajustou à mão (épico 8.3).
            item.origem = .manual
        } else if let evento {
            let novo = item_lista(categoria: categoria, nome: limpo, quantidade: valor,
                                  unidade: unidade, origem: .manual,
                                  ordem: evento.itens_lista.count)
            novo.evento = evento
            contexto.insert(novo)
        }

        try? contexto.save()
        fechar()
    }
}
