# ADR-014 — Tema Claro / Escuro / Sistema (Fase 9, Lote J)

## Contexto
A app tinha só o tema escuro. As cores eram constantes (`AppColors.x`), usadas
em ~190 sítios de 51 arquivos, muitas dentro de widgets `const`. O utilizador
pediu Claro, Escuro e Sistema, aplicado à app inteira e guardado.

## Decisão
1. **Duas paletas** (`AppPalette.dark` = a original, intacta; `AppPalette.light`).
   `AppColors` mantém os mesmos nomes de papel mas passa a *getters* que
   devolvem a cor da paleta ativa (`AppPalette.current`). Assim nenhum ecrã
   teve de mudar de API; só se retirou `const` onde havia cores (32 sítios).
2. **`AppTheme.light()` e `AppTheme.dark()`** constroem-se cada um a partir da
   *sua* paleta (nunca da ativa) e o `MaterialApp` escolhe com `themeMode`
   (Sistema segue o telemóvel em tempo real).
3. **`PaletteScope`** (`MaterialApp.builder`) põe a paleta ativa igual ao brilho
   do tema e, quando muda, reconstrói a árvore uma vez (`markNeedsBuild`
   recursivo, a técnica da documentação do Flutter para mudar de idioma): o
   estado, os scrolls e a navegação mantêm-se. Sem isto, widgets que leem
   `AppColors` sem depender de `Theme` ficariam com as cores antigas.
4. **Persistência**: `Settings.themeMode` (`system|light|dark`, por defeito
   `dark` — o aspeto de quem já usava a app); base de dados v7.
5. **Contraste**: a paleta clara cumpre WCAG AA nos papéis de texto
   (`app_palette_test` verifica as duas paletas).
6. `CustomPainter` que lê cores ao pintar guarda o brilho e repinta quando muda.

## Consequências
- `AppColors.x` já não pode ser usado em expressões `const` (o analisador avisa).
- Cores novas: acrescentar ao `AppPalette` (as duas) e ao `AppColors`.
- Um `static final` que guarde uma cor de `AppColors` ficaria preso à paleta do
  arranque: ler sempre dentro de `build`/`paint`.
- Verificar visualmente cada ecrã no tema claro (ver `QA_FASE8_CHECKLIST.md`, §8).
