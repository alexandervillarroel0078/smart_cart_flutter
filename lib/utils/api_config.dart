// Cambia esto según el entorno
const String entorno = "emulador"; // opciones: emulador | celular | pc

const String apiBaseURL = entorno == "emulador"
    ? "http://10.0.2.2:5000"
    : entorno == "celular"
        ? "http://192.168.0.12:5000" // 🔁 tu IP real aquí
        : "http://127.0.0.1:5000"; // para navegador de PC

Map<String, String> headersWithToken(String token) => {
      "Authorization": "Bearer $token",
    };
