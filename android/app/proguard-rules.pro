# Most Flutter plugin AARs (Firebase, audioplayers, speech_to_text, flutter_edge_tts, etc.)
# ship their own consumer ProGuard rules bundled in the .aar, applied automatically — this file
# only needs to cover gaps R8 can't infer on its own (reflection, JSON model fields).

# Firebase Cloud Messaging / Firestore-style model classes read via reflection.
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# flutter_edge_tts builds SSML/JSON payloads and parses WebSocket frames — keep its model
# classes so field names used via reflection/serialization survive minification.
-keep class com.google.edge_tts.** { *; }
-dontwarn com.google.edge_tts.**

# okhttp/okio, pulled in transitively by several networking-based plugins.
-dontwarn okhttp3.**
-dontwarn okio.**
