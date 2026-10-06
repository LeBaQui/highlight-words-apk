#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for the Android Text Highlight Bubble project
# Run: bash project_bundle.sh
# It creates the full project structure in the current directory.

mkdir -p app/src/main/java/com/lebacui/textbubble \
         app/src/main/res/xml \
         app/src/main/res/values \
         app/src/main/res/layout \
         app/src/main/res/drawable \
         .github/workflows

cat > settings.gradle.kts <<'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "TextBubbleHighlight"
include(":app")
EOF

cat > build.gradle.kts <<'EOF'
plugins {
    id("com.android.application") version "8.5.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}
EOF

cat > gradle.properties <<'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=true
kotlin.code.style=official
EOF

cat > app/build.gradle.kts <<'EOF'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.lebacui.textbubble"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.lebacui.textbubble"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isDebuggable = true
        }
    }

    buildFeatures {
        viewBinding = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")

    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
}
EOF

cat > app/proguard-rules.pro <<'EOF'
-dontwarn com.lebacui.textbubble.**
EOF

cat > app/src/main/AndroidManifest.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.TextBubbleHighlight">

        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <service
            android:name=".FloatingBubbleService"
            android:enabled="true"
            android:exported="false" />

        <service
            android:name=".AccessibilityTextCaptureService"
            android:enabled="true"
            android:exported="true"
            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService" />
            </intent-filter>
            <meta-data
                android:name="android.accessibilityservice"
                android:resource="@xml/accessibility_service_config" />
        </service>
    </application>

</manifest>
EOF

cat > app/src/main/res/xml/accessibility_service_config.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowStateChanged|typeWindowContentChanged|typeViewClicked"
    android:accessibilityFlags="flagReportViewIds|flagIncludeNotImportantViews"
    android:canRetrieveWindowContent="true"
    android:notificationTimeout="100"
    android:packageNames="*"
    android:canRequestFilterKeyEvents="false" />
EOF

cat > app/src/main/res/values/strings.xml <<'EOF'
<resources>
    <string name="app_name">Text Bubble Highlight</string>
    <string name="enable_accessibility">Enable Accessibility</string>
    <string name="enable_overlay">Enable Bubble Overlay</string>
    <string name="capture_text">Capture Text</string>
    <string name="bubble_hint">Tap bubble to scan and highlight</string>
    <string name="status_idle">Status: waiting</string>
</resources>
EOF

cat > app/src/main/res/values/colors.xml <<'EOF'
<resources>
    <color name="primary">#3B82F6</color>
    <color name="primary_dark">#1D4ED8</color>
    <color name="accent">#F59E0B</color>
    <color name="white">#FFFFFF</color>
    <color name="text_primary">#111827</color>
    <color name="bg_surface">#F3F4F6</color>
</resources>
EOF

cat > app/src/main/res/values/themes.xml <<'EOF'
<resources>
    <style name="Theme.TextBubbleHighlight" parent="Theme.Material3.DayNight.NoActionBar">
        <item name="colorPrimary">@color/primary</item>
        <item name="colorPrimaryVariant">@color/primary_dark</item>
        <item name="colorSecondary">@color/accent</item>
        <item name="android:statusBarColor">@android:color/transparent</item>
    </style>
</resources>
EOF

cat > app/src/main/res/layout/activity_main.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#F4F4F5"
    android:padding="24dp">

    <TextView
        android:id="@+id/titleText"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:text="Text Bubble Highlight"
        android:textColor="@color/text_primary"
        android:textSize="26sp"
        android:textStyle="bold"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent" />

    <Button
        android:id="@+id/enableAccessibilityButton"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginTop="24dp"
        android:text="@string/enable_accessibility"
        app:layout_constraintTop_toBottomOf="@id/titleText"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent" />

    <Button
        android:id="@+id/enableOverlayButton"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginTop="16dp"
        android:text="@string/enable_overlay"
        app:layout_constraintTop_toBottomOf="@id/enableAccessibilityButton"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent" />

    <Button
        android:id="@+id/captureTextButton"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginTop="16dp"
        android:text="@string/capture_text"
        app:layout_constraintTop_toBottomOf="@id/enableOverlayButton"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent" />

    <TextView
        android:id="@+id/statusText"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginTop="20dp"
        android:text="@string/status_idle"
        android:textColor="@color/text_primary"
        android:textSize="16sp"
        app:layout_constraintTop_toBottomOf="@id/captureTextButton"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent" />
