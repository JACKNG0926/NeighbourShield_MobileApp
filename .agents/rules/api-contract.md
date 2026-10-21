---
trigger: glob
globs: ["lib/**/*model*.dart", "lib/**/*dto*.dart", "lib/**/*repository*.dart", "lib/**/*service*.dart", "lib/**/*api*.dart", "**/openapi.yaml", "docs/api/**"]
description: Enforces strict adherence to the Django OpenAPI contract when building Flutter data layers.
---

# Django OpenAPI & Data Layer Contract Rules

This rule enforces strict architectural compliance between the Flutter mobile data layer and the Django REST Framework (DRF) backend.

## 1. Backend Authority & Contract Invariance
- The Django REST API (and its OpenAPI specification) is the authoritative source of truth.
- The local copy of the spec lives at `docs/api/openapi.yaml`. It is copied from the Django repo after every backend contract change.
- Before writing or changing a model or repository, read the endpoint in `docs/api/openapi.yaml`. If the endpoint or field is missing, or the spec looks outdated, STOP and ask. Do not guess field names or types.
- NEVER invent hypothetical endpoints, undocumented query parameters, or unsupported request body fields.
- NEVER alter JSON payload schemas unilaterally in the mobile client.
- When endpoint specifications change, coordinate schema updates from the Django backend first.

## 2. Networking Architecture & HTTP Standard
- **HTTP Client:** Exclusively use `package:http/http.dart`. Do NOT introduce `dio`, `chopper`, or `retrofit`.
- **Base URL:** Centralize API URL resolution via `ApiConfig.baseUrl` in `lib/app/api_config.dart`. Never hardcode IP addresses or domain URLs inside repositories.
- **Headers & Authentication:**
  - JSON mutation requests (`POST`, `PUT`, `PATCH` with a JSON body): Set `'Content-Type': 'application/json'`.
  - File uploads (e.g. `image` on `/api/posts/`): Use `http.MultipartRequest`. Do NOT set `Content-Type` manually; the client sets the multipart boundary itself.
  - All endpoints: Set `'Accept': 'application/json'`.
  - Authenticated endpoints: Retrieve the stored token from `SharedPreferences` (`auth_token`) and pass:
    `'Authorization': 'Token $token'` (DRF `TokenAuthentication` scheme; NEVER `'Bearer'`).
- **Network Timeouts:** Every HTTP request must specify an explicit timeout (e.g., `const Duration(seconds: 10)`) using `.timeout(...)` with descriptive exception handling.
- **Local HTTP (development only):** The local Django server uses plain `http://`.
  - Android 9+ blocks cleartext traffic by default; allow it in the debug manifest only (`android:usesCleartextTraffic="true"`).
  - iOS physical devices need an App Transport Security exception for the LAN IP in debug builds only.
  - Never ship these exceptions in release builds.

## 3. Serialization & Data Type Mapping
- **Case Mapping Standard:**
  - Backend sends and expects `snake_case` keys (e.g., `post_type`, `created_at`, `is_verified`, `author_role`).
  - Dart models must expose `camelCase` fields (e.g., `postType`, `createdAt`, `isVerified`, `authorRole`).
  - Map keys explicitly in `factory Model.fromJson(Map<String, dynamic> json)` and `Map<String, dynamic> toJson()`.
  - If code generation is introduced (`json_serializable` / `freezed`), configure `@JsonSerializable(fieldRename: FieldRename.snake)` or explicit `@JsonKey(name: '...')`.
- **Date & Time Handling:**
  - Django emits ISO 8601 UTC strings ending in `Z`. Fractional seconds may or may not be present (DRF default includes microseconds, e.g. `2026-10-21T11:00:30.123456Z`).
  - Parse defensively using `DateTime.tryParse(json['key'].toString())`; it accepts both forms.
  - Submit timestamps using `.toUtc().toIso8601String()`.
  - Formatting for display (e.g., `timeAgo`, localized date) belongs in presentation getters or formatting helpers, never in raw DTO properties.
- **Coordinates & Numeric Precision:**
  - The backend returns latitude/longitude as JSON numbers. Still parse defensively using `num.toDouble()` or `double.tryParse()` in case a value arrives as a numeric string.
  - When submitting coordinates to Django, clamp precision to 6 decimal places: `double.parse(lat.toStringAsFixed(6))`.
- **Enums & Choice Fields:**
  - Sanitize string choices from DRF with `.toLowerCase()`.
  - Use Dart 3 switch expressions with default fallback branches to prevent runtime crashes when Django introduces new choice values.
- **List Responses (Pagination):**
  - A list endpoint returns either a plain JSON array or a paginated object `{"count": int, "next": url|null, "previous": url|null, "results": [...]}`. Check the endpoint in `docs/api/openapi.yaml` to see which.
  - Repositories must handle both shapes: if the decoded body is a `List`, use it; if it is a `Map` with `results`, use that.

## 4. DRF Error Handling & Status Codes
- **200 OK / 201 Created:** Decode response body via `jsonDecode(response.body)`. Validate payload shape (`List` vs `Map`).
- **400 Bad Request (Validation Errors):** Parse DRF error dictionaries. Check for `detail` string or extract the first field error message. The body may not be JSON, so guard the decode:
  ```dart
  String errorMessage = 'Request failed (HTTP ${response.statusCode})';
  try {
    final decoded = jsonDecode(response.body);
    if (decoded is Map) {
      if (decoded.containsKey('detail')) {
        errorMessage = decoded['detail'].toString();
      } else if (decoded.isNotEmpty) {
        final firstKey = decoded.keys.first;
        final value = decoded[firstKey];
        errorMessage = (value is List && value.isNotEmpty) ? '$firstKey: ${value.first}' : '$firstKey: $value';
      }
    }
  } on FormatException {
    // Non-JSON body: keep the generic message above.
  }
  throw Exception(errorMessage);
  ```
