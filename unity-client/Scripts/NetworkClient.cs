using System;
using System.Collections.Generic;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Networking;
using ValeSombrio.Json;

namespace ValeSombrio
{
    // Cliente fino: manda a intenção (subscribe / start farm) e recebe snapshots.
    // Nunca calcula dano, XP ou drop — isso é tudo autoritativo no servidor.
    public class NetworkClient : MonoBehaviour
    {
        [Header("Conexão")]
        public string baseUrl = "http://localhost:3000";
        public string wsUrl = "ws://localhost:3000/ws";

        [Header("Sessão (preencha após login via curl/Postman)")]
        public string token;
        public string characterId;
        public string spotId = "spot_1";

        public event Action<CombatSnapshot> OnSnapshot;
        public event Action<string> OnInfo;
        public event Action<string> OnError;

        ClientWebSocket socket;
        CancellationTokenSource cts;

        async void Start()
        {
            if (string.IsNullOrEmpty(token) || string.IsNullOrEmpty(characterId))
            {
                Debug.LogWarning("[NetworkClient] Preencha token e characterId no Inspector antes de rodar.");
                return;
            }

            await EnsureFarmingAsync();
            await ConnectAsync();
        }

        async void OnDestroy()
        {
            cts?.Cancel();
            if (socket != null && socket.State == WebSocketState.Open)
            {
                try { await socket.CloseAsync(WebSocketCloseStatus.NormalClosure, "bye", CancellationToken.None); }
                catch { /* conexão já pode ter caído */ }
            }
        }

        // Garante que o personagem está com o farm ativo no servidor antes de assinar.
        async Task EnsureFarmingAsync()
        {
            var body = "{\"spotId\":\"" + spotId + "\"}";
            using var req = new UnityWebRequest($"{baseUrl}/characters/{characterId}/farm/start", "POST");
            byte[] bodyRaw = Encoding.UTF8.GetBytes(body);
            req.uploadHandler = new UploadHandlerRaw(bodyRaw);
            req.downloadHandler = new DownloadHandlerBuffer();
            req.SetRequestHeader("Content-Type", "application/json");
            req.SetRequestHeader("Authorization", "Bearer " + token);

            var op = req.SendWebRequest();
            while (!op.isDone) await Task.Yield();

            if (req.result != UnityWebRequest.Result.Success)
            {
                Debug.LogWarning($"[NetworkClient] farm/start respondeu {req.responseCode}: {req.downloadHandler.text}");
            }
        }

        async Task ConnectAsync()
        {
            socket = new ClientWebSocket();
            cts = new CancellationTokenSource();

            try
            {
                await socket.ConnectAsync(new Uri(wsUrl), cts.Token);
            }
            catch (Exception e)
            {
                OnError?.Invoke($"Falha ao conectar no WebSocket: {e.Message}");
                return;
            }

            var subscribeMsg = "{\"type\":\"subscribe\",\"token\":\"" + token + "\",\"characterId\":\"" + characterId + "\"}";
            await SendAsync(subscribeMsg);

            _ = ReceiveLoopAsync();
        }

        async Task SendAsync(string json)
        {
            var bytes = Encoding.UTF8.GetBytes(json);
            await socket.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, cts.Token);
        }

        async Task ReceiveLoopAsync()
        {
            var buffer = new byte[16 * 1024];
            var messageBuilder = new StringBuilder();

            while (socket.State == WebSocketState.Open && !cts.IsCancellationRequested)
            {
                WebSocketReceiveResult result;
                try
                {
                    result = await socket.ReceiveAsync(new ArraySegment<byte>(buffer), cts.Token);
                }
                catch (Exception e)
                {
                    OnError?.Invoke($"Conexão perdida: {e.Message}");
                    break;
                }

                if (result.MessageType == WebSocketMessageType.Close) break;

                messageBuilder.Append(Encoding.UTF8.GetString(buffer, 0, result.Count));
                if (!result.EndOfMessage) continue;

                var raw = messageBuilder.ToString();
                messageBuilder.Clear();
                HandleMessage(raw);
            }
        }

        void HandleMessage(string raw)
        {
            if (!(MiniJson.Deserialize(raw) is Dictionary<string, object> msg)) return;
            if (!msg.TryGetValue("type", out var typeObj) || !(typeObj is string type)) return;

            switch (type)
            {
                case "snapshot":
                    if (msg["snapshot"] is Dictionary<string, object> snapDict)
                    {
                        var snapshot = CombatSnapshot.FromDict(snapDict);
                        // Snapshots chegam numa thread do socket; volta pra main thread do Unity.
                        UnityMainThread.Enqueue(() => OnSnapshot?.Invoke(snapshot));
                    }
                    break;
                case "info":
                    UnityMainThread.Enqueue(() => OnInfo?.Invoke(msg.TryGetValue("message", out var m) ? m as string : ""));
                    break;
                case "error":
                    UnityMainThread.Enqueue(() => OnError?.Invoke(msg.TryGetValue("error", out var e) ? e as string : "erro desconhecido"));
                    break;
            }
        }
    }
}
