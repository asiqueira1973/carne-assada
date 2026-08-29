import Foundation

/// Toda a copy do app — seção 15 do spec.
///
/// Centralizada aqui para que o texto que o usuário lê seja **conteúdo final**, revisado
/// num lugar só, e não string espalhada que ninguém mais encontra para ajustar o tom.
/// O número de cada constante é o número da linha na tabela 15.
///
/// **Nenhuma copy contém preço**, de propósito (regra 11.16.6): o valor exibido no paywall
/// vem sempre de `Product.displayPrice` do StoreKit.
enum Copy {
    /// 15.1
    static let tituloHome = "Meus churrascos"
    /// 15.2
    static let botaoCriar = "Novo churrasco"
    /// 15.3
    static let placeholderTextoLivre = "Conta pra mim: quantas pessoas, tem criança, tem quem não come carne, e quanto tempo vai durar."
    /// 15.4
    static let exemploTextoLivre = #"Ex.: "15 adultos, 4 crianças, 3 não comem carne, do meio-dia até a noite""#
    /// 15.5
    static let botaoCalcular = "Calcular a lista"
    /// 15.6
    static let homeVazia = "Nenhum churrasco por aqui ainda. Bora marcar o primeiro?"
    /// 15.7
    static let modeloIndisponivel = "Vamos no modo manual — é rapidinho também."
    /// 15.8
    static let erroNaExtracao = "Não consegui entender dessa vez. Ajusta os números aqui embaixo que já resolve."
    /// 15.9
    static let avisoDeRecalculo = "Recalculando a lista. O que você adicionou à mão continua aí."
    /// 15.10
    static let tituloRevisaoDaNota = "Confere pra mim"
    /// 15.11
    static let divergenciaDeTotal = "A soma dos itens deu diferente do total da nota. Dá uma olhada — mas se estiver certo, pode seguir."
    /// 15.12
    static let nenhumItemReconhecido = "Não deu pra ler essa foto. Tenta de novo com mais luz, ou lança os itens à mão."
    /// 15.13
    static let semItensParaRatear = "Ainda não tem nada pra dividir. Adiciona a nota do mercado primeiro."
    /// 15.14
    static let ajusteHistoricoAplicado = "Ajustei com base no último churrasco."
    /// 15.15
    static let semParticipantes = "Quem foi no churrasco? Preciso dos nomes pra dividir a conta."
    /// 15.16
    static let resultadoMudou = "Os valores mudaram. Vale reenviar pro pessoal."
    /// 15.17
    static let erroAoSalvar = "Não consegui salvar agora. Tenta de novo."
    /// 15.18 — `{n} de {total} no carrinho`
    static func progressoDoMercado(_ n: Int, _ total: Int) -> String { "\(n) de \(total) no carrinho" }
    /// 15.19
    static let tudoComprado = "Carrinho completo. Bom churrasco! 🔥"
    /// 15.20
    static let tituloDoResultado = "A conta"
    /// 15.21
    static let explicacaoNaoBebe = "Não bebe: fora do rateio das bebidas alcoólicas"
    /// 15.22
    static let explicacaoCrianca = "Criança: paga meia na carne e nos acompanhamentos"
    /// 15.23
    static let explicacaoNaoComeCarne = "Não come carne: fora do rateio da carne"
    /// 15.24
    static let botaoCompartilhar = "Mandar pro grupo"
    /// 15.25
    static let posEvento = "Como foi? Sobrou muito? Faltou alguma coisa?"
    /// 15.26
    static let confirmarExclusaoDeChurrasco = "Apagar este churrasco? Não dá pra desfazer."
    /// 15.27
    static let apagarTodosOsDados = "Isso apaga todos os seus churrascos deste aparelho. Não dá pra desfazer."
    /// 15.28
    static let tituloDoPaywall = "Divida a conta sem digitar nada"
    /// 15.29
    static let subtituloDoPaywall = "Fotografe a nota do mercado e o Carne Assada calcula quanto cada um deve."
    /// 15.30 — exibidos como lista
    static let itensDoPaywall = [
        "Leitura da nota fiscal por foto",
        "Conta dividida com regra justa",
        "Quem não bebe não paga a cerveja",
        "Pronto pra mandar no grupo",
    ]
    /// 15.31
    static let reforcoDePagamentoUnico = "Pagamento único. Sem assinatura, sem mensalidade."
    /// 15.32
    static let falhaNaCompra = "Não deu pra concluir a compra. Tenta de novo daqui a pouco."
    /// 15.33
    static let restauracaoSemCompra = "Não encontrei nenhuma compra anterior nesta conta."
    /// 15.34
    static let restauracaoComSucesso = "Tudo certo, compra restaurada."
    /// 15.35
    static let botaoRestaurar = "Já comprei, restaurar"
    /// 15.36 — o principal argumento de compra (regra 11.16.8); precisa estar escrito.
    static let promessaDeCompraUnica = "Pagamento único. Tudo que vier depois já está incluído."

    /// Aviso da seção 20.4: sem backup do iPhone, trocar de aparelho perde os dados.
    static let avisoDeBackup = "Seus churrascos ficam só neste aparelho. Eles entram no backup do iPhone — mas se você trocar de celular sem backup, os dados se perdem."
}
