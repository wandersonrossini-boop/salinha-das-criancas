# 🤖 Manual da Inteligência Artificial (AI_GUIDELINES)

**ALERTA PARA QUALQUER IA ASSISTENTE:** 
Leia este documento **ANTES** de realizar qualquer alteração, refatoração ou implementação de funcionalidade no aplicativo `Salinha das Crianças`.

## 1. Visão Geral do Projeto
O **Salinha das Crianças** é um aplicativo Web/Mobile desenvolvido em Flutter, com foco em auxiliar professores do ministério infantil cristão. O aplicativo fornece ferramentas gamificadas e inteligentes para criar aulas, separar equipes, fazer chamadas e interagir com os alunos.

## 2. Estrutura de Diretórios (Arquitetura Atual)
O aplicativo utiliza uma estrutura baseada em features. **Não altere esta estrutura sem a aprovação explícita do desenvolvedor humano.**

```text
lib/
├── core/                       # Núcleo da aplicação (código reaproveitável)
│   ├── db/                     # Configurações e helpers do banco de dados (SQLite)
│   └── theme/                  # Definições de cores e tema do app
├── features/                   # Funcionalidades separadas por domínio
│   ├── ai_planner/             # Módulo de Geração de Planos de Aula (Integração Gemini)
│   ├── class_mode/             # Modo Aula (Apresentação interativa para TV/Projetor)
│   ├── games/                  # Jogos Interativos (ex: Quiz)
│   ├── home/                   # Tela inicial e navegação
│   ├── roulette/               # Funcionalidade de Roleta (sorteios)
│   ├── students/               # Módulo de cadastro e chamada de alunos
│   └── teams/                  # Módulo de separação e gestão de equipes
└── main.dart                   # Ponto de entrada do aplicativo
```

## 3. Tecnologias e Ferramentas Padrão
Sempre priorize a stack e os pacotes atuais antes de sugerir novas dependências.

- **Framework:** Flutter (versão de Release Web).
- **Gerenciamento de Estado:** Atualmente baseado em estados locais (`setState`) com transição futura para padrão BLoC/Cubit. Se for gerenciar estado, respeite a arquitetura leve atual até uma refatoração.
- **Banco de Dados:** SQLite (usando pacote `sqflite` e `sqflite_common_ffi_web` para suporte Web). Todas as operações devem passar pelo `DatabaseHelper`.
- **Inteligência Artificial:** O aplicativo utiliza o pacote oficial `google_generative_ai`.
- **Hospedagem:** Firebase Hosting.

## 4. Regras Rígidas para Modificação (CRÍTICO)

1. **A API do Gemini (Google AI):**
   - O modelo oficial suportado e validado em produção para a chave deste projeto é o **`gemini-2.5-flash`**.
   - A família `gemini-3.6` NÃO DEVE ser utilizada, pois foi descontinuada/bloqueada para a chave primária de acesso ou resulta em erro 400.
   - O `gemini_service.dart` deve sempre ler a `apiKey` via `SharedPreferences`. Nunca faça uma requisição com a chave vazia ou hardcoded.

2. **Web Release e Compatibilidade:**
   - Este app roda primariamente em navegadores (Flutter Web). Qualquer pacote novo deve ter suporte nativo ao ambiente Web.
   - Jamais inclua pacotes como `dart:io` diretamente em arquivos que são chamados na web, para evitar quebra de compilação.

3. **Design e UX (Interface do Usuário):**
   - Utilize a paleta de cores definida em `app_colors.dart` e `app_theme.dart`.
   - O design precisa ser vibrante, arredondado (bordas suaves) e infantil, evitando layouts frios ou corporativos.
   - Todas as modificações visuais devem se adaptar a telas mobile e desktop de forma fluída (Responsividade).

4. **Regra de Refatoração:**
   - **NÃO** realize grandes reestruturações arquiteturais sem que o usuário solicite explicitamente "Refatore a arquitetura". Foque em fazer a funcionalidade pedida trabalhar corretamente dentro do paradigma existente.

## 5. Como Iniciar o App
- Para compilar a versão final e atualizar o deploy:
  ```bash
  flutter build web --release
  firebase deploy --only hosting
  ```

---
*Assinado: Antigravity Agent, Julho de 2026. Documento fixo para continuidade de código.*
