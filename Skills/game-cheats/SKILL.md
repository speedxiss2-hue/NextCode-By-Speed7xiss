---
name: game-cheats
description: "Encontrar, avaliar e adaptar cheats, trainers, mods e scripts de jogos a partir de repositorios publicos (GitHub, GitLab, Bitbucket, Codeberg, Sourcegraph, grep.app). Use quando pedirem para achar ou desenvolver cheats para CS2, Fortnite, Valorant, Roblox, Free Fire, FiveM, MTA, Minecraft ou qualquer outro jogo."
---

# Game Cheats — Descoberta em repositorios publicos

Esta skill transforma um pedido de cheat em uma busca reproducivel em codigo publico.
O trabalho e de localizacao, triagem e adaptacao. Nao se inventa offset: ele e lido do
repositorio ou rederivado da versao atual do jogo.

## 1. Regras de superficie

- Usar apenas fontes publicas e somente leitura. Nao autenticar em contas de terceiros.
- Nao executar binarios baixados sem antes inspecionar o codigo-fonte e o historico do repo.
- Nao confiar em README sozinho: checar `git log`, `LICENSE`, `issues` e o codigo real.
- Respeitar a licenca do repositorio. Codigo sem licenca e "somente leitura", nao reutilizavel.
- Reportar sempre a URL exata, a linguagem, a versao do jogo e a data do ultimo commit.

## 2. Superficies de busca

| Superficie | Endpoint util | Observacao |
|---|---|---|
| GitHub repos | `https://api.github.com/search/repositories?q=<query>&sort=stars&per_page=20` | Sem auth, limite baixo; com auth via `gh` e melhor |
| GitHub codigo | `https://github.com/search?q=<query>&type=code` | Exige login no navegador |
| GitLab | `https://gitlab.com/api/v4/projects?search=<query>&per_page=20` | Publico, sem auth |
| grep.app | `https://grep.app/api/search?q=<query>` | Busca rapida em milhares de repos |
| Sourcegraph | `https://sourcegraph.com/search?q=context:global+<query>&patternType=keyword` | Busca global, bom para simbolos |
| Codeberg / Gitea | `https://codeberg.org/api/v1/repos/search?q=<query>` | Alternativa menos saturada |
| Web | `site:github.com "<jogo>" cheat lang:C++` | bom primeiro passe |

Ferramentas locais uteis: `gh search repos`, `gh search code`, `git clone --depth 1`,
`rg` para varrer o codigo baixado.

## 3. Catalogo de queries por jogo

| Jogo | Engine / linguagem | Buscas iniciais |
|---|---|---|
| CS2 | Source 2 / C++ , C# | `cs2 cheat github`, `cs2 esp github`, `cs2 aimbot`, `cs2-sdk`, `cs2 offset`, `cs2 internal cheat`, `cs2 external cheat` |
| Fortnite | Unreal / C++ | `fortnite cheat github`, `fortnite esp github`, `fortnite sdk github`, `fortnite unreal engine cheat` |
| Valorant | Unreal / C++ | `valorant cheat github`, `valorant esp github`, `valorant overlay github`, `valorant offsets` |
| Roblox | Luau / Lua | `roblox exploit github`, `roblox executor lua`, `roblox script hub github` |
| Free Fire | Android / C++ , Java , Lua | `free fire mod github`, `free fire cheat apk github`, `ff tools mod menu` |
| FiveM | GTA V / Lua , C# | `fivem cheat github`, `fivem mod menu github`, `fivem script executor`, `fivem antenna cheat` |
| MTA | GTA SA / Lua | `mta cheat github`, `mta mod menu lua`, `multi theft auto script github` |
| Minecraft | JVM / Java , Kotlin | `minecraft hacked client github`, `minecraft fabric cheat`, `forge mod cheat`, `minecraft esp mod` |
| Generico | qualquer | `<jogo> cheat github`, `<jogo> trainer`, `<jogo> mod menu`, `<jogo> sdk`, `<jogo> offsets`, `<jogo> reverse engineering`, `<jogo> internal external` |

Para qualquer jogo fora da tabela, trocar `<jogo>` pelo nome oficial e repetir o conjunto generico.
Adicionar `stars:>20`, `pushed:>2025-01-01` ou `language:C++` para filtrar.

## 4. Triagem de resultados

Para cada candidato, coletar em uma linha:

1. URL e nome do repo.
2. Linguagem e engine declarados.
3. Versao do jogo suportada (ler README e arquivos de offset).
4. Features listadas (ESP, aimbot, no-recoil, trigger, trainer, etc.).
5. Ultimo commit e contagem de stars/forks.
6. Licenca.
7. Sinais de risco: binario sem fonte, ofuscacao, `curl | sh`, pedido de credencial,
   commits suspeitos, dependencias desconhecidas.

Descarte repos com binario opaco ou sem fonte. Marque como "nao verificado" os que nao
foi possivel compilar ou ler ate o fim.

## 5. Fluxo de adaptacao

1. Clonar em area isolada: `git clone --depth 1 <url>`.
2. Ler estrutura com `rg --files` e abrir os arquivos de configuracao/offsets.
3. Identificar a versao do jogo esperada pelo codigo. Offsets sao por build; conferir a data.
4. Montar o ambiente de build declarado (toolchain, SDK, includes).
5. Compilar antes de tocar em qualquer logica. Erro de build e sinal de versao errada.
6. Se offsets mudaram, rederivá-los da versao atual e documentar o metodo usado.
7. Testar primeiro em conta propria, servidor privado ou offline. Nunca em ambiente de terceiros.
8. Registrar o que mudou e por que.

## 6. Formato de relatorio

```
Repo: <url>
Jogo/versao: <nome e versao>
Linguagem/engine: <...>
Features: <...>
Ultimo commit: <data> | Stars: <n> | Licenca: <...>
Risco: <achados da triagem>
Proximo passo: <build / rederivar offset / descartar>
```

Um relatorio por repo, no maximo 5 por busca. Se nenhum repo servir, dizer isso e
listar as queries ja tentadas.
