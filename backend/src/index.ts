import "dotenv/config";
import express from "express";
import { createServer } from "http";
import { authRouter } from "./routes/auth";
import { charactersRouter } from "./routes/characters";
import { attachWebSocketServer } from "./ws/server";

const app = express();
app.use(express.json());

app.get("/health", (_req, res) => res.json({ ok: true }));
app.use("/auth", authRouter);
app.use("/characters", charactersRouter);

const httpServer = createServer(app);
attachWebSocketServer(httpServer);

const port = Number(process.env.PORT) || 3000;
httpServer.listen(port, () => {
  console.log(`[server] Vale Sombrio backend rodando em http://localhost:${port}`);
  console.log(`[server] WebSocket em ws://localhost:${port}/ws`);
});
