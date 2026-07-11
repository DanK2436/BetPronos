-- =============================================================================
-- betPronos - Schema Supabase SQL
-- Coller dans : Supabase Dashboard -> SQL Editor -> New query -> Run
--
-- Plans d'abonnement :
--   1 Jour    : 500  CDF  (via Orange Money / Airtel Money / M-pesa)
--   1 Semaine : 2000 CDF
--   1 Mois    : 6000 CDF
--   1 Annee   : 25000 CDF
--
-- Regles :
--   - Essai gratuit : 1 jour + 5 predictions max
--   - Limite appareil : 2 comptes max par telephone
--   - SMS envoye a chaque paiement confirme
-- =============================================================================


-- ============================================================
-- 1. TABLE : profiles
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id                 UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username           TEXT        NOT NULL DEFAULT '',
  avatar_url         TEXT        NOT NULL DEFAULT '',
  device_id          TEXT        NOT NULL DEFAULT '',
  subscription_tier  TEXT        NOT NULL DEFAULT 'free',
  prediction_count   INTEGER     NOT NULL DEFAULT 0,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_device_id ON public.profiles(device_id);


-- ============================================================
-- 2. TABLE : subscriptions
-- ============================================================
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  plan_name    TEXT        NOT NULL,
  amount       INTEGER     NOT NULL,
  currency     TEXT        NOT NULL DEFAULT 'CDF',
  operator     TEXT        NOT NULL DEFAULT 'Orange Money',
  phone_number TEXT        NOT NULL DEFAULT '',
  start_date   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expiry_date  TIMESTAMPTZ NOT NULL,
  status       TEXT        NOT NULL DEFAULT 'active',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_expiry  ON public.subscriptions(expiry_date);


