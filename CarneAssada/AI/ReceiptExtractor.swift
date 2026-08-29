import Foundation
import FoundationModels
import UIKit
import Vision

/// O que a leitura da nota devolve, já pronto para a tela de revisão 10.9.
struct NotaLida: Equatable, Sendable {
    var estabelecimento: String?
    var dataCompra: Date?
    /// Total impresso na nota. Guardado só para o aviso de divergência (11.10.1);
    /// o rateio **nunca** usa este número.
    var valorTotal: Decimal?
    var itens: [ItemLido]
}

struct ItemLido: Equatable, Sendable {
    var descricao: String
    /// Nulo = o modelo não conseguiu ler. Entra pendente, **nunca** estimado (regra 11.10.2).
    var valor: Decimal?
    var categoria: categoria_rateio
}

/// Lê a foto de um cupom e devolve itens estruturados — épico 8.5.
///
/// ## Divergência de arquitetura em relação ao spec escrito
///
/// O spec previa mandar a imagem direto no prompt (premissa 4.3.1, iOS 27). O SDK disponível
/// é o do **iOS 26.1**, que não tem tipo de anexo de imagem no Foundation Models. Pela própria
/// regra de contingência da seção 4.2, o épico cai no caminho declarado: **Vision faz o OCR e
/// o texto reconhecido vai no prompt**. Nada mais do spec muda — a tela de revisão, os
/// guardrails e as regras 11.6/11.10 seguem idênticos.
///
/// Seção 20.3: a imagem é processada **em memória** e descartada. Nunca toca o disco,
/// nem como cache temporário.
struct ReceiptExtractor {

    /// Decisão 25.5: cupom longo é fatiado e processado em passadas, concatenando os itens.
    /// Limitar a N itens falharia justo na compra grande, que é a que mais precisa da feature.
    private static let linhasPorPassada = 40

    private static let instrucoes = """
    Você recebe o texto que um OCR leu de um cupom fiscal brasileiro e transforma em uma lista \
    de produtos comprados.

    Regras:
    - Uma entrada por produto. Ignore linhas de cabeçalho, CNPJ, endereço, forma de pagamento, \
    troco, tributos e mensagens do rodapé.
    - O valor é o total daquela linha, em reais. No cupom brasileiro a vírgula é decimal.
    - Se não der para ler o valor de um item com certeza, deixe o valor nulo. \
    NUNCA estime, nunca invente, nunca copie o valor de outra linha.
    - Classifique cada item: bebida_alcoolica para cerveja, vinho e destilado; \
    bebida_nao_alcoolica para refrigerante, suco, água e energético; \
    apenas_carne para carne, linguiça, frango e peixe; geral para todo o resto.
    - Resolva as abreviações do cupom: "REFRIG COLA 2L" vira "Refrigerante de cola 2L".
    """

    /// Faz OCR na imagem e extrai os itens.
    /// - Parameter imagem: a foto do cupom. Fica só em memória (seção 20.3).
    /// - Returns: a nota lida, com valores ilegíveis vindo nulos.
    /// - Throws: `ErroDeIA.indisponivel` em qualquer falha; `.naoEntendeu` quando o OCR
    ///   não achou texto nenhum (leva à copy 15.12).
    func ler(imagem: UIImage) async throws -> NotaLida {
        let linhas = try await reconhecerTexto(em: imagem)
        guard !linhas.isEmpty else { throw ErroDeIA.naoEntendeu }

        // Decisão 25.5: fatia em blocos de linhas e concatena o resultado das passadas.
        let blocos = stride(from: 0, to: linhas.count, by: Self.linhasPorPassada).map {
            Array(linhas[$0..<min($0 + Self.linhasPorPassada, linhas.count)])
        }

        var itens: [ItemLido] = []
        var estabelecimento: String?
        var data: Date?
        var total: Decimal?

        for (indice, bloco) in blocos.enumerated() {
            let parcial = try await extrairBloco(bloco, primeiro: indice == 0)
            itens.append(contentsOf: parcial.itens)
            // Cabeçalho e total só existem uma vez na nota: o primeiro bloco que os
            // trouxer manda, e as passadas seguintes não sobrescrevem.
            estabelecimento = estabelecimento ?? parcial.estabelecimento
            data = data ?? parcial.dataCompra
            total = total ?? parcial.valorTotal
        }

        guard !itens.isEmpty else { throw ErroDeIA.naoEntendeu }
        return NotaLida(estabelecimento: estabelecimento, dataCompra: data,
                        valorTotal: total, itens: itens)
    }