</androidx.constraintlayout.widget.ConstraintLayout>
EOF

cat > app/src/main/res/layout/overlay_bubble.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:background="@drawable/bubble_background"
    android:gravity="center"
    android:orientation="vertical"
    android:padding="12dp">

    <TextView
        android:id="@+id/bubbleText"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:gravity="center"
        android:text="B"
        android:textColor="#FFFFFF"
        android:textSize="20sp"
        android:textStyle="bold" />
</LinearLayout>
EOF

cat > app/src/main/res/layout/overlay_highlight.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:background="@drawable/highlight_background"
    android:orientation="vertical"
    android:padding="14dp">

    <TextView
        android:id="@+id/highlightTextView"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:maxWidth="280dp"
        android:text="Tap bubble to scan text"
        android:textColor="#111827"
        android:textSize="15sp" />
</LinearLayout>
EOF

cat > app/src/main/res/drawable/bubble_background.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#3B82F6" />
    <corners android:radius="28dp" />
</shape>
EOF

cat > app/src/main/res/drawable/highlight_background.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#FFF7CC" />
    <stroke android:width="2dp" android:color="#F59E0B" />
    <corners android:radius="18dp" />
</shape>
EOF

cat > app/src/main/java/com/lebacui/textbubble/MainActivity.kt <<'EOF'
package com.lebacui.textbubble

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.lebacui.textbubble.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.enableAccessibilityButton.setOnClickListener {
            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
        }

        binding.enableOverlayButton.setOnClickListener {
            if (!Settings.canDrawOverlays(this)) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                startActivity(intent)
            } else {
                startService(Intent(this, FloatingBubbleService::class.java))
                Toast.makeText(this, "Bubble overlay started", Toast.LENGTH_SHORT).show()
            }
        }

        binding.captureTextButton.setOnClickListener {
            val text = TextCaptureStore.latestText.ifBlank { "No text captured yet." }
            binding.statusText.text = text.take(220)
            Toast.makeText(this, text.take(200), Toast.LENGTH_LONG).show()
        }

        binding.statusText.text = "Ready. Enable Accessibility and overlay to begin."
    }
}
EOF

cat > app/src/main/java/com/lebacui/textbubble/TextCaptureStore.kt <<'EOF'
package com.lebacui.textbubble

object TextCaptureStore {
    @Volatile
    var latestText: String = ""
}
EOF

cat > app/src/main/java/com/lebacui/textbubble/AccessibilityTextCaptureService.kt <<'EOF'
package com.lebacui.textbubble

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class AccessibilityTextCaptureService : AccessibilityService() {
    companion object {
        const val ACTION_TEXT_CAPTURED = "com.lebacui.textbubble.TEXT_CAPTURED"
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                AccessibilityEvent.TYPE_VIEW_CLICKED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        }
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val allowedTypes = setOf(
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
            AccessibilityEvent.TYPE_VIEW_CLICKED
        )

        if (event.eventType !in allowedTypes) return

        val root = rootInActiveWindow ?: return
        val text = collectText(root)
        if (text.isNotBlank()) {
            TextCaptureStore.latestText = text
            val intent = Intent(ACTION_TEXT_CAPTURED).apply {
                putExtra("text", text)
            }
            sendBroadcast(intent)
        }
    }

    private fun collectText(node: AccessibilityNodeInfo?): String {
        if (node == null) return ""

        val builder = StringBuilder()
        val text = node.text?.toString()?.trim()
        if (!text.isNullOrBlank()) {
            builder.append(text).append("\n")
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val childText = collectText(child)
            if (childText.isNotBlank()) {
                builder.append(childText)
                if (!childText.endsWith("\n")) builder.append("\n")
            }
        }

        return builder.toString().trim()
    }

    override fun onInterrupt() = Unit
}
EOF

