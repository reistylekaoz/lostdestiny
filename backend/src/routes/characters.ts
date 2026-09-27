import { Router, Response } from "express";
import { z } from "zod";
import { pool } from "../db/pool";
import { AuthedRequest, requireAuth } from "../util/authMiddleware";
import { isValidClass } from "../game/classes";
import { sessionManager } from "../game/sessionManager";

export const charactersRouter = Router();
charactersRouter.use(requireAuth);

charactersRouter.get("/", async (req: AuthedRequest, res: Response) => {
  const accountId = req.auth!.accountId;
  const result = await pool.query(
    `SELECT id, slot_index, name, class, level, xp, gold, hp_current, current_spot_id, is_farming
     FROM characters WHERE account_id = $1 ORDER BY slot_index`,
    [accountId]
  );
  res.json({ characters: result.rows });
});

const createSchema = z.object({
  slotIndex: z.number().int().min(0).max(4),
  name: z.string().min(2).max(20),
  class: z.string(),
});

charactersRouter.post("/", async (req: AuthedRequest, res: Response) => {
  const parsed = createSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "dados inválidos", details: parsed.error.flatten() });
  }
  const { slotIndex, name, class: charClass } = parsed.data;
  if (!isValidClass(charClass)) {
    return res.status(400).json({ error: "classe desconhecida" });
  }

  const accountId = req.auth!.accountId;

  // até 5 personagens por conta — a constraint UNIQUE(account_id, slot_index) também garante isso
  const countResult = await pool.query(
    "SELECT COUNT(*) FROM characters WHERE account_id = $1",
    [accountId]
  );
  if (Number(countResult.rows[0].count) >= 5) {
    return res.status(409).json({ error: "limite de 5 personagens por conta atingido" });
  }

  try {
    const result = await pool.query(
      `INSERT INTO characters (account_id, slot_index, name, class)
       VALUES ($1, $2, $3, $4)
       RETURNING id, slot_index, name, class, level, xp, gold, hp_current`,
      [accountId, slotIndex, name, charClass]
    );
    res.status(201).json({ character: result.rows[0] });
  } catch (err: any) {
    if (err.code === "23505") {
      return res.status(409).json({ error: "já existe um personagem nesse slot" });
    }
    throw err;
  }
});

const farmSchema = z.object({
  spotId: z.string(),
});

// Inicia o farm automático server-side: o servidor passa a rodar o tick de
// combate para esse personagem independentemente do cliente estar conectado.
charactersRouter.post("/:id/farm/start", async (req: AuthedRequest, res: Response) => {
  const parsed = farmSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "spotId ausente" });
  }
  const characterId = String(req.params.id);
  const accountId = req.auth!.accountId;

  const owned = await pool.query(
    "SELECT id FROM characters WHERE id = $1 AND account_id = $2",
    [characterId, accountId]
  );
  if (!owned.rowCount) {
    return res.status(404).json({ error: "personagem não encontrado" });
  }

  await pool.query(
    "UPDATE characters SET is_farming = true, current_spot_id = $1 WHERE id = $2",
    [parsed.data.spotId, characterId]
  );

  await sessionManager.startFarming(characterId, parsed.data.spotId);
  res.json({ ok: true });
});

charactersRouter.post("/:id/farm/stop", async (req: AuthedRequest, res: Response) => {
  const characterId = String(req.params.id);
  const accountId = req.auth!.accountId;

  const owned = await pool.query(
    "SELECT id FROM characters WHERE id = $1 AND account_id = $2",
    [characterId, accountId]
  );
  if (!owned.rowCount) {
    return res.status(404).json({ error: "personagem não encontrado" });
  }

  await sessionManager.stopFarming(characterId);
  await pool.query("UPDATE characters SET is_farming = false WHERE id = $1", [characterId]);
  res.json({ ok: true });
});
