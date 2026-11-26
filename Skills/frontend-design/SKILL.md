---
name: frontend-design
description: "Build distinctive, production-grade web interfaces. Trigger on landing pages, marketing sites, dashboards, product UIs, component work, redesigns, and any frontend task where generic AI styling must be avoided. Do not use for native mobile — use mobile-design."
---

# Frontend Design

Produza interfaces que pareçam feitas por alguém com direção, não pelo template padrão de
modelo. O erro mais comum é gerar layouts corretos e visualmente esquecíveis.

## 1. Antes de escrever, fixe a direção

Escolha uma direção a partir do produto, não de preferência pessoal. Nomeie-a em uma frase
antes de tocar no código:

- Produto de ferro e precisão → industriais, grid rígido, mono, contraste alto, cantos retos.
- Produto de cuidado e saúde → serifados humanos, espaço em branco generoso, paleta quente,
  movimento lento.
- Produto de velocidade e dados → compacto, denso, tipografia técnica, acentos elétricos.
- Produto de entretenimento → expressivo, sobreposição, cor saturada, movimento com personalidade.

Se a direção não puder ser justificada pelo produto, ela é decoração. Corte.

## 2. Regras anti-genérico

- Nada de gradientes roxo/azul por padrão, glassmorphism em tudo, cards com sombra difusa
  idêntica, ou "hero com badge arredondado + duas colunas".
- Nada de `Inter` ou `system-ui` como única fonte quando a direção pede caráter. Use uma
  fonte de exibição para títulos e uma de leitura para corpo, com contraste real entre elas.
- Não repita o mesmo raio de borda em todos os elementos. Hierarquia de raios: 0 para
  estrutura, pequeno para controles, grande apenas onde o produto pede.
- Espaçamento segue uma escala (4/8/12/16/24/32/48/64). Nunca valores aleatórios.
- Cada tela precisa de um ponto focal inequívoco. Se tudo chama atenção, nada chama.

## 3. Tipografia

- Defina uma escala modular (por exemplo 1.25) e use-a em toda a interface.
- Títulos: `line-height` apertado (0.95–1.1), `letter-spacing` negativo em tamanhos grandes.
- Corpo: `line-height` 1.5–1.65, medida de linha 60–75 caracteres.
- Números em tabelas e métricas usam `font-variant-numeric: tabular-nums`.
- Limite de 2–3 famílias de fonte no projeto inteiro.

## 4. Cor

- Uma cor primária, uma neutra dominante, no máximo duas de acento.
- Construa a paleta a partir de um token de marca e derive estados (hover, active, disabled)
  por mistura — não escolha cores independentes para cada estado.
- Contraste: texto normal mínimo 4.5:1, texto grande 3:1, elementos de UI 3:1. Verifique,
  não estime.
- Modo escuro não é inversão de claro. Ajuste saturação e elevação separadamente.

## 5. Layout e responsividade

- Mobile primeiro, mas pense em conteúdo, não em breakpoint. Use `clamp()`, grid e
  `minmax()` antes de media queries.
- Defina uma largura máxima de conteúdo e centralize; evite texto correndo até a borda.
- Use `gap` em vez de margins para espaçamento entre irmãos.
- Elementos interativos têm área mínima de 44×44px em touch.
- Teste em 320px, 768px, 1280px e 1920px. O layout deve quebrar com intenção em cada um.

## 6. Movimento e estados

- Movimento serve para explicar mudança de estado, não para decorar. Duração 150–300ms
  para interações, 400–600ms para transições de tela.
- Use `transform` e `opacity`. Nunca anime `width`, `height` ou `top`.
- Respeite `prefers-reduced-motion`: desative ou reduce a movimento essencial.
- Todo componente interativo precisa de estados visuais para: repouso, hover, foco,
  ativo, carregando, erro, desabilitado e vazio. Estado de foco nunca deve ser removido
  sem substituto.

## 7. Acessibilidade (não negociável)

- Navegação por teclado completa, ordem de foco lógica, foco visível.
- Semântica HTML antes de ARIA. Use `<button>`, `<nav>`, `<main>`, `<h1>`–`<h6>` corretamente.
- Ícones com significado têm `aria-label`; ícones decorativos têm `aria-hidden="true"`.
- Formulários: `<label>` associado, mensagens de erro ligadas por `aria-describedby`.
- Teste com um leitor de tela e com teclado antes de declarar pronto.

## 8. Pré-voo antes de entregar

- A direção escolhida é visível na primeira tela?
- Existe um ponto focal claro?
- A tipografia tem hierarquia real?
- Contraste passa nos mínimos?
- Todos os estados interativos existem?
- Funciona em 320px e sem JavaScript?
- Teclado e leitor de tela funcionam?
- `prefers-reduced-motion` respeitado?

Se qualquer resposta for não, corrija antes de mostrar o trabalho.
