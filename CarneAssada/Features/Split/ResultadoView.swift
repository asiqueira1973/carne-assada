import SwiftUI
import SwiftData

/// Telas 10.12 e 10.13 — Resultado do rateio e detalhe do participante.
///
/// Épicos 8.7 e 8.8. Este é o momento 3 da seção 2: se o número parecer arbitrário, o
/// organizador não manda pro grupo. Por isso cada valor abre a composição linha a linha.
struct ResultadoView: View {

    @Bindable var evento: churrasco

    @Environment(\.modelContext) private var contexto

    @State private var compartilhando = false
    @State private var valorInicial: [UUID: Decimal] = [:]

    /// O rateio é **derivado**, nunca armazenado: recalcular do zero a cada leitura é o que
    /// impede o app de exibir um valor velho depois que um toggle mudou (exceção 9.2.7).
    private var resultado: ResultadoDoRateio {
        let confirmados = evento.compras.flatMap(\.itens).filter(\.entra_no_rateio)
        let pendentes = evento.compras.flatMap(\.itens).filter { $0.confirmado && $0.pendente }

        let itens = confirmados.map { item in
            ItemParaRateio(
                id: item.id,
                descricao: item.descricao,
                valor: item.valor_total ?? 0,
                categoria: item.categoria,
                atribuidosA: item.atribuicoes.compactMap { $0.quem?.id }
            )
        }

        let pessoas = evento.participantes
            .sorted { $0.ordem < $1.ordem }
            .map {
                ParticipanteParaRateio(
                    id: $0.id, nome: $0.nome, e_crianca: $0.e_crianca,
                    come_carne: $0.come_carne, bebe_alcool: $0.bebe_alcool, ordem: $0.ordem
                )
            }

        return SplitCalculator.calcular(itens: itens, participantes: pessoas,
                                        pendentes: pendentes.count)
    }

    /// Exceção 9.2.7: se os valores mudaram depois de já ter compartilhado, avisa.
    private var valoresMudaram: Bool {
        guard evento.status == .concluido, !valorInicial.isEmpty else { return false }
        return resultado.porParticipante.contains { valorInicial[$0.id] != $0.valor }
    }

    var body: some View {
        ZStack {
            Paleta.fundoTela.ignoresSafeArea()

            if evento.participantes.isEmpty {
                // Exceção 9.2.2: não dá para ratear sem ao menos um participante.
                estadoSemParticipantes
            } else if resultado.porParticipante.isEmpty || resultado.total == 0 {
                estadoSemItens
            } else {
                conteudo
            }
        }
        .navigationTitle(Copy.tituloDoResultado)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $compartilhando) {
            CompartilharView(texto: textoParaCompartilhar) {
                // Seção 12: compartilhar o resultado conclui o churrasco.
                if evento.irPara(.concluido) { try? contexto.save() }
                valorInicial = Dictionary(
                    uniqueKeysWithValues: resultado.porParticipante.map { ($0.id, $0.valor) }
                )
            }
        }
    }

    private var estadoSemParticipantes: some View {
        VStack(spacing: 22) {
            Ilustracao(asset: .turmaDeAmigos, altura: 180)
            Text(Copy.semParticipantes)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Paleta.carvaoEscuro)
                .multilineTextAlignment(.center)
        }
        .padding(Metrica.margemLateral)
    }

    private var estadoSemItens: some View {
        VStack(spacing: 22) {
            Ilustracao(asset: .notaEtelefone, altura: 180)
            Text(Copy.semItensParaRatear)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Paleta.carvaoEscuro)
                .multilineTextAlignment(.center)
        }
        .padding(Metrica.margemLateral)
    }

    private var conteudo: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: Metrica.entreCartoes) {
                    if valoresMudaram { Aviso(texto: Copy.resultadoMudou) }

                    if resultado.itensPendentes > 0 {
                        Aviso(texto: "\(resultado.itensPendentes) item(ns) sem valor ficaram de fora da conta.")
                    }

                    HStack {
                        Text("Total").font(.headline)
                        Spacer()
                        // 16.5.5: o total conta de 0 até o valor final.
                        ValorQueConta(valor: resultado.total)
                    }
                    .padding(.horizontal, 18).padding(.vertical, 16)
                    .cartao()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Total, \(Formatacao.moeda(resultado.total))")

                    ForEach(Array(resultado.porParticipante.enumerated()), id: \.element.id) {
                        indice, pessoa in
                        NavigationLink {
                            DetalheDoParticipanteView(resultado: pessoa, total: resultado.total)
                        } label: {
                            LinhaDoResultado(pessoa: pessoa)
                        }
                        .buttonStyle(.plain)
                        // 16.5.5: cards entram em cascata.
                        .cascata(indice: indice)
                    }
                }
                .padding(.horizontal, Metrica.margemLateral)
                .padding(.vertical, 8)
            }

            Button {
                compartilhando = true
            } label: {
                Label(Copy.botaoCompartilhar, systemImage: "square.and.arrow.up")
            }
            .buttonStyle(BotaoPrincipal())
            .padding(.horizontal, Metrica.margemLateral)
            .padding(.bottom, 8)
        }
    }

    private var textoParaCompartilhar: String {
        ShareTextBuilder.montar(nome: evento.nome, data: evento.data_evento,
                                resultado: resultado)
    }
}

