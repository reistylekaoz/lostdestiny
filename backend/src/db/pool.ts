import { Pool } from "pg";
import "dotenv/config";

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

pool.on("error", (err: Error) => {
  // Uma conexão idle caiu — não derruba o processo, só loga.
  console.error("[db] erro inesperado no pool de conexões:", err);
});
