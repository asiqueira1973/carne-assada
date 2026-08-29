import SwiftUI
import UIKit

/// Repertório de movimento — seção 16.5 do spec.
///
/// Tudo em SwiftUI nativo, sem nenhuma dependência externa (decisão 4.4 e assunção 24.10).
///
/// **Regra absoluta (16.5):** com `accessibilityReduceMotion` ligado, os movimentos 16.5.1
/// a 16.5.7 são substituídos por fade de 0,2 s ou por nada. O háptico **permanece** — quem
/// desliga movimento não está pedindo para deixar de sentir a confirmação.
enum Movimento {
    /// Curva base da seção 16.5.
    static let base = Animation.spring(response: 0.4, dampingFraction: 0.75)
    /// Substituta quando Reduzir Movimento está ligado.
    static let reduzida = Animation.easeInOut(duration: 0.2)

    /// A curva certa para o ambiente atual.
    static func curva(reduzir: Bool) -> Animation { reduzir ? reduzida : base }

    /// Atraso da cascata da lista pronta (16.5.2): 40 ms entre linhas.
    static let atrasoDaCascata: Double = 0.04
}

// MARK: - Háptico

/// Feedback tátil. Continua funcionando com Reduzir Movimento ligado (regra 16.5).
enum Haptico {
    /// 16.5.3 — marcar item no mercado.
    @MainActor static func leve() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    /// 16.5.4 — carrinho completo.
    @MainActor static func sucesso() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    /// 16.5.7 — erro.
    @MainActor static func erro() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

// MARK: - 16.5.1 — Chama animada (processando a descrição da turma)

/// Substitui o spinner padrão enquanto o modelo processa a descrição da turma.
///
/// Três línguas de fogo em `Canvas` + `phaseAnimator`, oscilando em escala e opacidade.
/// Máximo **3 s** visível; depois vira spinner comum — animação bonita que dura demais
/// deixa de tranquilizar e passa a parecer travamento.
struct ChamaAnimada: View {
    @Environment(\.accessibilityReduceMotion) private var reduzirMovimento
    @State private var passouDeTresSegundos = false

    var body: some View {
        Group {
            if reduzirMovimento || passouDeTresSegundos {
                ProgressView()
                    .controlSize(.large)
                    .tint(Paleta.brasaLaranja)
            } else {
                chamas
            }
        }
        .frame(height: 80)
        .task {
            try? await Task.sleep(for: .seconds(3))
            passouDeTresSegundos = true
        }
        .accessibilityLabel("Calculando")
    }

    private var chamas: some View {
        TimelineView(.animation) { contexto in
            let t = contexto.date.timeIntervalSinceReferenceDate
            Canvas { desenho, tamanho in
                let centro = CGPoint(x: tamanho.width / 2, y: tamanho.height / 2)
                // Três línguas de fogo, defasadas, cada uma com sua frequência —
                // fogo real não pulsa em uníssono.
                for indice in 0..<3 {
                    let fase = t * (1.6 + Double(indice) * 0.35) + Double(indice) * 1.1
                    let escala = 0.72 + 0.28 * sin(fase)
                    let opacidade = 0.45 + 0.4 * abs(sin(fase * 0.8))
                    let largura = 26.0 * escala
                    let altura = 46.0 * escala
                    let deslocamento = CGFloat(indice - 1) * 13

                    var caminho = Path()
                    let base = CGPoint(x: centro.x + deslocamento, y: centro.y + altura / 2)
                    caminho.move(to: base)
                    caminho.addQuadCurve(
                        to: CGPoint(x: base.x, y: base.y - altura),
                        control: CGPoint(x: base.x - largura, y: base.y - altura * 0.45)
                    )
                    caminho.addQuadCurve(
                        to: base,
                        control: CGPoint(x: base.x + largura, y: base.y - altura * 0.45)
                    )

                    desenho.fill(
                        caminho,
                        with: .color(indice == 1
                                     ? Color(red: 0.95, green: 0.69, blue: 0.20).opacity(opacidade)
                                     : Color(red: 1.0, green: 0.42, blue: 0.21).opacity(opacidade))
                    )
                }
            }
        }
    }
}

// MARK: - 16.5.2 — Cascata da lista pronta

/// Entrada em cascata de cima para baixo: fade + deslocamento de 12 pt, 40 ms entre linhas.
struct CascataDeEntrada: ViewModifier {
    let indice: Int
    @Environment(\.accessibilityReduceMotion) private var reduzirMovimento
    @State private var apareceu = false

