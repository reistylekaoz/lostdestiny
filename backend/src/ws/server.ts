import { WebSocketServer, WebSocket } from "ws";
import { Server as HttpServer } from "http";
import { verifyToken } from "../util/jwt";
import { pool } from "../db/pool";
import { sessionManager } from "../game/sessionManager";

interface ClientMessage {
  type: "subscribe";
  characterId: string;
  token: string;
}

export function attachWebSocketServer(httpServer: HttpServer) {
  const wss = new WebSocketServer({ server: httpServer, path: "/ws" });

  wss.on("connection", (ws: WebSocket) => {
    let unsubscribe: (() => void) | null = null;

    ws.on("message", async (raw) => {
      let msg: ClientMessage;
      try {
        msg = JSON.parse(raw.toString());
      } catch {
        ws.send(JSON.stringify({ type: "error", error: "mensagem inválida" }));
        return;
      }

      if (msg.type === "subscribe") {
        try {
          const auth = verifyToken(msg.token);
          const owned = await pool.query(
            "SELECT id FROM characters WHERE id = $1 AND account_id = $2",
            [msg.characterId, auth.accountId]
          );
          if (!owned.rowCount) {
            ws.send(JSON.stringify({ type: "error", error: "personagem não pertence a essa conta" }));
            return;
          }

          if (unsubscribe) unsubscribe();
          unsubscribe = sessionManager.registerListener(msg.characterId, (snapshot) => {
            if (ws.readyState === WebSocket.OPEN) {
              ws.send(JSON.stringify({ type: "snapshot", snapshot }));
            }
          });

          if (!sessionManager.isFarming(msg.characterId)) {
            ws.send(
              JSON.stringify({
                type: "info",
                message: "personagem não está farmando — chame POST /characters/:id/farm/start",
              })
            );
          }
        } catch {
          ws.send(JSON.stringify({ type: "error", error: "token inválido" }));
        }
      }
    });

    ws.on("close", () => {
      if (unsubscribe) unsubscribe();
    });
  });

  return wss;
}
