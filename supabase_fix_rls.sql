-- =============================================================================
-- betPronos - Correctif RLS : Trigger de création automatique de profil
-- A executer dans : Supabase Dashboard -> SQL Editor -> New query -> Run
-- Ce fichier corrige l'erreur 42501 (row-level security policy violation)
-- lors de l'inscription d'un nouvel utilisateur.
-- =============================================================================

-- Fonction : créer automatiquement le profil quand un user s'inscrit
-- La fonction tourne avec SECURITY DEFINER = elle bypasse le RLS légalement
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    username,
    avatar_url,
    device_id,
    subscription_tier,
    prediction_count
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    'https://api.dicebear.com/7.x/bottts/svg?seed=' ||
      COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'device_id', ''),
    'free',
    0
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Déclencheur : s'exécute après chaque nouvel utilisateur créé dans auth.users
DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users;
CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- FIN DU CORRECTIF
-- =============================================================================
