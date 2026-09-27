# Vale Sombrio — Cliente Unity (protótipo 3D isométrico)

Este cliente não calcula nada: só conecta no backend (Node + PostgreSQL, já
validado rodando o combate de verdade) via WebSocket e desenha o que o
servidor manda. Sem Unity Package extra — o parser JSON (`MiniJSON.cs`) vem
embutido no projeto.

## 0. Pré-requisitos

1. **Unity Hub** → [unity.com/download](https://unity.com/download)
2. No Hub, instale uma versão **LTS** (recomendado: 2022.3 LTS ou mais recente)
3. Node.js 18+ e PostgreSQL instalados na sua máquina (para rodar o backend localmente)

## 1. Rodar o backend localmente

Extraia o `mu-backend.zip` e rode:

```bash
cd mu-backend
npm install
```

Crie o banco (ajuste para como o Postgres está configurado na sua máquina):

```bash
createuser mu_dev --superuser        # ou via psql: CREATE USER mu_dev WITH PASSWORD '...' SUPERUSER;
createdb mu_idle -O mu_dev
```

Confira o `.env` (já vem com um exemplo) e depois:

```bash
npm run migrate
npm run seed
npm run dev
```

Deve aparecer `Vale Sombrio backend rodando em http://localhost:3000`.

## 2. Criar conta e personagem (uma vez, via terminal)

```bash
curl -s -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"voce@exemplo.dev","password":"senha123"}'
```

Guarde o `token` da resposta. Depois:

```bash
curl -s -X POST http://localhost:3000/characters \
  -H "Content-Type: application/json" -H "Authorization: Bearer SEU_TOKEN" \
  -d '{"slotIndex":0,"name":"Kael","class":"guerreiro_1m"}'
```

Guarde o `character.id` da resposta. Você vai colar os dois no Unity no passo 5.

## 3. Criar o projeto Unity

1. Unity Hub → **New Project** → template **3D (Core)** → nome `ValeSombrio`
2. Copie a pasta `Scripts/` deste pacote para dentro de `Assets/Scripts/` do projeto
3. Se aparecer erro de compilação mencionando `ClientWebSocket`: vá em
   **Edit → Project Settings → Player → Other Settings → Api Compatibility Level**
   e mude para **.NET Framework** (resolve em versões mais antigas do Unity)

## 4. Montar a cena

**Câmera** — selecione a `Main Camera`:
- Adicione o componente `IsometricCameraRig`
- Deixe os valores padrão (ela se posiciona sozinha no `Start()`)

**Chão** — `GameObject → 3D Object → Plane`, escala `(3, 1, 3)`, posição `(0,0,0)`, cor escura no material

**Personagem** (fica fixo, não anda):
- `GameObject → 3D Object → Capsule`, nome `Player`, posição `(-4, 1, 0)`
- Material com cor teal, por exemplo `(0.23, 0.56, 0.56)`

**6 spots de mob** — para cada um (`MobSlot_0` a `MobSlot_5`):
1. Crie um `GameObject` vazio no nome `MobSlot_N`, posicionado num arco na frente do Player. Sugestão de posições (X, Y, Z):
   - `MobSlot_0`: (0, 0, 2)
   - `MobSlot_1`: (2, 0, 3)
   - `MobSlot_2`: (4, 0, 2)
   - `MobSlot_3`: (1, 0, -1)
   - `MobSlot_4`: (3, 0, -1)
   - `MobSlot_5`: (5, 0, -1)
2. Dentro dele, crie um `Cube` (nome `Model`) em `(0,0.5,0)`, material vermelho — esse é o `mobModel`
3. Dentro do `Model`, crie outro `Cube` bem fino e alongado (nome `HpBarFill`), escala `(1, 0.08, 0.08)`, posição local `(0, 0.9, 0)`, material amarelo — esse é o `hpBarFill` (o script escala o eixo X conforme o HP)
4. Crie um `Cylinder` achatado (nome `RespawnIndicator`), escala `(1, 0.02, 1)`, material cinza translúcido — indica o spot vazio entre um mob e outro
5. No `MobSlot_N`, adicione o componente `MobSlotView` e arraste:
   - `mobModel` → o `Cube` "Model"
   - `hpBarFill` → o transform do `HpBarFill`
   - `mobRenderer` → o `Renderer` do `Model`
   - `respawnIndicator` → o `RespawnIndicator`

**HUD** — `GameObject → UI → Canvas`, dentro dele 4 `UI → Text` (Level, HP, XP, Gold) posicionados no canto superior esquerdo. Crie um `GameObject` vazio chamado `Hud`, adicione o componente `HudController` e arraste os 4 textos nos campos correspondentes.

**Bootstrap** — crie um `GameObject` vazio chamado `GameBootstrap`:
1. Adicione o componente `NetworkClient`
   - `baseUrl`: `http://localhost:3000`
   - `wsUrl`: `ws://localhost:3000/ws`
   - `token`: cole o token do passo 2
   - `characterId`: cole o id do personagem do passo 2
   - `spotId`: `spot_1`
2. Adicione o componente `GameBootstrap`
   - `network` → o próprio `NetworkClient` que você acabou de adicionar
   - `hud` → o `HudController` do objeto `Hud`
   - `mobSlotViews[0..5]` → os 6 `MobSlot_N`, **na ordem certa dos índices**

## 5. Play

Aperte Play. O Unity deve:
1. Chamar `POST /characters/:id/farm/start` automaticamente
2. Conectar no WebSocket e assinar o personagem
3. Receber snapshots a cada ~300ms e atualizar HUD + os 6 mobs (aparecendo, levando dano na barra de HP, morrendo, respawnando)

Se nada acontecer, olhe a aba **Console** do Unity — os erros do `NetworkClient` (token inválido, conexão recusada) aparecem lá.

## O que este protótipo NÃO tem ainda (de propósito, pra manter o primeiro passo simples)

- Números de dano flutuando (dá pra portar a ideia do protótipo HTML: instanciar um `UI.Text` temporário acima do mob a cada tick que o HP dele cair)
- Efeito visual de ataque (a linha dourada do protótipo HTML virou apenas a cor do mob mudando quando é o alvo)
- Tela de login/criação de personagem — hoje o token e characterId são colados manualmente no Inspector
- Múltiplos personagens/PT, câmera livre, animações de personagem

Esses são bons próximos passos depois que você validar que a conexão cliente-servidor está funcionando.