    func body(content: Content) -> some View {
        content
            .opacity(apareceu ? 1 : 0)
            .offset(y: apareceu || reduzirMovimento ? 0 : 12)
            .onAppear {
                // Com Reduzir Movimento, sobra só o fade — sem deslocamento e sem escalonar.
                withAnimation(
                    Movimento.curva(reduzir: reduzirMovimento)
                        .delay(reduzirMovimento ? 0 : Double(indice) * Movimento.atrasoDaCascata)
                ) {
                    apareceu = true
                }
            }
    }
}

extension View {
    /// Aplica a cascata 16.5.2 a uma linha de lista.
    func cascata(indice: Int) -> some View { modifier(CascataDeEntrada(indice: indice)) }
}

// MARK: - 16.5.4 — Brasas subindo (carrinho completo)

/// 12 partículas de brasa subindo por 1,5 s, uma única vez.
///
/// Livre para o agente escolher (16.6): o arranjo das partículas. A arte de cada brasa é o
/// asset fornecido — aqui só se decide onde cada uma nasce, quão rápido sobe e como gira.
struct BrasasSubindo: View {
    @Environment(\.accessibilityReduceMotion) private var reduzirMovimento
    @State private var inicio: Date?

    private static let duracao: TimeInterval = 1.5
    private static let quantidade = 12

    /// Semente fixa por partícula: o arranjo é irregular mas idêntico a cada execução,
    /// para não ficar diferente entre um churrasco e outro sem motivo.
    private struct Faisca {
        let x: CGFloat, atraso: Double, escala: CGFloat, giro: Double, asset: Ilustracoes
    }

    private static let faiscas: [Faisca] = (0..<quantidade).map { i in
        let f = Double(i)
        return Faisca(
            x: CGFloat(0.10 + 0.80 * ((f * 0.37).truncatingRemainder(dividingBy: 1))),
            atraso: (f * 0.083).truncatingRemainder(dividingBy: 0.6),
            escala: CGFloat(0.5 + 0.5 * ((f * 0.61).truncatingRemainder(dividingBy: 1))),
            giro: -25 + 50 * (f * 0.29).truncatingRemainder(dividingBy: 1),
            asset: [.brasa1, .brasa2, .brasa3][i % 3]
        )
    }

    var body: some View {
        // Regra absoluta 16.5: com Reduzir Movimento, a animação decorativa simplesmente
        // não toca. O háptico de sucesso continua, disparado por quem chama.
        if !reduzirMovimento {
            GeometryReader { geo in
                TimelineView(.animation(paused: inicio == nil)) { contexto in
                    let decorrido = inicio.map { contexto.date.timeIntervalSince($0) } ?? 0
                    ZStack {
                        ForEach(0..<Self.quantidade, id: \.self) { i in
                            let faisca = Self.faiscas[i]
                            let progresso = min(max((decorrido - faisca.atraso) / Self.duracao, 0), 1)
                            if progresso > 0 && progresso < 1 {
                                Image(faisca.asset.rawValue)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22 * faisca.escala)
                                    .rotationEffect(.degrees(faisca.giro * progresso))
                                    // Sobe e some: opacidade cai na segunda metade do voo.
                                    .opacity(progresso < 0.5 ? 1 : (1 - progresso) * 2)
                                    .position(
                                        x: geo.size.width * faisca.x,
                                        y: geo.size.height * (1 - progresso * 0.9)
                                    )
                            }
                        }
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear { inicio = Date() }
        }
    }
}

// MARK: - 16.5.5 — Valores contando de 0 até o valor final

/// Conta de 0 até o valor em 0,6 s. O `monospacedDigit()` de `estiloValor()` é o que
/// impede o layout de tremer enquanto o número corre (16.2).
struct ValorQueConta: View {
    let valor: Decimal
    @Environment(\.accessibilityReduceMotion) private var reduzirMovimento
    @State private var exibido: Decimal = 0

    var body: some View {
        Text(Formatacao.moeda(exibido))
            .estiloValor()
            .onAppear { animar() }
            .onChange(of: valor) { _, _ in animar() }
            // VoiceOver lê o valor final direto — não faz sentido narrar a contagem.
            .accessibilityLabel(Formatacao.moeda(valor))
    }

    private func animar() {
        guard !reduzirMovimento else { exibido = valor; return }
        exibido = 0
        Task { @MainActor in
            let passos = 24
            let duracaoDoPasso = UInt64(0.6 / Double(passos) * 1_000_000_000)
            for passo in 1...passos {
                try? await Task.sleep(nanoseconds: duracaoDoPasso)
                exibido = valor * Decimal(passo) / Decimal(passos)
            }
            exibido = valor
        }
    }
}

// MARK: - 16.5.7 — Shake de erro

/// Shake horizontal de 6 pt, duas oscilações. Acompanha háptico `.error`.
struct ShakeDeErro: ViewModifier {
    let disparo: Int
    @Environment(\.accessibilityReduceMotion) private var reduzirMovimento
    @State private var deslocamento: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: deslocamento)
            .onChange(of: disparo) { _, _ in
                Haptico.erro()
                guard !reduzirMovimento else { return }
                Task { @MainActor in
                    for passo: CGFloat in [6, -6, 6, -6, 0] {
                        withAnimation(.easeInOut(duration: 0.06)) { deslocamento = passo }
                        try? await Task.sleep(for: .milliseconds(60))
                    }
                }
            }
    }
}

extension View {
    /// Aplica o shake 16.5.7 sempre que `disparo` mudar.
    func shakeDeErro(disparo: Int) -> some View { modifier(ShakeDeErro(disparo: disparo)) }
}
