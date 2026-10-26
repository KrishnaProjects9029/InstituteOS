# InstituteOS — Hosting Architecture, Cost Modeling & Feasibility Audit

**Document Version:** 1.1.0 (Remediated Baseline)  
**Status:** Approved Architectural Specification  
**Deployment Strategy:** Free-Tier-First Development transitioning to Metered Multi-Tenant Production  
**Primary Providers:** Supabase, Vercel, Cloudflare, Stripe, Resend, Upstash, Twilio/Gupshup  

---

## 1. Free-Tier-First Strategy & Infrastructure Baseline

InstituteOS operates within free or near-zero-cost infrastructure tiers throughout development, testing, and early customer pilots (V1 through V3).

```
┌────────────────────────────────────────────────────────────────────────┐
│                   INFRASTRUCTURE SERVICE EVALUATION                    │
├────────────────────┬────────────────────┬──────────────────────────────┤
│ SERVICE & PROVIDER │ FREE TIER LIMITS   │ KNOWN PRODUCTION LIMITATIONS │
├────────────────────┼────────────────────┼──────────────────────────────┤
│ Application Host   │ 100GB Bandwidth,   │ 10-15s serverless execution  │
│ (Vercel Hobby)     │ Unlimited Deploy   │ timeout; custom domain CNAME │
│                    │ Previews, 1M edge  │ routing requires Pro plan    │
├────────────────────┼────────────────────┼──────────────────────────────┤
│ Managed Database   │ 500MB DB storage,  │ Inactivity pause after 7     │
│ (Supabase Free)    │ 1GB file storage,  │ days of no queries; no Point-│
│                    │ 50k monthly active │ in-Time Recovery (PITR);     │
│                    │ users, 500MB egress│ 60 direct connection pool cap│
├────────────────────┼────────────────────┼──────────────────────────────┤
│ Payment Gateway    │ Sandbox Mode       │ Standard Stripe processing   │
│ (Stripe First)     │ (Free testing)     │ fees per successful charge;  │
│                    │                    │ merchant verification needed │
├────────────────────┼────────────────────┼──────────────────────────────┤
│ Transactional Mail │ 3,000 emails/month │ Requires verified sending    │
│ (Resend Free)      │ (100 emails/day)   │ domain; no dedicated IP      │
├────────────────────┼────────────────────┼──────────────────────────────┤
│ Edge CDN & DNS     │ Unlimited DDoS,    │ Advanced WAF rules and edge  │
│ (Cloudflare Free)  │ Global CDN caching,│ SSL for custom tenant SaaS   │
│                    │ Universal SSL      │ domains requires SSL for SaaS│
└────────────────────┴────────────────────┴──────────────────────────────┘
```

---

## 2. Infrastructure Evolution & Commercial Features

### 1. Stripe-First Online Payments (V4)
- **Fee Model:** Pay-as-you-go per transaction. No monthly platform fee for standard accounts.
- **Stripe Billing:** Used for SaaS subscription plans, plan upgrades, and recurring tenant billing.
- **Regulatory Consideration:** For Indian merchants, Stripe compliance requires active business verification, GSTIN documentation, and compliance with RBI guidelines on international remittances and domestic card recurring mandates.

### 2. Dedicated Branded Mobile Apps Release Management (V4)
- **Shared Codebase Architecture:** Built on React Native with Expo. Single unified codebase with parameterized configurations.
- **Release Automation:** Expo Application Services (EAS Build & Submit) or Fastlane pipelines build separate `.apk`/`.aab` and `.ipa` binaries per tenant.
- **Store Accounts:**
  - Option A: Deployed to client-owned Apple/Google accounts ($99/year Apple, $25 one-time Google).
  - Option B: Apple Custom B2B Apps / Google Private App distribution.

### 3. Dual-Mode SMS Infrastructure (V3)
- **Mode A (BYO):** Zero platform cost. Tenant pays carrier directly. Platform stores encrypted credentials in AES-256 vault.
- **Mode B (InstituteOS-Managed):** Platform purchases bulk SMS credits from carriers (e.g. ₹0.12–₹0.18/SMS) and bills institutes with a transparent margin via pre-funded credit wallets. Internal database ledger tracks balance deductions per message.

### 4. Attendance-Rule Engine Infrastructure (V1)
- Delivered in PostgreSQL database tier using efficient SQL resolution functions (`resolve_effective_attendance_rule`).
- $0 incremental infrastructure cost; runs entirely within database compute.
