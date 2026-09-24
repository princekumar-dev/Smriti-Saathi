# Smriti Saathi — Architecture

A complete map of how the app is built and how every part works together. Pairs with
[readme.md](readme.md) (overview & quick start).

---

## 1. Design principles

Three constraints drive every decision:

1. **Offline is the default, not the exception.** The device is the source of truth. The backend is
   a *replica* the app reconciles with when it can reach it. A senior in a low-connectivity area
   must get the identical experience online and off.
2. **Never lose a write.** Local writes are durable the instant they happen. Server state is only
   trusted to *clear* a pending write after it confirms the write landed (HTTP 2xx).
3. **Voice-first, calm, grounded.** Large type, gentle motion, spoken output, and an AI that only
   ever talks about *this* elder's real life (RAG-grounded), degrading gracefully to simpler engines
   rather than failing.

---

## 2. High-level layers

```
┌──────────────────────────────────────────────────────────────────────┐
│  UI  —  screens/ + widgets/ + navigation/app_shell.dart                │
│         (read/write ONLY through repositories & services)              │
├──────────────────────────────────────────────────────────────────────┤
│  State  —  state/ (AppSettings, AuthState, AuthSession)                │
│            InheritedNotifier scopes provide these down the tree        │
├──────────────────────────────────────────────────────────────────────┤
│  Domain services  —  services/                                         │
│    MemoryService · RagService · Local/Backend AI · VoiceEngine · STT   │
├──────────────────────────────────────────────────────────────────────┤
│  Repositories  —  data/repositories/  (local-first CRUD, one per box)  │
├───────────────┬──────────────────────────────────────────────────────┤
│ Sync engine   │  Connectivity                                          │
│ sync_service  │  connectivity_service  (network + health ping)         │
├───────────────┴──────────────────────────────────────────────────────┤
│  Local store  —  data/local (Hive boxes)   │   api_service (HTTP)      │
├─────────────────────────────────────────────┴──────────────────────────┤
│  Hive (on-device)                          │   Node/Express + MongoDB   │
└─────────────────────────────────────────────┴──────────────────────────┘
```

The golden rule: **UI → repository → Hive** always succeeds; **repository/sync → ApiService →
server** is best-effort and reconciled later.

## 3. Boot sequence (`lib/main.dart`)

```
main()
 ├─ WidgetsFlutterBinding.ensureInitialized()
 ├─ GoogleFonts.allowRuntimeFetching = true   # local bundled fonts first, network as fallback
 ├─ AppAssets.init()
 ├─ LocalStore().init()            # open every Hive box BEFORE first frame → instant offline reads
 ├─ ConnectivityService().init()   # OS network state + first backend health ping
 ├─ SyncService().syncAll()        # (unawaited) pull fresh + flush any pending writes
 ├─ LocalModelManager().init()     # prepare on-device LLM (download managed lazily)
 └─ runApp(SmirithiSaathiApp)
```

`SmirithiSaathiApp` wraps the tree in three scopes and picks the first screen reactively:

```
AppSettingsScope (AppSettings)
  └─ AuthScope (AuthState)
       └─ AuthSessionScope (AuthSession, legacy)
            └─ MaterialApp
                 home: _getInitialScreen()
```

`_getInitialScreen()` (rebuilds on auth/settings change, cross-faded by an `AnimatedSwitcher`):

| Condition | Screen |
|-----------|--------|
| auth not initialized **or** splash not done | `PremiumSplashScreen` (animated; skipped on web where index.html already shows one) |
| no language chosen | `LanguageSelectionScreen` |
| `auth.isCaretaker` | `CaretakerDashboardScreen` |
| `auth.isPatient` | `AppShell` (the 5-tab elder companion) |
| otherwise | `OnboardingScreen` |

`MediaQuery.textScaler` is driven by `AppSettings.textScale` (1.12 when large text is on), so the
whole UI scales for readability.

## 4. State layer (`lib/state/`)

All three are `ChangeNotifier`s exposed via `InheritedNotifier` scopes (`*.of(context)`).

- **`AppSettings`** — language, large-text, voice responses on/off, **offline mode**, notifications,
  voice rate/pitch/persona. Persisted in `shared_preferences`. Exposes `textScale` and `ttsLocale`
  (resolved through `AppTranslations.getLanguageInfo`). *Language lookups must normalize through
  `AppTranslations.getLanguageInfo` — the language id is the native name, not an ISO code.*
