import Foundation
import SwiftData

/// Entidades SwiftData — seção 7 do spec.
///
/// Convenção 18.1: **o modelo de dados fica em português `snake_case`**, com os nomes de
/// campo exatamente como escritos na seção 7. Tudo acima da camada de modelo é inglês.
/// A fronteira de idioma é esta.

// MARK: - churrasco (7.2)

/// Um evento de churrasco. Raiz do modelo: tudo pendura aqui.
/// Exclusão é hard delete com cascata para todas as filhas (7.2).
@Model
final class churrasco {
    /// PK.
    var id: UUID = UUID()
    /// Editável; usado no histórico e no texto compartilhado (14.1).
    var nome: String = "Churrasco"
    /// Só a data importa; a hora é ignorada.
    var data_evento: Date = Date()
    /// Onde o churrasco está no fluxo (seção 12).
    var status_bruto: String = status_churrasco.planejando.rawValue
    /// Parâmetro de cálculo (regra 11.1).
    var qtd_adultos: Int = 0
    /// Criança = até ~12 anos, por marcador, sem idade (regra 11.2).
    var qtd_criancas: Int = 0
    /// Subconjunto de `qtd_adultos`, **não soma a ele** (regra 11.3).
    var qtd_vegetarianos: Int = 0
    /// Subconjunto de `qtd_adultos`.
    var qtd_nao_bebem_alcool: Int = 0
    /// Faixas de multiplicador na regra 11.1.3.
    var duracao_horas: Int = 5
    /// O texto que o usuário digitou. Nulo quando o churrasco nasceu só com steppers.
    /// Guardado para auditoria da extração (7.2).
    var descricao_livre: String?
    var origem_parametros_bruta: String = origem_dado.manual.rawValue
    /// Decisão 25.3: carne suína é opcional e nasce desligada, para não inflar a lista
    /// de quem não faz costelinha.
    var inclui_carne_suina: Bool = false
    /// Regra 11.14: o usuário pode desligar o ajuste histórico com um toque, voltando à lista base.
    var ajuste_historico_ligado: Bool = true
    var criado_em: Date = Date()
    var atualizado_em: Date = Date()

    // Cascata de exclusão (7.2): apagar o churrasco apaga tudo que pende dele.
    @Relationship(deleteRule: .cascade, inverse: \participante.evento)
    var participantes: [participante] = []

    @Relationship(deleteRule: .cascade, inverse: \item_lista.evento)
    var itens_lista: [item_lista] = []

    @Relationship(deleteRule: .cascade, inverse: \compra.evento)
    var compras: [compra] = []

    @Relationship(deleteRule: .cascade, inverse: \registro_pos_evento.evento)
    var registro: registro_pos_evento?

    init(nome: String = "Churrasco", data_evento: Date = Date()) {
        self.id = UUID()
        self.nome = nome
        self.data_evento = data_evento
        self.criado_em = Date()
        self.atualizado_em = Date()
    }

    /// O enum tipado por trás do campo persistido. SwiftData guarda a `rawValue` em String
    /// para que renomear um caso no futuro seja migração de dado, não corrupção silenciosa.
    var status: status_churrasco {
        get { status_churrasco(rawValue: status_bruto) ?? .planejando }
        set { status_bruto = newValue.rawValue }
    }

    var origem_parametros: origem_dado {
        get { origem_dado(rawValue: origem_parametros_bruta) ?? .manual }
        set { origem_parametros_bruta = newValue.rawValue }
    }

    /// Aplica uma transição da seção 12. Transição não permitida é ignorada em silêncio —
    /// o app nunca muda de status sozinho fora do que a máquina de estados autoriza (11.15).
    /// - Returns: `true` se o status mudou.
    @discardableResult
    func irPara(_ destino: status_churrasco) -> Bool {
        guard status != destino, status.permiteIrPara(destino) else { return false }
        status = destino
        atualizado_em = Date()
        return true
    }
}

// MARK: - participante (7.3)

