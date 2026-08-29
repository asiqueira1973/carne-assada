import SwiftUI
import SwiftData

/// Tela 10.14 — Como foi?
///
/// Épico 8.9. O objetivo do épico é uma frase: **o próximo churrasco erra menos que este.**
/// O texto vira ajuste percentual por categoria, aplicado só ao churrasco seguinte (11.14).
struct ComoFoiView: View {

    @Bindable var evento: churrasco

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var fechar
    @Environment(ModelAvailabilityService.self) private var disponibilidade

    @State private var texto = ""
    @State private var salvando = false

    var body: some View {
        NavigationStack {
            ZStack {
                Paleta.fundoTela.ignoresSafeArea()

                VStack(spacing: 18) {
                    Ilustracao(asset: .espetoEPrato, altura: 150)
                        .padding(.top, 8)

                    Text(Copy.posEvento)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Paleta.carvaoEscuro)
                        .multilineTextAlignment(.center)

                    TextEditor(text: $texto)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 130)
                        .padding(12)
                        .cartao()
                        .overlay(alignment: .topLeading) {
                            if texto.isEmpty {
                                Text("Ex.: sobrou muita linguiça e faltou cerveja.")
                                    .font(.body)
                                    .foregroundStyle(Paleta.textoSecundario)
                                    .padding(.horizontal, 17)
                                    .padding(.vertical, 20)
                                    .allowsHitTesting(false)
                            }
                        }
                        .accessibilityLabel("Como foi o churrasco")

                    if !disponibilidade.podeUsarIA {
                        // Modelo indisponível: o texto vira anotação e nenhum ajuste é
                        // aplicado (épico 8.9). O app diz isso, em vez de prometer o que não vai fazer.
                        Aviso(texto: "Vou guardar isso como anotação. O ajuste automático precisa da Apple Intelligence ligada.",
                              cor: Paleta.brasaLaranja)
                    }

                    Spacer()

                    Button {
                        salvar()
                    } label: {
                        if salvando { ProgressView().tint(.white) } else { Text("Salvar") }
                    }
                    .buttonStyle(BotaoPrincipal())
                    .disabled(texto.trimmingCharacters(in: .whitespaces).isEmpty || salvando)

                    Button("Agora não") { fechar() }
                        .font(.subheadline)
                }
                .padding(.horizontal, Metrica.margemLateral)
                .padding(.bottom, 14)
            }
            .navigationTitle("Como foi?")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { texto = evento.registro?.texto_livre ?? "" }
        }
    }

    /// Grava o registro. O ajuste é opcional: se o modelo falhar, o texto fica como anotação
    /// com `ajustes_json` nulo (7.8) e a lista do próximo churrasco sai na quantidade base.
    private func salvar() {
        salvando = true
        let limpo = texto.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            var json: String?
            if disponibilidade.podeUsarIA {
                json = try? await PostEventAdjustmentExtractor().extrair(de: limpo).json
            }

            await MainActor.run {
                // 7.10.6: no máximo um registro por churrasco.
                if let existente = evento.registro {
                    existente.texto_livre = limpo
                    existente.ajustes_json = json
                } else {
                    let registro = registro_pos_evento(texto_livre: limpo, ajustes_json: json)
                    registro.evento = evento
                    contexto.insert(registro)
                }
                try? contexto.save()
                salvando = false
                fechar()
            }
        }
    }
}
