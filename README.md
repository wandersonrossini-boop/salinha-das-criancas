# Salinha das Crianças 🐑✨

Um aplicativo premium internacional projetado para professores de ministério infantil, inspirado em plataformas de excelência educacional e engajamento como **Duolingo**, **Khan Academy Kids** e **Kahoot**.

---

## 🚀 Tecnologias Utilizadas
*   **Framework**: Flutter (com suporte total para Web)
*   **Gerenciamento de Estado**: `flutter_bloc` / `hydrated_bloc`
*   **Banco de Dados & Hospedagem**: Firebase (Firestore, Auth, Hosting)
*   **Estilização & Design**: Custom Design System baseado em Material Design 3 (MD3) com tipografias lúdicas (`Fredoka` e `Nunito`).

---

## 📁 Estrutura de Pastas (Arquitetura Limpa)

O projeto segue uma estrutura baseada em recursos (**Feature-First**), facilitando a escalabilidade e manutenção:

```text
lib/
├── core/                  # Recursos compartilhados por todo o aplicativo
│   ├── components/        # Widgets globais reutilizáveis
│   ├── db/                # Helper unificado de banco de dados (Firestore/Web)
│   ├── design_system/     # Definições do sistema de design global
│   └── theme/             # Configuração de temas e estilos visuais
└── features/              # Funcionalidades isoladas por contexto de negócio
    ├── ai_planner/        # Planejador de Aulas Inteligente com IA
    ├── auth/              # Fluxo de Autenticação de Usuários
    ├── class_mode/        # Modo Aula interativo
    ├── games/             # Central de Jogos Lúdicos
    ├── home/              # Dashboard Principal
    ├── roulette/          # Roleta de perguntas/atividades
    ├── students/          # Gestão de alunos
    └── teams/             # Gestão de equipes/grupos
```

---

## 🎨 Identidade Visual & Design System
*   **Tipografia**:
    *   `Fredoka`: Para títulos, cabeçalhos e botões de destaque (estilo amigável e premium).
    *   `Nunito`: Para descrições, textos longos e corpo do aplicativo (alta legibilidade).
*   **Cores do Projeto**:
    *   📘 **Plano de Aula**: Azul
    *   📒 **Jogos**: Amarelo
    *   📗 **Biblioteca**: Verde
    *   📙 **Pais**: Laranja
    *   🔮 **IA Assistente**: Roxo
    *   📓 **Relatórios**: Slate (Cinza Azulado)
*   **Mascote (Ovelhinha 3D)**: Integrada globalmente via `<MascotWidget>` para fornecer feedback emocional nas interações dos alunos.

---

## 🛠️ Como Executar o Projeto

1. **Pré-requisitos**:
    *   Flutter SDK instalado e configurado.
    *   Acesso aos serviços do Firebase (configurados no arquivo `firebase.json` e `lib/firebase_options.dart`).

2. **Obter dependências**:
    ```bash
    flutter pub get
    ```

3. **Executar localmente**:
    ```bash
    flutter run -d chrome
    ```

4. **Publicar/Deploy**:
    O projeto conta com o script de deploy automatizado:
    ```powershell
    ./deploy_app.ps1
    ```
