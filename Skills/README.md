# NextCode Skills

Biblioteca de skills próprias do NextCode. Cada pasta contém um `SKILL.md` com frontmatter
(`name`, `description`) no formato que o OpenCode já consome — o mesmo formato usado em
`src/packages/plugins/figma/skills/*/SKILL.md`.

## Skills incluídas

| Pasta | O que cobre | Referências de origem |
|---|---|---|
| `frontend-design/` | Interfaces web, landing pages, dashboards, redesenho anti-genérico | `Ilm-Alan/frontend-design`, `vercel-labs/agent-skills`, `github/awesome-copilot`, `addyosmani/agent-skills`, `mattpocock/skills`, `emilkowalski/skills` |
| `mobile-design/` | iOS e Android, HIG / Material, touch, safe areas, tipografia de plataforma | `designed-by-ai/skills`, `leonxlnx/taste-skill`, `uizze.sh` |
| `backend/` | API design, autenticação, modelagem de dados, erros, segurança, testes | `clerk/skills`, `wshobson/agents`, `affaan-m/ecc`, `jiatastic/open-python-skills` |
| `design-systems/` | Tokens, componentes, acessibilidade, documentação, motion | `vercel-labs/agent-skills`, `mattpocock/skills`, `emilkowalski/skills` |
| `reverse-engineering/` | Análise estática e dinâmica, Ghidra/IDA/x64dbg, teardown de formatos e protocolos | `morluto/rea`, `AIshihzong/awesome-reverse-engineer-anything`, `sickn33/agentic-awesome-skills`, `VoltAgent/awesome-agent-skills` |
| `game-cheats/` | Busca e triagem de cheats/mods em repositórios públicos (GitHub, GitLab, grep.app, Sourcegraph) para qualquer jogo | escrita local |
| `jailbreak-everthing/` | Framework de persona/prompt. Arquivo convertido de `SKILL.txt` para `SKILL.md` para ser descoberto. Somente invocação explícita (`disable-model-invocation: true`) | arquivo local preexistente |

## Como carregar

O schema do OpenCode já expõe `skills: string[]` — "Additional paths or URLs to discover skills from"
(`packages/schema/src/config.ts`). Aponte para esta pasta:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "skills": ["./Skills"]
}
```

Caminhos relativos são resolvidos a partir da raiz do projeto. Também é possível usar um
caminho absoluto ou uma URL. Depois de editar, reinicie o NextCode ou deixe o watcher
de config recarregar — `ConfigSkillPlugin` observa os diretórios de skills em busca de mudanças.

Neste projeto o app desktop faz `process.chdir(homedir())`, então o config efetivo fica em
`%USERPROFILE%\.config\opencode\opencode.json`, apontando por caminho absoluto para esta pasta.
O mesmo arquivo registra um comando `/nome` para cada skill. Exemplo: `/game-cheats`,
`/frontend-design`, `/backend`.

## Convenção de autoria

- Uma skill por diretório, arquivo sempre chamado `SKILL.md`.
- Frontmatter obrigatório: `name` e `description`. A description é o que dispara a skill,
  então escreva-a como uma regra de ativação — "Trigger when...", não como um resumo.
- Material de apoio vai em `references/` e é linkado a partir do `SKILL.md`.
- `disable-model-invocation: true` apenas quando a skill deve ser chamada pelo usuário,
  nunca automaticamente pelo modelo.

## Invocação por comando

Cada skill tem um comando slash com o mesmo nome, registrado em `opencode.json`:

```
/frontend-design <tarefa>
/backend <tarefa>
/design-systems <tarefa>
/mobile-design <tarefa>
/reverse-engineering <tarefa>
/game-cheats <jogo>
/jailbreak-everthing <tarefa>
```

O template do comando carrega a skill pela ferramenta `skill` e repassa os argumentos.
`jailbreak-everthing` não aparece no catálogo automático do modelo por causa de
`disable-model-invocation: true` — ele só entra em conversa quando chamado diretamente.
