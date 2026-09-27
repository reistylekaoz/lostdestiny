using UnityEngine;

namespace ValeSombrio
{
    // Câmera ortográfica no ângulo clássico isométrico (parecido com MU Online:
    // vista de cima em diagonal, sem perspectiva forçando profundidade).
    [RequireComponent(typeof(Camera))]
    public class IsometricCameraRig : MonoBehaviour
    {
        public Vector3 lookAtPoint = new Vector3(0, 0, 3f);
        public float distance = 12f;
        public float pitchDegrees = 35f;   // inclinação pra baixo
        public float yawDegrees = 45f;     // rotação clássica isométrica
        public float orthographicSize = 6f;

        void Start()
        {
            var cam = GetComponent<Camera>();
            cam.orthographic = true;
            cam.orthographicSize = orthographicSize;

            var rotation = Quaternion.Euler(pitchDegrees, yawDegrees, 0f);
            transform.position = lookAtPoint - rotation * Vector3.forward * distance;
            transform.rotation = rotation;
        }
    }
}
