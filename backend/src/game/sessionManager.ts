import { pool } from "../db/pool";
import { CombatSession, recalcStats } from "./combat";
import { CombatSnapshot, EquipmentBonus, MobTemplateData } from "./types";

const TICK_INTERVAL_MS = 300;

type Listener = (snapshot: CombatSnapshot) => void;

interface ActiveSession {
  session: CombatSession;
  interval: NodeJS.Timeout;
  listeners: Set<Listener>;
}

class SessionManager {
  private sessions = new Map<string, ActiveSession>();

  isFarming(characterId: string): boolean {
    return this.sessions.has(characterId);
  }

  async startFarming(characterId: string, spotId: string): Promise<void> {
    if (this.sessions.has(characterId)) return; // já rodando

    const charResult = await pool.query(
      `SELECT level, xp, base_forca, base_vit, gold, hp_current FROM characters WHERE id = $1`,
      [characterId]
    );
    const char = charResult.rows[0];
    if (!char) throw new Error("personagem não encontrado");

    const spotResult = await pool.query(
      `SELECT mt.id, mt.name, mt.base_hp, mt.base_xp, mt.gold_min, mt.gold_max
       FROM spots s JOIN mob_templates mt ON mt.id = s.mob_template_id
       WHERE s.id = $1`,
      [spotId]
    );
    const mobRow = spotResult.rows[0];
    if (!mobRow) throw new Error("spot não encontrado");
    const mobTemplate: MobTemplateData = {
      id: mobRow.id,
      name: mobRow.name,
      baseHp: mobRow.base_hp,
      baseXp: mobRow.base_xp,
      goldMin: mobRow.gold_min,
      goldMax: mobRow.gold_max,
    };

    const equipmentBonuses = await this.loadEquipmentBonuses(characterId);
    const hpMaxAtLoad = 40 + char.base_vit * 6; // aproximação até recalcular completo
    const stats = recalcStats(
      char.base_forca,
      char.base_vit,
      equipmentBonuses,
      char.level,
      char.xp,
      Number(char.gold),
      char.hp_current,
      hpMaxAtLoad
    );

    const session = new CombatSession(characterId, mobTemplate, stats, equipmentBonuses);
    const listeners = new Set<Listener>();

    const interval = setInterval(async () => {
      const events = session.tick(TICK_INTERVAL_MS / 1000);
      for (const ev of events) {
        if (ev.type === "kill") {
          await pool.query(
            `INSERT INTO event_log (character_id, event_type, payload) VALUES ($1, 'kill', $2)`,
            [characterId, JSON.stringify(ev)]
          );
          if (ev.drop) {
            await pool.query(
              `INSERT INTO item_instances (template_id, owner_character_id, quality, bonus, equipped_slot)
               VALUES ($1, $2, $3, $4, NULL)`,
              [ev.drop.templateId, characterId, ev.drop.quality, JSON.stringify(ev.drop.bonus)]
            );
            await pool.query(
              `INSERT INTO event_log (character_id, event_type, payload) VALUES ($1, 'item_drop', $2)`,
              [characterId, JSON.stringify(ev.drop)]
            );
          }
        } else if (ev.type === "level_up") {
          await pool.query(
            `INSERT INTO event_log (character_id, event_type, payload) VALUES ($1, 'level_up', $2)`,
            [characterId, JSON.stringify(ev)]
          );
        }
      }

      // Persistência periódica do estado (a cada tick é aceitável no skeleton;
      // em produção, isso deve ser feito com menor frequência ou em lote).
      const stats = session.getStats();
      await pool.query(
        `UPDATE characters SET level=$1, xp=$2, base_forca=$3, base_vit=$4, gold=$5, hp_current=$6, last_tick_at=now()
         WHERE id = $7`,
        [stats.level, stats.xp, stats.baseForca, stats.baseVit, stats.gold, stats.hp, characterId]
      );

      const snapshot = session.getSnapshot();
      for (const listener of listeners) listener(snapshot);
    }, TICK_INTERVAL_MS);

    this.sessions.set(characterId, { session, interval, listeners });
  }

  async stopFarming(characterId: string): Promise<void> {
    const active = this.sessions.get(characterId);
    if (!active) return;
    clearInterval(active.interval);
    const stats = active.session.getStats();
    await pool.query(
      `UPDATE characters SET level=$1, xp=$2, base_forca=$3, base_vit=$4, gold=$5, hp_current=$6
       WHERE id = $7`,
      [stats.level, stats.xp, stats.baseForca, stats.baseVit, stats.gold, stats.hp, characterId]
    );
    this.sessions.delete(characterId);
  }

  registerListener(characterId: string, listener: Listener): () => void {
    const active = this.sessions.get(characterId);
    if (!active) return () => {};
    active.listeners.add(listener);
    listener(active.session.getSnapshot()); // snapshot imediato ao conectar
    return () => active.listeners.delete(listener);
  }

  private async loadEquipmentBonuses(characterId: string): Promise<EquipmentBonus[]> {
    const result = await pool.query(
      `SELECT bonus FROM item_instances WHERE owner_character_id = $1 AND equipped_slot IS NOT NULL`,
      [characterId]
    );
    return result.rows.map((r: { bonus: EquipmentBonus }) => r.bonus);
  }
}

export const sessionManager = new SessionManager();
