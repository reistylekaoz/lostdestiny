using UnityEngine;

namespace ValeSombrio
{
    // Representa visualmente um dos 6 spots de mob. Puramente cosmético:
    // liga/desliga o modelo e ajusta a barra de HP conforme o snapshot do servidor.
    public class MobSlotView : MonoBehaviour
    {
        [Header("Referências (arraste no Inspector)")]
        public GameObject mobModel;         // cubo/capsula representando o mob
        public Transform hpBarFill;         // um cubo fino escalado no eixo X como barra de HP
        public Renderer mobRenderer;        // pra mudar a cor quando é o alvo atual
        public GameObject respawnIndicator;  // ex: um anel/disco fantasma

        static readonly Color colorNormal = new Color(0.63f, 0.22f, 0.22f);
        static readonly Color colorTarget = new Color(0.87f, 0.76f, 0.29f);

        public void Apply(MobSlotData data, bool isTarget)
        {
            bool alive = data.mob != null && data.mob.IsAlive;

            if (mobModel) mobModel.SetActive(alive);
            if (respawnIndicator) respawnIndicator.SetActive(!alive);

            if (!alive) return;

            float ratio = data.mob.hpMax > 0 ? (float)data.mob.hp / data.mob.hpMax : 0f;
            if (hpBarFill)
            {
                var scale = hpBarFill.localScale;
                scale.x = Mathf.Clamp01(ratio);
                hpBarFill.localScale = scale;
            }

            if (mobRenderer)
            {
                mobRenderer.material.color = isTarget ? colorTarget : colorNormal;
            }
        }
    }
}
