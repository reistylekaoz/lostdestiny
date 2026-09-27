import { Router, Request, Response } from "express";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { pool } from "../db/pool";
import { signToken } from "../util/jwt";

export const authRouter = Router();

const credentialsSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

authRouter.post("/register", async (req: Request, res: Response) => {
  const parsed = credentialsSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "email ou senha inválidos" });
  }
  const { email, password } = parsed.data;

  const existing = await pool.query("SELECT id FROM accounts WHERE email = $1", [email]);
  if (existing.rowCount) {
    return res.status(409).json({ error: "já existe uma conta com esse e-mail" });
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const result = await pool.query(
    "INSERT INTO accounts (email, password_hash) VALUES ($1, $2) RETURNING id, email",
    [email, passwordHash]
  );
  const account = result.rows[0];
  const token = signToken({ accountId: account.id, email: account.email });
  res.status(201).json({ token, account: { id: account.id, email: account.email } });
});

authRouter.post("/login", async (req: Request, res: Response) => {
  const parsed = credentialsSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "email ou senha inválidos" });
  }
  const { email, password } = parsed.data;

  const result = await pool.query(
    "SELECT id, email, password_hash FROM accounts WHERE email = $1",
    [email]
  );
  const account = result.rows[0];
  if (!account) {
    return res.status(401).json({ error: "credenciais inválidas" });
  }

  const valid = await bcrypt.compare(password, account.password_hash);
  if (!valid) {
    return res.status(401).json({ error: "credenciais inválidas" });
  }

  const token = signToken({ accountId: account.id, email: account.email });
  res.json({ token, account: { id: account.id, email: account.email } });
});
