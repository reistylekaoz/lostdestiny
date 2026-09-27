import {
  CharacterStats,
  CombatEvent,
  CombatSnapshot,
  EquipmentBonus,
  ItemDrop,
  MobInstance,
  MobSlot,
  MobTemplateData,
} from "./types";

// Toda essa lógica é autoritativa: roda só no servidor. O cliente (Unity)
// recebe apenas snapshots e eventos, nunca calcula dano ou drop.

const SLOT_COUNT = 6;
const RESPAWN_DELAY_SEC = 1.0;
const ATTACK_INTERVAL_SEC = 0.75;

function clamp(v: number, a: number, b: number) {
  return Math.max(a, Math.min(b, v));
}

function randRange(a: number, b: number) {
  return a + Math.random() * (b - a);
}

export function xpForLevel(level: number): number {
  return Math.round(20 * Math.pow(level, 1.5));
}

export function recalcStats(
  baseForca: number,
  baseVit: number,
  equipmentBonuses: EquipmentBonus[],
  level: number,
  xp: number,
  gold: number,
  currentHp: number,
  currentHpMax: number
): CharacterStats {
  let forca = baseForca;
  let vit = baseVit;
  let danoBonus = 0;
  for (const b of equipmentBonuses) {
    forca += b.forca || 0;
    vit += b.vit || 0;
    danoBonus += b.dano || 0;
  }
  const hpMax = 40 + vit * 6;
  const ratio = currentHpMax > 0 ? currentHp / currentHpMax : 1;
  const hp = Math.round(hpMax * clamp(ratio, 0, 1));
  const dano = Math.round(3 + forca * 0.8 + danoBonus);
  return {
    level,
    xp,
    xpMax: xpForLevel(level),
    baseForca,
    baseVit,
    gold,
    hp,
    hpMax,
    dano,
    forca,
    vit,
  };
}

function makeMobInstance(template: MobTemplateData, characterLevel: number): MobInstance {
  const scale = 1 + (characterLevel - 1) * 0.35;
  const hpMax = Math.round(template.baseHp * scale);
  return {
    name: template.name,
    hp: hpMax,
    hpMax,
    xp: Math.round(template.baseXp * (1 + (characterLevel - 1) * 0.25)),
    goldMin: template.goldMin,
    goldMax: template.goldMax,
  };
}

// Pool mínimo de itens para o skeleton — em produção isso vem da tabela
// item_templates filtrada pelo spot/mapa.
const ITEM_POOL: Array<{ templateId: string; slot: string; name: string; bonus: EquipmentBonus }> = [
  { templateId: "espada_curta", slot: "arma", name: "Espada Curta", bonus: { dano: 2 } },
  { templateId: "escudo_bronze", slot: "escudo", name: "Escudo de Bronze", bonus: { vit: 2 } },
  { templateId: "elmo_couro", slot: "elmo", name: "Elmo de Couro", bonus: { vit: 1 } },
  { templateId: "peitoral_reforcado", slot: "armadura", name: "Peitoral Reforçado", bonus: { vit: 3 } },
  { templateId: "luvas_batalha", slot: "luvas", name: "Luvas de Batalha", bonus: { forca: 1 } },
  { templateId: "botas_ligeiras", slot: "botas", name: "Botas Ligeiras", bonus: { forca: 1 } },
  { templateId: "brinco_runico", slot: "brinco", name: "Brinco Rúnico", bonus: { dano: 1 } },
  { templateId: "anel_amaldicoado", slot: "anel", name: "Anel Amaldiçoado", bonus: { dano: 1, forca: 1 } },
];

function rollDrop(): ItemDrop | null {
  if (Math.random() > 0.3) return null;
  const pick = ITEM_POOL[Math.floor(Math.random() * ITEM_POOL.length)];
  const roll = Math.random();
  const quality = roll > 0.85 ? 3 : roll > 0.6 ? 2 : roll > 0.3 ? 1 : 0;
  const mult = quality === 3 ? 1.6 : quality === 2 ? 1.3 : quality === 1 ? 1.15 : 1;
  const bonus: EquipmentBonus = {};
  for (const k of Object.keys(pick.bonus) as Array<keyof EquipmentBonus>) {
    bonus[k] = Math.round((pick.bonus[k] || 0) * mult);
  }
  return { templateId: pick.templateId, slot: pick.slot, name: pick.name, quality, bonus };
}