- **`AuthState`** — the role machine: `unauthenticated / caretaker / patient`. Holds
  `CaretakerProfile` and `PatientProfile`, the registered-patients list, and the pass-key login.
  Follows a **"local first, backend when available"** precedent: e.g. `loginCaretaker` tries the
  backend and falls back to locally-stored profiles, so auth works offline too.
- **`AuthSession`** — a legacy session scope kept for compatibility.

### Two-role flow

```
RoleSelectionScreen
 ├─ Caregiver  → CaretakerAuthScreen (login / sign up only)
 │                 └─ PatientRegistrationScreen → CaretakerDashboardScreen
 └─ Patient    → PatientLoginScreen (pass-key entry only) → AppShell
```

The caretaker and patient auth screens are deliberately **split** — the caregiver never sees a
pass-key box, and the elder never sees a password form.

## 5. Local store (`lib/data/local/`)

**`local_store.dart` — `LocalStore` singleton.** Opens Hive and every box in `init()`:

- **Synced boxes:** `memories`, `family`, `reminders`, `game_scores`
- **Local-only boxes:** `chat_history`, `graph_nodes`, `graph_edges`
- **Bookkeeping:** `sync_meta` (stores `lastPulled_<collection>` cursors for `?since=`)

Records are plain `Map<String, dynamic>` keyed by their client-assigned string `id` — **no
TypeAdapters / build_runner**, matching the app's existing Map/JSON handling. `LocalStore` exposes
raw `readAll / read / put / remove` and the pull-cursor helpers.

**`sync_fields.dart` — the sync contract.** Defines the metadata keys and helpers every record uses:

| Key | Meaning |
|-----|---------|
| `id` | client-assigned; same id the server upserts on |
| `patientId` | owning senior |
| `updatedAt` | epoch **ms**; drives last-write-wins |
| `dirty` | has unpushed local changes |
| `deleted` | tombstone — replay DELETE to server, then drop locally |

Helpers: `markDirty`, `markDeleted`, `stampUpdatedAt`, `clearDirty`, `isPending`, `isTombstone`,
`normalizeRemote` (coerces server timestamps — int/num/ISO/Mongo `$date` — to ms and sets
`dirty=false`), and the `SyncStatus` enum (`synced / syncing / pending / error / offline`).

## 6. Repositories (`lib/data/repositories/`)

The **only** thing screens use to read/write domain data. `SyncedRepository` is the shared base over
one Hive box:

- `getAll({patientId})` → live (non-tombstone) records, newest-first by `updatedAt`. Instant, offline.
- `getById(id)` → one record (null if missing/tombstoned).
- `upsert(record)` → write Hive stamped `dirty=true, updatedAt=now`; `notifyListeners()`; if
  `synced`, fire-and-forget `SyncService.pushOne`.
- `delete(id)` → write a tombstone (`markDeleted`) and push; dropped locally once the DELETE confirms.
- `refreshFromRemote()` → `SyncService.syncAll()` then notify.

A repository constructed with `synced: false` (chat history) persists locally but never marks dirty
or pushes. Concrete repos: `MemoryRepository`, `FamilyRepository`, `ReminderRepository`,
`GameScoreRepository`, `ChatRepository` (local-only).

## 7. Connectivity (`lib/services/connectivity_service.dart`)

A single `ChangeNotifier` wrapping `connectivity_plus` **once** (replacing old per-widget
subscriptions). `isOnline` is the AND of three signals:

```
isOnline = hasNetwork (OS reports an interface up)
         AND serverReachable (a real /api/health ping succeeded)
         AND NOT forcedOffline (user's "work offline" override)
```

This distinction matters: a device can be on Wi-Fi but behind a captive portal, or have a working
server on an otherwise "offline" link. A **30-second health timer** re-probes so the app recovers
from server-side outages even when the OS signal never changes. On any **offline→online transition**
it calls `SyncService().syncAll()`. `hasNetworkButNoServer` lets the UI show nuanced messaging, and
`setForcedOffline` wires to a settings toggle.

## 8. Sync engine (`lib/services/sync_service.dart`)

The outbox engine — a singleton `ChangeNotifier` exposing `status` and `pendingCount`. Each synced
box is bound to its remote CRUD via a `_CollectionBinding { box, fetch(since), save, remoteDelete }`.

**`pullFresh()`** — for each collection:
1. Read the `lastPulled` cursor → build `?since=` (ISO).
2. Fetch remote; `normalizeRemote` each record.
3. **Skip any local record that is `dirty`** (never clobber unpushed work).
4. **Last-write-wins:** overwrite only if `incoming.updatedAt >= local.updatedAt`.
5. If the incoming record is a server soft-delete (`deleted:true`) → remove locally.
6. Advance the `lastPulled` cursor to the max `updatedAt` seen.

