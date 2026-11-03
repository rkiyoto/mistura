import Foundation

enum TextStrings {
    // MARK: - Navigation
    static let appTitle = "Mistura"

    // MARK: - Search
    static let searchPlaceholder = "Buscar receitas"
    static let searchIdle = "Busque receitas por nome ou ingrediente."
    static let historySectionTitle = "Vistos recentemente"
    static let searchTypeName = "Nome"
    static let searchTypeIngredient = "Ingrediente"

    // MARK: - Search Results
    static func searchEmptyMessage(query: String) -> String {
        "Nenhuma receita encontrada para \"\(query)\"."
    }

    static let searchErrorMessage = "Não foi possível buscar as receitas. Verifique sua conexão e tente novamente."

    // MARK: - Detail
    static let ingredientsSectionTitle = "Ingredientes"
    static let instructionsSectionTitle = "Modo de preparo"
    static let shoppingCartButton = "Comprar ingredientes"
    static let detailLoadError = "Não foi possível carregar a receita."
    static let detailNotFound = "Receita não encontrada."
    static let retryButton = "Tentar novamente"

    // MARK: - Accessibility
    static let clearHistoryAccessibilityLabel = "Limpar histórico"
    static let clearHistoryAccessibilityHint = "Remove todas as receitas do histórico"
    static let addToCartAccessibilityLabel = "Adicionar ingredientes ao carrinho de compras"
    static let addToCartAccessibilityHint = "Abre o iFood Mercado com a lista de ingredientes não marcados"
    static let watchVideoAccessibilityLabel = "Assistir vídeo da receita no YouTube"
    static let watchVideoAccessibilityHint = "Abre o vídeo em um navegador externo"

    // MARK: - Errors
    static let historySaveError = "Falha ao salvar no histórico:"
    static let searchClearError = "Error on clearing history:"
}

