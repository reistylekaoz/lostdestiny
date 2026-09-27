import { pool } from "./pool";

async function seed() {
  await pool.query(
    `INSERT INTO maps (id, name) VALUES ('floresta_amaldicoada', 'Floresta Amaldiçoada')
     ON CONFLICT (id) DO NOTHING;`
  );

  await pool.query(
    `INSERT INTO mob_templates (id, name, base_hp, base_xp, gold_min, gold_max)
     VALUES ('lobo_sombrio', 'Lobo Sombrio', 26, 5, 1, 3)
     ON CONFLICT (id) DO NOTHING;`
  );

  await pool.query(
    `INSERT INTO spots (id, map_id, name, mob_template_id, slot_count, min_level)
     VALUES ('spot_1', 'floresta_amaldicoada', 'Spot I', 'lobo_sombrio', 6, 1)
     ON CONFLICT (id) DO NOTHING;`
  );

  const items: Array<[string, string, string, Record<string, number>]> = [
    ["espada_curta", "Espada Curta", "arma", { dano: 2 }],
    ["escudo_bronze", "Escudo de Bronze", "escudo", { vit: 2 }],
    ["elmo_couro", "Elmo de Couro", "elmo", { vit: 1 }],
    ["peitoral_reforcado", "Peitoral Reforçado", "armadura", { vit: 3 }],
    ["luvas_batalha", "Luvas de Batalha", "luvas", { forca: 1 }],
    ["botas_ligeiras", "Botas Ligeiras", "botas", { forca: 1 }],
    ["brinco_runico", "Brinco Rúnico", "brinco", { dano: 1 }],
    ["anel_amaldicoado", "Anel Amaldiçoado", "anel", { dano: 1, forca: 1 }],
  ];

  for (const [id, name, slot, bonus] of items) {
    await pool.query(
      `INSERT INTO item_templates (id, name, slot, base_bonus)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (id) DO NOTHING;`,
      [id, name, slot, bonus]
    );
  }

  console.log("[seed] dados iniciais inseridos.");
  await pool.end();
}

seed().catch((err) => {
  console.error("[seed] falhou:", err);
  process.exit(1);
});