**`pushPending()`** — for each dirty record:
- Tombstone → `remoteDelete(id)`; on success `remove()` it locally.
- Otherwise → `save(record)`; on success, **re-read** and clear `dirty` **only if `updatedAt` still
  matches** what was pushed (guards against a newer local edit that raced in mid-push).
- **A failed push changes nothing locally** — the record stays pending and retries next trigger.

**`syncAll()`** = health-check → `pullFresh()` → `pushPending()` → recompute `pendingCount`/`status`.
No-ops if already syncing or offline.

**Triggers:** app start (if online) · reconnect (ConnectivityService) · `pushOne` right after a
local write · `requestSyncDebounced()` (2 s) after a burst · manual retry.

`_stripSyncMeta` removes the purely-local `dirty` flag before sending to the server (the server keeps
its own `updatedAt`/`deleted`).

## 9. The AI Saathi pipeline

The conversational companion is built to **always answer**, degrading through tiers so it works with
no model and no network. Grounding comes first, generation second.

### 9.1 RAG grounding (`rag_service.dart`)

`RagService.retrieveContext({query, profile, language})` assembles a compact, factual context block
from the elder's real data — **all read from local repositories, so RAG is fully offline**:

- **Patient profile** — name, nickname/vocative, age/gender, health/memory condition, primary
  caretaker, personal likes/notes.
- **Culturally authentic kinship vocatives** per language/region — e.g. Assamese *Aita/Koka*,
  Manipuri *Ebe/Epu*, Mizo *Ka pi/Ka pu*, Nepali *Bajai/Baje* — so the companion addresses the elder
  the way their family would.
- **Family directory, routine/reminders, and memories** relevant to the query.

This context grounds the model so it speaks about *this* person with **zero hallucination**.

### 9.2 Generation tiers

```
User speaks/types in Saathi screen
        │
        ▼
RagService.retrieveContext()  ──►  grounded context string
        │
        ▼
LocalAiService.buildChatMLPrompt()   # ChatML, tuned for Qwen 2.5, warm 1–2 sentence replies
        │
  ┌─────┴───────────────────────────────────────────────────────┐
  ▼                                                               ▼
[Tier 1] On-device model                          [Tier 2] Backend AI bridge
  LocalModelManager + sherpa_onnx                    POST /api/ai/chat →
  (Qwen 2.5 1.5B, downloaded on demand)              Ollama smriti-saathi:1.5b
                                                     → base qwen2.5:1.5b
        │                                                    │
        └──────────────────────┬─────────────────────────────┘
                               ▼
              [Tier 3] SaathiAiEngine (rule-based)
   Deterministic, offline: greetings, memory-recall quiz flow,
   arithmetic, reassurance — guarantees a gentle reply always.
```

- **`local_model_manager.dart`** downloads and manages the on-device LLM (variants with size
  formatting, download status).
- **`local_ai_service.dart`** builds the ChatML prompt (or delegates to `RagService.buildRagPrompt`
  when context exists) and runs generation.
- **`saathi_ai_engine.dart`** is the always-available fallback and also owns the **memory-recall
  flow**: it can set an `activeRecallMemory`, then evaluate the elder's next answer via
  `MemoryService.evaluateAnswer` and respond encouragingly whether right or "sweet try."
- The **backend `/api/ai/chat`** (server.js) tries the tuned Ollama model, falls back to base
  `qwen2.5:1.5b`, then to server-side rule handling (e.g. arithmetic) — mirroring the client tiers.

### 9.3 Voice (`voice_engine.dart`, `speech_service.dart`, `tts/`)

- **`VoiceEngine`** — output. Chooses the best available voice and reports `VoiceQuality`
  (`natural` neural → `basicNative` → `phoneticFallback` Romanized Indian-English → `unavailable`),
  so the UI can nudge installing a better offline voice pack. Calm senior pacing (rate ≈ 0.92),
  warm pitch, text sanitization, persona (female "Warm Companion" / male "Gentle Companion").
- **Neural TTS** — `tts/neural_tts_service.dart` (+ `_io` / `_web` implementations) via `sherpa_onnx`,
  with `voice_model_manager.dart` / `voice_model_registry.dart` managing downloadable voice packs.
- **`speech_service.dart`** — speech-to-text for spoken answers and commands.

