using System.Collections.Generic;

namespace ValeSombrio
{
    // Espelha exatamente o que o backend manda em CombatSnapshot (src/game/types.ts).
    // O servidor é dono da verdade — este objeto é só para desenhar na tela.

    public class CharacterStats
    {
        public int level, xp, xpMax, baseForca, baseVit, gold, hp, hpMax, dano, forca, vit;
    }

    public class MobInstance
    {
        public string name;
        public int hp, hpMax, xp, goldMin, goldMax;
        public bool IsAlive => hp > 0;
    }

    public class MobSlotData
    {
        public int index;
        public MobInstance mob; // null (ou hp<=0) = slot vazio, respawnando
    }

    public class CombatSnapshot
    {
        public string characterId;
        public CharacterStats stats;
        public List<MobSlotData> mobSlots = new List<MobSlotData>();
        public int currentTargetIndex = -1;

        public static CombatSnapshot FromDict(Dictionary<string, object> d)
        {
            var snap = new CombatSnapshot
            {
                characterId = GetString(d, "characterId")
            };

            if (d.TryGetValue("stats", out var statsObj) && statsObj is Dictionary<string, object> sd)
            {
                snap.stats = new CharacterStats
                {
                    level = GetInt(sd, "level"),
                    xp = GetInt(sd, "xp"),
                    xpMax = GetInt(sd, "xpMax"),
                    baseForca = GetInt(sd, "baseForca"),
                    baseVit = GetInt(sd, "baseVit"),
                    gold = GetInt(sd, "gold"),
                    hp = GetInt(sd, "hp"),
                    hpMax = GetInt(sd, "hpMax"),
                    dano = GetInt(sd, "dano"),
                    forca = GetInt(sd, "forca"),
                    vit = GetInt(sd, "vit"),
                };
            }

            if (d.TryGetValue("mobSlots", out var slotsObj) && slotsObj is List<object> slotsList)
            {
                foreach (var item in slotsList)
                {
                    if (!(item is Dictionary<string, object> slotDict)) continue;
                    var slot = new MobSlotData { index = GetInt(slotDict, "index") };
                    if (slotDict.TryGetValue("mob", out var mobObj) && mobObj is Dictionary<string, object> md)
                    {
                        slot.mob = new MobInstance
                        {
                            name = GetString(md, "name"),
                            hp = GetInt(md, "hp"),
                            hpMax = GetInt(md, "hpMax"),
                            xp = GetInt(md, "xp"),
                            goldMin = GetInt(md, "goldMin"),
                            goldMax = GetInt(md, "goldMax"),
                        };
                    }
                    snap.mobSlots.Add(slot);
                }
            }

            snap.currentTargetIndex = d.TryGetValue("currentTargetIndex", out var t) && t != null ? GetInt(d, "currentTargetIndex") : -1;

            return snap;
        }

        static int GetInt(Dictionary<string, object> d, string key)
        {
            if (!d.TryGetValue(key, out var v) || v == null) return 0;
            if (v is long l) return (int)l;
            if (v is double dd) return (int)dd;
            return 0;
        }

        static string GetString(Dictionary<string, object> d, string key)
        {
            return d.TryGetValue(key, out var v) ? v as string : null;
        }
    }
}