-- ============================================================
-- 3. TABLE : payments
-- ============================================================
CREATE TABLE IF NOT EXISTS public.payments (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  subscription_id  UUID        REFERENCES public.subscriptions(id),
  amount           INTEGER     NOT NULL,
  currency         TEXT        NOT NULL DEFAULT 'CDF',
  operator         TEXT        NOT NULL DEFAULT 'Orange Money',
  phone_number     TEXT        NOT NULL DEFAULT '',
  shwary_reference TEXT        UNIQUE NOT NULL,
  status           TEXT        NOT NULL DEFAULT 'pending',
  plan_name        TEXT        NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  confirmed_at     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_payments_user_id   ON public.payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_reference ON public.payments(shwary_reference);


-- ============================================================
-- 4. TABLE : predictions
-- ============================================================
CREATE TABLE IF NOT EXISTS public.predictions (
  id                   UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID         NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  match_id             TEXT         NOT NULL,
  home_team_name       TEXT         NOT NULL DEFAULT '',
  away_team_name       TEXT         NOT NULL DEFAULT '',
  league_name          TEXT         NOT NULL DEFAULT '',
  consensus_home_score INTEGER      NOT NULL DEFAULT 0,
  consensus_away_score INTEGER      NOT NULL DEFAULT 0,
  overall_confidence   NUMERIC(4,2) NOT NULL DEFAULT 0.00,
  overall_analysis     TEXT         NOT NULL DEFAULT '',
  agents_data          JSONB        NOT NULL DEFAULT '[]'::jsonb,
  created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_predictions_user_id  ON public.predictions(user_id);
CREATE INDEX IF NOT EXISTS idx_predictions_match_id ON public.predictions(match_id);


-- ============================================================
-- 5. TABLE : notifications_log
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notifications_log (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type         TEXT        NOT NULL DEFAULT 'sms',
  message      TEXT        NOT NULL,
  status       TEXT        NOT NULL DEFAULT 'sent',
  triggered_by TEXT        NOT NULL DEFAULT 'payment',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications_log(user_id);


-- ============================================================
-- 6. TABLE : device_accounts
-- ============================================================
CREATE TABLE IF NOT EXISTS public.device_accounts (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id     TEXT        NOT NULL,
  user_id       UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(device_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_device_accounts_device_id ON public.device_accounts(device_id);


-- ============================================================
-- 7. TABLE : favorites
-- ============================================================
CREATE TABLE IF NOT EXISTS public.favorites (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type        TEXT        NOT NULL DEFAULT 'league',
  external_id TEXT        NOT NULL,
  name        TEXT        NOT NULL,
  logo_url    TEXT        NOT NULL DEFAULT '',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, external_id, type)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.favorites(user_id);


-- =============================================================================
-- 8. FONCTIONS ET TRIGGERS
-- =============================================================================

-- Trigger : mise a jour automatique de updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();


-- Trigger : Creer automatiquement un profil lors de l'inscription
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, avatar_url, device_id, subscription_tier, prediction_count)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    'https://api.dicebear.com/7.x/bottts/svg?seed=' || COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'device_id', ''),
    'free',
    0
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- Trigger : bloquer plus de 2 comptes par appareil
CREATE OR REPLACE FUNCTION public.check_device_account_limit()
RETURNS TRIGGER AS $$
DECLARE
  account_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO account_count
    FROM public.profiles
   WHERE device_id = NEW.device_id
     AND id <> NEW.id;

  IF account_count >= 2 THEN
    RAISE EXCEPTION 'Limite de 2 comptes par appareil atteinte.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER trg_check_device_limit
  BEFORE INSERT ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.check_device_account_limit();


-- Fonction : activer un abonnement apres paiement Shwary
CREATE OR REPLACE FUNCTION public.activate_subscription(
  p_user_id       UUID,
  p_plan_name     TEXT,
  p_amount        INTEGER,
  p_currency      TEXT,
  p_operator      TEXT,
  p_phone_number  TEXT,
  p_shwary_ref    TEXT
)
RETURNS UUID AS $$
DECLARE
  v_duration  INTERVAL;
  v_expiry    TIMESTAMPTZ;
  v_sub_id    UUID;
  v_sms       TEXT;
BEGIN
  CASE p_plan_name
    WHEN '1 Jour'    THEN v_duration := INTERVAL '1 day';
    WHEN '1 Semaine' THEN v_duration := INTERVAL '7 days';
    WHEN '1 Mois'    THEN v_duration := INTERVAL '1 month';
    WHEN '1 Annee'   THEN v_duration := INTERVAL '1 year';
    ELSE                  v_duration := INTERVAL '1 day';
  END CASE;

  v_expiry := NOW() + v_duration;

  INSERT INTO public.subscriptions
    (user_id, plan_name, amount, currency, operator, phone_number,
     start_date, expiry_date, status)
  VALUES
    (p_user_id, p_plan_name, p_amount, p_currency, p_operator,
     p_phone_number, NOW(), v_expiry, 'active')
  RETURNING id INTO v_sub_id;

  UPDATE public.payments
     SET status = 'success',
         subscription_id = v_sub_id,
         confirmed_at = NOW()
   WHERE shwary_reference = p_shwary_ref;

  UPDATE public.profiles
     SET subscription_tier = 'premium',
         prediction_count  = 0
   WHERE id = p_user_id;

  v_sms := 'betPronos : Paiement de ' || p_amount || ' ' || p_currency
         || ' reussi via ' || p_operator
         || ' pour la formule "' || p_plan_name
         || '". Acces Premium active jusqu au '
         || TO_CHAR(v_expiry AT TIME ZONE 'Africa/Kinshasa', 'DD/MM/YYYY a HH24:MI')
         || '.';

  INSERT INTO public.notifications_log
    (user_id, type, message, status, triggered_by)
  VALUES
    (p_user_id, 'sms', v_sms, 'sent', 'payment');

  RETURN v_sub_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Fonction : expirer automatiquement les abonnements perim
CREATE OR REPLACE FUNCTION public.check_expired_subscriptions()
RETURNS INTEGER AS $$
DECLARE
  expired_count INTEGER := 0;
  v_user_id UUID;
BEGIN
  FOR v_user_id IN
    SELECT DISTINCT user_id
      FROM public.subscriptions
     WHERE status = 'active'
       AND expiry_date < NOW()
  LOOP
    UPDATE public.profiles
       SET subscription_tier = 'free',
           prediction_count  = 0
     WHERE id = v_user_id;

    UPDATE public.subscriptions
       SET status = 'expired'
     WHERE user_id = v_user_id
       AND status  = 'active'
       AND expiry_date < NOW();

    INSERT INTO public.notifications_log
      (user_id, type, message, status, triggered_by)
    VALUES (
      v_user_id,
      'sms',
      'betPronos : Votre abonnement Premium a expire. Renouvelez-le pour continuer a profiter des pronos IA.',
      'sent',
      'expiry_warning'
    );

    expired_count := expired_count + 1;
  END LOOP;

  RETURN expired_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Fonction : verifier si l essai gratuit est encore valide
CREATE OR REPLACE FUNCTION public.is_trial_valid(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_created_at  TIMESTAMPTZ;
  v_pred_count  INTEGER;
BEGIN
  SELECT created_at, prediction_count
    INTO v_created_at, v_pred_count
    FROM public.profiles
   WHERE id = p_user_id;

  RETURN (NOW() - v_created_at < INTERVAL '24 hours'
          AND v_pred_count < 5);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =============================================================================
-- 9. ROW LEVEL SECURITY (RLS)
-- =============================================================================
ALTER TABLE public.profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.predictions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_accounts   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites         ENABLE ROW LEVEL SECURITY;

-- profiles
CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_insert" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- subscriptions
CREATE POLICY "subscriptions_select" ON public.subscriptions
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "subscriptions_insert" ON public.subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- payments
CREATE POLICY "payments_select" ON public.payments
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "payments_insert" ON public.payments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- predictions
CREATE POLICY "predictions_select" ON public.predictions
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "predictions_insert" ON public.predictions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- notifications_log (lecture seule par l utilisateur)
CREATE POLICY "notif_select" ON public.notifications_log
  FOR SELECT USING (auth.uid() = user_id);

-- device_accounts
CREATE POLICY "device_select" ON public.device_accounts
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "device_insert" ON public.device_accounts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- favorites
CREATE POLICY "favorites_select" ON public.favorites
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "favorites_insert" ON public.favorites
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "favorites_delete" ON public.favorites
  FOR DELETE USING (auth.uid() = user_id);


-- =============================================================================
-- 10. PERMISSIONS
-- =============================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated;

GRANT SELECT, INSERT, UPDATE ON public.profiles          TO authenticated;
GRANT SELECT, INSERT         ON public.subscriptions     TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.payments          TO authenticated;
GRANT SELECT, INSERT         ON public.predictions       TO authenticated;
GRANT SELECT                 ON public.notifications_log TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.favorites         TO authenticated;
GRANT SELECT, INSERT         ON public.device_accounts   TO authenticated;

GRANT EXECUTE ON FUNCTION public.activate_subscription       TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_trial_valid              TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_expired_subscriptions TO service_role;

-- =============================================================================
-- FIN DU SCRIPT betPronos
-- =============================================================================