/// Quem foi ao churrasco. **Não é usuário do app** (seção 5): não acessa nada,
/// é apenas registro de dado no aparelho do organizador.
@Model
final class participante {
    var id: UUID = UUID()
    /// Livre; único dentro do churrasco, case-insensitive (7.10.1).
    var nome: String = ""
    /// Afeta o peso no rateio (regra 11.7).
    var e_crianca: Bool = false
    var come_carne: Bool = true
    /// Criança nasce com `false` e o campo fica bloqueado na UI (7.3).
    var bebe_alcool: Bool = true
    /// Ordem de exibição = ordem de cadastro.
    var ordem: Int = 0

    var evento: churrasco?

    @Relationship(deleteRule: .cascade, inverse: \atribuicao.quem)
    var atribuicoes: [atribuicao] = []

    init(nome: String, e_crianca: Bool = false, come_carne: Bool = true,
         bebe_alcool: Bool = true, ordem: Int = 0) {
        self.id = UUID()
        self.nome = nome
        self.e_crianca = e_crianca
        self.come_carne = come_carne
        // Regra 7.3: criança nunca entra no rateio de bebida alcoólica.
        self.bebe_alcool = e_crianca ? false : bebe_alcool
        self.ordem = ordem
    }
}

// MARK: - item_lista (7.4)

/// Item da lista de compras. Exclusão é hard delete (7.4).
@Model
final class item_lista {
    var id: UUID = UUID()
    var categoria_bruta: String = categoria_lista.outro.rawValue
    /// Ex.: "Picanha", "Carvão".
    var nome: String = ""
    /// Sempre > 0 (7.10.4). Zerar equivale a excluir o item.
    var quantidade: Decimal = 0
    var unidade_bruta: String = unidade_medida.unidade.rawValue
    /// Marcação do modo mercado (8.4).
    var comprado: Bool = false
    /// `calculado` = veio da regra 11.1; `manual` = o usuário adicionou.
    /// O recálculo preserva os `manual` e substitui os `calculado` (8.3).
    var origem_bruta: String = origem_dado.calculado.rawValue
    /// Ordem dentro da categoria.
    var ordem: Int = 0

    var evento: churrasco?

    init(categoria: categoria_lista, nome: String, quantidade: Decimal,
         unidade: unidade_medida, origem: origem_dado = .calculado, ordem: Int = 0) {
        self.id = UUID()
        self.categoria_bruta = categoria.rawValue
        self.nome = nome
        self.quantidade = quantidade
        self.unidade_bruta = unidade.rawValue
        self.origem_bruta = origem.rawValue
        self.ordem = ordem
    }

    var categoria: categoria_lista {
        get { categoria_lista(rawValue: categoria_bruta) ?? .outro }
        set { categoria_bruta = newValue.rawValue }
    }

    var unidade: unidade_medida {
        get { unidade_medida(rawValue: unidade_bruta) ?? .unidade }
        set { unidade_bruta = newValue.rawValue }
    }

    var origem: origem_dado {
        get { origem_dado(rawValue: origem_bruta) ?? .calculado }
        set { origem_bruta = newValue.rawValue }
    }
}

// MARK: - compra (7.5)

/// Uma nota/cupom. Um churrasco pode ter várias (mercado + açougue + bebida).
/// A imagem da nota **não é armazenada** em momento nenhum (seção 20.3).
@Model
final class compra {
    var id: UUID = UUID()
    /// Nulo quando o modelo não identifica o mercado ou a compra foi lançada à mão.
    var estabelecimento: String?
    var data_compra: Date = Date()
    /// Total lido da nota. Nulo quando não foi possível ler.
    /// O rateio **nunca** usa este campo — usa sempre a soma dos itens confirmados (regra 11.10.1).
    var valor_total_informado: Decimal?
    var origem_bruta: String = origem_dado.extraido.rawValue
    var criado_em: Date = Date()

    var evento: churrasco?

    @Relationship(deleteRule: .cascade, inverse: \item_compra.nota)
    var itens: [item_compra] = []

    init(estabelecimento: String? = nil, data_compra: Date = Date(),
         valor_total_informado: Decimal? = nil, origem: origem_dado = .extraido) {
        self.id = UUID()
        self.estabelecimento = estabelecimento
        self.data_compra = data_compra
        self.valor_total_informado = valor_total_informado
        self.origem_bruta = origem.rawValue
        self.criado_em = Date()
    }

