# 🎨 Design Specification: Modal de Edição de Alarme (Dark Mode)

Este documento especifica o guia de estilos, paleta de cores, tipografia, componentes e estados visuais para o componente de modal de configuração/edição de alarme.

---

## 📐 1. Layout & Estrutura

* **Tipo de Componente:** Modal / Card Flutuante com cantos arredondados.
* **Alinhamento:** Centralizado na tela (vertical e horizontalmente).
* **Backdrop (Fundo da tela):** Overlay escurecido sólido com opacidade para focar no modal.
* **Borda e Sombra:** Bordas arredondadas suaves (`border-radius`) com leve elevação / sombra difusa para separação de profundidade.

---

## 🎨 2. Paleta de Cores (Dark Theme)

| Elemento | Hex / Cor | Descrição |
| :--- | :--- | :--- |
| **Fundo da Página** | `#121212` / `#1A1A1A` | Fundo principal da aplicação |
| **Fundo do Card (Modal)** | `#1E1E1E` | Superfície do container principal |
| **Container de Inputs / Seletor de Hora** | `#2C2C2E` | Fundo de destaque para campos e dígitos |
| **Dígito Selecionado / Foco** | `#3A3A3C` | Realce para o bloco de dígitos em edição ativa |
| **Texto Primário** | `#FFFFFF` | Dígitos do relógio e títulos de alto contraste |
| **Texto Secundário / Labels** | `#A1A1A6` | Rótulos ("Repetir:", "Etiqueta:", "Som:") |
| **Bordas / Separadores Sutis** | `#38383A` | Delimitação de campos e botões |
| **Botões Neutros** | `#3A3A3C` | Fundo para "Cancelar" e botões de dias da semana |
| **Botão de Destaque (Salvar)** | `#E5E5EA` / `#FFFFFF` | Fundo de alto contraste para ação primária (texto escuro `#1C1C1E`) |

---

## 🔤 3. Tipografia

* **Fonte Principal:** San Francisco (`SF Pro Display` / `SF Pro Text`) ou alternativas modernas (`Inter`, `Roboto`).
* **Display de Horário:**
  * **Tamanho:** ~`36px` a `42px`
  * **Peso:** `Semi-Bold` / `Bold`
  * **Família Numérica:** Monospaçada ou tabular figures (`font-variant-numeric: tabular-nums`) para evitar que a largura mude conforme os dígitos alteram.
* **Labels e Textos dos Campos:**
  * **Tamanho:** `13px` a `14px`
  * **Peso:** `Regular` / `Medium`
* **Textos de Botões:**
  * **Tamanho:** `13px` a `14px`
  * **Peso:** `Medium` / `Semi-Bold`

---

## 🧩 4. Especificação dos Componentes

### 1. Seletor de Hora (Time Display & Selector)
* **Estrutura:** Container retangular horizontal centralizado no topo com cantos arredondados (`8px`).
* **Comportamento:**
  * Separado visualmente em **Horas**, **Separador (`:`)** e **Minutos**.
  * O bloco em foco/edição (ex: minutos `30`) recebe um fundo destacado (`#3A3A3C`) com cantos arredondados, indicando seleção para digitação ou rolagem.

### 2. Seletor de Dias da Semana ("Repetir")
* **Estrutura:** Linha horizontal com a label à esquerda ("Repetir:") e 7 botões compactos circulares/retangulares com cantos arredondados (`6px`).
* **Dias:** `S`, `T`, `Q`, `Q`, `S`, `S`, `D` (Segunda a Domingo).
* **Estados:**
  * *Inativo:* Fundo cinza escuro (`#2C2C2E`), texto secundário (`#8E8E93`).
  * *Ativo / Selecionado:* Fundo acinzentado claro ou azul de destaque com texto branco.

### 3. Campo de Texto: Etiqueta (Label Input)
* **Estrutura:** Label descritiva à esquerda alinhada com campo de input à direita.
* **Input:** Fundo escuro com borda sutil, texto com placeholder suave (ex: *"Alarme"*).

### 4. Dropdown: Som (Sound Selector)
* **Estrutura:** Select / Dropdown padronizado com cantos arredondados.
* **Ícone:** Setas duplas verticais (`⇅` / `chevron-up-down`) indicando expansão de lista suspensa.
* **Valor Padrão:** *"Radar (Padrão)"*.

### 5. Checkbox: Adiar (Snooze Toggle)
* **Estrutura:** Checkbox clássico com cantos arredondados e ícone de "check" (`✓`) marcado por padrão ao lado do texto *"Adiar"*.

### 6. Ações do Modal (Footer)
* Alinhado à direita na base do modal.
* **Botão Secundário ("Cancelar"):**
  * Estilo: Fundo cinza translúcido (`#2C2C2E`), texto branco, cantos arredondados (`6px`).
* **Botão Primário ("Salvar"):**
  * Estilo: Fundo contrastante (Branco/Cinza Claro), texto escuro (`#1C1C1E`), cantos arredondados (`6px`).

---

## 📱 5. Acessibilidade (a11y)
* Relação de contraste de cores mínima de 4.5:1 para textos legíveis sobre fundos escuros.
* Suporte à navegação por teclado (`Tab`, `Shift + Tab`, setas para ajustar dígitos de horário).
* Rótulos (`aria-label`) associados diretamente a cada botão de dia da semana (ex: *"Repetir toda Segunda-feira"*).