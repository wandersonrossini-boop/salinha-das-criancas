# ADR-001 — AulaStatusService

## Status
Aceito — 03/08/2026

## Contexto
A Home ("Hoje na Aula") precisa reagir ao momento real da aula do dia
(chamada pendente → aula não iniciada → aula em andamento → concluída),
mas hoje ela só verifica se existe um `LessonPlan` salvo. Não existe
nenhuma persistência do progresso do Modo Ministrar: `ClassModeScreen`
guarda a etapa atual (`_expandedIndex`) apenas em memória do widget, e
se reseta a cada vez que a tela é recriada.

Ao investigar o código (branch `recovery/office-stable-2026-07-31`),
identificamos que **parte da persistência necessária já existe**:

- `attendance_date` (SharedPreferences) — já grava a data da última
  chamada feita, usado hoje só pelo card "Turma de Hoje".
- `lesson_completed_<lessonId>` (SharedPreferences, gravado por
  `DatabaseHelper.markLessonAsCompleted`) — já marca aula concluída ao
  clicar em "Finalizar Ministração".

O único dado que falta persistir é a **etapa atual do Modo Ministrar**.

## Decisão
Criar um `AulaStatusService` pequeno e isolado, usando
`SharedPreferences`, que:

**Lê:**
- `lesson_completed_<lessonId>` (já existente, sem duplicar)
- `attendance_date` (já existente, sem duplicar)
- `etapa_atual_<lessonId>` + `etapa_atual_<lessonId>_data` (novo)

**Grava (apenas isto):**
- `etapa_atual_<lessonId>` — índice da etapa atual
- `etapa_atual_<lessonId>_data` — data em que essa etapa foi salva
  (permite resetar automaticamente em um novo dia)

**Explicitamente NÃO grava:**
- Alunos
- LessonPlan (conteúdo da aula)
- Equipes / pontos
- Perguntas de quiz
- Relatórios

Qualquer necessidade fora desse escopo deve usar os serviços já
existentes (`DatabaseHelper`, `ChamadaScreen`, etc.), não este serviço.

## Motivação
- Manter a arquitetura atual (`setState` + `SharedPreferences` +
  `DatabaseHelper`), conforme `MANUAL_DA_IA.md`, item 4 ("Regra de
  Refatoração").
- Evitar introduzir `flutter_bloc`/`hydrated_bloc` — esses pacotes
  estão no `pubspec.yaml`, mas não há nenhum uso real (`Cubit`, `Bloc`,
  `BlocProvider`) em todo o `lib/`. Adotá-los agora seria uma
  reestruturação arquitetural não solicitada.
- Evitar Firestore nesta fase — não há necessidade real ainda de
  sincronizar o progresso da aula entre dispositivos.
- Reaproveitar chaves de `SharedPreferences` já existentes
  (`attendance_date`, `lesson_completed_<id>`) em vez de recriar essa
  informação em outro formato, reduzindo a superfície de mudança.
- Permitir que o Hero Card da Home ("Hoje na Aula") se torne reativo
  ao estado real da aula, sem alterar seu layout/identidade visual.

## Consequências
- **Positivo:** implementação pequena, isolada, offline-first, sem
  dependências novas, fácil de testar isoladamente (dado que é uma
  classe estática simples de I/O).
- **Positivo:** cada chave é escopada por `lessonId`, então trocar de
  plano de aula não mistura o progresso de uma aula com outra.
- **Negativo conhecido:** não sincroniza entre dispositivos — se o
  professor trocar de celular/navegador no meio da aula, o progresso
  de etapa não acompanha (chamada e conclusão, que já eram
  Firestore/local, têm o mesmo comportamento hoje).
- **Caminho de evolução:** se/quando surgir necessidade real de
  multi-dispositivo, histórico de sessões ou relatórios detalhados por
  aula, substituir este serviço por uma entidade `ClassSession` com
  `Repository` sobre Firestore. Este ADR deliberadamente adia essa
  camada até haver essa necessidade concreta.

## Alternativas consideradas
1. **`ClassSession` + Repository + Firestore desde já** — rejeitada
   por aumentar complexidade sem resolver um problema atual; adiada
   para quando houver necessidade real (ver "Caminho de evolução").
2. **Usar `flutter_bloc`/`hydrated_bloc`** (já no `pubspec.yaml`) —
   rejeitada por exigir migrar Home, ClassMode e Chamada ao mesmo
   tempo, o que fere a regra de não fazer grandes refatorações sem
   solicitação explícita.