    var origem: origem_dado {
        get { origem_dado(rawValue: origem_bruta) ?? .extraido }
        set { origem_bruta = newValue.rawValue }
    }
}

// MARK: - item_compra (7.6)

/// Linha da nota fiscal, depois da revisão do usuário.
@Model
final class item_compra {
    var id: UUID = UUID()
    /// Como aparece na nota, normalizada pelo modelo.
    var descricao: String = ""
    /// Valor da linha em reais. Sempre ≥ 0 (7.10.3).
    /// Nulo = o modelo não conseguiu ler; item entra pendente e **nunca** com valor
    /// estimado (regra 11.10.2). Item pendente não entra no rateio.
    var valor_total: Decimal?
    var categoria_rateio_bruta: String = categoria_rateio.geral.rawValue
    /// Vira `true` quando o usuário passa pela tela de revisão.
    /// Item não confirmado não entra em nenhum cálculo (regra 11.11).
    var confirmado: Bool = false
    var origem_bruta: String = origem_dado.extraido.rawValue
    /// Ordem de leitura na nota.
    var ordem: Int = 0

    var nota: compra?

    @Relationship(deleteRule: .cascade, inverse: \atribuicao.item)
    var atribuicoes: [atribuicao] = []

    init(descricao: String, valor_total: Decimal?,
         categoria: categoria_rateio = .geral, confirmado: Bool = false,
         origem: origem_dado = .extraido, ordem: Int = 0) {
        self.id = UUID()
        self.descricao = descricao
        // 7.10.3: valor negativo lido da nota (desconto) nunca vira item negativo.
        self.valor_total = valor_total.map { max(0, $0) }
        self.categoria_rateio_bruta = categoria.rawValue
        self.confirmado = confirmado
        self.origem_bruta = origem.rawValue
        self.ordem = ordem
    }

    var categoria: categoria_rateio {
        get { categoria_rateio(rawValue: categoria_rateio_bruta) ?? .geral }
        set { categoria_rateio_bruta = newValue.rawValue }
    }

    var origem: origem_dado {
        get { origem_dado(rawValue: origem_bruta) ?? .extraido }
        set { origem_bruta = newValue.rawValue }
    }

    /// Item sem valor legível. Fica visível como pendente na revisão e fora do rateio (11.10.2).
    var pendente: Bool { valor_total == nil }

    /// Entra no rateio? Só o que está confirmado **e** tem valor (regras 11.11 e 11.10.2).
    var entra_no_rateio: Bool { confirmado && valor_total != nil }
}

// MARK: - atribuicao (7.7)

/// Associativa de "quem consumiu o quê".
///
/// **Ausência de linhas para um item significa "divide conforme a categoria de rateio"**
/// (regra 11.5) — não significa "ninguém consumiu". Presença de linhas é atribuição
/// explícita e sobrepõe a categoria.
@Model
final class atribuicao {
    var id: UUID = UUID()
    var item: item_compra?
    var quem: participante?

    init(item: item_compra, quem: participante) {
        self.id = UUID()
        self.item = item
        self.quem = quem
    }
}

// MARK: - registro_pos_evento (7.8)

/// O que sobrou e o que faltou. No máximo um por churrasco (7.10.6).
@Model
final class registro_pos_evento {
    var id: UUID = UUID()
    /// O que o usuário escreveu ("sobrou linguiça, faltou cerveja").
    var texto_livre: String = ""
    /// JSON com os ajustes percentuais por categoria.
    /// Desnormalizado de propósito (trade-off declarado em 7.8): é lido inteiro,
    /// escrito inteiro e nunca consultado por campo. Nulo quando o modelo estava indisponível.
    var ajustes_json: String?
    var criado_em: Date = Date()

    var evento: churrasco?

    init(texto_livre: String, ajustes_json: String? = nil) {
        self.id = UUID()
        self.texto_livre = texto_livre
        self.ajustes_json = ajustes_json
        self.criado_em = Date()
    }
}
