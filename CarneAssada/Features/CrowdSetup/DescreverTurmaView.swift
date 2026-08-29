import SwiftUI
import SwiftData

/// Telas 10.3 e 10.4 — Descrever a turma e ajustar os parâmetros.
///
/// Épico 8.2. O ponto inteiro desta tela é o princípio 0.1: o modelo extrai, o usuário
/// confirma. **Nenhum valor extraído é gravado sem o toque em "Confirmar".**
struct DescreverTurmaView: View {

    @Bindable var evento: churrasco

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var fechar
    @Environment(ModelAvailabilityService.self) private var disponibilidade

    /// Etapas da tela. Com o modelo indisponível o usuário entra direto em `.parametros`
    /// e o campo de texto livre nem aparece (regra 11.9).
    private enum Etapa { case descrever, processando, parametros }

    @State private var etapa: Etapa = .descrever
    @State private var texto = ""
    @State private var parametros = ParametrosTurma()
    @State private var mensagemDeErro: String?
    @State private var disparoDoShake = 0
    @State private var tarefa: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                Paleta.fundoTela.ignoresSafeArea()

                switch etapa {
                case .descrever: telaDeDescricao
                case .processando: telaDeProcessamento
                case .parametros: telaDeParametros
                }
            }
            .navigationTitle("A turma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { tarefa?.cancel(); fechar() }
                }
            }
            .onAppear(perform: preparar)
            .onDisappear { tarefa?.cancel() }
        }
    }

    // MARK: - 10.3 Descrever a turma

    private var telaDeDescricao: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                TextEditor(text: $texto)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 130)
                    .padding(12)
                    .cartao()
                    .overlay(alignment: .topLeading) {
                        if texto.isEmpty {
                            Text(Copy.placeholderTextoLivre)
                                .font(.body)
                                .foregroundStyle(Paleta.textoSecundario)
                                .padding(.horizontal, 17)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                    }
                    .accessibilityLabel("Descreva a turma")

                Text(Copy.exemploTextoLivre).estiloLegenda()
            }

            if let mensagemDeErro {
                Text(mensagemDeErro)
                    .font(.footnote)
                    .foregroundStyle(Paleta.atencao)
                    .shakeDeErro(disparo: disparoDoShake)
            }

            Spacer()

            Button(Copy.botaoCalcular) { calcular() }
                .buttonStyle(BotaoPrincipal())
                .disabled(texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button("Prefiro digitar os números") {
                withAnimation(.easeInOut(duration: 0.2)) { etapa = .parametros }
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, minHeight: Metrica.toqueMinimo)
            .contentShape(.rect)
        }
        .padding(Metrica.margemLateral)
    }

    // MARK: - Processando (16.5.1)

    private var telaDeProcessamento: some View {
        VStack(spacing: 20) {
            Spacer()
            ChamaAnimada()
            Text("Montando a lista…")
                .font(.headline)
                .foregroundStyle(Paleta.carvaoEscuro)
            Spacer()
            // Requisito 17.2: acima de 4 s, o caminho manual precisa estar à mão.
            Button("Cancelar e digitar à mão") {
                tarefa?.cancel()
                etapa = .parametros
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, minHeight: Metrica.toqueMinimo)
            .contentShape(.rect)
        }
        .padding(Metrica.margemLateral)
    }

    // MARK: - 10.4 Parâmetros da turma

    private var telaDeParametros: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Metrica.entreCartoes) {
                    if !disponibilidade.podeUsarIA {
                        // Copy 15.7: o app não explica que a Apple Intelligence está
                        // desligada. Ele só oferece o caminho manual, sem drama.
                        Aviso(texto: Copy.modeloIndisponivel, cor: Paleta.brasaLaranja)
                    }

                    StepperDeParametro(titulo: "Adultos", valor: $parametros.adultos,
                                       faixa: 0...200)
                    StepperDeParametro(titulo: "Crianças", valor: $parametros.criancas,
                                       faixa: 0...100,
                                       legenda: "Até uns 12 anos. Paga meia na carne.")
                    StepperDeParametro(titulo: "Não comem carne",
                                       valor: $parametros.vegetarianos,
                                       faixa: 0...max(parametros.adultos, 0),
                                       legenda: "Faz parte dos adultos, não soma a eles.")
                    StepperDeParametro(titulo: "Não bebem álcool",
                                       valor: $parametros.naoBebemAlcool,
                                       faixa: 0...max(parametros.adultos, 0),
                                       legenda: "Faz parte dos adultos, não soma a eles.")
                    StepperDeParametro(titulo: "Duração", valor: $parametros.duracaoHoras,
                                       faixa: 1...24, sufixo: "h",
                                       legenda: "Churrasco mais longo pede mais bebida e mais carvão.")

                    Toggle(isOn: $parametros.incluiCarneSuina) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Vai ter carne suína").font(.body)
                            Text("Costelinha, pernil, linguiça de porco.").estiloLegenda()
                        }
                    }
                    .tint(Paleta.brasaLaranja)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .cartao()
                }
                .padding(.horizontal, Metrica.margemLateral)
                .padding(.top, 8)
            }

            Button("Confirmar") { confirmar() }
                .buttonStyle(BotaoPrincipal())
                .padding(Metrica.margemLateral)
        }
    }

    // MARK: - Ações

    /// Carrega o estado inicial. Regra 11.9: com o modelo indisponível o campo de texto
    /// livre **não aparece** — o usuário vai direto para os steppers.
    private func preparar() {
        parametros = ParametrosTurma(
            adultos: evento.qtd_adultos,
            criancas: evento.qtd_criancas,
            vegetarianos: evento.qtd_vegetarianos,
            naoBebemAlcool: evento.qtd_nao_bebem_alcool,
            duracaoHoras: evento.duracao_horas,
            incluiCarneSuina: evento.inclui_carne_suina
        )
        texto = evento.descricao_livre ?? ""
        if !disponibilidade.podeUsarIA { etapa = .parametros }
    }

    /// Chama o extrator e leva o resultado para os steppers — **sem gravar** (princípio 0.1).
    private func calcular() {
        mensagemDeErro = nil
        etapa = .processando
        tarefa = Task {
            do {
                let extraido = try await CrowdParameterExtractor().extrair(de: texto)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    // O toggle de suíno é escolha do usuário, não do modelo: preserva.
                    var novo = extraido
                    novo.incluiCarneSuina = parametros.incluiCarneSuina
                    parametros = novo
                    withAnimation(.easeInOut(duration: 0.2)) { etapa = .parametros }
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    // Copy 15.8: o usuário fica na tela, com o texto digitado preservado.
                    mensagemDeErro = Copy.erroNaExtracao
                    disparoDoShake += 1
                    etapa = .descrever
                }
            }
        }
    }

    /// Grava os parâmetros e regera a lista de compras (épicos 8.2 e 8.3).
    private func confirmar() {
        let (p, _) = parametros.comClamp()
        evento.qtd_adultos = p.adultos
        evento.qtd_criancas = p.criancas
        evento.qtd_vegetarianos = p.vegetarianos
        evento.qtd_nao_bebem_alcool = p.naoBebemAlcool
        evento.duracao_horas = p.duracaoHoras
        evento.inclui_carne_suina = p.incluiCarneSuina
        // 7.2: `descricao_livre` guarda o texto original para auditoria da extração.
        let limpo = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        evento.descricao_livre = limpo.isEmpty ? nil : limpo
        evento.origem_parametros = limpo.isEmpty ? .manual : .extraido
        evento.atualizado_em = Date()

        let ajuste = ListaService.ajusteAplicavel(para: evento, contexto: contexto)
        ListaService.regerar(evento, ajuste: ajuste, contexto: contexto)
        try? contexto.save()
        fechar()
    }
}

// MARK: - Componentes

/// Um parâmetro da turma em stepper. Nunca digitação: a tela 10.4 é para o polegar.
private struct StepperDeParametro: View {
    let titulo: String
    @Binding var valor: Int
    let faixa: ClosedRange<Int>
    var sufixo: String = ""
    var legenda: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Stepper(value: $valor, in: faixa) {
                HStack {
                    Text(titulo).font(.body)
                    Spacer()
                    Text("\(valor)\(sufixo)")
                        .font(.body.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Paleta.brasaLaranja)
                }
            }
            if let legenda { Text(legenda).estiloLegenda() }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(minHeight: Metrica.toqueMinimo)
        .cartao()
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(valor)")
    }
}

/// Faixa de aviso não bloqueante, usada para as copies 15.7, 15.9, 15.11 e 15.14.
struct Aviso: View {
    let texto: String
    var cor: Color = Paleta.atencao
    var icone: String = "info.circle.fill"

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icone)
                .foregroundStyle(cor)
            Text(texto)
                .font(.footnote)
                .foregroundStyle(Paleta.carvaoEscuro)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(cor.opacity(0.12), in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}
