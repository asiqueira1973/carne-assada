import SwiftUI
import SwiftData

/// Entrada do app.
///
/// Sem login, sem backend, sem sincronização (princípio 0.3): o container do SwiftData é
/// local e é a única fonte de dado do produto.
@main
struct CarneAssadaApp: App {

    /// Serviço da seção 13. Lido uma vez na abertura e observado por `Transaction.updates`.
    @State private var entitlement = EntitlementService()
    /// Regra 11.9: decide se os pontos de IA aparecem ou somem da UI.
    @State private var disponibilidade = ModelAvailabilityService()

    @Environment(\.scenePhase) private var faseDaCena

    private let container: ModelContainer

    init() {
        do {
            container = try MainActor.assumeIsolated { try Persistencia.container() }
        } catch {
            // Falha ao abrir o store é irrecuperável: sem persistência não existe produto.
            // Não há caminho de degradação honesto aqui — melhor falhar alto que silenciar.
            fatalError("Não foi possível abrir o store do SwiftData: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(entitlement)
                .environment(disponibilidade)
                .tint(Paleta.brasaLaranja)
                // pt-BR apenas (requisito 17.11).
                .environment(\.locale, Formatacao.localeBR)
                .task { await entitlement.carregar() }
        }
        .modelContainer(container)
        .onChange(of: faseDaCena) { _, nova in
            // O usuário pode ter ligado a Apple Intelligence nos Ajustes enquanto estava fora.
            if nova == .active { disponibilidade.reconsultar() }
        }
    }
}
