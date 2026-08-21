# 🎯 Diretrizes Permanentes de Produto e UX — Salinha das Crianças

> **Status:** Documento Vivo / Referência Oficial  
> **Complementa:** `MANUAL_DO_USUARIO.md` e `MANUAL_DA_IA.md`

---

## 🎯 1. Filosofia Central do Produto
O **Salinha das Crianças** é um copiloto para professores do ministério infantil cristão. Seu objetivo principal é **reduzir a carga cognitiva** durante a aula no domingo de manhã.

Toda nova funcionalidade ou alteração de tela DEVE responder positivamente às perguntas:
1. *Facilita a vida do professor com a mão no celular?*
2. *Reduz cliques e elimina distrações?*
3. *Funciona naturalmente em uma sala com crianças em movimento?*

Se a resposta for negativa, a solução deve ser refeita.

---

## 🔄 2. O Fluxo Oficial da Aula
O aplicativo acompanha obrigatoriamente três momentos do domingo:
1. **Preparação:** Visualização/geração do plano, memorização do versículo e checagem de materiais.
2. **Execução:** Chamada rápida, quebra-gelo, história, dinâmica/jogo e oração.
3. **Encerramento:** Pontuação de equipes, registros de faltas e relatório final.

Nenhuma funcionalidade deve ser criada desconectada deste ciclo.

---

## 🎨 3. Diretrizes Rígidas de UX e Design

### A. Prioridade de Tarefa e Ação Única
* Cada tela deve possuir **apenas uma ação principal em destaque** (Primary Action).
* Ações secundárias devem ser visivelmente discretas.
* O estado da tela muda com a tarefa: se a chamada foi feita, o botão vira *“Continuar Aula”*.

### B. Continuidade e Redução de Carga
* O professor nunca deve perder a noção de onde está no roteiro.
* **Proibido:** Múltiplos botões com a mesma função, cards com informações duplicadas (ex: repetindo versículo no topo e em baixo) e termos burocráticos.

### C. Visual Profissional e Acolhedor
* Evitar excesso de emojis soltos no texto, gradientes pesados e visual saturado de "template genérico".
* Usar o mascote da salinha apenas em momentos afetivos estratégicos (feedback de conclusão, acolhimento, estados vazios).
* Priorizar espaço em branco, boa tipografia, cantos arredondados suaves e ícones vetoriais do Material.

---

## 🏫 4. Pedagogia Infantil e Realidade de Sala

### A. Diferenciação por Faixa Etária
O aplicativo deve adaptar a profundidade do conteúdo às etapas de desenvolvimento:
* **4–6 anos:** Aprendizagem concreta, forte apoio visual/imagens, movimento corporal, pouca leitura.
* **7–8 anos:** Associação visual/texto, pequenas sequências de lógica, cooperação em grupo, dramatização.
* **9–11 anos:** Interpretação textual, aplicação prática no cotidiano, desafios, autonomia e dinâmicas competitivas.

### B. Suporte a Turmas Mistas (Regra de Ouro)
O aplicativo deve permitir que a **mesma história bíblica** atenda uma sala com idades variadas simultaneamente, adaptando apenas a complexidade das perguntas (Quiz) e das dinâmicas, sem exigir múltiplos planos de aula paralelos para a mesma sala.

---

## 🛠️ 5. Padrões de Telas Registrados

### Home (Painel Principal)
* **Hero Card Único:** Reúne a lição ativa, o versículo chave, a contagem temporal dinâmicamente e **uma única ação primária**.
* **Cards Auxiliares:** Aniversários, Pedidos de Oração e Faltas funcionam como apoio secundário abaixo do Hero Card.
* **Saudação:** Preservar o perfil do professor logado (*"Bom dia, Wan!"*).

### Modo Ministrar (Roteiro)
* Fluxo linear e focado.
* Botão `Próxima Etapa` como protagonista absoluto no fim de cada fase.
* Chamada acessível como atalho discreto no topo, sem poluir o roteiro.

### Formulários e Cadastros
* Entradas nativas e rápidas: **Tirar foto / Escolher da galeria** (jamais pedir links de imagem por URL).
* Campos voltados à rotina infantil (ex: *Alergias ou Cuidados Especiais*).

---

## 🏗️ 6. Diretrizes Técnicas (Arquitetura & Web)
1. **Intenção na UI:** O método `build()` dos widgets nunca deve conter regras de negócio complexas. As intenções (ações, cores e rótulos) devem vir limpas de ViewModels/Presenters em Dart puro.
2. **Compatibilidade Flutter Web:** Todos os pacotes e chamadas devem compilar e rodar nativamente em browsers sem bibliotecas exclusivas de desktop/mobile (`dart:io`).
