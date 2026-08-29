import Foundation
import SwiftUI

/// Enums do modelo de dados — seção 7.9 do spec.
/// Nomes e valores em português `snake_case`, exatamente como escritos ali (convenção 18.1).

/// Onde o churrasco está no fluxo. Máquina de estados na seção 12.
enum status_churrasco: String, Codable, CaseIterable, Sendable {
    case planejando
    case comprando
    case fechando_conta
    case concluido

    /// Rótulo curto para o chip da Home (tela 10.1).
    var rotulo: String {
        switch self {
        case .planejando: "Lista pronta"
        case .comprando: "No mercado"
        case .fechando_conta: "Fechando a conta"
        case .concluido: "Conta fechada"
        }
    }

    /// Cor do chip. Cor de marca, não semântica — status aqui é informação, não estado de erro.
    var cor: Color {
        switch self {
        case .planejando: Paleta.cervejaDourado
        case .comprando: Paleta.brasaLaranja
        case .fechando_conta: Paleta.churrascoVermelho
        case .concluido: Paleta.limaoVerde
        }
    }

    /// Transições permitidas pela seção 12. `planejando → concluido` é proibido.
    func permiteIrPara(_ destino: status_churrasco) -> Bool {
        switch (self, destino) {
        case (.planejando, .comprando), (.planejando, .fechando_conta): true
        case (.comprando, .fechando_conta), (.comprando, .planejando): true
        case (.fechando_conta, .concluido), (.fechando_conta, .comprando): true
        case (.concluido, .fechando_conta): true
        default: false
        }
    }
}

/// Categoria de um item da lista de compras. Organiza a lista e escolhe o ícone de categoria (16.7).
enum categoria_lista: String, Codable, CaseIterable, Sendable {
    case carne
    case acompanhamento
    case bebida_alcoolica
    case bebida_nao_alcoolica
    case carvao_e_utensilios
    case outro

    var rotulo: String {
        switch self {
        case .carne: "Carne"
        case .acompanhamento: "Acompanhamento"
        case .bebida_alcoolica: "Bebida alcoólica"
        case .bebida_nao_alcoolica: "Bebida sem álcool"
        case .carvao_e_utensilios: "Carvão e utensílios"
        case .outro: "Outros"
        }
    }

    /// Cor do título da categoria (16.2: título de seção na cor da categoria).
    var cor: Color {
        switch self {
        case .carne: Paleta.churrascoVermelho
        case .acompanhamento: Paleta.milhoAmarelo
        case .bebida_alcoolica: Paleta.cervejaDourado
        case .bebida_nao_alcoolica: Paleta.limaoVerde
        case .carvao_e_utensilios: Paleta.carvaoEscuro
        case .outro: Paleta.textoSecundario
        }
    }

    /// Nome do asset do ícone de categoria (16.7.1: constante tipada).
    var icone: String {
        switch self {
        case .carne: "category_meat"
        case .acompanhamento: "category_sides"
        case .bebida_alcoolica: "category_alcohol"
        case .bebida_nao_alcoolica: "category_soft_drink"
        case .carvao_e_utensilios: "category_charcoal"
        case .outro: "category_other"
        }
    }

    /// Ordem de exibição da lista de compras — segue a ordem de uso no churrasco.
    var ordem: Int {
        switch self {
        case .carne: 0
        case .acompanhamento: 1
        case .bebida_alcoolica: 2
        case .bebida_nao_alcoolica: 3
        case .carvao_e_utensilios: 4
        case .outro: 5
        }
    }
}

/// Como um item de compra é dividido entre os participantes. Regra 11.5.
enum categoria_rateio: String, Codable, CaseIterable, Sendable {
    case geral
    case bebida_alcoolica
    case bebida_nao_alcoolica
    case apenas_carne

    var rotulo: String {
        switch self {
        case .geral: "Todo mundo"
        case .bebida_alcoolica: "Quem bebe"
        case .bebida_nao_alcoolica: "Bebida sem álcool"
        case .apenas_carne: "Quem come carne"
        }
    }

    var cor: Color {
        switch self {
        case .geral: Paleta.textoSecundario
        case .bebida_alcoolica: Paleta.cervejaDourado
        case .bebida_nao_alcoolica: Paleta.limaoVerde
        case .apenas_carne: Paleta.churrascoVermelho
        }
    }
}

/// Unidade de compra de um item da lista. Governa o arredondamento da regra 11.1.4.
enum unidade_medida: String, Codable, CaseIterable, Sendable {
    case kg
    case g
    case unidade
    case litro
    case ml
    case pacote

    /// Abreviação exibida ao lado da quantidade.
    var abreviacao: String {
        switch self {
        case .kg: "kg"
        case .g: "g"
        case .unidade: "un"
        case .litro: "L"
        case .ml: "ml"
        case .pacote: "pct"
        }
    }
}

/// De onde veio um dado. Serve para o recálculo preservar o que o usuário escreveu (8.3).
enum origem_dado: String, Codable, CaseIterable, Sendable {
    /// Gerado pela regra 11.1 em Swift puro.
    case calculado
    /// Veio da leitura da nota pelo modelo.
    case extraido
    /// Digitado pelo usuário.
    case manual
}
