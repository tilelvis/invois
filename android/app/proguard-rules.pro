# Baseline R8 rules for Invois release builds.
#
# Most Flutter plugins (isar, printing, pdf, share_plus, url_launcher,
# package_info_plus, path_provider, shared_preferences, fl_chart) ship their
# own consumer ProGuard rules bundled in their AARs, which Gradle merges in
# automatically — this file only needs to cover anything not already handled.
#
# IMPORTANT: R8 shrinking can only be fully verified by actually running a
# shrunk release build on a device — this environment has no Flutter
# toolchain to build/run one. After enabling this, do one real release build
# (`flutter build apk --release` or via release.yml) and smoke-test the app
# end to end (PDF generation, sharing, product/invoice CRUD) before trusting
# it in production. If something breaks only in release (not debug), it's
# almost always a missing keep rule here.

# Keep annotations - several plugins use reflection based on these at runtime.
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep anything Parcelable/Serializable (some plugin platform-channel data
# classes are (de)serialized this way).
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
}

# Silence R8 warnings for optional dependencies pulled in transitively by
# plugins that aren't actually used at runtime by this app (safe to ignore
# rather than fail the build over).
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
