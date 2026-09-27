using UnityEngine;

namespace ValeSombrio
{
    // Ponto único de montagem: liga os eventos do NetworkClient às views.
    // Coloque este script num GameObject vazio chamado "GameBootstrap".
    public class GameBootstrap : MonoBehaviour
    {
        public NetworkClient network;
        public HudController hud;
        public MobSlotView[] mobSlotViews = new MobSlotView[6]; // na mesma ordem dos índices do servidor (0-5)

        void Awake()
        {
            // Garante que o dispatcher de thread principal existe antes de qualquer snapshot chegar.
            if (FindObjectOfType<UnityMainThread>() == null)
            {
                new GameObject("UnityMainThread").AddComponent<UnityMainThread>();
            }
        }

        void OnEnable()
        {
            network.OnSnapshot += HandleSnapshot;
            network.OnInfo += msg => Debug.Log($"[servidor] {msg}");
            network.OnError += msg => Debug.LogWarning($"[servidor] {msg}");
        }

        void OnDisable()
        {
            network.OnSnapshot -= HandleSnapshot;
        }

        void HandleSnapshot(CombatSnapshot snapshot)
        {
            hud.Apply(snapshot);

            foreach (var slotData in snapshot.mobSlots)
            {
                if (slotData.index < 0 || slotData.index >= mobSlotViews.Length) continue;
                var view = mobSlotViews[slotData.index];
                if (view == null) continue;
                bool isTarget = slotData.index == snapshot.currentTargetIndex;
                view.Apply(slotData, isTarget);
            }
        }
    }
}
