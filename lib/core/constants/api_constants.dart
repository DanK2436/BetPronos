class ApiConstants {
  // Supabase
  static const String supabaseUrl = "https://cgyiipfmplrrshevhpof.supabase.co";
  static const String supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNneWlpcGZtcGxycnNoZXZocG9mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMzQ2MDgsImV4cCI6MjA5MDgxMDYwOH0.pFia6_FvyF9cth1T9JgjDXLhvJkjxoxLf5okIQlHTvI";

  // APIs Football
  // API-Football
  static const String apiFootballBaseUrl = "https://v3.football.api-sports.io";
  static const String apiFootballKey = "2814bb2f4d64fb650fb8655a308ea6ce";
  
  // TheSportsDB
  static const String theSportsDbV1Url = "https://www.thesportsdb.com/api/v1/json";
  static const String theSportsDbV2Url = "https://www.thesportsdb.com/api/v2/json";
  // Default API key for free tier is "3" or maybe user has a custom one? In the txt it says "Api keys : v1 Base URL...". We can use standard public key "3" or "2" or we can do requests without key if not needed. We'll use "3" as default.
  static const String theSportsDbKey = "3"; 

  // Football-Data
  static const String footballDataBaseUrl = "https://api.football-data.org/v4";
  static const String footballDataToken = "94f10d05ccdf4a15aed6436360b4638c";

  // AI Keys
  static const String geminiKey1 = "AQ.Ab8RN6KqC9ufPVhvfBHTB0xquZNi0tLyHdb5Be8RUi1JsySh_w";
  static const String geminiKey2 = "AQ.Ab8RN6KDpw_Jp7Ajtv6m97oVd967kCIlVTwwUAVYq1xSvGbFaQ";
  static const String openAiKey = "sk-M0A20DXFHbwSr11LNih5hwcUt57RLZ8wCnIsjbBGrKyfBKjq";
  static const String mistralKey = "4Y4z8BkOcEdi9YoEh9xckZ0eQzbXmklh";
  static const String deepseekKey = "sk-cd585bad3c394bf4a28f87301e1c0e35";

  // Payment (Shwary)
  static const String shwaryApiKey = "shwary_bddffc43-02a9-455d-9c2c-09928ac539cd";
  static const String shwaryBaseUrl = "https://api.shwary.com/v1";
}
