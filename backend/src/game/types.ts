export interface EquipmentBonus {
  forca?: number;
  vit?: number;
  dano?: number;
}

export interface CharacterStats {
  level: number;
  xp: number;
  xpMax: number;
  baseForca: number;
  baseVit: number;
  gold: number;
  hp: number;
  hpMax: number;
  dano: number;
  forca: number; // força total (base + equipamento)
  vit: number; // vitalidade total (base + equipamento)
}

export interface MobTemplateData {
  id: string;
  name: string;
  baseHp: number;
  baseXp: number;
  goldMin: number;
  goldMax: number;
}

export interface MobInstance {
  name: string;
  hp: number;
  hpMax: number;
  xp: number;
  goldMin: number;
  goldMax: number;
}

export interface MobSlot {
  index: number;
  mob: MobInstance | null;
  respawnTimer: number;
}

export interface ItemDrop {
  templateId: string;
  slot: string;
  name: string;
  quality: number; // 0..3
  bonus: EquipmentBonus;
}

export type CombatEvent =
  | { type: "kill"; mobName: string; xpGained: number; goldGained: number; drop: ItemDrop | null }
  | { type: "level_up"; newLevel: number };

export interface CombatSnapshot {
  characterId: string;
  stats: CharacterStats;
  mobSlots: Array<{ index: number; mob: MobInstance | null }>;
  currentTargetIndex: number | null;
}