- **401 Unauthorized:** Missing, expired, or invalid token. Invalidate token in `SharedPreferences` and bubble up exception for session gating.
- **403 Forbidden:** Role permission denied. Fail closed; never grant elevated feature access locally.
- **404 Not Found:** Throw specific resource not found exception.
- **500+ Server Error:** Do not decode or display the response body (it may be HTML). Throw a generic server error message without leaking sensitive internal stack traces.

## 5. Security & Session Integrity
- Never log authentication tokens or passwords in debug logs or telemetry.
- Verify role authorization using both role string and backend verification flags (e.g., `is_verified_volunteer == true && is_volunteer_opted_in == true` for volunteer dashboards). Fail closed if attributes conflict or if either flag is missing from the `/api/me/` response.

## 6. Directory Structure & Canonical Reference
- Repositories: Place in `lib/features/<feature>/data/<feature>_repository.dart`.
- Models: Place in `lib/features/<feature>/models/<model>.dart`.
- Presentation code must never perform direct HTTP calls. Always encapsulate API interactions within repository classes.
- Canonical implementation reference:
  - Model: `lib/features/reports/models/safety_report.dart`
  - Repository: `lib/features/reports/data/safety_report_repository.dart`

## 7. Endpoint Reference (mirror of the Django contract)
This table is a summary. If it disagrees with `docs/api/openapi.yaml`, the OpenAPI file wins. Update both together.

| Endpoint | Method | Auth | Body type | Request summary | Key response fields |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `/api/auth/login/` | `POST` | None | JSON | `{"username", "password"}` | `{"token", "user"}` |
| `/api/auth/register/` | `POST` | None | JSON | `{"username", "password", "email", "phone_number", "residence": id}` | `{"token", "user"}` |
| `/api/auth/volunteer/apply/` | `POST` | Token | none | empty | `{"detail"}` |
| `/api/me/` | `GET`, `PATCH` | Token | JSON | partial profile fields | `{"id", "username", "role", "unit_address", "is_verified_volunteer", "is_volunteer_opted_in", ...}` |
| `/api/me/location/` | `PUT` | Token | JSON | `{"latitude", "longitude"}` | `{"detail"}` |
| `/api/incidents/` | `GET`, `POST` | Token | JSON | `{"latitude", "longitude", "message", "incident_type"}` | Incident object |
| `/api/incidents/<id>/acknowledge/` | `POST` | Token (Security/Volunteer) | JSON | `{"eta_minutes", "note"}` | `{"incident", "acknowledgement_id", "is_first_acknowledgement"}` |
| `/api/posts/` | `GET`, `POST` | Token | **multipart** | `{"title", "description", "latitude", "longitude", "image": file}` | SafetyPost object |
| `/api/community-posts/` | `GET`, `POST` | Token | JSON | `{"title", "content"}` | `{"id", "author_name", "author_area", "title", "content", "created_at"}` |
| `/api/devices/` | `GET`, `POST` | Token | JSON | `{"fcm_token", "platform": "android\|ios"}` | `{"id", "platform", "is_active", "last_seen"}` |
| `/api/areas/` | `GET` | Token | none | none | list of `{"id", "name", "center_latitude", "center_longitude", "radius_m"}` |
| `/api/properties/` | `GET` | Token | none | none | list of properties |

Last synced with Django `openapi.yaml`: (fill in date)

## 8. Entity Reference & Model Consistency

### Rules
- **Naming:** The entity map below mirrors the Django contract. Use the Dart class names listed here. Do not invent new class names; if an entity is missing, ask for it to be added to the table first.
- **One model per entity:** One immutable model class per entity, in `lib/features/<feature>/models/`. Do not create a second class for the same API resource.
- **Type mapping from JSON:**
  - `int` → `int`, `str` → `String`, `bool` → `bool`, number → `double` (via `num.toDouble()`)
  - datetime → `DateTime` (UTC, parsed with `DateTime.tryParse`)
  - choice field → Dart `enum` with a fallback value for unknown strings
  - foreign key → `int` (ID only, unless the table says nested)
- **Nullability:** A field the contract marks nullable is a nullable Dart type (`String?`). A field the contract marks required must be non-null; if it is missing or the wrong type in a response, throw a `FormatException` instead of silently defaulting.
- **Read-only and write-only fields:** Read-only fields (e.g. `author_name`, `created_at`) are parsed in `fromJson` but never sent in `toJson`. Write-only fields (`password`, `fcm_token`) are sent in `toJson` and never stored on the model.
- **Source of truth:** If this section disagrees with `docs/api/openapi.yaml`, the OpenAPI file wins; update both.

### Entity map (mirror of Django)
| Entity | API path | Dart class | Feature folder |
| :--- | :--- | :--- | :--- |
| User | `/api/me/`, `/api/auth/*` | TODO | TODO |
| Area | `/api/areas/` | TODO | TODO |
| Property | `/api/properties/` | TODO | TODO |
| Incident | `/api/incidents/` | TODO | TODO |
| Acknowledgement | `/api/incidents/<id>/acknowledge/` | TODO | TODO |
| SafetyPost | `/api/posts/` | `SafetyReport` (assumed same entity; confirm) | `lib/features/reports/` |
| CommunityPost | `/api/community-posts/` | TODO | TODO |
| Device | `/api/devices/` | TODO | TODO |

For the field list of each entity, see "Known fields" in the Django `api-contract.md` and keep it in sync here.