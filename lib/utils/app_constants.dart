class AppConstants {
  // HuggingFace models
  static const blipModel = "Salesforce/blip-image-captioning-base";

  // Pick a free text-generation model you like.
  // Note: availability can change; you can swap later without touching UI.
  static const textGenModel = "mistralai/Mistral-7B-Instruct-v0.2";

  // Daily limit
  static const dailyMaxGenerations = 5;

  // OPTIONAL: HuggingFace token (recommended).
  // Do NOT hardcode in UI. You can set it via --dart-define at run time:
  // flutter run --dart-define=HF_TOKEN=xxxxx
  static const hfToken = String.fromEnvironment("HF_TOKEN", defaultValue: "");
}
