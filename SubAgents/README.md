# SubAgents do NextCode

Um arquivo `.md` por agente. Cada arquivo e um subagente: o nome do arquivo (sem `.md`) e o id,
o frontmatter traz `description` e `mode: subagent`, e o corpo e o prompt de sistema.

| Arquivo | Id do agente | Funcao |
|---|---|---|
| `programador.md` | `programador` | Programacao geral, qualquer linguagem |
| `tarefas-dia-a-dia.md` | `tarefas-dia-a-dia` | Rotina, planos, resumos, automacoes leves |
| `backend.md` | `backend` | APIs, auth, banco, filas, testes de servidor |
| `frontend.md` | `frontend` | Interfaces web, componentes, estado, a11y |
| `design.md` | `design` | Identidade visual, tokens, mockups |
| `cheats.md` | `cheats` | Cheats de jogos, memoria, offsets, hooks, overlays |
| `reverse-engineering.md` | `reverse-engineering` | Analise estatica/dinamica, assinaturas |
| `game-cheats-researcher.md` | `game-cheats-researcher` | Busca de cheats em repositorios publicos |

## Como o NextCode carrega estes arquivos

O app desktop faz `process.chdir(homedir())`, entao ele nao encontra config dentro do projeto.
O carregamento funciona assim:

- `%USERPROFILE%\.config\opencode\opencode.json` — registra skills, comandos `/nome` e aponta os caminhos.
- `%USERPROFILE%\.config\opencode\agent\` — copia (ou junction) destes `.md`, e onde o NextCode le os subagentes.

Os arquivos desta pasta sao a fonte editavel. Depois de editar, sincronize com o diretorio global:

```powershell
Copy-Item ".\source do NEXTCODE\SubAgents\*.md" "$env:USERPROFILE\.config\opencode\agent\" -Force
```

O watcher de config recarrega os agentes sozinho. Se nao recarregar, reinicie o NextCode.
