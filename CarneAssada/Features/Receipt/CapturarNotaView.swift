import SwiftUI
import SwiftData
import PhotosUI

/// Telas 10.8 e 10.9 — Capturar a nota e revisar os itens extraídos.
///
/// Épico 8.5. Duas regras mandam nesta tela:
/// - **Princípio 0.1**: nenhum item é gravado antes da confirmação. O que o modelo extrai
///   entra com `confirmado = false` e só a confirmação vira `true`.
/// - **Seção 20.3**: a imagem da nota é processada **em memória** e descartada. Nunca é
///   gravada em disco, nem como cache temporário. É o dado mais sensível do app.
struct CapturarNotaView: View {

    let evento: churrasco

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var fechar

    private enum Etapa { case escolher, processando, revisar, erro }

    @State private var etapa: Etapa = .escolher
    @State private var selecaoDaGaleria: PhotosPickerItem?
    @State private var abrindoCamera = false
    @State private var lida: NotaLida?
    @State private var mensagemDeErro = ""
    @State private var tarefa: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                Paleta.fundoTela.ignoresSafeArea()

                switch etapa {
                case .escolher: telaDeEscolha
                case .processando: telaDeProcessamento
                case .erro: telaDeErro
                case .revisar:
                    if let lida {
                        RevisaoDaLeitura(lida: lida, evento: evento) { fechar() }
                    }
                }
            }
            .navigationTitle(etapa == .revisar ? Copy.tituloRevisaoDaNota : "Nota do mercado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { tarefa?.cancel(); fechar() }
                }
            }
            .fullScreenCover(isPresented: $abrindoCamera) {
                CameraPicker { imagem in processar(imagem) }
                    .ignoresSafeArea()
            }
            .onChange(of: selecaoDaGaleria) { _, novo in
                guard let novo else { return }
                Task {
                    // A imagem vive só nesta variável local e some com ela (seção 20.3).
                    guard let dados = try? await novo.loadTransferable(type: Data.self),
                          let imagem = UIImage(data: dados) else { return }
                    processar(imagem)
                }
            }
            .onDisappear { tarefa?.cancel() }
        }
    }

    // MARK: - Escolher a foto

    private var telaDeEscolha: some View {
        VStack(spacing: 22) {
            Spacer()
            Ilustracao(asset: .notaEtelefone, altura: 200)

            Text("Fotografe a nota inteira, num lugar com luz. Não precisa ficar reta.")
                .font(.body)
                .foregroundStyle(Paleta.textoSecundario)
                .multilineTextAlignment(.center)

            // Aviso de privacidade na hora certa: no momento em que ele vai tirar a foto,
            // não escondido na política (seção 20.3).
            Label("A foto é lida aqui no aparelho e descartada. Ela não fica salva.",
                  systemImage: "lock.fill")
                .font(.footnote)
                .foregroundStyle(Paleta.textoSecundario)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                abrindoCamera = true
            } label: {
                Label("Tirar foto", systemImage: "camera.fill")
            }
            .buttonStyle(BotaoPrincipal())

            PhotosPicker(selection: $selecaoDaGaleria, matching: .images) {
                Text("Escolher da galeria").font(.subheadline)
            }
        }
        .padding(.horizontal, Metrica.margemLateral)
        .padding(.bottom, 14)
    }

    // MARK: - Processando (cancelável — requisito 17.3)

    private var telaDeProcessamento: some View {
        VStack(spacing: 20) {
            Spacer()
            ChamaAnimada()
            Text("Lendo a nota…")
                .font(.headline)
                .foregroundStyle(Paleta.carvaoEscuro)
            Text("Cupom grande demora um pouco mais.").estiloLegenda()
            Spacer()
            Button("Cancelar") { tarefa?.cancel(); etapa = .escolher }
                .font(.subheadline)
                .frame(maxWidth: .infinity, minHeight: Metrica.toqueMinimo)
                .contentShape(.rect)
        }
        .padding(Metrica.margemLateral)
    }

    // MARK: - Erro de leitura

    private var telaDeErro: some View {
        VStack(spacing: 22) {
            Spacer()
            Ilustracao(asset: .fotoIlegivel, altura: 180)
            Text(mensagemDeErro)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Paleta.carvaoEscuro)
                .multilineTextAlignment(.center)
            Spacer()
            Button("Tentar outra foto") { etapa = .escolher }
                .buttonStyle(BotaoPrincipal())
            Button("Lançar os itens à mão") { criarCompraVaziaEFechar() }
                .font(.subheadline)
                .frame(maxWidth: .infinity, minHeight: Metrica.toqueMinimo)
                .contentShape(.rect)
        }
        .padding(.horizontal, Metrica.margemLateral)
        .padding(.bottom, 14)
    }

    // MARK: - Ações

    /// Roda o OCR e a extração. A `UIImage` só existe dentro deste escopo e é liberada
    /// quando ele termina — nada é escrito em disco (seção 20.3).
    private func processar(_ imagem: UIImage) {
        abrindoCamera = false
        etapa = .processando
        tarefa = Task {
            do {
                let resultado = try await ReceiptExtractor().ler(imagem: imagem)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    lida = resultado
                    etapa = .revisar
                }
            } catch ErroDeIA.naoEntendeu {
                guard !Task.isCancelled else { return }
                // Copy 15.12, com caminho direto para o lançamento manual (épico 8.5).
                await MainActor.run {
                    mensagemDeErro = Copy.nenhumItemReconhecido
                    etapa = .erro
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    mensagemDeErro = Copy.nenhumItemReconhecido
                    etapa = .erro
                }
            }
        }
    }

    /// Cria uma compra vazia para o usuário preencher à mão e leva direto para a revisão.
    private func criarCompraVaziaEFechar() {
        let nota = compra(origem: .manual)
        nota.evento = evento
        contexto.insert(nota)
        try? contexto.save()
        fechar()
    }
}

// MARK: - Câmera

/// Câmera do sistema. `UIImagePickerController` porque só precisamos de uma foto única,
/// sem controle de captura — não vale um pipeline de AVFoundation para isso.
struct CameraPicker: UIViewControllerRepresentable {
    let aoCapturar: (UIImage) -> Void
    @Environment(\.dismiss) private var fechar

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordenador {
        Coordenador(aoCapturar: aoCapturar, aoFechar: { fechar() })
    }

    final class Coordenador: NSObject, UIImagePickerControllerDelegate,
                             UINavigationControllerDelegate {
        let aoCapturar: (UIImage) -> Void
        let aoFechar: () -> Void

        init(aoCapturar: @escaping (UIImage) -> Void, aoFechar: @escaping () -> Void) {
            self.aoCapturar = aoCapturar
            self.aoFechar = aoFechar
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            // A imagem sai daqui direto para o processamento em memória. Em nenhum ponto
            // ela é salva no álbum nem escrita em disco (seção 20.3).
            if let imagem = info[.originalImage] as? UIImage { aoCapturar(imagem) }
            aoFechar()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            aoFechar()
        }
    }
}
