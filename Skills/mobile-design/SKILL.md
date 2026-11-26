---
name: mobile-design
description: "Design native mobile interfaces for iOS and Android. Trigger on app screens, React Native / SwiftUI / Compose UI, mobile redesigns, touch interaction, safe areas, and platform convention decisions. Do not use for responsive web — use frontend-design."
---

# Mobile Design

Mobile não é web estreita. Respeite as convenções da plataforma — o usuário traz expectativas
do sistema operacional e quebra-las custa atenção e aprendizado.

## 1. Escolha a plataforma primeiro

- iOS → siga a *Human Interface Guidelines*. Navegação com `UINavigationController`-like
  push/pop, sheet modais, tab bar inferior, swipe-from-edge para voltar.
- Android → siga o *Material Design 3*. App bars, navigation rail/bottom nav, snackbars,
  back button do sistema, predictive back.
- Multiplataforma (React Native / Flutter / Compose Multiplatform) → escolha uma plataforma
  como base e adapte a outra explicitamente. Nunca produza um híbrido que pareça estranho
  nas duas.

## 2. Fundamentos de toque

- Área mínima de toque: 44×44pt no iOS, 48×48dp no Android.
- Espaçamento entre alvos de toque: no mínimo 8pt/dp.
- Gesto de voltar do sistema deve continuar funcionando. Não sequestre o botão de voltar.
- Ações destrutivas exigem confirmação; ações comuns e reversíveis não pedem permissão.
- Feedback imediato a cada toque: mudança de estado visual ou háptico. Nunca deixe o usuário
  sem resposta em menos de 100ms.

## 3. Safe areas e layout

- Respeite `safeAreaInsets` / `WindowCompat` / `safe-area-inset-*`: status bar, notch,
  Dynamic Island, home indicator, teclado virtual.
- Nunca coloque conteúdo interativo sob o home indicator ou atrás da status bar.
- Ajuste a interface quando o teclado aparece. Use `KeyboardAvoidingView` / `imePadding`
  para manter o campo ativo visível.
- Suporte orientação retrato e paisagem, ou declare explicitamente que o app é retrato-only.
- Teste em telas pequenas (iPhone SE / 360dp) e grandes (Pro Max / tablets).

## 4. Tipografia e densidade

- iOS: corpo 16pt mínimo, títulos comDynamic Type. Android: corpo 16sp mínimo.
- Suporte fontes dinâmicas do sistema (Dynamic Type / font scale). Layout deve crescer sem
  cortar texto — use `Text` com número de linhas ilimitado e containers flexíveis.
- Hierarquia por tamanho e peso, não por cor sozinha.
- Texto truncado é exceção; se ocorrer, truncamento com reticências e acesso ao conteúdo
  completo por outra via.

## 5. Navegação e estrutura

- Uma hierarquia clara: o usuário sempre sabe onde está e como volta.
- Tab bar para 3–5 seções de primeiro nível. Mais de 5, use "Mais".
- Modais apenas para tarefas autônomas que devem ser completadas ou descartadas.
- Listas longas usam virtualization (`FlatList`/`LazyColumn`/`UICollectionView` diferencial).
  Nunca renderize milhares de linhas de uma vez.
- Estado de carregamento: skeleton quando o conteúdo é conhecido, spinner quando não é.
- Estados vazios e de erro precisam de ação explícita, não apenas mensagem.

## 6. Movimento e hápticos

- Transições seguem o modelo mental da plataforma: push horizontal no iOS, elevação e
  compartilhamento de elemento no Android.
- Use hápticos com parcimônia: sucesso, seleção, aviso. Não vibrei em cada scroll.
- Respeite `prefers-reduced-motion` / "Remover animações" do sistema.

## 7. Acessibilidade mobile

- VoiceOver e TalkBack: rótulos, traits/roles e ordem de leitura corretos.
- Toque único ativa; gestures complexos precisam de alternativa acessível.
- Contraste mínimo 4.5:1 para texto; alvos de toque com folga.
- Teste com o leitor de tela ligado e com fonte do sistema no tamanho máximo.

## 8. Checklist antes de entregar

- Convenções da plataforma seguidas?
- Safe areas e teclado tratados?
- Alvos de toque com tamanho e espaçamento corretos?
- Back do sistema funciona?
- Dynamic Type / font scale não quebra o layout?
- Listas longas virtualizadas?
- Estados vazios, carregando e erro implementados?
- VoiceOver / TalkBack e contraste verificados?
- Testado em dispositivo pequeno e grande?
