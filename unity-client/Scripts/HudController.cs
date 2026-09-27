using UnityEngine;
using UnityEngine.UI;

namespace ValeSombrio
{
    // HUD simples: nível, HP, XP, ouro. Crie um Canvas > 4 objetos Text (UI
    // legado, sem precisar importar TextMeshPro) e arraste aqui.
    public class HudController : MonoBehaviour
    {
        public Text levelText;
        public Text hpText;
        public Text xpText;
        public Text goldText;
        public Text logText; // opcional: última linha de evento (kill/level up)

        public void Apply(CombatSnapshot snapshot)
        {
            if (snapshot?.stats == null) return;
            var s = snapshot.stats;
            if (levelText) levelText.text = $"Nv. {s.level}";
            if (hpText) hpText.text = $"HP {s.hp} / {s.hpMax}";
            if (xpText) xpText.text = $"XP {s.xp} / {s.xpMax}";
            if (goldText) goldText.text = $"Ouro {s.gold}";
        }

        public void Log(string message)
        {
            if (logText) logText.text = message;
        }
    }
}
