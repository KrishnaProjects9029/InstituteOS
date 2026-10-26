# InstituteOS — Hosting Architecture, Cost Modeling & Feasibility Audit

**Document Version:** 1.0.0  
**Status:** Approved Architectural Specification  
**Deployment Strategy:** Free-Tier-First Development transitioning to Metered Multi-Tenant Production  
**Primary Providers:** Supabase, Vercel, Cloudflare, Resend, Upstash, Gupshup/Twilio  

---

## 1. Free-Tier-First Strategy & Infrastructure Baseline

To adhere strictly to **Non-Negotiable Project Rule 8**, InstituteOS is architected to operate entirely within free or near-zero-cost infrastructure tiers throughout development, testing, and early customer pilots (V1 through V3).

The table below details the target providers, free quota allocations, operational ceilings, and migration triggers:

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
│ Cache & Queue      │ 10,000 commands/day│ Ephemeral memory; rate-      │
│ (Upstash Redis)    │ 256MB memory cap   │ limiting only for low traffic│
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

## 2. Infrastructure Evolution: Free Tier vs. Paid Production

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    INFRASTRUCTURE TRANSITION TIMELINE                       │
├───────────────────────────────┬─────────────────────────────────────────────┤
│ VERSIONS 1 – 3 (DEVELOPMENT)  │ VERSIONS 4 – 5 (PRODUCTION & ENTERPRISE)    │
├───────────────────────────────┼─────────────────────────────────────────────┤
│ • Supabase Free Tier ($0/mo)  │ • Supabase Pro Tier ($25/mo base)           │
│   (500MB DB, Manual Backups)  │   (8GB DB, No Inactivity Pause, Daily PITR)│
│                               │                                             │
│ • Vercel Hobby Tier ($0/mo)   │ • Vercel Pro Tier ($20/seat/mo)             │
│   (Local subdomains, Preview) │   (Edge Middleware, Custom Tenant Domains)  │
│                               │                                             │
│ • Cloudflare Free ($0/mo)     │ • Cloudflare for Platforms ($20/mo + usage) │
│   (Standard DNS / CDN)        │   (Automated SSL for Tenant Custom Domains) │
│                               │                                             │
│ • Resend Free ($0/mo)         │ • Resend Pro ($20/mo for 50k emails)        │
│   (100 emails/day developer)  │   (High delivery throughput for reports)    │
│                               │                                             │
│ • BYO SMS / WhatsApp ($0 cost)│ • BYO SMS / WhatsApp Gateway Pass-Through   │
│   (Tenants fund own gateway)  │   (Platform charges 0% markup or pass-thru) │
│                               │                                             │
│ ESTIMATED COST: $0.00 / month │ ESTIMATED BASE: ~$65.00 – $85.00 / month    │
└───────────────────────────────┴─────────────────────────────────────────────┘
```

---

## 3. Critical Capabilities Requiring Paid Infrastructure

While application features and business logic are fully implementable on free tiers, certain **production capabilities** strictly necessitate paid commercial services. These must be approved prior to V4/V5 deployment:

### 1. Point-in-Time Recovery (PITR) & High-Availability Backups (V5)
- **Free Tier Reality:** Supabase Free provides only manual SQL snapshot downloads and lacks automated Point-in-Time Recovery.
- **Enterprise Requirement:** To meet **RPO < 1 Hour** in disaster recovery audits (REQ-SEC-005), the production database requires Supabase Pro ($25/month), which enables continuous write-ahead log (WAL) archiving.

### 2. Tenant Custom Domains with Automated SSL (V4)
- **Free Tier Reality:** Standard Vercel Hobby and Cloudflare Free tiers require manual DNS binding and do not support dynamic programmatically generated SSL certificates for third-party customer CNAMEs (`admissions.apexacademy.com`).
- **Enterprise Requirement:** Provisioning automated SSL certificates for hundreds of custom tenant domains requires **Cloudflare for Platforms** ($20/month base) or **Vercel Custom Domains API** ($20/seat/month).

### 3. Telecom Carrier Fees: SMS & WhatsApp Messaging (V3–V4)
- **Free Tier Reality:** There is no free tier for commercial Indian telecom SMS (DLT) or WhatsApp Business API. Carriers charge per message.
- **Cost Structure:**
  - Indian DLT Transactional SMS: \~₹0.15 to ₹0.25 ($0.002 to $0.003) per SMS + mandatory one-time entity registration fee (₹5,900 / $70).
  - WhatsApp Business API (Authentication / Utility): \~₹0.35 to ₹0.80 ($0.004 to $0.010) per conversation window.
- **Architectural Solution:** To preserve platform margin, InstituteOS implements a **Bring-Your-Own (BYO) Provider Credential** model. Institutes provide their own Twilio/Gupshup account keys and pay telecom costs directly.

### 4. Apple App Store & Google Play Developer Licenses (V4)
- **Google Play Console:** One-time registration fee of **$25.00**.
- **Apple Developer Program:** Annual recurring subscription of **$99.00 / year**.
- **White-Label Branded App Constraint:** If individual institutes demand dedicated apps published under their own school legal entity in app stores, Apple and Google developer guidelines mandate that each institute must purchase their own $99/yr Apple Developer account and D-U-N-S business verification number.

### 5. Generative AI Token Quotas (V4)
- **Pricing Assumptions:** Google Gemini 1.5 Flash (~$0.075 per 1M input tokens, ~$0.30 per 1M output tokens).
- **Cost Control:** Institutes have configurable monthly spending caps; free trials are limited to 100k tokens.

---

## 4. Cost-Control Strategy & Upgrade Approval Rules

To prevent accidental financial commitments during development and early rollout, the following governance rules are enforced:

1. **Strict Developer Free-Tier Isolation:** All local development, CI/CD test runners, and staging previews must use mock adapters or verified free-tier developer accounts. No production credit cards will be configured on development environments.
2. **Upgrade Trigger Protocol:** Upgrading any service from Free to Paid requires a formal **Architecture Upgrade Justification**:
   - The specific resource constraint must be demonstrably exceeded (> 80% of free quota on active users).
   - Commercial revenue from active paying institutes must cover the infrastructure upgrade cost.
   - Formal sign-off must be obtained from the Technical Project Manager and Product Architect.
3. **Database Connection Guardrails:** To prevent crashing the Supabase free connection limit (60 direct connections), Next.js applications must connect through **Supabase Supavisor** in transaction pooling mode (`port 6543`), ensuring idle connections are reclaimed instantly.
