# EnglishForge 2.0

Aplicação Android **offline-first** para gerir um plano pessoal de aprendizagem de inglês do A1 ao C2. O projeto foi construído para reduzir procrastinação, excesso de materiais e medo de falar, e não apenas para exibir uma lista de lições.

## O que torna este projeto diferente

O EnglishForge funciona como um **sistema operacional de aprendizagem pessoal**:

- converte o currículo A1–C2 num próximo passo concreto;
- usa uma missão mínima diária em vez de uma página inicial cheia de opções;
- aplica a regra “nunca faltar dois dias seguidos”;
- cria dívida de estudo automaticamente para dias perdidos e recupera-a aos poucos;
- permite somente um material ativo por habilidade, movendo o anterior para espera;
- mantém uma escada gradual de speaking e uma linha do tempo de gravações;
- combina repetição espaçada, quizzes, exercícios, calendário e imersão;
- oferece um reprodutor de inglês com velocidade, retorno de 10 s, loop A–B e marcadores;
- guarda tudo localmente em SQLite, sem conta e sem servidor.

## Funcionalidades implementadas

### Planeamento e consistência

- onboarding com nível, rotina e horário;
- calendário mensal e agenda diária;
- criação de blocos com tipo, duração, data, hora e notificação;
- modelo semanal automático;
- modo foco com cronómetro por blocos;
- rotinas mínima e ideal;
- sequência de estudo, XP e minutos;
- faltas, motivos e dívida de minutos;
- recuperação leve de 2, 5, 10 ou 20 minutos;
- radar de risco de abandono.

### Currículo

- base de dados curricular em JSON;
- 65 unidades distribuídas entre A1, A2, B1, B2, C1 e C2;
- gramática, vocabulário, pronúncia e foco por habilidade;
- roteiro dos oito meses;
- progresso por unidade em três estados;
- próxima unidade sugerida automaticamente.

### Speaking

- gravação local de voz;
- títulos, temas, autoavaliação e observações;
- reprodução e eliminação das gravações;
- comparação com gravações antigas;
- escada de confiança para speaking;
- sugestões de temas e microações de dois minutos.

### Vocabulário, frases e avaliação

- banco de palavras e frases;
- significado, exemplo, categoria e etiquetas;
- revisão por repetição espaçada inspirada no SM-2;
- cartões vencidos e classificação de resposta;
- criação e edição de quizzes;
- respostas predefinidas, explicação e feedback final;
- histórico e média dos quizzes;
- exercícios de tradução, lacunas, reescrita e resposta aberta;
- resposta-modelo e registo de precisão.

### Materiais e imersão

- importação de áudio, vídeo, PDF, EPUB, texto e DOCX;
- estados: ativo, espera, concluído e arquivo;
- nível, habilidade, notas e progresso;
- regra automática de um recurso ativo por habilidade;
- reprodutor interno de áudio com 0,5× a 2×;
- voltar/avançar 10 segundos;
- loop A–B para shadowing;
- marcadores com transcrição, tradução ou nota;
- retoma da última posição.

### Dados e interface

- SQLite com 12 tabelas;
- backup e restauro JSON;
- tema claro, escuro e sistema;
- interface Material 3 responsiva com navegação inferior ou lateral;
- aplicação em português com conteúdos de inglês;
- funcionamento sem internet depois da instalação.

## Estrutura do projeto

```text
english_forge/
├── .github/workflows/build-apk.yml
├── assets/
│   ├── data/curriculum.json
│   └── images/app_icon.png
├── lib/
│   ├── controllers/
│   ├── core/
│   │   ├── services/
│   │   ├── theme/
│   │   └── utils/
│   ├── models/
│   ├── repositories/
│   ├── screens/
│   └── widgets/
├── test/
├── tool/configure_android.py
└── pubspec.yaml
```

## Gerar o APK sem Android Studio

1. Extraia a pasta `english_forge`.
2. Crie um repositório no GitHub.
3. Envie **o conteúdo da pasta**, incluindo `.github`.
4. Abra **Actions**.
5. Escolha **Build EnglishForge APK**.
6. Clique em **Run workflow**.
7. Quando terminar, abra a execução e descarregue o artefacto `EnglishForge-APK-...`.

O artefacto contém:

- `EnglishForge-universal-release.apk`: escolha mais simples, funciona nas arquiteturas incluídas;
- `app-arm64-v8a-release.apk`: indicado para a maioria dos telemóveis Android atuais;
- `app-armeabi-v7a-release.apk`: Android ARM de 32 bits;
- `app-x86_64-release.apk`: emuladores e alguns dispositivos x86;
- `SHA256SUMS.txt`: somas para verificar os ficheiros.

Não ative GitHub Pages. O workflow apenas testa e compila o APK.

## O que o workflow faz

1. instala Java 17 e Flutter 3.44.4;
2. instala Android API 36;
3. gera somente a plataforma Android com `flutter create --no-pub`;
4. aplica automaticamente AGP 8.11.1, Gradle 8.13, Java 17 e desugaring;
5. acrescenta permissões de microfone e notificações;
6. configura os receivers que restauram alarmes depois de reiniciar o telefone;
7. aplica o ícone do EnglishForge;
8. executa resolução de dependências, análise estática e testes;
9. gera APK universal e APKs por arquitetura;
10. publica os APKs como artefactos do GitHub Actions.

## Validação incluída

- testes de repetição espaçada, sequência e integridade do currículo em `test/`;
- relatório técnico em `docs/VALIDATION.md`;
- mapa dos módulos em `docs/PROJECT_MAP.md`;
- o workflow interrompe se a resolução de dependências, análise, testes ou build falhar.

## Privacidade e limitações deliberadas

- Não existe login, publicidade, telemetria ou sincronização remota.
- O backup JSON guarda os registos e caminhos, mas não duplica ficheiros grandes de áudio, vídeo ou PDF.
- A avaliação da pronúncia é uma autoavaliação estruturada; reconhecimento fonético por IA exigiria modelos adicionais e aumentaria muito o APK.
- PDFs, EPUBs, DOCX e vídeos são organizados pela biblioteca, mas o leitor interno especializado nesta versão é dedicado a áudio.
- Alguns fabricantes restringem alarmes em segundo plano; o utilizador pode precisar permitir atividade em segundo plano nas definições do telefone.

## Desenvolvimento local opcional

Android Studio não é necessário. Com Flutter e Android SDK instalados:

```bash
flutter create --platforms=android --project-name english_forge --org com.piaraly --no-pub .
python3 tool/configure_android.py
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

## Banco de dados

Tabelas principais:

- `study_events`
- `vocabulary`
- `recordings`
- `materials`
- `quizzes`
- `quiz_questions`
- `quiz_attempts`
- `exercises`
- `curriculum_progress`
- `study_logs`
- `study_debts`
- `player_bookmarks`

## Versão

**2.0.1+3** — correção de compatibilidade com `file_picker` 11, componentes visuais e teste de widget do workflow.
