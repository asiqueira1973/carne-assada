import SwiftUI
import SwiftData

/// Tela 10.10 — Turma / participantes.
///
/// Épico 8.6. Adicionar exige **apenas o nome**; os três marcadores têm default da seção 7.3.
/// Participante não é usuário do app (seção 5): é registro de dado no aparelho do organizador.
struct TurmaView: View {

    @Bindable var evento: churrasco

    @Environment(\.modelContext) private var contexto

    @State private var nomeNovo = ""
    @State private var avisoDeDuplicata: String?

    private var participantes: [participante] {
        evento.participantes.sorted { $0.ordem < $1.ordem }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Paleta.fundoTela.ignoresSafeArea()

                VStack(spacing: 0) {
                    if participantes.isEmpty {
                        estadoVazio
                    } else {
                        lista
                    }
                    campoDeAdicao
                }
            }
            .navigationTitle("A turma")
        }
    }

    private var estadoVazio: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(Paleta.fundoCartao).frame(width: 250, height: 250)
                Ilustracao(asset: .turmaDeAmigos, altura: 190)
            }
            Text(Copy.semParticipantes)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Paleta.carvaoEscuro)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, Metrica.margemLateral)
    }

    private var lista: some View {
        List {
            ForEach(participantes) { pessoa in
                CardDeParticipante(pessoa: pessoa)
                    .modifier(LinhaSemFundo())
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { excluir(pessoa) } label: {
                            Label("Excluir", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var campoDeAdicao: some View {
        VStack(spacing: 8) {
            if let avisoDeDuplicata {
                Text(avisoDeDuplicata)
                    .font(.footnote)
                    .foregroundStyle(Paleta.atencao)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 10) {
                TextField("Nome de quem foi", text: $nomeNovo)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit { adicionar() }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: Metrica.toqueMinimo)
                    .cartao()

                Button {
                    adicionar()
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: Metrica.toqueMinimo, height: Metrica.toqueMinimo)
                        .background(Paleta.brasaLaranja, in: .circle)
                }
                .disabled(nomeNovo.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Adicionar participante")
            }
        }
        .padding(.horizontal, Metrica.margemLateral)
        .padding(.vertical, 10)
    }

    // MARK: - Ações

    /// Adiciona um participante aplicando a regra 7.10.1 de nome duplicado.
    private func adicionar() {
        let bruto = nomeNovo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !bruto.isEmpty else { return }

        // 7.10.1: único dentro do churrasco, **case-insensitive**. Colisão vira " (2)"
        // e avisa — porque dois "João" no rateio é erro garantido na hora de cobrar.
        let existentes = Set(evento.participantes.map { $0.nome.lowercased() })
        var nome = bruto
        if existentes.contains(nome.lowercased()) {
            var sufixo = 2
            while existentes.contains("\(bruto) (\(sufixo))".lowercased()) { sufixo += 1 }
            nome = "\(bruto) (\(sufixo))"
            avisoDeDuplicata = "Já tinha um \(bruto). Esse virou \(nome)."
        } else {
            avisoDeDuplicata = nil
        }

        let pessoa = participante(nome: nome, ordem: evento.participantes.count)
        pessoa.evento = evento
        contexto.insert(pessoa)
        try? contexto.save()
        nomeNovo = ""
    }

    /// Regra 11.12: excluir participante é reversível por re-adição e **não** pede confirmação.
    /// A cascata de `atribuicao` (7.3) remove as marcações dele e o rateio se recalcula
    /// sozinho na próxima leitura — ele é derivado, não armazenado.
    private func excluir(_ pessoa: participante) {
        contexto.delete(pessoa)
        try? contexto.save()
    }
}

// MARK: - Card

/// Um participante com seus três marcadores. Cards grandes de propósito: a seção 9.3 prevê
/// o aparelho passando de mão em mão, e menu escondido não funciona nesse uso.
private struct CardDeParticipante: View {
    @Bindable var pessoa: participante

    @Environment(\.modelContext) private var contexto

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Nome", text: $pessoa.nome)
                .font(.body.weight(.semibold))
                .foregroundStyle(Paleta.carvaoEscuro)

            VStack(spacing: 8) {
                Toggle("É criança", isOn: Binding(
                    get: { pessoa.e_crianca },
                    set: { novo in
                        pessoa.e_crianca = novo
                        // Critério 8.6: marcar criança força `bebe_alcool = false`.
                        if novo { pessoa.bebe_alcool = false }
                        try? contexto.save()
                    }
                ))

                Toggle("Come carne", isOn: Binding(
                    get: { pessoa.come_carne },
                    set: { pessoa.come_carne = $0; try? contexto.save() }
                ))

                Toggle("Bebe álcool", isOn: Binding(
                    get: { pessoa.bebe_alcool },
                    set: { pessoa.bebe_alcool = $0; try? contexto.save() }
                ))
                // Criança nasce sem álcool e o campo fica bloqueado (7.3).
                .disabled(pessoa.e_crianca)
            }
            .font(.subheadline)
            .tint(Paleta.brasaLaranja)
        }
        .padding(16)
        .cartao()
    }
}
