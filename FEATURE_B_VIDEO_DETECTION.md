# 📱 Feature B — Content-Aware Adaptive Scroll
## Video Playback Detection for Auto Clicker App

> **Project:** Auto Clicker (Flutter, Android + iOS)  
> **Owner:** Qaswar Sarfraz  
> **Feature Status:** Proposed — Ready for Implementation  
> **Companion Docs:** [`requirementsautoclicker.md`](./requirementsautoclicker.md) · [`PROJECT_COMPLETE.md`](./PROJECT_COMPLETE.md)

---

## 📋 Table of Contents

1. [Problem Statement](#-problem-statement)
2. [Roman Urdu Summary](#-roman-urdu-summary)
3. [Quick Comparison Table](#-quick-comparison-table)
4. [Solution 1 — Android Native (RECOMMENDED)](#-solution-1--android-native-os-detection-recommended)
5. [Solution 2 — On-Device AI (YOLOv5 / MoViNet TFLite)](#-solution-2--on-device-lightweight-ai-model)
6. [Solution 3 — Cloud Vision AI (Gemini API)](#-solution-3--cloud-vision-ai-api-gemini-25-flash)
7. [Why NOT SmolVLM2?](#-why-not-smolvlm2)
8. [Functional Requirements (FR-B)](#-functional-requirements-fr-b)
9. [Non-Functional Requirements (NFR-B)](#-non-functional-requirements-nfr-b)
10. [Build Order](#-recommended-build-order)
11. [Open Source References](#-open-source-references)

---

## 🔍 Problem Statement

User sets a scroll script with a **4–5 second interval**. While auto-scrolling through a social media feed (Instagram, TikTok, YouTube Shorts, Facebook Reels), a **video post appears**. The fixed-interval scroll doesn't know or care — it scrolls past the video before it finishes.

**Goal:** Detect that a video is currently **playing on-screen**, and **hold the next scroll** until the video ends (or a configurable maximum wait time is reached).

---

## 🗣️ Roman Urdu Summary

> **Masla (Problem):** Jab user Instagram/TikTok/YouTube par auto-scroll chala raha ho aur koi video aa jaye, to app us video ko ignore karke agle post par scroll kar deti hai. Feature B ka maqsad hai ke **jab bhi koi video play hoti ho, to agla scroll ruk jaye** — jab tak video khatam na ho ya configurable time limit (default 3 min) expire na ho.
>
> **3 solutions hain:**
> - **Solution 1 (BEST):** Android ka apna built-in system use karo — koi AI model nahi, koi API key nahi, bilkul free, phone par hi kaam karta hai.
> - **Solution 2:** Chhota sa AI model (2MB) phone ke andar hi rakho — internet nahi chahiye, API key nahi chahiye, free hai.
> - **Solution 3:** Google Gemini AI ko screenshot bhejo — API key chahiye, internet chahiye, buhut slow, generally recommended NAHI hai is app ke liye.

---

## 📊 Quick Comparison Table

| Detail | Solution 1 ✅ BEST | Solution 2 🟡 Alternate | Solution 3 ❌ Not Recommended |
|---|---|---|---|
| **Technology** | Android Native OS APIs | YOLOv5 Nano / MoViNet TFLite | Google Gemini 2.5 Flash API |
| **Type** | OS-Level Event Listener | On-Device AI (Open Source) | Cloud AI (API Call) |
| **API Key Needed?** | ❌ No | ❌ No | ✅ Yes |
| **Monthly Cost** | **$0 (Free)** | **$0 (Free)** | Free (1,500 req/day), then Paid |
| **Internet Required?** | ❌ No (100% Offline) | ❌ No (100% Offline) | ✅ Yes |
| **Speed / Latency** | **< 5 ms (Instant)** | **10 – 20 ms (Very Fast)** | **1,000 – 2,000 ms (Slow)** |
| **Battery Impact** | Negligible | Moderate | High (Continuous Network Calls) |
| **Accuracy** | High (YouTube, media apps) | Medium (screen UI detection) | High (AI Vision) |
| **App Architecture** | ✅ Matches offline-first design | ✅ Matches offline-first design | ❌ Breaks NFR-07 (no INTERNET perm) |
| **New Permission** | Notification Access | MediaProjection (screen capture) | INTERNET |
| **Hugging Face / GitHub** | N/A | `ultralytics/yolov5`, `google/movinet` | `gemini-2.5-flash` API |

---

## ✅ Solution 1 — Android Native OS Detection (RECOMMENDED)

### What It Is
Android already requires every well-behaved video app to publish a **`MediaSession`** with a `PlaybackState` (STATE_PLAYING, STATE_PAUSED, etc.) whenever it plays media. This is exactly what the lock screen, Bluetooth car displays, and Android Auto use. Our app reads this **without looking at a single pixel of the screen**.

As a **fallback**, the existing `AccessibilityService` can inspect the current window's node tree for known video player view class names.

### Roman Urdu Mein Asaan Wazahat
> Android OS mein ek built-in system hai — jab bhi koi app (YouTube, Instagram, TikTok) video chalata hai, Android OS ko bata deta hai ke "video chal rahi hai." Hamare app ko sirf is notification ko "sun'na" hai. Jab aisa notification mile, scroll rok do. Jab video band ho jaye, dobara scroll shuru kar do. **Koi AI nahi, koi internet nahi, koi cost nahi.**

### 📋 New Permission Required
```xml
<!-- AndroidManifest.xml -->
<service
    android:name=".service.MediaPlaybackListenerService"
    android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"
    android:exported="false">
    <intent-filter>
        <action android:name="android.service.notification.NotificationListenerService" />
    </intent-filter>
</service>
```

### 💻 Implementation — Kotlin Code
```kotlin
// service/MediaPlaybackListenerService.kt
class MediaPlaybackListenerService : NotificationListenerService() {

    private lateinit var mediaSessionManager: MediaSessionManager

    override fun onListenerConnected() {
        mediaSessionManager =
            getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
    }

    /**
     * Called by the automation engine BEFORE each scroll dispatch.
     * Returns true if ANY recognized app is currently playing video/audio.
     */
    fun isAnyMediaPlaying(): Boolean {
        val component = ComponentName(this, MediaPlaybackListenerService::class.java)
        val controllers = mediaSessionManager.getActiveSessions(component)
        return controllers.any {
            it.playbackState?.state == PlaybackState.STATE_PLAYING
        }
    }
}
```

### 💻 Accessibility Fallback — Kotlin Code
```kotlin
// Inspect accessibility node tree for video player elements
class VideoDetectionService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val rootNode = rootInActiveWindow ?: return
        try {
            if (isVideoNodePresent(rootNode)) {
                pauseAutoScroll()
            }
        } finally {
            rootNode.recycle()
        }
    }

    private fun isVideoNodePresent(root: AccessibilityNodeInfo): Boolean {
        val videoIndicators = listOf(
            "video_player", "player_view", "exoplayer",
            "progress_bar", "play_button", "pause_button"
        )
        return searchNodeTree(root, videoIndicators) != null
    }

    private fun searchNodeTree(
        node: AccessibilityNodeInfo,
        keywords: List<String>
    ): AccessibilityNodeInfo? {
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            try {
                val viewId = child.viewIdResourceName ?: ""
                val desc = child.contentDescription?.toString() ?: ""
                if (keywords.any { viewId.contains(it, ignoreCase = true) || desc.contains(it, ignoreCase = true) }) {
                    return child
                }
                val found = searchNodeTree(child, keywords)
                if (found != null) return found
            } finally {
                child.recycle()
            }
        }
        return null
    }

    override fun onInterrupt() {}
}
```

### 💰 Cost & API Key
| Item | Detail |
|---|---|
| API Key | **Not required** |
| Monthly Cost | **$0 (100% Free forever)** |
| Model Download | None (uses Android OS APIs) |
| Internet | Not required |

### ✅ Pros
- Zero cost, zero API key, zero internet
- Near-instant detection (< 5ms)
- Negligible battery impact (event callback, not a poll loop)
- Works reliably with YouTube, Spotify, podcast apps, and most media players
- Aligns perfectly with `NFR-07: zero internet permission`

### ⚠️ Limitations (Disclosed Honestly)
- Instagram Reels, TikTok, and Facebook in-feed videos are **inconsistent** — some versions publish a `MediaSession`, some autoplay muted without one.
- Settings UI must show: *"Works reliably with YouTube and most media apps. Support for Instagram/TikTok/Facebook in-feed video depends on app version and may not always be detected."*

---

## 🤖 Solution 2 — On-Device Lightweight AI Model

### What It Is
A small, pre-trained TensorFlow Lite model (**YOLOv5 Nano** or **MoViNet-A0**) is bundled inside the app (~2–3 MB). It analyzes screen frames captured every ~500ms to detect video player UI elements (play button, seek bar, progress bar) — **completely offline**, no API key, no internet.

### Roman Urdu Mein Asaan Wazahat
> Ek chhota sa AI model (sirf 2MB — ek song se bhi chota!) phone ke andar hi install hoga. Yeh har 500ms mein screen ki ek photo leta hai aur check karta hai ke koi video player dikh raha hai ya nahi. Sab kuch phone par hota hai — koi internet, koi API key, koi cost nahi.

### 📦 Model Options

| Model | Source | Size | RAM Usage | Latency | License |
|---|---|---|---|---|---|
| **YOLOv5 Nano TFLite** | `ultralytics/yolov5` on GitHub & HuggingFace | 2–3 MB | < 50 MB | 6–18 ms | Apache 2.0 |
| **MoViNet-A0 TFLite** | `google/movinet` on HuggingFace | ~3 MB | < 60 MB | < 20 ms | Apache 2.0 |
| YOLOv8 Nano TFLite | `ultralytics/ultralytics` | 4–5 MB | < 80 MB | 10–20 ms | AGPL-3.0 |

> **Hugging Face Links:**
> - YOLOv5: https://huggingface.co/qualcomm/Yolo-v5
> - MoViNet: https://huggingface.co/google/movinet
> - YOLOv5 GitHub: https://github.com/ultralytics/yolov5

### 💻 Implementation — Gradle Dependencies
```groovy
// build.gradle (app level)
dependencies {
    implementation 'org.tensorflow:tensorflow-lite:2.14.0'
    implementation 'org.tensorflow:tensorflow-lite-support:0.4.4'
    implementation 'org.tensorflow:tensorflow-lite-gpu:2.14.0' // Optional: GPU acceleration
}
```

### 💻 Implementation — Kotlin Detector Class
```kotlin
// detector/YoloVideoDetector.kt
class YoloVideoDetector(context: Context) {

    private val interpreter: Interpreter

    init {
        val model = loadModelFile(context, "yolo-v5-nano.tflite")
        val options = Interpreter.Options().apply {
            addDelegate(GpuDelegate()) // Use NPU/GPU for speed
        }
        interpreter = Interpreter(model, options)
    }

    /** Returns true if a video player UI element is detected on screen */
    fun isVideoPlayerOnScreen(bitmap: Bitmap): Boolean {
        val input = preprocess(bitmap) // Resize to 320x320
        val output = Array(1) { Array(1) { Array(25200) { FloatArray(85) } } }
        interpreter.run(input, output)
        return hasVideoPlayerDetection(output[0][0], confidenceThreshold = 0.5f)
    }

    private fun loadModelFile(context: Context, filename: String): ByteBuffer {
        val fd = context.assets.openFd(filename)
        return FileInputStream(fd.fileDescriptor).channel.map(
            FileChannel.MapMode.READ_ONLY, fd.startOffset, fd.declaredLength
        )
    }
}
```

### 💻 Screen Frame Capture (MediaProjection)
```kotlin
// Capture screen frame for YOLO analysis
val mediaProjection = mediaProjectionManager.createMediaProjection(resultCode, resultData)
val imageReader = ImageReader.newInstance(screenWidth, screenHeight, PixelFormat.RGBA_8888, 2)
val virtualDisplay = mediaProjection.createVirtualDisplay(
    "ScreenCapture", screenWidth, screenHeight, screenDensity,
    DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
    imageReader.surface, null, null
)
```

### 💰 Cost & API Key
| Item | Detail |
|---|---|
| API Key | **Not required** |
| Monthly Cost | **$0 (100% Free — Apache 2.0 Open Source)** |
| Model Size | ~2–3 MB (bundled in app APK) |
| Internet | Not required |
| Training | Free (Google Colab GPU for custom training) |

### ✅ Pros
- Zero cost, zero API key, zero internet
- Fast inference: 6–18 ms on mid-range phones
- Works for apps that don't publish MediaSession
- Model size is tiny (~2–3 MB)

### ⚠️ Limitations
- Requires `MediaProjection` permission — system shows recurring consent dialog
- Moderate CPU/battery cost (continuous frame capture)
- May false-positive on animated GIFs or moving ads
- Best used as **opt-in "Advanced Detection"** mode, not the default

---

## ☁️ Solution 3 — Cloud Vision AI API (Gemini 2.5 Flash)

> **⚠️ NOT RECOMMENDED for this app — included for completeness only.**

### What It Is
Periodically send a low-res screenshot to **Google Gemini 2.5 Flash API** and ask: *"Is a video currently playing on this screen? Answer YES or NO."*

### Roman Urdu Mein Asaan Wazahat
> Phone se screen ka screenshot liya jata hai aur Google ke AI server par internet ke zariye bheja jata hai. AI jawab deta hai "video chal rahi hai ya nahi." **Problem yeh hai ke is app ka pura design internet-free hai (NFR-07), aur network round-trip ki wajah se detection buhut slow (1-2 second) hoti hai. Isliye is solution ko AVOID karna chahiye.**

### 🔑 API Key Setup
1. **Google AI Studio** par jayein: https://aistudio.google.com/apikey
2. **"Create API Key"** click karein
3. Project create karein ya existing select karein
4. API Key copy karein aur secure store karein

### 💻 Implementation — HTTP API Call
```kotlin
// Gemini 2.5 Flash API request
val apiKey = "YOUR_GEMINI_API_KEY"
val endpoint =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey"

val requestBody = """
{
  "contents": [{
    "parts": [
      {
        "inline_data": {
          "mime_type": "image/jpeg",
          "data": "$base64Screenshot"
        }
      },
      {
        "text": "Look at this mobile screenshot. Is there a video, reel, or short currently playing? Reply with only YES or NO."
      }
    ]
  }]
}
"""
```

### 💰 Cost & API Key Details
| Item | Detail |
|---|---|
| API Key | **Required** (free from Google AI Studio) |
| Free Tier | ~**1,500 requests/day, 15 RPM** (Gemini 2.5 Flash) |
| Paid Tier | ~$0.075 per 1M tokens via Google Cloud Billing |
| Estimated Monthly Cost (Active Use) | **$20 – $100+ depending on usage** |
| Internet | **Required** |

> **⚠️ Important — Google AI Pro Subscription Warning:**  
> Buying a personal **Google AI Pro subscription ($19.99/mo)** does **NOT** increase your app's API quota.  
> Consumer AI Pro only increases usage of the Gemini web UI, AI Studio chat, and Antigravity.  
> App Developer API calls are billed separately via **Google Cloud Billing (pay-per-token)**. These are completely separate systems.

### ❌ Why This Is NOT Recommended
1. **Breaks `NFR-07`:** App's entire architecture is "zero declared INTERNET permission, 100% offline."
2. **Slow:** Network round-trip = 1,000–2,000ms vs. < 5ms for Solution 1.
3. **Privacy Concern:** App starts sending periodic screenshots off-device.
4. **Unnecessary:** Solutions 1 & 2 solve the same problem for free, offline, and faster.

---

## 🚫 Why NOT SmolVLM2 (HuggingFace)?

Research mentions **`HuggingFaceTB/SmolVLM2-256M-Video-Instruct`**. Here is why it is **not suitable** for this use case:

| Concern | Detail |
|---|---|
| **Wrong Task** | SmolVLM2 is designed for video **understanding** (captioning, Q&A) — NOT real-time playback state detection |
| **RAM** | Even the 256M variant requires **1.38 GB RAM** — crashes background services on most phones |
| **Latency** | Inference takes **2–5 seconds** per query — too slow for real-time scroll control |
| **Battery** | Continuous background running drains battery in **2–3 hours** |
| **Overkill** | We only need a YES/NO "is video playing" signal |

### When SmolVLM2 IS Useful (Different Use Cases)
- ✅ Generating video summaries or captions
- ✅ Answering questions about video content
- ✅ Long-form video analysis on server/cloud
- ✅ Batch processing (not real-time)

---

## 📋 Functional Requirements (FR-B)

| ID | Requirement |
|---|---|
| **FR-B1** | Settings exposes a **"Wait for video to finish before scrolling"** toggle, **off by default** |
| **FR-B2** | When enabled, requires **Notification Access** special permission — requested via dedicated permission screen |
| **FR-B3** | While detection indicates `STATE_PLAYING`, the engine **holds next scroll dispatch** |
| **FR-B4** | A **maximum wait cap** (default: 3 minutes, configurable) forces scroll even if playback state is stuck |
| **FR-B5** | If Notification Access is denied/revoked, feature **silently falls back to fixed-interval scrolling** |
| **FR-B6** | Detection mechanism limitations **disclosed in-app in plain language** at the toggle screen |
| **FR-B7** | Time spent "holding" for a video **counts toward Feature A's Session Fatigue Timer** elapsed time |

---

## 📋 Non-Functional Requirements (NFR-B)

| ID | Requirement |
|---|---|
| **NFR-B1** | **Zero new outbound network calls** — must not compromise the app's "zero INTERNET permission" posture |
| **NFR-B2** | Detection check latency must be **< 50ms** (local API read or lightweight node-tree walk only) |
| **NFR-B3** | Feature must **degrade gracefully** (FR-B5) rather than fail loudly |

---

## 🏗️ Recommended Build Order

```
Step 1 (Ship First)  → Feature A: Session Fatigue Timer
                        (Pure Dart, no new permission, fastest to ship)
                        ↓
Step 2               → Feature B, Solution 1: MediaSession Detection
                        (Free, on-device, covers YouTube + media apps)
                        ↓
Step 3               → Feature B, Accessibility Heuristic Fallback
                        (Catches Instagram/TikTok cases; reuses existing permission)
                        ↓
Step 4 (Optional)    → Feature B, Solution 2: YOLOv5 Nano TFLite
                        (Only if user feedback shows Solutions 1+2 miss too many cases)
                        Ship behind explicit "Advanced Detection" opt-in toggle
                        ↓
Step 5 (Avoid)       → Feature B, Solution 3: Cloud AI Vision
                        Do NOT build unless offline-first architecture is intentionally changed
```

---

## 📂 Open Source References

| Project | Description | Link |
|---|---|---|
| **Blokky** | Reels/Shorts blocker using Accessibility Service | https://github.com/Ronjar/Blokky |
| **Scrolless** | Multi-platform (Instagram, TikTok, YouTube) blocker | https://github.com/DuarteBarbosaDev/Scrolless |
| **Shorts Blocker** | YouTube Shorts auto-detect via Accessibility | https://github.com/atick-faisal/Shorts-Blocker |
| **YOLOv5 Android** | YOLOv5 TFLite Android implementation | https://github.com/vokhidovhusan/yolov5-android |
| **MobileNet-Yolo** | 3MB model for mobile deployment | https://github.com/dog-qiuqiu/MobileNet-Yolo |
| **ultralytics/yolov5** | Official YOLOv5 repo (Hugging Face) | https://huggingface.co/qualcomm/Yolo-v5 |
| **google/movinet** | MoViNet video classification (Hugging Face) | https://huggingface.co/google/movinet |

---

## 📝 Final Summary (TLDR)

| Priority | Solution | Cost | API Key | Verdict |
|---|---|---|---|---|
| 🥇 **Ship First** | Solution 1: Android Native MediaSession + Accessibility | **$0** | **None** | ✅ **Build Now** |
| 🥈 **Fallback** | Solution 2: YOLOv5 Nano TFLite (on-device AI) | **$0** | **None** | 🟡 **Opt-in Toggle** |
| 🥉 **Avoid** | Solution 3: Gemini 2.5 Flash Cloud API | $0–$100+/mo | **Required** | ❌ **Not Recommended** |

---

*Prepared for Qaswar Sarfraz — Auto Clicker (Flutter, Android + iOS)*  
*Cross-referenced against `requirementsautoclicker.md` NFR-07 (zero internet permission)*  
*Pricing figures current as of August 2026 — verify against live documentation before implementation.*
