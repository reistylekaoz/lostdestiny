# Vale Sombrio — Backend

Esqueleto do servidor autoritativo do MU-like idle/AFK. Toda a simulação de
combate, drops e progressão roda aqui — o cliente (Godot) nunca calcula nada,
só renderiza o que o servidor manda.

## Stack

- Node.js + TypeScript (`tsx` para dev, sem build step no dia a dia)
- Express para a API REST (conta, personagens)
- `ws` para o WebSocket que transmite o combate em tempo real
- PostgreSQL para toda a persistência

## Setup local

```bash
npm install
npm run migrate   # aplica src/db/schema.sql
npm run seed      # popula mapa, spot, mob e itens iniciais
npm run dev        # sobe o servidor em http://localhost:3000
```

Variáveis de ambiente em `.env` (`DATABASE_URL`, `JWT_SECRET`, `PORT`).

## Fluxo testado

1. `POST /auth/register` `{email, password}` → devolve token JWT
2. `POST /characters` `{slotIndex, name, class}` (Bearer token) → cria personagem
3. `POST /characters/:id/farm/start` `{spotId: "spot_1"}` → inicia a simulação
   server-side (tick a cada 300ms, autoritativo, persiste no Postgres)
4. WebSocket em `ws://localhost:3000/ws`, mandar
   `{"type":"subscribe","token":"...","characterId":"..."}` → recebe
   snapshots (`{"type":"snapshot","snapshot":{...}}`) em tempo real
5. `POST /characters/:id/farm/stop` → encerra a sessão e persiste o estado final

## O que já existe

- Autenticação (registro/login) com bcrypt + JWT
- Até 5 personagens por conta (`slot_index` 0-4)
- 11 classes definidas em `src/game/classes.ts` (dano/skills próprios ainda
  não implementados — todas usam a mesma fórmula de combate por ora)
- Combate autoritativo com 6 mobs simultâneos por spot, respawn automático,
  level up, drop de itens com variação de qualidade (+1/+2/+3)
- Persistência de personagem, itens e log de eventos (kills, drops, level up)

## O que falta (próximas etapas)

- **Equipar item**: rota `POST /characters/:id/equip` que move um
  `item_instance` da mochila pro slot e recalcula os stats da sessão ativa
  (`sessionManager` já tem `setEquipmentBonuses`, falta expor via API)
- **Catch-up offline**: hoje a simulação só roda enquanto há um
  `setInterval` ativo no processo. Para funcionar de verdade como AFK/idle
  (personagem progride mesmo com o processo reiniciado ou o jogador off por
  horas), trocar por: ao iniciar farm, calcular matematicamente o progresso
  do período decorrido em vez de manter um tick real-time por personagem
  offline — importante antes de ter muitos jogadores simultâneos
- **PT de 5 personagens rodando junto**: hoje cada personagem farma
  isoladamente; falta a lógica de grupo (bônus de PT, todos os 5 no mesmo
  spot)
- **Multi-spot / multi-mapa**: só existe 1 spot com 1 tipo de mob; falta
  variar terreno, elementais (para o pentagrama), bosses etc.
- **Skills por classe**: dano em área (guerreiro mago), heal/buff (elfa),
  etc. — hoje todas as classes atacam igual
- **Autenticação real de produção**: JWT em `.env` de dev não é seguro para
  produção; trocar secret e considerar refresh tokens
