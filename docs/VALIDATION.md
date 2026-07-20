# Relatório de validação — EnglishForge 2.0.1+3

Data: 20 de julho de 2026

## Correções desta versão

Foram corrigidos os 11 diagnósticos apresentados pelo GitHub Actions:

- duas chamadas antigas `FilePicker.platform.pickFiles`, substituídas pela API estática `FilePicker.pickFiles`;
- o ícone inexistente `Icons.check_small`;
- o parâmetro ausente `eyebrow` no `SectionHeader`;
- o teste-modelo `widget_test.dart` que ainda tentava instanciar `MyApp`;
- dois usos de identificadores descartados com múltiplos sublinhados;
- um bloco `if` sem chavetas;
- a coleção do `SectionHeader`, atualizada para elemento nulo-consciente.

## Verificações executadas no ambiente de geração

- 49 ficheiros Dart analisados com uma gramática tree-sitter para Dart: nenhum nó de erro sintático.
- Todos os imports Dart relativos verificados: nenhum ficheiro local em falta.
- `assets/data/curriculum.json` validado como JSON.
- Currículo confirmado com 6 níveis e 65 unidades: A1 (6), A2 (10), B1 (12), B2 (13), C1 (12), C2 (12).
- `tool/configure_android.py` compilado pelo Python para validar a sintaxe.
- Estrutura do projeto e ficheiros do workflow revistos após as correções.

## Validação realizada pelo GitHub Actions

O workflow é a verificação autoritativa da integração Flutter/Gradle/Android. Ele executa:

1. resolução das dependências;
2. apresentação do grafo de dependências;
3. `flutter analyze --no-fatal-infos`;
4. `flutter test --reporter=expanded`;
5. compilação do APK universal em modo release;
6. compilação dos APKs separados por ABI;
7. geração de checksums SHA-256.

O ambiente em que o projeto foi corrigido não contém Flutter SDK nem Android SDK. Portanto, este relatório não afirma que o APK foi compilado localmente. A execução seguinte do GitHub Actions deve ser usada para confirmar a análise semântica completa, os testes Flutter e a compilação nativa.
