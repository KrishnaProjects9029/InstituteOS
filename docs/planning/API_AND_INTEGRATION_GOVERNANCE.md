# InstituteOS — API & Integration Governance Specification

**Document Version:** 1.0.0  
**Status:** Approved Architectural Specification  
**API Paradigm:** RESTful JSON APIs & Event-Driven Webhooks  
**Version Strategy:** Semantic URL Versioning (`/api/v1/`) with Formal Deprecation Lifecycles  

---

## 1. API Architecture & Surface Categories

InstituteOS exposes three distinct API surfaces, each engineered for specific trust boundaries, performance requirements, and protocols:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        INSTITUTE-OS API SURFACES                       │
├────────────────────┬────────────────────┬──────────────────────────────┤
│ SURFACE            │ CONSUMERS          │ AUTHENTICATION & PROTOCOL    │
├────────────────────┼────────────────────┼──────────────────────────────┤
│ 1. Internal App    │ Next.js Web Client │ Next.js Server Actions &     │
│    RPCs            │                    │ HTTP-Only Secure JWT Cookies │
├────────────────────┼────────────────────┼──────────────────────────────┤
│ 2. Mobile App API  │ React Native /     │ Bearer Access Tokens         │
│                    │ Expo Clients       │ (`/api/v1/mobile/...`)       │
├────────────────────┼────────────────────┼──────────────────────────────┤
│ 3. External Partner│ Third-party LMS,   │ Cryptographic Scoped API     │
│    & Public API    │ Biometric Hardware │ Keys (`inst_live_...`)       │
└────────────────────┴────────────────────┴──────────────────────────────┘
```

---

## 2. API Versioning, Deprecation & Backward Compatibility

### Versioning Policy
1. **URI Versioning:** External and mobile APIs strictly utilize path-based semantic versioning (e.g., `/api/v1/students`, `/api/v1/attendance`).
2. **Backward-Compatible Changes (No Version Bump):**
   - Adding new optional request parameters.
   - Adding new fields to JSON response payloads.
   - Adding new webhook event types.
3. **Breaking Changes (Requires Version Increment to `/api/v2/`):**
   - Renaming or removing existing fields or endpoints.
   - Modifying data types or validation constraints (e.g. making an optional field mandatory).
   - Changing error response structures or HTTP status code contracts.

### Deprecation & Sunset Schedule
When an API version is targeted for deprecation:
1. **Minimum 6-Month Deprecation Window:** Older API versions are maintained in production for at least 180 days following the formal release of a successor version.
2. **Standard HTTP Deprecation Headers:** All responses from deprecated endpoints include standard IETF headers:
   ```http
   Deprecation: @1793404800
   Sunset: Wed, 28 Oct 2026 23:59:59 GMT
   Link: <https://developer.instituteos.com/migration-v1-to-v2>; rel="deprecation"
   ```
3. **Telemetry & Notification:** Platform monitoring tracks callers using deprecated versions; automated alerts notify tenant administrators and developer contacts.

---

## 3. Authentication & Scoped API Key Management

External consumers authenticate via high-entropy, cryptographically hashed API keys issued from the tenant administration portal:

### API Key Format & Storage
- **Public Key Token:** `inst_live_` (Production) or `inst_test_` (Sandbox) prefix followed by 48 base62 alphanumeric characters (e.g., `inst_live_8F1a29B...`).
- **Database Storage:** The raw key is displayed to the user **exactly once** upon creation. The database stores only the SHA-256 hash in `api_keys(key_hash)`.
- **Key Rotation:** Supports seamless zero-downtime key rotation via dual-active grace periods.

### Granular Scope Enforcement
API keys are bound to explicit, fine-grained scopes:
- `students:read`, `students:write`
- `attendance:read`, `attendance:record`
- `fees:read`, `payments:record`
- `webhooks:manage`

Requests attempting actions outside their granted scopes return `403 Forbidden` with error code `INSUFFICIENT_SCOPE`.

---

## 4. Rate Limiting & Abuse Prevention

To protect platform availability and prevent noisy-neighbor degradation, rate limits are enforced at the edge using a **Redis Token Bucket Algorithm** (Upstash Redis / Cloudflare Workers):

```
┌────────────────────────────────────────────────────────────────────────┐
│                        RATE LIMITING THRESHOLDS                        │
├────────────────────┬────────────────────┬──────────────────────────────┤
│ CLIENT TIER        │ BURST CAPACITY     │ SUSTAINED REFILL RATE        │
├────────────────────┼────────────────────┼──────────────────────────────┤
│ Unauthenticated    │ 20 requests / min  │ 0.33 req / sec (per IP)      │
│ (Public Forms)     │                    │                              │
├────────────────────┼────────────────────┼──────────────────────────────┤
│ Authenticated Web  │ 300 requests / min │ 5.0 req / sec (per User)     │
│ & Mobile Users     │                    │                              │
├────────────────────┼────────────────────┼──────────────────────────────┤
│ External API Keys  │ 600 requests / min │ 10.0 req / sec (per Tenant)  │
│ (Starter Tier)     │                    │                              │
├────────────────────┼────────────────────┼──────────────────────────────┤
│ External API Keys  │ 3,000 requests/min │ 50.0 req / sec (per Tenant)  │
│ (Enterprise Tier)  │                    │                              │
└────────────────────┴────────────────────┴──────────────────────────────┘
```

When rate limits are exceeded, the API returns `429 Too Many Requests` with standard retry headers:
```http
HTTP/1.1 429 Too Many Requests
Retry-After: 42
X-RateLimit-Limit: 600
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1793404842
```

---

## 5. Webhook Ingestion & Egress Governance

InstituteOS functions as both a **Webhook Ingestion Consumer** (receiving events from payment gateways and telecom carriers) and a **Webhook Dispatcher** (publishing real-time events to tenant LMS and ERP systems).

### Inbound Webhook Ingestion (Payment Gateways: Razorpay / Stripe)
1. **HMAC-SHA256 Signature Verification:** Every incoming webhook payload is verified using the provider's shared secret before processing. Requests with missing or invalid signatures are rejected instantly (`401 Unauthorized`).
2. **Replay Attack Shield:** Webhook timestamps (`X-Razorpay-Event-Time` or `Stripe-Signature` timestamp) are verified to be within a 300-second window of system time. Older payloads are discarded.
3. **Idempotent Ingestion Table:**
   Every event ID is recorded in an `inbound_webhook_events` table with a unique constraint. If a duplicate event ID arrives, the system logs the duplication and responds `200 OK` without re-executing financial mutations.

```sql
CREATE TABLE inbound_webhook_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider VARCHAR(50) NOT NULL, -- 'RAZORPAY', 'STRIPE', 'GUPSHUP'
    event_id VARCHAR(150) NOT NULL,
    payload JSONB NOT NULL,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_provider_event UNIQUE (provider, event_id)
);
```

### Outbound Webhook Dispatch (Tenant Integrations)
1. **Cryptographic Signing:** Payloads are signed using HMAC-SHA256 with the tenant's webhook signing secret. The signature is transmitted in the `X-InstituteOS-Signature` header:
   ```http
   X-InstituteOS-Signature: t=1793404800,v1=9b1d98a0c2394...
   ```
2. **Durable Delivery Queue & Exponential Backoff:**
   Failed outbound webhook dispatches retry automatically using an exponential backoff schedule:
   - Attempt 1: Immediate
   - Attempt 2: 1 minute
   - Attempt 3: 5 minutes
   - Attempt 4: 30 minutes
   - Attempt 5: 2 hours
3. **Dead-Letter Handling:** After 5 unsuccessful attempts, the webhook event transitions to `FAILED_DEAD_LETTER`, generating an alert in the tenant developer dashboard.

---

## 6. Standard Webhook Event Schemas

All outbound events follow the CloudEvents specification format:

```json
{
  "specversion": "1.0",
  "id": "evt_9a8b7c6d-5e4f-4a3b-2c1d-0e9f8a7b6c5d",
  "source": "https://api.instituteos.com/v1/institutes/8f1a23c0",
  "type": "student.attendance.recorded",
  "time": "2026-10-24T18:00:00Z",
  "datacontenttype": "application/json",
  "data": {
    "institute_id": "8f1a23c0-32b1-4f81-8172-e19034cb9911",
    "branch_id": "22e84120-77a4-4903-8d2a-194567ac8833",
    "student_id": "90e12345-bcde-4567-8901-23456789abcd",
    "admission_number": "ADM-2026-0042",
    "attendance_date": "2026-10-24",
    "period_number": null,
    "status": "ABSENT",
    "recorded_by_user_id": "4a7375a0-9c2f-4882-990a-5b12854b7c12"
  }
}
```

---

## 7. Developer Portal, Sandbox & Documentation

In Version 4, InstituteOS introduces a dedicated **Developer Portal**:
1. **Interactive API Documentation:** OpenAPI 3.1 specification rendered via Swagger UI / Scalar, supporting instant interactive testing.
2. **Isolated Test Sandbox:** Tenants can toggle between `Live` and `Test` modes. In test mode, API keys interact with synthetic test students and simulated payment responses without incurring gateway charges or modifying live records.
3. **Webhook Simulator:** Enables developers to trigger simulated events (e.g. `payment.succeeded`, `student.admitted`) to test their local webhook endpoints.
