### Entity map
| Entity (canonical) | Django model | Serializer | API path | Dart class (Flutter) |
| :--- | :--- | :--- | :--- | :--- |
| User | `core.User` | `MobileProfileSerializer` (profile), `RegistrationSerializer` (register), `UserSerializer` (nested & admin) | `/api/me/`, `/api/auth/*`, `/api/users/` | `UserSession` (`lib/features/auth/models/user_session.dart`) |
| Area | `core.Area` | `AreaSerializer` | `/api/areas/` | none |
| Property | `core.Property` | `PropertySerializer` | `/api/properties/` | none |
| Incident | `core.Incident` | `IncidentSerializer` | `/api/incidents/` | `VolunteerIncident` (`lib/features/volunteer/models/volunteer_incident.dart`) |
| Acknowledgement | `core.Acknowledgement` | None (Action dict in `IncidentViewSet.acknowledge`) | `/api/incidents/<id>/acknowledge/` | none |
| SafetyPost | `core.SafetyPost` | `SafetyPostSerializer` | `/api/posts/` | `SafetyReport` (`lib/features/reports/models/safety_report.dart`) |
| CommunityPost | `core.CommunityPost` | `CommunityPostSerializer` | `/api/community-posts/` | `CommunityPost` (`lib/features/community/models/community_post.dart`) |
| Device | `core.Device` | `DeviceSerializer` | `/api/devices/` | none (managed via `DeviceRegistrationService`) |

### Known fields
Types are JSON types. Every exposed field includes its type, nullability (`nullable` vs `non-nullable`), and read/write flag (`read-only`, `writable`, or `write-only`):
- **User (`core.User`):**
  - Exposed in profile (`MobileProfileSerializer`) and nested (`UserSerializer`):
    - `id`: int, non-nullable, read-only
    - `username`: str, non-nullable, read-only in profile (writable on register)
    - `email`: str, non-nullable (blank allowed `""`), writable
    - `first_name`: str, non-nullable (blank allowed `""`), writable
    - `last_name`: str, non-nullable (blank allowed `""`), writable
    - `role`: str choice (`resident` | `volunteer` | `security` | `admin`), non-nullable, read-only
    - `phone_number`: str, non-nullable (blank allowed `""`), writable
    - `unit_address`: str, non-nullable (blank allowed `""`), writable
    - `area`: int (FK to Area), nullable (`null=True`), read-only in profile
    - `residence`: int (FK to Property), nullable (`null=True`), read-only in profile (writable on register)
    - `is_volunteer_opted_in`: bool, non-nullable, writable
    - `is_verified_volunteer`: bool, non-nullable, read-only
    - `password`: str, write-only (in `RegistrationSerializer` only, never returned in responses)
- **Area (`core.Area`, `AreaSerializer`):**
  - `id`: int, non-nullable, read-only
  - `name`: str, non-nullable, writable (read-only in API via `ReadOnlyModelViewSet`)
  - `center_latitude`: number (decimal), nullable (`null=True`), writable
  - `center_longitude`: number (decimal), nullable (`null=True`), writable
  - `radius_m`: int, nullable (`null=True`), writable
  *(Note: `volunteer_radius_m` is NOT a field on Area; it belongs to `EscalationPolicy`).*
- **Property (`core.Property`, `PropertySerializer`):**
  - `id`: int, non-nullable, read-only
  - `area`: int (FK to Area), non-nullable, writable
  - `unit_number`: str, non-nullable, writable
  - `address_line`: str, non-nullable, writable
  - `postal_code`: str, non-nullable (blank allowed `""`), writable
  - `property_type`: str choice (`house` | `apartment` | `townhouse` | `other`), non-nullable, writable
  - `latitude`: number (decimal), nullable (`null=True`), writable
  - `longitude`: number (decimal), nullable (`null=True`), writable
  - `is_active`: bool, non-nullable, writable
  - `created_at`: datetime (ISO 8601 UTC), non-nullable, read-only
  - `resident_count`: int (computed from `residents.count`), non-nullable, read-only
