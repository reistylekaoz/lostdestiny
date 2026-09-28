# Lost Destiny — Cliente Godot

Cliente 3D isométrico em **Godot 4.4+ (GDScript)**. Não calcula nada: faz
login, garante o farm ativo no servidor e desenha os snapshots que chegam pelo
WebSocket (~a cada 300ms).

A cena é montada por código em `scripts/main.gd` — não há nada para arrastar
no Inspector. O personagem é um guerreiro de duas espadas (Knight do KayKit) e
os mobs são esqueletos (KayKit Skeletons), todos animados.

## Rodar

1. Instale a **Godot 4.4 ou mais recente** (versão padrão, não precisa da .NET):
   [godotengine.org/download](https://godotengine.org/download)
2. Suba o backend (ver `backend/README.md`) e crie uma conta e um personagem:

   ```bash
   curl -s -X POST http://localhost:3000/auth/register \
     -H "Content-Type: application/json" \
     -d '{"email":"voce@exemplo.dev","password":"senha123"}'

   curl -s -X POST http://localhost:3000/characters \
     -H "Content-Type: application/json" -H "Authorization: Bearer SEU_TOKEN" \
     -d '{"slotIndex":0,"name":"Kael","class":"guerreiro_1m"}'
   ```

3. Copie `dev_config.example.cfg` para `dev_config.cfg` (ignorado pelo git) e
   preencha e-mail e senha. `id` vazio usa o primeiro personagem da conta.
4. Abra a Godot → **Import** → selecione `godot-client/project.godot` → **F5**.

O cliente chama `POST /auth/login`, `GET /characters`,
`POST /characters/:id/farm/start` e então assina o personagem em
`ws://.../ws`. Se a conexão cair ele reconecta sozinho (o servidor continua
farmando enquanto isso). Erros aparecem no HUD e na aba **Output**.

## Estrutura

| Arquivo | Papel |
|---|---|
| `scripts/main.gd` | Monta a cena e liga a rede às views |
| `scripts/network_client.gd` | REST (`HTTPRequest`) + WebSocket (`WebSocketPeer`) |
| `scripts/character_view.gd` | Modelo rigado + slots de equipamento presos aos ossos + animações |
| `scripts/item_visuals.gd` | Catálogo id do item → modelo 3D |
| `scripts/wings_placeholder.gd` | Asa provisória para validar o slot de asas |
| `scripts/mob_slot_view.gd` | Um dos 6 spots: mob animado, barra de HP, número de dano, alvo, respawn |
| `scripts/hud.gd` | Nível, HP, XP, ouro e linha de log |
| `scripts/isometric_camera.gd` | Câmera ortogonal isométrica |

O renderer é o **Compatibility** (OpenGL), pra exportar pra web e mobile sem
surpresa.

## Equipamento visual (armas, asas, sets, montaria)

Todos os personagens KayKit usam o mesmo esqueleto, então um item encaixa em
qualquer classe. `CharacterView.equip(slot, modelo)` prende o modelo no osso
do slot:

| Slot | Osso | Uso |
|---|---|---|
| `weapon_r` / `weapon_l` | `handslot.r` / `handslot.l` | Armas (o guerreiro usa uma espada em cada) |
| `wings` | `chest` | Asas (hoje um placeholder procedural) |
| `helmet` | `head` | Capacete do set |

Ainda não implementados: **sets** (trocar as peças do corpo — braços, pernas,
tronco — por peças do mesmo esqueleto) e **montaria** (o personagem vira filho
de um ponto de sela no modelo da montaria, com animação de sentado).

## Créditos dos assets

- [KayKit Adventurers](https://kaylousberg.itch.io/kaykit-adventurers) e
  [KayKit Skeletons](https://kaylousberg.itch.io/kaykit-skeletons) — Kay
  Lousberg, licença CC0 (ver `LICENSE.txt` em cada pasta de `assets/`).

## Próximos passos

- Tela de login/seleção de personagem (hoje vem do `dev_config.cfg`)
- Modelos de asa e montaria de verdade; sets com peças trocáveis
- Mostrar drops e inventário quando a API de equipar existir
- PT de 5 personagens, mais spots/mapas