cat > app/src/main/java/com/lebacui/textbubble/FloatingBubbleService.kt <<'EOF'
package com.lebacui.textbubble

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView

class FloatingBubbleService : android.app.Service() {
    private lateinit var windowManager: WindowManager
    private lateinit var bubbleView: View
    private var highlightView: View? = null
    private var highlightOn = false

    private val captureReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val text = intent?.getStringExtra("text") ?: ""
            if (text.isNotBlank()) {
                TextCaptureStore.latestText = text
                updateBubbleText(text)
                if (highlightOn) {
                    showHighlightOverlay(text)
                }
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        bubbleView = LayoutInflater.from(this).inflate(R.layout.overlay_bubble, null)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 40
            y = 180
        }

        bubbleView.setOnClickListener {
            toggleHighlightMode()
        }

        bubbleView.setOnLongClickListener {
            val text = TextCaptureStore.latestText.ifBlank { "No text captured yet" }
            showHighlightOverlay(text)
            true
        }

        val bubbleText = bubbleView.findViewById<TextView>(R.id.bubbleText)
        bubbleText.text = "B"

        windowManager.addView(bubbleView, params)

        registerReceiver(
            captureReceiver,
            IntentFilter(AccessibilityTextCaptureService.ACTION_TEXT_CAPTURED)
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(captureReceiver)
        } catch (_: IllegalArgumentException) {
        }
        if (bubbleView.isAttachedToWindow) {
            windowManager.removeView(bubbleView)
        }
        highlightView?.let { view ->
            if (view.isAttachedToWindow) {
                windowManager.removeView(view)
            }
        }
    }

    private fun toggleHighlightMode() {
        highlightOn = !highlightOn
        if (highlightOn) {
            val text = TextCaptureStore.latestText.ifBlank { "Tap bubble again to exit highlight mode" }
            showHighlightOverlay(text)
        } else {
            hideHighlightOverlay()
        }
        updateBubbleText(TextCaptureStore.latestText)
    }

    private fun showHighlightOverlay(text: String) {
        if (highlightView != null) {
            val tv = highlightView?.findViewById<TextView>(R.id.highlightTextView)
            tv?.text = text
            return
        }

        val view = LayoutInflater.from(this).inflate(R.layout.overlay_highlight, null)
        val textView = view.findViewById<TextView>(R.id.highlightTextView)
        textView.text = text

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER_HORIZONTAL or Gravity.BOTTOM
            y = 220
        }

        windowManager.addView(view, params)
        highlightView = view
    }

    private fun hideHighlightOverlay() {
        highlightView?.let { view ->
            if (view.isAttachedToWindow) {
                windowManager.removeView(view)
            }
            highlightView = null
        }
    }

    private fun updateBubbleText(text: String) {
        val bubbleText = bubbleView.findViewById<TextView>(R.id.bubbleText)
        bubbleText.text = if (highlightOn) "X" else "B"
        bubbleText.contentDescription = if (highlightOn) "Exit highlight mode" else "Enter highlight mode"
    }
}
EOF

cat > .github/workflows/android-build.yml <<'EOF'
name: Android APK Build

on:
  push:
    branches: [ main ]
  pull_request:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Set up Android SDK
        uses: android-actions/setup-android@v3

      - name: Generate Gradle wrapper if needed
        run: gradle wrapper --no-daemon

      - name: Build debug APK
        run: ./gradlew assembleDebug

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-debug-apk
          path: app/build/outputs/apk/debug/app-debug.apk
EOF

cat > README.md <<'EOF'
# Android Text Highlight Bubble

A simple Android prototype for:
- Floating bubble overlay
- Accessibility-based text extraction
- Highlight panel
- CI build of debug APK

## Steps
1. Open in Android Studio
2. Sync Gradle
3. Build APK
4. Grant:
   - Draw over other apps
   - Accessibility permission
5. Tap the bubble to toggle highlight mode

## Build
```bash
./gradlew assembleDebug
```

## Notes
This version uses Android Accessibility Service to collect text from the active app. It is suitable for reading text from the accessibility tree, not full-screen OCR from raw screenshots.
EOF

echo "Project scaffold created successfully."
echo "Run in Android Studio or: ./gradlew assembleDebug"
