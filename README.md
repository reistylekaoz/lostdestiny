# Lost Destiny — Idle MMORPG

MMORPG idle/AFK inspirado em MU Online: personagem fixo num spot, mobs
aparecem automaticamente pra serem farmados, equipamento (set, asa, arma,
brincos, anéis, montaria, pentagrama, artefatos, coleção) dá status ao longo
do tempo. Combate, drops e progressão são **autoritativos no servidor** — o
cliente só renderiza.

## Estrutura

- **`backend/`** — servidor Node + TypeScript + PostgreSQL. Dono da verdade:
  simula combate, calcula status, persiste tudo. Ver `backend/README.md`
  para setup e para o que já existe / falta.
- **`unity-client/`** — protótipo de cliente 3D isométrico em Unity. Conecta
  no backend via REST + WebSocket, não calcula nada. Ver
  `unity-client/README.md` para o passo a passo de configuração da cena.

## Estado atual

- Backend: auth, até 5 personagens por conta, 11 classes definidas, combate
  autoritativo com 6 mobs simultâneos por spot, level up, drop de itens,
  persistência completa — tudo testado ponta a ponta.
- Cliente Unity: cena `SampleScene` montada de ponta a ponta no Editor
  (câmera isométrica, chão, personagem, 6 mob slots com `MobSlotView`
  wireado, HUD com `HudController` wireado, `GameBootstrap` conectando
  tudo). Falta só preencher `token`/`characterId` no `NetworkClient` e
  apontar `baseUrl`/`wsUrl` para um backend acessível da máquina do
  usuário — ver "Próximos passos".

## Próximos passos

**Bloqueador imediato pra ver a cena Unity funcionando:** o backend hoje só
roda no sandbox do chat, que não é acessível pela máquina do usuário. Falta:
1. Rodar `backend/` localmente na máquina do usuário (`npm install`, criar o
   Postgres, `npm run migrate && npm run seed && npm run dev` — ver
   `backend/README.md`).
2. Criar uma conta + personagem via curl/Postman contra esse backend local
   pra obter `token` e `character.id`.
3. Colar esses dois valores nos campos `Token`/`Character Id` do componente
   `NetworkClient` (no objeto `GameBootstrap` da cena `SampleScene`) e
   apertar Play.

Depois disso, ver a seção "O que falta" em `backend/README.md` —
resumindo: equipar item via API, catch-up de progresso offline (pra
idle/AFK funcionar de verdade mesmo com o personagem desconectado), PT de
5 personagens, mais mapas/spots, skills por classe.

## Log de sessões

Toda vez que o projeto for trabalhado a partir do chat (não pelo Claude
Code direto no repositório), a entrada correspondente é adicionada aqui —
assim o Claude Code, ao continuar o trabalho, sabe o que foi feito fora do
repositório antes de seguir.

- **2026-09-27** — Sessão inicial via chat: criado o backend completo
  (auth, personagens, combate autoritativo, persistência) e o esqueleto do
  cliente Unity (scripts de rede, câmera isométrica, views, HUD). Testado
  ponta a ponta no sandbox do chat. Repositório criado e populado com o
  primeiro commit.
- **2026-09-27 (cont.)** — Montagem manual da cena Unity via computer-use
  direto no Editor na máquina do usuário: `Main Camera` com
  `IsometricCameraRig`, `Ground` (Plane), `Player` (Capsule), os 6
  `MobSlot_0`..`MobSlot_5` completos (cada um com `Model` + `HpBarFill` +
  `RespawnIndicator` + componente `MobSlotView` wireado), Canvas com HUD
  (`LevelText`/`HpText`/`XpText`/`GoldText`) e objeto `Hud` com
  `HudController` wireado, e objeto `GameBootstrap` com `NetworkClient` +
  `GameBootstrap` conectando o HUD e os 6 mob slots na ordem certa. Cena
  salva. Não foi testado com Play ainda — falta rodar o backend na máquina
  do usuário e preencher `token`/`characterId` no `NetworkClient` (ver
  "Próximos passos" acima).
