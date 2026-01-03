#!/bin/bash
# Generate cfg.yml from environment variables at runtime

echo "=== Generating config from environment variables ==="
echo "POSTGRES_HOST: ${POSTGRES_HOST:-NOT_SET}"
echo "POSTGRES_USER: ${POSTGRES_USER:-NOT_SET}"
echo "POSTGRES_DB: ${POSTGRES_DB:-NOT_SET}"
echo "OPENAI_API_KEY: ${OPENAI_API_KEY:0:20}..." # Show first 20 chars only

cat > /app/cfg.yml <<EOF
logging:
  path: memmachine.log
  level: info

episode_store:
  database: postgres_db

episodic_memory:
  long_term_memory:
    embedder: openai_embedder
    reranker: rrf_reranker
    vector_graph_store: postgres_db
  short_term_memory:
    llm_model: openai_model
    message_capacity: 500

semantic_memory:
  llm_model: openai_model
  embedding_model: openai_embedder
  database: postgres_db

session_manager:
  database: postgres_db

resources:
  databases:
    postgres_db:
      provider: postgres
      config:
        host: ${POSTGRES_HOST}
        port: 5432
        user: ${POSTGRES_USER}
        password: \$POSTGRES_PASSWORD
        db_name: ${POSTGRES_DB}

  embedders:
    openai_embedder:
      provider: openai
      config:
        model: "text-embedding-3-small"
        api_key: \$OPENAI_API_KEY
        base_url: "https://api.openai.com/v1"
        dimensions: 1536

  language_models:
    openai_model:
      provider: openai-responses
      config:
        model: "gpt-4o-mini"
        api_key: \$OPENAI_API_KEY
        base_url: "https://api.openai.com/v1"

  rerankers:
    rrf_reranker:
      provider: "rrf-hybrid"
      config:
        reranker_ids:
          - identity_ranker
          - bm25_ranker
    identity_ranker:
      provider: "identity"
    bm25_ranker:
      provider: "bm25"
EOF

echo "=== Config file generated at /app/cfg.yml ==="
echo "=== Starting MemMachine server ==="

# Run the server
exec memmachine-server
