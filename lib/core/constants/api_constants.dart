class ApiConstants {
  // Supabase
  static const String supabaseUrl = "https://cgyiipfmplrrshevhpof.supabase.co";
  static const String supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNneWlpcGZtcGxycnNoZXZocG9mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMzQ2MDgsImV4cCI6MjA5MDgxMDYwOH0.pFia6_FvyF9cth1T9JgjDXLhvJkjxoxLf5okIQlHTvI";

  // ============================================================
  // APIS FOOTBALL
  // ============================================================
  static const String apiFootballBaseUrl = "https://v3.football.api-sports.io";
  static const String apiFootballKey = "2814bb2f4d64fb650fb8655a308ea6ce";

  static const String theSportsDbV1Url = "https://www.thesportsdb.com/api/v1/json";
  static const String theSportsDbKey = "3";

  static const String footballDataBaseUrl = "https://api.football-data.org/v4";
  static const String footballDataToken = "94f10d05ccdf4a15aed6436360b4638c";

  // ============================================================
  // AI KEYS — Prédictions + Fallback football
  // ============================================================
  // Google Gemini (2 clés en rotation)
  static const String geminiKey1 = "AQ.Ab8RN6KqC9ufPVhvfBHTB0xquZNi0tLyHdb5Be8RUi1JsySh_w";
  static const String geminiKey2 = "AQ.Ab8RN6KDpw_Jp7Ajtv6m97oVd967kCIlVTwwUAVYq1xSvGbFaQ";
  static const String geminiBaseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";

  // Kimi (Moonshot AI)
  static const String kimiKey = "Sk-EHOsAlpCgotnkR3dAUoKlNCL1TOXOxMbrbodVkuU2ztj6dQ1";
  static const String kimiBaseUrl = "https://api.moonshot.cn/v1/chat/completions";

  // Mistral
  static const String mistralKey = "4Y4z8BkOcEdi9YoEh9xckZ0eQzbXmklh";
  static const String mistralBaseUrl = "https://api.mistral.ai/v1/chat/completions";

  // DeepSeek
  static const String deepseekKey = "sk-cd585bad3c394bf4a28f87301e1c0e35";
  static const String deepseekBaseUrl = "https://api.deepseek.com/chat/completions";

  // OpenAI
  static const String openAiKey = "sk-M0A20DXFHbwSr11LNih5hwcUt57RLZ8wCnIsjbBGrKyfBKjq";

  // Perplexity (recherche web native — fallback football)
  static const String perplexityKey = "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";
  static const String perplexityBaseUrl = "https://api.perplexity.ai/chat/completions";

  // Grok (xAI — analyse cotes BetPawa/1XBet)
  static const String grokKey = "xai-rEKaV75zjevaaph7tGFh6RbKZMkzW1TyBdPk3NwelJ0qsVM5S8n9K8rXZ0udZ5nS7JyaGeLmQ6pIg52a";
  static const String grokBaseUrl = "https://api.x.ai/v1/chat/completions";

  // Z.ai
  static const String zaiKey = "69a4b36afdfb483e9f3e4b07dc5bcc1d.Zshz6QV4bKZzH8yv";
  static const String zaiBaseUrl = "https://api.z.ai/api/v1/chat/completions";

  // Ollama (local, optionnel)
  static const String ollamaKey = "bcc6a5daa24146a3a463728031da0f35.JqFbnFnPYpQzreSkp50Xfofr";

  // ============================================================
  // PAIEMENT MAISHAPAY (Orange Money, Airtel Money, M-Pesa via RDC)
  // ============================================================
  static const String maishaPayPublicApiKey = "MP-LIVEPK-DOw\$T0SnM/SekDy32h0M5\$A6Z2H350e.TJSq1HIRT70jndZdocX.v53cSIcxy65\$qD2ThvocUy\$EYn10vD\$3S80\$Mh4SnfByyHSH.Fazv1Dfmc2uy9sjE7VG";
  static const String maishaPaySecretApiKey = "MP-LIVESK-.QR7cOsKCy6GE8f2lue2J.uF8MgITIRNzPzC1I\$XDj\$h2R7lF1\$aZ0i0B.Md0nJZD0AUrqeQR.Ld8U.cPMHTGfCbLB\$SV3FfH/jd6Btyah\$eiCQ5Y\$7r2uu2";
  static const String maishaPayBaseUrl = "https://marchand.maishapay.online/api/payment/rest/vers1.0/merchant";
  static const String maishaPayWebhookUrl =
      "https://cgyiipfmplrrshevhpof.supabase.co/functions/v1/maishapay-webhook";

  // Plans tarifaires (en CDF)
  static const Map<String, int> subscriptionPlans = {
    '1 Jour'    : 500,
    '1 Semaine' : 2000,
    '1 Mois'    : 6000,
    '1 Année'   : 25000,
  };

  // Opérateurs supportés
  static const List<String> paymentOperators = [
    'Orange Money',
    'Airtel Money',
    'M-Pesa',
  ];
}
