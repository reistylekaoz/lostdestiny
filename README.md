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
- Cliente Unity: scripts prontos (rede, câmera isométrica, views dos mobs,
  HUD), aguardando a montagem da cena no Editor.

## Próximos passos

Ver a seção "O que falta" em `backend/README.md` — resumindo: equipar item
via API, catch-up de progresso offline (pra idle/AFK funcionar de verdade
mesmo com o personagem desconectado), PT de 5 personagens, mais mapas/spots,
skills por classe.

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
