import SwiftUI
import SwiftData

/// Tela 10.2 — Novo churrasco.
///
/// Só nome e data (item 3.1 do escopo). Princípio 0.4: do toque em "novo churrasco" até a
/// lista pronta são no máximo 3 telas, então esta precisa ser trivial.
struct NovoChurrascoView: View {

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var fechar

    @State private var nome = ""
    @State private var data = Date()
    @State private var erroAoSalvar = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome do churrasco", text: $nome)
                        .textInputAutocapitalization(.sentences)
                    DatePicker("Data", selection: $data, displayedComponents: .date)
                } footer: {
                    Text("Se você não der um nome, ele vai se chamar Churrasco mesmo.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Paleta.fundoTela)
            .navigationTitle(Copy.botaoCriar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { fechar() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { salvar() }
                }
            }
            .alert(Copy.erroAoSalvar, isPresented: $erroAoSalvar) {
                Button("Ok", role: .cancel) {}
            }
        }
    }

    /// Grava o churrasco. Nome em branco cai no default da seção 7.2 ("Churrasco"),
    /// para que ninguém seja obrigado a digitar nada aqui (princípio 0.4).
    private func salvar() {
        let limpo = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        let novo = churrasco(nome: limpo.isEmpty ? "Churrasco" : limpo, data_evento: data)
        contexto.insert(novo)
        do {
            try contexto.save()
            fechar()
        } catch {
            // Seção 12: erro de persistência mantém o estado anterior e mostra a copy 15.17.
            contexto.delete(novo)
            erroAoSalvar = true
        }
    }
}

#Preview {
    NovoChurrascoView()
        .modelContainer(try! Persistencia.containerEmMemoria())
}