    // MARK: - Passo 1: OCR (Vision)

    /// Reconhece o texto do cupom, linha a linha, na ordem de leitura.
    ///
    /// `.accurate` com correção de idioma desligada: nome de produto de cupom é abreviação
    /// ("REFRIG COLA 2L"), e o corretor do Vision transformaria isso em outra palavra.
    /// Quem resolve a abreviação é o modelo, no passo 2.
    private func reconhecerTexto(em imagem: UIImage) async throws -> [String] {
        guard let cgImage = imagem.cgImage else { throw ErroDeIA.naoEntendeu }

        var pedido = RecognizeTextRequest()
        pedido.recognitionLevel = .accurate
        pedido.usesLanguageCorrection = false
        pedido.recognitionLanguages = [Locale.Language(identifier: "pt-BR")]

        do {
            let observacoes = try await pedido.perform(on: cgImage)
            return observacoes
                .compactMap { $0.topCandidates(1).first?.string }
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        } catch {
            throw ErroDeIA.indisponivel
        }
    }

    // MARK: - Passo 2: estruturação (Foundation Models)

    /// Manda um bloco de linhas ao modelo e recebe os itens tipados.
    private func extrairBloco(_ linhas: [String], primeiro: Bool) async throws -> NotaLida {
        let sessao = LanguageModelSession(instructions: Self.instrucoes)
        let cabecalho = primeiro
            ? "Este é o começo do cupom, com o nome do mercado, a data e possivelmente o total."
            : "Esta é a continuação de um cupom já começado. Traga só os produtos, sem cabeçalho."

        do {
            let resposta = try await sessao.respond(
                to: "\(cabecalho)\n\nTexto lido do cupom:\n\(linhas.joined(separator: "\n"))",
                generating: NotaExtraida.self
            )
            return converter(resposta.content)
        } catch {
            throw ErroDeIA.indisponivel
        }
    }

    /// Converte a saída do modelo nos tipos do app, aplicando os guardrails em **código**.
    private func converter(_ gerado: NotaExtraida) -> NotaLida {
        let itens = gerado.itens.compactMap { item -> ItemLido? in
            let descricao = item.descricao.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !descricao.isEmpty else { return nil }
            return ItemLido(
                descricao: descricao,
                // 13.2.1 / 11.10.2: valor nulo continua nulo, e valor negativo (desconto)
                // nunca vira item negativo (7.10.3).
                valor: item.valor.flatMap { $0 < 0 ? nil : Decimal($0) },
                // 13.2.5: categoria inválida cai em `geral`, garantido pelo enum tipado.
                categoria: item.categoriaSugerida.comoCategoria
            )
        }

        let estabelecimento = gerado.estabelecimento?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return NotaLida(
            estabelecimento: (estabelecimento?.isEmpty ?? true) ? nil : estabelecimento,
            dataCompra: gerado.dataCompra.flatMap(Self.interpretarData),
            valorTotal: gerado.valorTotal.flatMap { $0 < 0 ? nil : Decimal($0) },
            itens: itens
        )
    }

    /// Lê a data no formato brasileiro. Data ilegível vira nulo, e a compra assume hoje (7.5).
    private static func interpretarData(_ texto: String) -> Date? {
        let formatador = DateFormatter()
        formatador.locale = Locale(identifier: "pt_BR")
        formatador.dateFormat = "dd/MM/yyyy"
        return formatador.date(from: texto.trimmingCharacters(in: .whitespaces))
    }
}