export class CombatSession {
  readonly characterId: string;
  private mobTemplate: MobTemplateData;
  private stats: CharacterStats;
  private equipmentBonuses: EquipmentBonus[];
  private mobSlots: MobSlot[];
  private currentTargetIndex: number | null = null;
  private attackCooldown = 0;

  constructor(characterId: string, mobTemplate: MobTemplateData, stats: CharacterStats, equipmentBonuses: EquipmentBonus[]) {
    this.characterId = characterId;
    this.mobTemplate = mobTemplate;
    this.stats = stats;
    this.equipmentBonuses = equipmentBonuses;
    this.mobSlots = Array.from({ length: SLOT_COUNT }, (_, i) => ({
      index: i,
      mob: makeMobInstance(mobTemplate, stats.level),
      respawnTimer: 0,
    }));
  }

  getStats(): CharacterStats {
    return this.stats;
  }

  setEquipmentBonuses(bonuses: EquipmentBonus[]) {
    this.equipmentBonuses = bonuses;
    this.stats = recalcStats(
      this.stats.baseForca,
      this.stats.baseVit,
      this.equipmentBonuses,
      this.stats.level,
      this.stats.xp,
      this.stats.gold,
      this.stats.hp,
      this.stats.hpMax
    );
  }

  private pickTarget(): number | null {
    const alive = this.mobSlots.filter((s) => s.mob && s.mob.hp > 0);
    if (!alive.length) return null;
    return alive[0].index;
  }

  private grantXp(amount: number, events: CombatEvent[]) {
    this.stats.xp += amount;
    while (this.stats.xp >= this.stats.xpMax) {
      this.stats.xp -= this.stats.xpMax;
      this.stats.level += 1;
      this.stats.baseForca += 2;
      this.stats.baseVit += 3;
      this.stats = recalcStats(
        this.stats.baseForca,
        this.stats.baseVit,
        this.equipmentBonuses,
        this.stats.level,
        this.stats.xp,
        this.stats.gold,
        this.stats.hpMax, // cheio ao subir de nível
        this.stats.hpMax
      );
      events.push({ type: "level_up", newLevel: this.stats.level });
    }
  }

  /** Avança a simulação `dtSeconds` no tempo. Retorna os eventos ocorridos nesse passo. */
  tick(dtSeconds: number): CombatEvent[] {
    const events: CombatEvent[] = [];

    for (const slot of this.mobSlots) {
      if (!slot.mob || slot.mob.hp <= 0) {
        slot.mob = null;
        slot.respawnTimer += dtSeconds;
        if (slot.respawnTimer >= RESPAWN_DELAY_SEC) {
          slot.mob = makeMobInstance(this.mobTemplate, this.stats.level);
          slot.respawnTimer = 0;
        }
      }
    }

    if (this.currentTargetIndex === null || !this.mobSlots[this.currentTargetIndex].mob) {
      this.currentTargetIndex = this.pickTarget();
      this.attackCooldown = 0;
    }

    if (this.currentTargetIndex !== null) {
      this.attackCooldown += dtSeconds;
      if (this.attackCooldown >= ATTACK_INTERVAL_SEC) {
        this.attackCooldown = 0;
        const slot = this.mobSlots[this.currentTargetIndex];
        const mob = slot.mob!;
        const dmg = Math.round(this.stats.dano * randRange(0.85, 1.2));
        mob.hp -= dmg;
        if (mob.hp <= 0) {
          mob.hp = 0;
          const goldGain = Math.round(randRange(mob.goldMin, mob.goldMax));
          this.stats.gold += goldGain;
          this.grantXp(mob.xp, events);
          const drop = rollDrop();
          events.push({ type: "kill", mobName: mob.name, xpGained: mob.xp, goldGained: goldGain, drop });
          slot.mob = null;
          slot.respawnTimer = 0;
          this.currentTargetIndex = null;
        }
      }
    }

    return events;
  }

  getSnapshot(): CombatSnapshot {
    return {
      characterId: this.characterId,
      stats: this.stats,
      mobSlots: this.mobSlots.map((s) => ({ index: s.index, mob: s.mob })),
      currentTargetIndex: this.currentTargetIndex,
    };
  }
}
