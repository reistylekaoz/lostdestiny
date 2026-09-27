import fs from "fs";
import path from "path";
import { pool } from "./pool";

async function migrate() {
  const sql = fs.readFileSync(path.join(__dirname, "schema.sql"), "utf-8");
  await pool.query(sql);
  console.log("[migrate] schema aplicado com sucesso.");
  await pool.end();
}

migrate().catch((err) => {
  console.error("[migrate] falhou:", err);
  process.exit(1);
});
