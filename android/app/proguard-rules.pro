# Release keep rules. R8 runs in full mode for release builds and deletes code
# that is only reached by reflection, which crashes the app (DECISIONS D198).

# why: WorkManager (the widget's midnight job) builds its Room database through
# the generated class's no-argument constructor, by reflection, at app start.
# Without this, release builds crash on launch with
# NoSuchMethodException: androidx.work.impl.WorkDatabase_Impl.<init>.
-keep class * extends androidx.room.RoomDatabase { void <init>(); }

# why: WorkManager creates workers (our Midnight worker included) by reflection.
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

# why: flutter_local_notifications stores scheduled bill reminders with Gson,
# which reads field names and generic types by reflection. These are the rules
# the plugin documents for release builds.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
