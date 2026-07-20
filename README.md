# EnglishForge

Aplicativo Android offline para gerir um plano pessoal de inglês A1–C2, combater procrastinação e acelerar speaking.

## Principais módulos
- Dashboard com missão mínima, XP, sequência, faltas e dívida de estudo.
- Grade curricular A1–C2 baseada no plano de 8 meses.
- Tarefas, plano semanal e alarmes locais.
- Gravação cronológica de speaking e reprodução de áudios.
- Banco de palavras/frases e revisão por uso.
- Criador e executor de quizzes offline.
- Biblioteca antiacúmulo com estados **ativo / espera / concluído**.
- Player de imersão com velocidade de 0,5× a 2× para shadowing.
- Modo anti-procrastinação de 2 minutos.
- Backup JSON local.

## Gerar APK exclusivamente pelo GitHub Actions
1. Crie um repositório no GitHub.
2. Extraia este ZIP e envie todos os ficheiros para a branch `main`.
3. Abra **Actions → Build Android APK → Run workflow**.
4. Aguarde o job terminar.
5. No fim da execução, descarregue o artefacto **EnglishForge-APK**.
6. Dentro do ZIP do artefacto haverá APKs por arquitetura. Na maioria dos telefones atuais use `app-arm64-v8a-release.apk`.

O workflow instala Flutter, gera a pasta Android, configura permissões, analisa, testa, compila em release e publica os APKs como artefactos. Não cria página web e não exige Android Studio.

## Observações
- Os dados ficam no dispositivo. Não há conta, anúncios ou servidor.
- O catálogo de materiais guarda referências aos ficheiros escolhidos; mover ou apagar esses ficheiros fora do app pode invalidar o caminho.
- O APK gerado pelo workflow usa assinatura de debug/release automática do Flutter para instalação direta. Para Play Store, configure uma keystore privada.
- Alarmes exatos podem depender da autorização do Android e das regras de economia de bateria do fabricante.

## Estrutura
- `lib/main.dart`: aplicação completa.
- `.github/workflows/build-apk.yml`: CI para gerar APK.
- `tool/configure_android.dart`: permissões Android aplicadas durante o CI.
- `test/widget_test.dart`: teste básico de abertura.
