# Cloud Functions for Chargily Subscriptions

This Functions code exposes:
- createChargilyPayment (Callable): Creates a Chargily checkout session with server-calculated price and returns checkoutUrl.
- chargilyWebhook (HTTP): Validates Chargily HMAC signature and, on paid events, updates Firestore subscriptions/{userId}.

Security:
- Firestore rules prevent client writes to subscriptions collection.
- Webhook signature uses HMAC-SHA256 over the raw body.
- Idempotency via webhook_events collection.

Config:
- CHARGILY_SECRET_KEY (secret param)
- CHARGILY_PUBLIC_KEY (secret param)
- CHARGILY_API_URL (string param, default prod)
- PREMIUM_MONTHLY_PRICE_DZD, PREMIUM_YEARLY_PRICE_DZD (int params)

Deployment:
- Set params and secrets: firebase functions:secrets:set CHARGILY_SECRET_KEY; firebase functions:secrets:set CHARGILY_PUBLIC_KEY.
- Deploy: npm run deploy
