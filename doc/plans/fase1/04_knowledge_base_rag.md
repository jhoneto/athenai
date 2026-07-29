# Plano 4 — Knowledge Base & RAG simples

> Independente do Connector Layer — pode ser desenvolvido em paralelo aos Planos 5/6. Depende apenas do Plano 1 (Agent).

## Objetivo

- Cada `Agent` pode ter uma `KnowledgeBase` com documentos (PDF, Word, planilha)
- Documentos são indexados em `Document::Chunk` com embeddings (`pgvector`)
- Uma tool nativa (`Tool::Native::KnowledgeSearch`, ver `doc/architecture.md` §5.2) usa esses chunks para dar contexto ao LLM — a integração completa com o Tool Engine acontece no Plano 5/6, aqui entregamos o pipeline de indexação e busca por similaridade

## Dependência de infraestrutura

Adicionar `pgvector` ao Postgres:

```ruby
class EnablePgvector < ActiveRecord::Migration[8.1]
  def change
    enable_extension "vector"
  end
end
```

Gem: adicionar `gem "neighbor"` ao Gemfile (wrapper Rails-idiomático sobre `pgvector`, evita SQL manual de similaridade).

## Migrations

```ruby
class CreateKnowledgeBases < ActiveRecord::Migration[8.1]
  def change
    create_table :knowledge_bases do |t|
      t.references :agent, null: false, foreign_key: true, index: { unique: true }
      t.timestamps
    end
  end
end

class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.references :knowledge_base, null: false, foreign_key: true
      t.string  :filename, null: false
      t.integer :status, null: false, default: 0   # pending, processing, indexed, failed
      t.text    :error
      t.timestamps
    end
  end
end

class CreateDocumentChunks < ActiveRecord::Migration[8.1]
  def change
    create_table :document_chunks do |t|
      t.references :document, null: false, foreign_key: true
      t.integer :position, null: false
      t.text    :content, null: false
      t.vector  :embedding, limit: 1536   # dimensão do modelo de embedding usado
      t.timestamps
    end

    add_index :document_chunks, [ :document_id, :position ], unique: true
  end
end
```

Anexo binário do documento via Active Storage (`has_one_attached :file` — não precisa de migration própria, usa as tabelas padrão do Active Storage já instaladas no Rails 8).

## Models

`app/models/knowledge_base.rb`

```ruby
class KnowledgeBase < ApplicationRecord
  belongs_to :agent
  has_many :documents, dependent: :destroy
end
```

`app/models/document.rb`

```ruby
class Document < ApplicationRecord
  belongs_to :knowledge_base
  has_one_attached :file
  has_many :chunks, class_name: "Document::Chunk", dependent: :destroy

  enum :status, { pending: 0, processing: 1, indexed: 2, failed: 3 }

  validates :filename, presence: true

  def account
    knowledge_base.agent.account
  end
end
```

`app/models/document/chunk.rb`

```ruby
class Document::Chunk < ApplicationRecord
  self.table_name = "document_chunks"

  belongs_to :document

  has_neighbors :embedding   # da gem neighbor

  validates :content, presence: true
end
```

`Agent` ganha:

```ruby
has_one :knowledge_base, dependent: :destroy
```

## Extração para namespace (chama API externa — embeddings)

`app/models/document/indexer.rb`

```ruby
class Document::Indexer
  CHUNK_SIZE = 1_000

  def initialize(document)
    @document = document
  end

  def call
    @document.update!(status: :processing)
    text = extract_text
    chunks = text.scan(/.{1,#{CHUNK_SIZE}}/m)

    chunks.each_with_index do |content, index|
      embedding = RubyLLM.embed(content).vectors.first
      @document.chunks.create!(position: index, content: content, embedding: embedding)
    end

    @document.update!(status: :indexed)
  rescue => e
    @document.update!(status: :failed, error: e.message)
  end

  private

  def extract_text
    @document.file.download # extração real (PDF/DOCX) via gem dedicada fica fora do escopo do MVP;
                             # Fase 1 assume texto simples/plain text e PDFs extraídos com `pdf-reader`
  end
end
```

`app/models/document/search.rb`

```ruby
class Document::Search
  def initialize(knowledge_base)
    @knowledge_base = knowledge_base
  end

  def call(query, limit: 5)
    embedding = RubyLLM.embed(query).vectors.first
    Document::Chunk
      .joins(:document)
      .where(documents: { knowledge_base_id: @knowledge_base.id, status: :indexed })
      .nearest_neighbors(:embedding, embedding, distance: "cosine")
      .limit(limit)
  end
end
```

## Job

`app/jobs/document_index_job.rb`

```ruby
class DocumentIndexJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    Document::Indexer.new(Document.find(document_id)).call
  end
end
```

## Controller (Dashboard)

`app/controllers/documents_controller.rb`

```ruby
class DocumentsController < ApplicationController
  before_action :set_knowledge_base

  def index
    @documents = @knowledge_base.documents.order(created_at: :desc)
  end

  def create
    document = @knowledge_base.documents.create!(filename: params[:file].original_filename)
    document.file.attach(params[:file])
    DocumentIndexJob.perform_later(document.id)
    redirect_to agent_documents_path(@knowledge_base.agent)
  end

  def destroy
    @knowledge_base.documents.find(params[:id]).destroy
    redirect_to agent_documents_path(@knowledge_base.agent)
  end

  private

  def set_knowledge_base
    agent = current_account.agents.find(params[:agent_id])
    @knowledge_base = agent.knowledge_base || agent.create_knowledge_base!
  end
end
```

## Rotas

```ruby
resources :agents do
  resources :documents, only: %i[index create destroy]
end
```

## Views

- `app/views/documents/index.html.erb` — lista com status (badge: pendente/processando/indexado/falhou), formulário de upload
- Sem necessidade de Stimulus complexo — `input type="file"` padrão com submit direto

## Testes

- `spec/models/document_spec.rb`, `spec/models/document/chunk_spec.rb`
- `spec/models/document/indexer_spec.rb` — mocka `RubyLLM.embed`, garante chunking e criação de `Document::Chunk`
- `spec/models/document/search_spec.rb` — mocka embedding da query, garante ordenação por proximidade
- `spec/jobs/document_index_job_spec.rb`
- `spec/requests/documents_spec.rb` — isolamento por account/agent

## Critérios de aceite

- [ ] Upload de documento dispara indexação assíncrona
- [ ] Falha de indexação fica visível (`status: failed` + `error`)
- [ ] Busca por similaridade retorna os chunks mais relevantes de um agente específico (nunca de outro agente/account)
- [ ] Nenhuma chamada real de embeddings nos testes
