---
name: reverse-engineering
description: "Reverse engineer binaries, formats, protocols, and firmware. Trigger on analyzing executables, unpacking or deobfuscating, understanding file formats, protocol teardown, root-cause analysis from symbols or disassembly, and security research on systems you are authorized to inspect."
---

# Reverse Engineering

Engenharia reversa é leitura: entender o que um artefato faz e por quê. O resultado é um
mapa — estruturas, fluxos e decisões — que outra pessoa consegue verificar.

## 1. Defina a pergunta

Antes de abrir qualquer ferramenta, escreva o que você quer responder:

- Qual é o formato deste arquivo?
- Como este valor é validado?
- Qual função processa esta entrada?
- Por que este comportamento acontece?

Sem pergunta, a análise vira passeio. Com pergunta, você sabe quando parar.

## 2. Inventário do artefato

- Hash (SHA-256), tamanho, tipo (`file`), arquitetura, sistema alvo.
- Strings, imports/exports, seções, dependências, símbolos e build info.
- Assinatura digital e cadeia, quando relevante.
- Compare com versões anteriores quando houver — diff de binário frequentemente revela
  exatamente a mudança que importa.

## 3. Análise estática

- **Ghidra** → decompilação, análise de tipos, scripting em Python/Java para automação.
- **IDA Pro** → disassembly, Hex-Rays, FLIRT para bibliotecas, IDC/Python.
- **radare2 / rizin** → scripting e análise rápida via CLI.
- **010 Editor / Kaitai Struct** → formatos de arquivo com templates declarativos.
- Identifique bibliotecas e runtime antes de ler código: reimplementar `memcpy` como
  mistério é perda de tempo. Use assinaturas FLIRT/SigMaker ou equivalente.
- Nomeie funções e tipos à medida que entende. O mapa é o artefato de saída.

## 4. Análise dinâmica

- **x64dbg / WinDbg** (Windows), **gdb / lldb** (Unix), **Frida** (instrumentação),
  **QEMU / Unicorn** (emulação).
- Breakpoints em pontos de validação, comparação de strings, alocação e I/O.
- Trace de chamadas e argumentos; observe estado de memória antes e depois de cada função.
- Compare execução com entradas válidas e inválidas — a diferença localiza a lógica de decisão.
- Isole em VM ou ambiente descartável. Artefatos desconhecidos podem ter comportamento
  persistente ou de rede.

## 5. Formatos e protocolos

- Para formatos: encontre magic bytes, estrutura de cabeçalho, campos de tamanho/offset,
  checksums e seções. Documente como uma especificação com offsets e tipos.
- Para protocolos: capture tráfego (Wireshark), separe framing de payload, identifique
  handshakes, sequenciamento, codificação e campos de integridade.
- Escreva um parser independente e valide-o contra amostras reais. Se o parser reproduz
  o comportamento, o entendimento está correto.

## 6. Ofuscação e empacotamento

- Detecte packers por entropia, seções suspeitas, imports mínimos e ponto de entrada
  atípico.
- Descompacte em memória e despeje o image original antes de analisar — use um dump
  consistente e verifique com o mapa de seções.
- Para código ofuscado: controle de fluxo, constantes codificadas e virtualização. Trabalhe
  de fora para dentro — identifique primeiro a interface, depois o núcleo.
- Documente o que foi ofuscado e como foi recuperado, para que outro analista reproduza.

## 7. Anti-análise

- Técnicas comuns: detecção de debugger, timing checks, integridade de código, anti-VM,
  exceções como fluxo, criptografia de strings, syscalls indiretos.
- Abordagem: observe primeiro com instrumentação leve (Frida/ETW), depois decida se precisa
  patch, emulação ou correlação de comportamento.
- Prefira entender o mecanismo a aplicar um patch cego. Patch sem compreensão gera falso
  positivo e análise que não fecha.

## 8. Entrega

- Relatório com: pergunta respondida, versão/hash analisada, ferramentas e configuração,
  endereços e offsets, estruturas recuperadas, evidência (capturas, traces, snippets) e
  limitações do que não foi confirmado.
- Inclua um script ou parser reproduzível quando aplicável.
- Separe fato de inferência. "A função em 0x1400a3b20 compara o argumento com 'ADMIN'"
  é fato; "provavelmente é autorização" é inferência — marque como tal.

Escopo: analise sistemas que você tem autorização para inspecionar. O conteúdo desta skill
é metodologia de análise, não uma ferramenta de circumventção de licenças.