// MARK: - Linha do resultado

private struct LinhaDoResultado: View {
    let pessoa: ResultadoParticipante

    var body: some View {
        HStack(spacing: 14) {
            Text(pessoa.nome)
                .font(.body)
                .foregroundStyle(Paleta.carvaoEscuro)
                .frame(maxWidth: .infinity, alignment: .leading)

            ValorQueConta(valor: pessoa.valor)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Paleta.textoSecundario)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(minHeight: Metrica.toqueMinimo)
        .cartao()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pessoa.nome), \(Formatacao.moeda(pessoa.valor))")
        .accessibilityHint("Toque para ver como chegou nesse valor")
    }
}

// MARK: - 10.13 Detalhe do participante

/// Composição do valor, linha a linha, com o motivo de cada inclusão e de cada exclusão.
/// É o que torna a conta auditável (mitigação do risco 23.8).
struct DetalheDoParticipanteView: View {
    let resultado: ResultadoParticipante
    let total: Decimal

    var body: some View {
        ZStack {
            Paleta.fundoTela.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Metrica.entreCartoes) {
                    HStack {
                        Text("Total dele").font(.headline)
                        Spacer()
                        Text(Formatacao.moeda(resultado.valor)).estiloValor()
                    }
                    .padding(.horizontal, 18).padding(.vertical, 16)
                    .cartao()

                    ForEach(resultado.composicao) { linha in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(linha.titulo)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Paleta.carvaoEscuro)
                                Spacer()
                                Text(Formatacao.moeda(linha.valor))
                                    .font(.body.monospacedDigit())
                                    .foregroundStyle(linha.valor > 0
                                                     ? Paleta.carvaoEscuro
                                                     : Paleta.textoSecundario)
                            }
                            if let explicacao = linha.explicacao {
                                Text(explicacao).estiloLegenda()
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cartao()
                        .accessibilityElement(children: .combine)
                    }

                    if resultado.absorveuArredondamento {
                        // Regra 11.8: alguém precisa absorver a sobra de centavos, e o app
                        // diz quem foi em vez de deixar um número que não fecha na mão.
                        Text("Os centavos que sobraram da divisão entraram aqui, pra soma bater exatamente com o total.")
                            .estiloLegenda()
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, Metrica.margemLateral)
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(resultado.nome)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Share sheet

/// Share sheet do iOS com o texto da seção 14.1. Funciona sem rede (critério 8.8).
struct CompartilharView: UIViewControllerRepresentable {
    let texto: String
    let aoCompartilhar: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controlador = UIActivityViewController(activityItems: [texto],
                                                   applicationActivities: nil)
        controlador.completionWithItemsHandler = { _, concluiu, _, _ in
            if concluiu { aoCompartilhar() }
        }
        return controlador
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
