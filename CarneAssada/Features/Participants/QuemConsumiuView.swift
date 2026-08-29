import SwiftUI
import SwiftData

/// Tela 10.11 — Quem consumiu.
///
/// Épico 8.6. Um item de compra e a lista de participantes marcável.
///
/// Regra 11.5: **ausência de marcação significa "divide conforme a categoria"** — não
/// "ninguém consumiu". Marcar alguém sobrepõe a categoria e divide igualmente só entre os
/// marcados. A tela precisa deixar isso explícito, senão o organizador marca todo mundo
/// achando que precisa.
struct QuemConsumiuView: View {

    @Bindable var item: item_compra
    let evento: churrasco

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var fechar

    private var participantes: [participante] {
        evento.participantes.sorted { $0.ordem < $1.ordem }
    }

    private var marcados: Set<UUID> {
        Set(item.atribuicoes.compactMap { $0.quem?.id })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Paleta.fundoTela.ignoresSafeArea()

                if participantes.isEmpty {
                    VStack(spacing: 18) {
                        Ilustracao(asset: .turmaDeAmigos, altura: 160)
                        Text(Copy.semParticipantes)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Paleta.carvaoEscuro)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Metrica.margemLateral)
                } else {
                    conteudo
                }
            }
            .navigationTitle(item.descricao.isEmpty ? "Quem consumiu?" : item.descricao)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pronto") { fechar() }
                }
            }
        }
    }

    private var conteudo: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: Metrica.entreCartoes) {
                    Aviso(
                        texto: marcados.isEmpty
                            ? "Sem ninguém marcado, este item divide conforme a categoria: \(item.categoria.rotulo.lowercased())."
                            : "Só quem está marcado paga por este item. A categoria fica de fora.",
                        cor: Paleta.brasaLaranja
                    )

                    // Cards grandes, um por pessoa: a seção 9.3 prevê o celular passando
                    // de mão em mão, e cada um marcando o que consumiu.
                    ForEach(participantes) { pessoa in
                        Button {
                            alternar(pessoa)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: marcados.contains(pessoa.id)
                                      ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(marcados.contains(pessoa.id)
                                                     ? Paleta.sucesso : Paleta.textoSecundario)
                                    .symbolEffect(.bounce, value: marcados.contains(pessoa.id))

                                Text(pessoa.nome)
                                    .font(.body)
                                    .foregroundStyle(Paleta.carvaoEscuro)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if pessoa.e_crianca {
                                    Chip(texto: "criança", cor: Paleta.milhoAmarelo)
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .frame(minHeight: Metrica.toqueMinimo)
                            .contentShape(.rect)
                            .cartao()
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityValue(marcados.contains(pessoa.id) ? "marcado" : "não marcado")
                        .accessibilityAddTraits(.isButton)
                    }
                }
                .padding(.horizontal, Metrica.margemLateral)
                .padding(.vertical, 8)
            }

            if !marcados.isEmpty {
                Button("Limpar marcação") { limpar() }
                    .font(.subheadline)
                    .padding(.bottom, 12)
            }
        }
    }

    private func alternar(_ pessoa: participante) {
        Haptico.leve()
        if let existente = item.atribuicoes.first(where: { $0.quem?.id == pessoa.id }) {
            contexto.delete(existente)
        } else {
            let nova = atribuicao(item: item, quem: pessoa)
            contexto.insert(nova)
        }
        try? contexto.save()
    }

    /// Limpa a atribuição, devolvendo o item ao rateio por categoria (regra 11.5).
    private func limpar() {
        for a in item.atribuicoes { contexto.delete(a) }
        try? contexto.save()
    }
}
