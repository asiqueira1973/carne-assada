import Foundation
import SwiftData

/// Versionamento do esquema — seção 7.12 do spec.
///
/// O spec exige `VersionedSchema` / `SchemaMigrationPlan` **desde a v1**: nenhuma migração
/// leve não versionada. Com isso, a primeira mudança de modelo já nasce com um degrau
/// nomeado para onde apontar, em vez de virar migração implícita e imprevisível.
enum EsquemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [churrasco.self, participante.self, item_lista.self,
         compra.self, item_compra.self, atribuicao.self, registro_pos_evento.self]
    }
}

/// Plano de migração do store. Hoje tem um único degrau; a v2 entra como `EsquemaV2`
/// mais um `MigrationStage` aqui, e o teste da seção 22.1 cobre a passagem.
enum PlanoDeMigracao: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [EsquemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

/// Fábrica do container do app.
///
/// Store local, **sem CloudKit** (princípio 0.3: zero conta, zero nuvem).
/// Seção 7.12: nenhum seed. Na primeira abertura o usuário vê o estado vazio da Home (15.6),
/// não um churrasco de exemplo.
enum Persistencia {
    /// Container de produção, gravado no container do app e protegido pelo Data Protection
    /// do iOS (seção 20.4).
    @MainActor
    static func container() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(versionedSchema: EsquemaV1.self),
            migrationPlan: PlanoDeMigracao.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: false)
        )
    }

    /// Container em memória, para testes e para os previews do Xcode.
    static func containerEmMemoria() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(versionedSchema: EsquemaV1.self),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
