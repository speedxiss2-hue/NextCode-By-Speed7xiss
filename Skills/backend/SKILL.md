---
name: backend
description: "Design and implement backend services: HTTP APIs, authentication and authorization, data modeling, error contracts, background jobs, caching, security hardening, and tests. Trigger on API design, server endpoints, auth flows, database schemas, service architecture, and backend review."
---

# Backend

Construa serviços que falham de forma previsível, escalam sem surpresa e são fáceis de
operar. Correção e contratos antes de otimização.

## 1. Contratos de API primeiro

- Defina rotas, métodos, corps de requisição/resposta e códigos de status antes de
  implementar. REST ou GraphQL — escolha um e seja consistente.
- Nomes de recursos no plural, substantivos nas rotas, verbos no método HTTP.
- Status codes com significado: `200`/`201`/`204`, `400` validação, `401` não autenticado,
  `403` sem permissão, `404` não encontrado, `409` conflito, `422` regra de negócio,
  `429` rate limit, `500` erro inesperado.
- Paginação em todas as listagens: `limit`/`cursor`, com `next_cursor` na resposta.
- Versionamento explícito (`/v1/...`) quando a API for pública.

## 2. Validação na fronteira

- Valide e normalize toda entrada externa em um único ponto — body, query, params, headers.
- Use um schema (Zod, Pydantic, Effect Schema) e propague valores tipados para dentro.
- Não revalide internamente o que o schema já garantiu.
- Falhas de validação retornam `400` com campo, mensagem e código legíveis pelo cliente.
- Limites explícitos: tamanho máximo de body, tamanho de array, comprimento de string,
  profundidade de JSON. Nada de corpo ilimitado.

## 3. Autenticação e autorização

- Nunca implemente cripto própria. Use bibliotecas mantidas: Argon2id/bcrypt para senhas,
  OAuth 2.1/OIDC para login delegado, JWT com validação de assinatura, `exp`, `iss`, `aud`.
- Tokens de acesso curtos (5–15 min), refresh com rotação e detecção de reuso.
- Armazene sessões/refresh em cookie `HttpOnly`, `Secure`, `SameSite=Lax/Strict` quando web.
- Autorização por política centralizada: verifique permissão no ponto de entrada, não
  espalhado pelo código. Negue por padrão.
- Rate limit por IP e por usuário em rotas sensíveis: login, signup, reset, API pública.
- Log de auditoria para ações privilegiadas: quem, o quê, quando, de onde.

## 4. Dados

- Modele entidades e relacionamentos antes de escrever queries. Chaves primárias estáveis
  (UUIDv7 ou equivalente), `created_at`/`updated_at` em toda tabela.
- Use migrations versionadas. Nunca altere schema em produção com DDL ad-hoc.
- Índices explicados por query real: índice sem query que o justifique é dívida.
- Transações para operações multi-escrita. Conheça o nível de isolamento do seu banco.
- Conexões em pool com limites; timeout de query; circuit breaker para dependências.
- Segredos nunca no código: variáveis de ambiente ou cofre, com rotação documentada.

## 5. Erros e observabilidade

- Uma forma de erro em todo o serviço: `{ code, message, details?, request_id }`.
- Erros internos nunca vazam stack trace ou detalhe de infraestrutura ao cliente.
- `request_id` em toda requisição, propagado para logs e resposta.
- Logs estruturados (JSON) com nível, tempo, request_id e contexto relevante. Sem PII em logs.
- Métricas mínimas: latência por rota (p50/p95/p99), taxa de erro, saturação, throughput.
- Health check (`/health`) separado de readiness (`/ready`) — o primeiro não depende de
  serviços externos.

## 6. Segurança

- HTTPS everywhere, HSTS, headers de segurança (`CSP`, `X-Content-Type-Options`,
  `Referrer-Policy`).
- CORS com origens explícitas, nunca `*`.
- Proteção contra CSRF em cookies de sessão; contra SQL injection sempre com query
  parametrizada/ORM.
- Idempotência em operações de escrita mutáveis, via `Idempotency-Key`.
- Secrets em memória com tempo de vida curto; rotação e revogação testadas.
- Audit dependencies (`npm audit`, `pip-audit`) e fixe versões com lockfile.

## 7. Background jobs e caching

- Tarefas pesadas fora do request: fila com retry exponencial, dead-letter e idempotência.
- Cache com TTL explícito e chave determinística. Defina invalidação antes de adicionar cache.
- Nunca use cache como fonte de verdade para dados que não podem ser perdidos.

## 8. Testes

- Testes de integração contra API real com banco de teste — não mocks de tudo.
- Cubra: caso feliz, validação, não autorizado, não encontrado, conflito, erro interno.
- Testes de migração e de contrato quando houver consumidores externos.
- Testes rodam a partir do diretório do pacote, não da raiz do monorepo.

## 9. Entrega

Antes de declarar pronto: contrato documentado, migrações testadas, variáveis de ambiente
listadas, limites e rate limits definidos, observabilidade ligada, e um runbook de como
operar o serviço.
