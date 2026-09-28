# Lost Destiny — Cliente Godot

Cliente 3D isométrico em **Godot 4.4+ (GDScript)**. Não calcula nada: faz
login, garante o farm ativo no servidor e desenha os snapshots que chegam pelo
WebSocket (~a cada 300ms).

A cena é montada por código em `scripts/main.gd` — não há nada para arrastar
no Inspector. Os cubos/cápsula são placeholders até termos modelos.

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
| `scripts/mob_slot_view.gd` | Um dos 6 spots: mob, barra de HP, número de dano, indicador de respawn |
| `scripts/hud.gd` | Nível, HP, XP, ouro e linha de log |
| `scripts/isometric_camera.gd` | Câmera ortogonal isométrica |

O renderer é o **Compatibility** (OpenGL), pra exportar pra web e mobile sem
surpresa.

## Próximos passos

- Tela de login/seleção de personagem (hoje vem do `dev_config.cfg`)
- Modelos e animações no lugar dos placeholders
- Mostrar drops e inventário quando a API de equipar existir
- PT de 5 personagens, mais spots/mapas
