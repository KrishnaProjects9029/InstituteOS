# InstituteOS — Open Questions, Technical Risks & Decision Matrix

**Document Version:** 1.1.0 (Remediated Baseline)  
**Status:** Architectural Audit & Risk Register  
**Priority Hierarchy:** Critical Blockers -> High Architectural Risks -> Operational Decisions  

---

## 1. Resolved Baseline Decisions Registry

The four foundational architectural choices have been formally confirmed and resolved:

```
┌────────────────────────────────────────────────────────────────────────┐
│                      RESOLVED DECISION BASELINE                        │
├────┬─────────────────────────────┬───────────────────────┬─────────────┤
│ ID │ DECISION TOPIC              │ RESOLVED DECISION     │ TARGET VER  │
├────┼─────────────────────────────┼───────────────────────┼─────────────┤
│B-01│ Payment Gateway Strategy    │ **Stripe First** with │ V4 Online   │
│    │                             │ provider adapters     │ Integration │
├────┼─────────────────────────────┼───────────────────────┼─────────────┤
│B-02│ Attendance Override Scope   │ **Full Inheritance**  │ **V1 Core** │
│    │ Hierarchy                   │ Inst > Br > Crs > Cls │ Foundation  │
├────┼─────────────────────────────┼───────────────────────┼─────────────┤
│B-03│ Mobile App Distribution     │ **Separate Branded    │ V4 Mobile   │
│    │ Architecture                │ Apps per Institute**  │ Delivery    │
├────┼─────────────────────────────┼───────────────────────┼─────────────┤
│B-04│ SMS Messaging Strategy      │ **Both Modes:**       │ V3 Omni-    │
│    │                             │ BYO + Managed Credits │ channel Com │
└────┴─────────────────────────────┴───────────────────────┴─────────────┘
```

---

## 2. Technical Risks & Mitigation Strategies

### Risk 1: Separate Branded Mobile App Release Maintenance (V4)
- **Risk Description:** Building and publishing dedicated iOS and Android apps for every institute could create massive maintenance overhead during mobile updates and app store reviews (e.g. Apple Guideline 4.2.6).
- **Probability:** High | **Impact:** High
- **Mitigation:**
  - Standardize on a single, highly maintainable React Native / Expo codebase with dynamic asset injection (logos, colors, app names, bundle IDs).
  - Automate the build, code signing, and app store submission pipelines using **Fastlane** and **Expo Application Services (EAS Build/Submit)**.
  - Structure Apple Developer deployments through client-owned developer accounts or Apple Custom B2B Distribution where appropriate.

### Risk 2: Stripe Payment Methods & Regulatory Compliance for Indian Merchants
- **Risk Description:** While Stripe provides world-class APIs, certain Indian domestic payment features (e.g., domestic recurring e-mandates, direct UPI deep-linking) have specific Reserve Bank of India (RBI) compliance requirements and onboarding criteria.
- **Probability:** Medium | **Impact:** Medium
- **Mitigation:**
  - Build payment integration behind a clean `PaymentGatewayAdapter` interface.
  - Implement Stripe Checkout / Stripe Elements for standard card rails, international fees, and SaaS subscriptions.
  - Ensure adapter design permits straightforward plug-in of domestic UPI gateways (e.g. Razorpay/Cashfree) if an institute requires domestic auto-debit rails not active on their Stripe account.

### Risk 3: Platform-Managed SMS Quotas and DLT Entity Liability
- **Risk Description:** Operating a platform-managed SMS credit pool requires InstituteOS to act as a telemarketing entity under Indian Telecom Commercial Communications Customer Preference Regulations (TCCCPR).
- **Probability:** Medium | **Impact:** Medium
- **Mitigation:**
  - Dual-mode architecture ensures large institutes with existing DLT registrations can immediately use BYO credentials.
  - For platform-managed mode, maintain an immutable internal credit ledger, enforce strict prepayment balance checks before queueing SMS jobs, and validate pre-registered DLT template IDs.

### Risk 4: Attendance Inheritance Resolution Performance at Scale
- **Risk Description:** Dynamically resolving effective attendance rules across 4 hierarchy levels (Class > Course > Branch > Institute) for hundreds of thousands of daily attendance entries could become a database bottleneck if not optimized.
- **Probability:** Low | **Impact:** High
- **Mitigation:**
  - Deterministic PostgreSQL resolution function `resolve_effective_attendance_rule()` uses composite indexes on `(institute_id, scope_level, class_id, course_id, branch_id)`.
  - Resolution results are cached in application memory or Redis during bulk attendance marking sessions.

---

## 3. Conflict Resolution & Consistency Record

| Area | Former Inconsistency | Remediated Invariant |
| :--- | :--- | :--- |
| **Payment Gateway** | Prior draft recommended Razorpay first. | **Stripe First is strictly enforced.** Secondary gateways supported via provider adapter. |
| **Mobile Apps** | Prior draft adopted single multi-tenant app and deferred white-label apps. | **Dedicated Branded Mobile Apps for Every Institute** planned for V4 with shared codebase and automated release pipelines. |
| **SMS Modes** | Prior draft favored BYO-only to avoid liability. | **Dual Modes (BYO + InstituteOS-Managed Credits)** fully supported in V3. |
| **Attendance Scope** | Prior draft deferred override hierarchy to V3. | **Full 4-tier inheritance engine implemented in V1 Core Foundation.** |
