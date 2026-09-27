using System;
using System.Collections.Concurrent;
using UnityEngine;

namespace ValeSombrio
{
    // O recebimento do WebSocket roda em código assíncrono; isso garante que
    // qualquer callback que toque a API do Unity (instanciar, mudar UI) execute
    // na thread principal, evitando exceções de thread cruzada.
    public class UnityMainThread : MonoBehaviour
    {
        static readonly ConcurrentQueue<Action> queue = new ConcurrentQueue<Action>();
        static UnityMainThread instance;

        public static void Enqueue(Action action)
        {
            if (action == null) return;
            queue.Enqueue(action);
        }

        void Awake()
        {
            if (instance != null && instance != this) { Destroy(gameObject); return; }
            instance = this;
            DontDestroyOnLoad(gameObject);
        }

        void Update()
        {
            while (queue.TryDequeue(out var action))
            {
                try { action(); }
                catch (Exception e) { Debug.LogException(e); }
            }
        }
    }
}