- **Incident (`core.Incident`, `IncidentSerializer`):**
  - `id`: int, non-nullable, read-only
  - `user`: object (`UserSerializer`), non-nullable, read-only
  - `latitude`: number (decimal), non-nullable, writable on create
  - `longitude`: number (decimal), non-nullable, writable on create
  - `message`: str, non-nullable (blank allowed `""`), writable on create
  - `incident_type`: str choice (`medical` | `crime` | `fire` | `accident` | `other`), non-nullable, writable on create
  - `status`: str choice (`pending` | `acknowledged` | `escalated` | `resolved` | `cancelled`), non-nullable, read-only
  - `created_at`: datetime (ISO 8601 UTC), non-nullable, read-only
  - `escalation_level`: int, non-nullable, read-only
  - `next_escalation_at`: datetime (ISO 8601 UTC), nullable (`null=True`), read-only
  - `acknowledged_by`: object (`UserSerializer`), nullable (`null=True`), read-only
  - `acknowledged_at`: datetime (ISO 8601 UTC), nullable (`null=True`), read-only
  - `resolved_at`: datetime (ISO 8601 UTC), nullable (`null=True`), read-only
  - `resolution_note`: str, non-nullable (blank allowed `""`), read-only
  *(Note: `severity` does NOT exist on Incident; it exists on SafetyPost).*
- **Acknowledgement (`core.Acknowledgement`):**
  - Managed via action endpoint `/api/incidents/<id>/acknowledge/` (no standalone ModelSerializer).
  - Request payload:
    - `eta_minutes`: int, nullable / optional, writable
    - `note`: str, optional (defaults to `""`), writable
  - Action response payload:
    - `incident`: object (`IncidentSerializer`), non-nullable, read-only
    - `acknowledgement_id`: int, non-nullable, read-only
    - `is_first_acknowledgement`: bool, non-nullable, read-only
  - Underlying model fields (`core.Acknowledgement`):
    - `id`: int, non-nullable, read-only
    - `incident`: int (FK to Incident), non-nullable
    - `responder`: int (FK to User), non-nullable
    - `responder_type`: str choice (`security` | `volunteer`), non-nullable, computed
    - `acknowledged_at`: datetime (ISO 8601 UTC), non-nullable, read-only
    - `eta_minutes`: int, nullable (`null=True`), writable
    - `note`: str, non-nullable (blank allowed `""`), writable
- **SafetyPost (`core.SafetyPost`, `SafetyPostSerializer`):**
  - `id`: int, non-nullable, read-only
  - `author`: object (`UserSerializer`), non-nullable, read-only
  - `post_type`: str choice (`hazard` | `announcement` | `broadcast`), non-nullable, writable (residents limited to `hazard`)
  - `category`: str choice (`broken_light` | `suspicious` | `road` | `flood` | `fire` | `road_closure` | `maintenance` | `other`), non-nullable, writable
  - `title`: str, non-nullable, writable
  - `description`: str, non-nullable, writable
  - `latitude`: number (decimal), nullable (`null=True`), writable
  - `longitude`: number (decimal), nullable (`null=True`), writable
  - `image`: str (URL / file path), nullable (`null=True`), writable (multipart)
  - `area`: int (FK to Area), nullable (`null=True`), writable
  - `affected_areas`: array of int (ManyToMany to Area PKs), non-nullable (empty allowed `[]`), writable (admin only)
  - `severity`: str choice (`info` | `warning` | `critical`), non-nullable, writable
  - `status`: str choice (`open` | `in_progress` | `resolved` | `rejected`), non-nullable, read-only
  - `is_verified`: bool, non-nullable, read-only (admin only)
  - `verified_at`: datetime (ISO 8601 UTC), nullable (`null=True`), read-only
  - `resolved_at`: datetime (ISO 8601 UTC), nullable (`null=True`), read-only
  - `expires_at`: datetime (ISO 8601 UTC), nullable (`null=True`), writable
  - `created_at`: datetime (ISO 8601 UTC), non-nullable, read-only
  *(Note: `author_role` does NOT exist as a direct field; author's role is provided inside the nested `author.role`).*
- **CommunityPost (`core.CommunityPost`, `CommunityPostSerializer`):**
  - `id`: int, non-nullable, read-only
  - `author_name`: str (computed from `author.username`), non-nullable, read-only
  - `author_area`: str (computed from `author.area.name`), non-nullable, read-only
  - `title`: str, non-nullable, writable
  - `content`: str, non-nullable, writable
  - `is_hidden`: bool, non-nullable, read-only
  - `created_at`: datetime (ISO 8601 UTC), non-nullable, read-only
- **Device (`core.Device`, `DeviceSerializer`):**
  - `id`: int, non-nullable, read-only
  - `fcm_token`: str, non-nullable, write-only (omitted from responses)
  - `platform`: str choice (`android` | `ios` | `web`), non-nullable, writable
  - `is_active`: bool, non-nullable, writable
  - `created_at`: datetime (ISO 8601 UTC), non-nullable, read-only
  - `last_seen`: datetime (ISO 8601 UTC), non-nullable, read-only