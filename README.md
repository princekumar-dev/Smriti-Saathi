<div align="center">

# 🌿 Smriti Saathi

### _"Because every memory matters…"_

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-Express-339933?style=flat-square&logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248?style=flat-square&logo=mongodb&logoColor=white)](https://www.mongodb.com)
[![SIH](https://img.shields.io/badge/Built_for-Smart_India_Hackathon-e11d48?style=flat-square)](https://www.sih.gov.in/)

**An offline-first, voice-first AI companion for elderly wellbeing.**

Built for [Smart India Hackathon](https://www.sih.gov.in/) — a warm, calm, multilingual
companion that helps seniors (especially those living with memory loss / early dementia)
stay oriented, revisit cherished memories, keep their daily routine, and feel close to
family — **whether they are online or not.**

</div>

---

## Table of Contents

1. [What it is](#-what-it-is)
2. [Key features](#-key-features)
3. [Who uses it](#-who-uses-it-two-roles)
4. [Tech stack](#-tech-stack)
5. [Quick start](#-quick-start)
6. [Project structure](#-project-structure)
7. [How it works](#-how-it-works-short-version)
8. [Offline-first sync model](#-offline-first-sync-model)
9. [Backend API](#-backend-api)
10. [Security notes](#-security--privacy-notes)
11. [Full architecture](#-full-architecture)

---

## 🌱 What it is

Smriti Saathi ("Memory Companion") is a Flutter application paired with a Node/Express +
MongoDB backend. It is designed around three realities of caring for an elder with memory
difficulties:

- **Connectivity is unreliable.** The app must work *exactly the same* offline as online.
  Everything is written to an on-device database first and synced later — nothing is ever lost.
- **Reading is hard; speaking is natural.** The interface is voice-first, with large calm
  typography, neural text-to-speech, and speech recognition in the elder's own language.
- **Family is the anchor.** A caregiver sets things up and stays connected; the elder gets a
  simple, safe, encouraging experience.

## ✨ Key features

| Area | What it does |
|------|--------------|
| 🧠 **AI Saathi** | A gentle conversational companion. Answers, reassures, and reminisces. Runs **on-device** (local Qwen 2.5 model via `sherpa_onnx` / `LocalModelManager`) with a backend Ollama bridge and a rule-based engine as graceful fallbacks. Grounded by a **RAG** layer so it speaks about *this* elder's real family, routine, and memories — never hallucinated. |
| 📸 **Memories** | People / Places / Objects / Moments. Photos picked from the device gallery or camera and stored locally for offline viewing. Each memory can be narrated aloud, favorited, and turned into a gentle recall quiz. |
| 🎙️ **Voice-first** | Neural TTS narration + speech-to-text, calibrated for a calm senior pace, with per-language voice packs and a Romanized-English phonetic fallback when a native voice isn't installed. |
| 👪 **Family** | A directory of loved ones with relationship and photo, used both for reassurance and to ground the AI. |
| ⏰ **Routine & reminders** | Daily reminders (medication, meals, activities) that persist offline. |
| 🎮 **Cognitive activities** | Elder-friendly games (memory match, recall quizzes, etc.); scores/streaks are persisted and synced. |
| 🌍 **Multilingual** | 15+ Indian languages including Hindi, Bengali, Tamil, Telugu, Kannada, Malayalam, Marathi, Gujarati, Punjabi, Odia, and North-East Indian languages (**Assamese, Manipuri, Mizo, Nepali**) with culturally authentic kinship vocatives. |
| 📶 **Works offline** | Local Hive database is the source of truth. Reconnecting silently syncs to MongoDB — pushed only after a confirmed server write. |

## 👥 Who uses it (two roles)

The app forks at a **Role Selection** screen:

- **Caregiver** (family) → signs up / logs in, registers the senior, and manages their profile,
  memories, family, and reminders. Lands on the **Caretaker Dashboard**.
- **Patient / Senior** (elder) → enters a **pass key** the family gave them (no password to
  remember) and lands directly in the simple 5-tab companion shell.

## 🛠 Tech stack

**App (Flutter / Dart, SDK `>=3.4.0 <4.0.0`)**
- `hive_ce` / `hive_ce_flutter` — offline-first local database (records are plain maps)
- `connectivity_plus` — network state; `http` — backend sync
- `speech_to_text`, `flutter_tts`, `sherpa_onnx`, `audioplayers` — voice in/out & on-device neural TTS
- `image_picker`, `path_provider`, `permission_handler` — local media
- `shared_preferences` — auth profiles & preferences
- `google_fonts` + bundled Indic font families

**Backend (`server/`)**
- Node.js + Express + Mongoose → **MongoDB Atlas**
- Optional local **Ollama** bridge serving a tuned `smriti-saathi:1.5b` (Qwen 2.5) model

## 🚀 Quick start

### Prerequisites
- Flutter SDK (Dart `>=3.4.0`)
- Node.js 18+ (for the backend)
- An Android device/emulator (primary target; web/desktop also build)

### 1. Run the app
```bash
flutter pub get
flutter run
```

### 2. Run the backend (optional — the app works fully offline without it)
```bash
cd server
npm install
node server.js          # serves on http://localhost:5000
```

The app auto-detects the backend via a health ping. With no backend reachable, everything still
works locally and syncs whenever a server becomes available.

> **Note:** don't run `flutter run` / rebuilds in CI or shared environments without confirming how
> you want to test — voice, camera, and model download need a real device.

## 📁 Project structure

```
Smriti-Saathi/
├── lib/
│   ├── main.dart                     # Boot: init Hive, connectivity, sync; splash; role routing
│   ├── data/
│   │   ├── app_translations.dart     # 15+ language packs, fonts, kinship vocatives
│   │   ├── local/
│   │   │   ├── local_store.dart       # Hive handle: opens all boxes, raw read/write
│   │   │   └── sync_fields.dart       # Sync metadata (id/updatedAt/dirty/deleted) + helpers
│   │   ├── repositories/              # Single source screens read/write through
│   │   │   ├── synced_repository.dart # Base: local-first upsert/delete + best-effort push
│   │   │   ├── memory_repository.dart
│   │   │   ├── family_repository.dart
│   │   │   ├── reminder_repository.dart
│   │   │   ├── chat_repository.dart          # local-only (no server endpoint)
│   │   │   └── game_score_repository.dart
│   │   └── memory_graph/              # Local people/places/events graph (nodes + edges)
│   ├── services/
│   │   ├── connectivity_service.dart # One connectivity controller + health ping → triggers sync
│   │   ├── sync_service.dart         # Outbox engine: pull (LWW) then push (clear only on 2xx)
│   │   ├── api_service.dart          # HTTP client for the backend + incremental ?since= queries
│   │   ├── memory_service.dart       # Memory domain API (image pick/persist, recall quiz)
│   │   ├── rag_service.dart          # Builds grounded context from profile/family/routine/memories
│   │   ├── local_ai_service.dart     # ChatML prompt build + on-device/backend generation
│   │   ├── local_model_manager.dart  # Downloads/manages the on-device LLM
│   │   ├── saathi_ai_engine.dart     # Rule-based conversational fallback + recall flow
│   │   ├── voice_engine.dart         # Neural + system TTS, pacing, phonetic fallback
│   │   ├── speech_service.dart       # Speech-to-text
│   │   └── tts/                       # Neural TTS (io/web), voice model manager & registry
│   ├── state/
│   │   ├── app_settings.dart         # Language, text size, voice, offline mode (ChangeNotifier)
│   │   ├── auth_state.dart           # Roles (caretaker/patient), profiles, pass-key login
│   │   └── auth_session.dart         # Legacy session scope
│   ├── screens/
│   │   ├── auth/                      # role_selection, caretaker_auth, patient_login, registration
│   │   ├── caretaker/                 # caretaker dashboard
│   │   ├── games/                     # cognitive activities
│   │   ├── home_screen.dart  saathi_screen.dart  memories_screen.dart
│   │   ├── activities_screen.dart  family_screen.dart  routine_screen.dart
│   │   ├── onboarding_screen.dart  language_selection_screen.dart  settings_screen.dart
│   │   └── ...
│   ├── navigation/app_shell.dart     # 5-tab elder shell (Home · Saathi · Memories · Activities · Family)
│   ├── theme/                        # app_theme.dart (palette/type), app_motion.dart
│   └── widgets/                      # reusable UI (offline_badge, cards, fx, orbs, buttons)
├── server/
│   ├── server.js                     # Express + Mongoose API (+ Ollama AI bridge)
│   └── Modelfile.smriti-saathi-1.5b  # Ollama modelfile for the tuned Qwen 2.5 companion
├── assets/                           # images, audio, Indic fonts
├── android/ · ios/ · web/ · windows/ · linux/ · macos/
├── pubspec.yaml
├── readme.md
└── ARCHITECTURE.md                   # Deep dive: layers, data flow, sync algorithm
```

## 🧭 How it works (short version)

1. **Boot (`main.dart`)** — open the Hive store, start `ConnectivityService`, and kick a first
   `SyncService.syncAll()` if online. Show the branded splash, then route by state:
   no language → language picker; caretaker → dashboard; patient → app shell; otherwise onboarding.
2. **Screens never call the network directly.** They read/write **repositories**, which write to
   **Hive first** (stamped `dirty`) and then best-effort push when online.
3. **Connectivity is reconciled**, not assumed — a real backend health ping decides "online,"
   and an offline→online transition auto-triggers a full sync.
4. **AI Saathi** answers using on-device generation grounded by the **RAG** layer (the elder's own
   profile, family, routine, and memories), with backend and rule-based fallbacks — so it stays
   useful even with no model downloaded and no network.

## 🔄 Offline-first sync model

Every synced record is a plain map carrying sync metadata:

```jsonc
{ "...domainFields": "...",
  "id": "mem_1699...",     // client-assigned; the server upserts on this
  "patientId": "...",
  "updatedAt": 1699999999, // epoch ms — drives last-write-wins
  "dirty": true,           // has unpushed local changes
  "deleted": false }       // tombstone: replay DELETE then drop locally
```

- **Write** → Hive immediately (`dirty=true`), then a best-effort single push if online.
- **Reconnect / app start / debounce** → `syncAll()` = **pull** (incremental `?since=`, merged
  last-write-wins, never clobbering a locally-dirty record) **then push**.
- **Dirty is cleared / tombstones dropped _only after_ a confirmed HTTP 2xx** — a failed or
  interrupted push leaves the record pending and it retries later. **Nothing is ever lost.**
- Chat history and the memory graph are **local-only** (persisted but not pushed).

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full algorithm and edge cases.

## 🌐 Backend API

Base URL defaults to `http://localhost:5000`. All sync collections support incremental pulls
(`?since=<iso|ms>`) and soft-delete so tombstones propagate.

| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/api/health` | Reachability ping (used by connectivity reconcile) |
| POST | `/api/caretakers/signup` · `/login` | Caregiver auth |
| GET | `/api/caretakers` | List caregivers |
| POST/GET | `/api/patients` | Register / list seniors |
| POST | `/api/patients/validate-passkey` | Pass-key login for the elder |
| GET/POST/DELETE | `/api/memories` | Memories (soft-delete) |
| GET/POST/DELETE | `/api/family` | Family members (soft-delete) |
| GET/POST/PUT/DELETE | `/api/reminders` | Reminders (soft-delete) |
| GET/POST/DELETE | `/api/gamescores` | Game scores (soft-delete) |
| POST | `/api/ai/chat` | AI bridge → tuned `smriti-saathi:1.5b` (Ollama), with base-model & rule fallbacks |
| DELETE | `/api/cleanup/all` | Hard reset (all collections) |

## 🔐 Security & privacy notes

- **Privacy by design:** the app is fully usable with **no account beyond a family pass key** and
  **no network** — the elder's data lives on-device in Hive.
- ⚠️ **`server/server.js` currently contains a hard-coded MongoDB Atlas connection string.** This is a
  committed secret and should be rotated and moved to an environment variable (`MONGODB_URI` via
  `.env`) before any real deployment. Do not treat the current credentials as safe.
- The backend has **no authentication middleware** on its data routes yet — anyone who can reach the
  server can read/write. Add auth (and TLS) before exposing it publicly. `usesCleartextTraffic` is
  enabled on Android for local development.
- Passwords are currently stored/compared in plaintext on the backend — hash them (e.g. bcrypt)
  before production.

## 📖 Full architecture

For the complete deep dive — layer-by-layer responsibilities, the boot sequence, the AI/RAG
pipeline, the sync state machine, data shapes, and how the pieces fit together — see
**[ARCHITECTURE.md](ARCHITECTURE.md)**.

---

<div align="center">
Made with 🌿 for our elders. <em>Because every memory matters.</em>
</div>