## 10. Memories domain (`memory_service.dart` + `memories_screen.dart`)

- Categories: **People / Places / Objects / Moments**.
- Images picked from **gallery or camera** (`image_picker`), copied into the app documents dir
  (`memory_media/` via `path_provider`) so they render offline (`Image.file`), with network/asset
  fallbacks. Android permissions: `CAMERA`, `READ_MEDIA_IMAGES/VIDEO`, legacy `READ_EXTERNAL_STORAGE`.
- Each memory supports **narration** (VoiceEngine, with an estimated progress bar), **favorite**, and
  a **recall quiz** (`evaluateAnswer` + `recallQuestion`/`recallAnswer`) wired into both the memories
  screen and the AI recall flow.
- A local **memory graph** (`data/memory_graph/`: nodes = people/places/events, edges =
  relationships) is persisted in local-only Hive boxes for richer future recall.

## 11. Backend (`server/`)

Node + Express + Mongoose against **MongoDB Atlas** (`Smrithi_Saathi`). Five domain models plus game
scores, each carrying `updatedAt` and `deleted` for sync.

**Sync-aware conventions:**
- `buildSyncFilter(req)` — filters by `patientId`; when `?since=` is present returns only records
  with `updatedAt > since` **and includes tombstones** (so deletes reach clients), otherwise hides
  `deleted` docs. `stampUpdate(data)` sets `updatedAt=now` on every write.
- Upserts use `findOneAndUpdate({id}, …, {upsert:true})` keyed on the client string `id`.
- DELETEs are **soft** (`deleted:true, updatedAt:now`) so tombstones propagate; `/api/cleanup/all`
  is the only hard delete.

Routes (base `http://localhost:5000`): see the table in [readme.md](readme.md#-backend-api).
`/api/ai/chat` is the AI bridge described in §9.2.

## 12. Data flow examples

**Create a memory, offline → later online**
```
User adds memory (photo from gallery)
 → MemoryService copies image to memory_media/
 → MemoryRepository.upsert(record)
     → Hive.put (dirty=true, updatedAt=now)     ✅ durable, visible instantly
     → notifyListeners → UI updates
     → SyncService.pushOne → offline, no-op
...device reconnects...
 → ConnectivityService detects offline→online
     → SyncService.syncAll → pullFresh (LWW) → pushPending
         → POST /api/memories succeeds (2xx)
         → re-read, updatedAt unchanged → clearDirty     ✅ pending cleared
```

**Delete a family member**
```
FamilyRepository.delete(id)
 → Hive.put(markDeleted) (deleted=true, dirty=true)   # tombstone
 → getAll() now hides it
 → push: DELETE /api/family/:id (soft-delete on server)
     → on 2xx: Hive.remove(id)                          # tombstone dropped
 → other devices pull ?since= → see deleted:true → drop locally
```

## 13. Theming & UX (`lib/theme/`, `lib/widgets/`)

- **`app_theme.dart`** — the calming forest/cream palette (`forest`, `deepForest`, `sage`, `coral`,
  `warmAmber`, `cream`), radii, shadows, gradients, and button/input text styles.
- **`app_motion.dart`** — shared staggered entrance timing (`AppMotion.staggerDelay`).
- **Fonts** — Comfortaa/Plus Jakarta/DM Sans/Playfair/Caveat/Outfit/Nunito plus a full set of Noto
  Indic families (Tamil, Telugu, Kannada, Malayalam, Gujarati, Gurmukhi, Oriya, Bengali/Hind…) so
  every supported language renders natively.
- **Widgets** — `offline_badge` (sync/connectivity indicator), memory/family cards, `breathing_orb`,
  `voice_waveform`, `fade_slide_in`, animated buttons, headers.

## 14. Verification & conventions

- `flutter analyze` should be clean on touched files (project uses `flutter_lints`).
- Server syntax: `node --check server/server.js`; sync routes exercised with `curl` (`?since=`,
  soft-delete).
- Manual E2E for offline behavior: airplane mode → create/edit/play/chat → restore connection →
  confirm pushed to Mongo and `dirty` cleared; kill mid-push → confirm nothing cleared and it retries.
- Conflict strategy is **last-write-wins by `updatedAt`** (sufficient for single-elder data) — not a
  full CRDT.

---

_Keep this document in sync with the code. If you add a synced collection, wire it in `LocalStore`
boxes, a `SyncedRepository`, a `SyncService._CollectionBinding`, and the server (schema +
`buildSyncFilter`/`stampUpdate` + soft-delete)._


