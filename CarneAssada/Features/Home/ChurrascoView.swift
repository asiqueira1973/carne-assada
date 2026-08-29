import SwiftUI
import SwiftData

/// Contêiner do churrasco aberto — `TabView` com Lista, Mercado, Conta e Turma.
///
/// Divergência declarada em relação à seção 10: o spec previa três abas (Lista / Conta /
/// Turma) com o modo mercado como tela separada. O design do produto promoveu **Mercado**
/// a aba própria, e é o que está implementado — o modo mercado é o momento 2 da seção 2 e
/// merece estar a um toque, não escondido atrás da lista. A tela 10.5 mantém o botão
/// "Abrir o modo mercado" mesmo assim.
///
/// A aba Conta exibe o cadeado **desde o início**, não só no momento do toque: é a
/// mitigação do risco 23.9 (o usuário não pode descobrir o paywall com a nota na mão).
struct ChurrascoView: View {

    @Bindable var evento: churrasco

    @Environment(EntitlementService.self) private var entitlement
    @State private var aba: Aba = .lista
    @State private var abrindoComoFoi = false

    enum Aba: Hashable { case lista, mercado, conta, turma }

    var body: some View {
        TabView(selection: $aba) {
            Tab("Lista", systemImage: "fork.knife", value: Aba.lista) {
                ListaDeComprasView(evento: evento, irParaMercado: { aba = .mercado })
            }

            Tab("Mercado", systemImage: "cart.fill", value: Aba.mercado) {
                ModoMercadoView(evento: evento, irParaConta: { aba = .conta })
            }

            Tab("Conta", systemImage: iconeDaConta, value: Aba.conta) {
                ContaView(evento: evento)
            }

            Tab("Turma", systemImage: "person.2.fill", value: Aba.turma) {
                TurmaView(evento: evento)
            }
        }
        .navigationTitle(evento.nome)
        .navigationBarTitleDisplayMode(.inline)
        .tint(Paleta.brasaLaranja)
        .toolbar {
            // Fluxo 9.1, passo 10: dias depois, o organizador registra o que sobrou.
            // Só aparece com o churrasco concluído — antes disso não há o que relatar.
            if evento.status == .concluido {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { abrindoComoFoi = true } label: {
                        Image(systemName: "text.bubble")
                    }
                    .accessibilityLabel("Como foi?")
                }
            }
        }
        .sheet(isPresented: $abrindoComoFoi) { ComoFoiView(evento: evento) }
    }

    /// Cadeado na aba Conta enquanto a compra não estiver liberada (mitigação do risco 23.9).
    /// No estado `desconhecido` o cadeado **não** aparece: enquanto o StoreKit não responde,
    /// o app não afirma que a feature está trancada (regra 11.16.4).
    private var iconeDaConta: String {
        entitlement.estado == .naoComprado ? "lock.fill" : "dollarsign.circle.fill"
    }
}
