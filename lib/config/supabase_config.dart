class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://frfgmbgzildtfchtmchr.supabase.co',
  );

  // Supabase's anon/publishable key is safe to embed in a client app —
  // it's not a secret, Row Level Security is the real access boundary.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyZmdtYmd6aWxkdGZjaHRtY2hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2Nzg4NzEsImV4cCI6MjA5MzI1NDg3MX0.NosVCB74WEpoOLcioOWO731wcxAuZf7Dkv3Eyj9O5bY',
  );
}
