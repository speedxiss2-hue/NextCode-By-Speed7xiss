---
name: design-systems
description: "Build and evolve design systems: tokens, theming, component APIs, accessibility, documentation, motion, and contribution workflow. Trigger on token architecture, component libraries, Figma-to-code handoff, refactoring repeated UI into a system, and design system audits."
---

# Design Systems

Um design system é contrato entre design e engenharia. Não é uma pasta de componentes — é
um Vocabulary compartilhado com regras de uso, dono e processo de evolução.

## 1. Tokens antes de componentes

- Tokens em três camadas: **primitivos** (valores brutos), **semânticos** (intenção,
  `color.action.primary`), **componente** (escopo específico).
- Componentes consomem tokens semânticos. Nunca consume um token primitivo diretamente —
  quando o primitivo muda, o semântico absorve.
- Nomeie por papel, não por aparência: `surface.raised`, não `gray-100`.
- Cubra todos os estados: default, hover, focus, active, disabled, error, selected.
- Tokens de movimento (duração, easing), espaçamento, raio, tipografia e elevation também
  são tokens — não apenas cor.

## 2. Tematização

- Light e dark são dois conjuntos de valores semânticos, não uma inversão automática.
- Defina o comportamento de fallback para temas customizados: todo token semântico precisa
  de valor em todos os temas suportados.
- Teste os três caminhos: light, dark e custom-theme fallback.
- Nunca use valores crus de cor diretamente em componentes; a auditoria deve encontrar
  `var(--token)` ou equivalente.

## 3. API de componente

- Props descrevem intenção (`variant`, `size`, `state`), não estilo (`red`, `padding8`).
- Composição sobre variações infinitas: prefira `children` e slots a 20 props booleanas.
- Propague `ref`, `id`, `aria-*`, `data-*` e handlers nativos. Componente que engole isso
  quebra acessibilidade e integração.
- Componente controlado e não controlado quando fizer sentido, com comportamento padrão
  estável.
- Um componente, uma responsabilidade. Se um `Button` sabe buscar dados, ele não é botão.

## 4. Acessibilidade como requisito de base

- Cada componente tem roles, nomes e estados corretos para leitor de tela.
- Navegação por teclado completa, com foco visível e ordem lógica.
- `focus-visible` padronizado no sistema — não por componente.
- Contraste verificado para todos os estados e temas.
- Testes automatizados de acessibilidade no CI, além de teste manual com leitor de tela.

## 5. Documentação

- Cada componente: quando usar, quando **não** usar, props, estados, exemplos e notas de
  acessibilidade.
- Documentação vive junto do código e é gerada a partir dele quando possível.
- Inclua exemplos de anti-padrões — o que impediu o componente de ser reutilizado antes.
- Changelog do sistema com migrações explícitas quando um breaking change acontecer.

## 6. Figma → código

- Nomes de componentes e variáveis no Figma espelham os tokens do código.
- Use Code Connect ou mapeamento equivalente para manter links entre componente de design
  e implementação.
- Exporte tokens de uma fonte única. Não mantenha paleta duplicada no Figma e no CSS.
- Mudanças no sistema de design são revisadas como código: revisão, aprovação, versão.

## 7. Governança

- Dono por área (tokens, componentes, documentação, acessibilidade).
- Processo de proposta: problema → proposta → revisão → implementação → migração → release.
- Versionamento semântico. Breaking changes com depreciação e caminho de migração.
- Auditoria periódica: componentes duplicados, tokens órfãos, usos de valores crus,
  componentes sem documento. Remova o que não é usado.

## 8. Critério de pronto

- Tokens semânticos cobrindo light, dark e fallback?
- APIs por intenção, não por estilo?
- Acessibilidade verificada por componente?
- Documentação com exemplos e anti-exemplos?
- Figma e código sincronizados?
- Proprietário e processo de mudança definidos?
