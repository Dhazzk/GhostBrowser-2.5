#!/usr/bin/env bash
# ==============================================================================
# DH BROWSER (Android TV) - Full Project Scaffolding Script
# ==============================================================================
# Este script crea un repositorio Android listo para compilar con GitHub Actions.
# Genera:
#  - Estructura completa de proyecto Android (Gradle wrapper, manifests, Leanback TV)
#  - Paleta de diseño exacta "Ghost Glass" (#100c16, púrpura #9d4edd, #c77dff)
#  - Icono SVG del fantasma morado sonriente con colmillos y ojos brillantes
#  - Interfaz web local completa con DH Shield, reproductor y explorador
#  - Automatización GitHub Actions (.github/workflows/build-apk.yml)
# ==============================================================================

set -e

echo "👻 Generando estructura completa para DH Browser (Android TV)..."

# 1. Crear directorios
mkdir -p .github/workflows
mkdir -p app/src/main/java/com/dhbrowser/tv
mkdir -p app/src/main/res/drawable
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/xml
mkdir -p app/src/main/assets/www

cat << 'EOF' > .gitignore
.gradle/
build/
local.properties
.idea/
*.iml
EOF

# 2. GitHub Actions Workflow (.github/workflows/build-apk.yml)
cat << 'EOF' > .github/workflows/build-apk.yml
name: Build DH Browser Android TV APK

on:
  push:
    branches: [ "main", "master" ]
  pull_request:
    branches: [ "main", "master" ]
  workflow_dispatch:

jobs:
  build:
    name: Build Android TV Release & Debug APK
    runs-on: ubuntu-24.04

    steps:
      - name: 📥 Checkout repository
        uses: actions/checkout@v4

      - name: ☕ Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'
          cache: 'gradle'

      - name: 📱 Accept Android SDK licenses
        run: |
          mkdir -p "$ANDROID_HOME/licenses"
          printf '\n24333f8a63b6825ea9c5514f83c2829b004d1fee\n' > "$ANDROID_HOME/licenses/android-sdk-license"

      - name: 🐘 Set up Gradle
        uses: gradle/actions/setup-gradle@v4
        with:
          gradle-version: '8.5'

      - name: 🛠️ Build APK with Gradle
        run: gradle assembleDebug --console=plain --stacktrace

      - name: 📦 Upload APK as Artifact
        uses: actions/upload-artifact@v4
        with:
          name: DH-Browser-AndroidTV-APK
          path: app/build/outputs/apk/debug/*.apk
          retention-days: 14
EOF

# 3. Raíz: settings.gradle y build.gradle
cat << 'EOF' > settings.gradle
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
rootProject.name = "DH Browser TV"
include ':app'
EOF

cat << 'EOF' > build.gradle
plugins {
    id 'com.android.application' version '8.2.2' apply false
}
EOF

cat << 'EOF' > gradle.properties
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=true
EOF

# 4. App Gradle (app/build.gradle)
cat << 'EOF' > app/build.gradle
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.dhbrowser.tv'
    compileSdk 34

    defaultConfig {
        applicationId "com.dhbrowser.tv"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0.0"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    implementation 'androidx.webkit:webkit:1.10.0'
}
EOF

# 5. AndroidManifest.xml (Configurado para Android TV Leanback y navegación D-Pad)
cat << 'EOF' > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Requerimientos Android TV -->
    <uses-feature android:name="android.software.leanback" android:required="true" />
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
    
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />

    <application
        android:allowBackup="true"
        android:icon="@drawable/ic_dh_ghost"
        android:banner="@drawable/tv_banner"
        android:label="@string/app_name"
        android:theme="@style/Theme.DHBrowserTV"
        android:hardwareAccelerated="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:configChanges="keyboard|keyboardHidden|navigation|orientation|screenLayout|screenSize|smallestScreenSize"
            android:screenOrientation="landscape">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# 6. MainActivity.java (WebView optimizada para TV + Interceptor de Popups DH Shield)
cat << 'EOF' > app/src/main/java/com/dhbrowser/tv/MainActivity.java
package com.dhbrowser.tv;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.net.Uri;
import android.os.Bundle;
import android.os.SystemClock;
import android.text.InputType;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.InputDevice;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.Toast;
import androidx.webkit.WebViewAssetLoader;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayInputStream;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.Locale;

public class MainActivity extends Activity {

    private static final String HOME_URL = "https://appassets.androidplatform.net/assets/www/index.html";

    private static final String PREFS = "dhbrowser_prefs";
    private static final String KEY_FAVORITES = "favorites";
    private static final String KEY_ENGINE = "engine";
    private static final String ENGINE_GOOGLE = "google";
    private static final String ENGINE_DDG = "duckduckgo";

    private static final String[] BLOCKED_HOSTS = {
        "doubleclick.net", "googlesyndication.com", "adservice.google.com",
        "popads.net", "adsterra.com", "propellerads.com"
    };

    private SharedPreferences prefs;
    private WebView webView;
    private WebViewAssetLoader assetLoader;
    private FrameLayout root;
    private CursorView cursorView;

    // Barra de herramientas
    private ImageButton btnBack;
    private ImageButton btnForward;
    private ImageButton btnRefresh;
    private ImageButton btnHome;
    private ImageButton btnStar;
    private EditText addressBar;

    // Estado del cursor virtual
    private boolean cursorMode = true;
    private float cursorX = 0f;
    private float cursorY = 0f;
    private float density = 1f;
    private long downTime = 0L;
    private boolean pressed = false;

    @Override
    @SuppressLint("SetJavaScriptEnabled")
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        density = getResources().getDisplayMetrics().density;

        webView = new WebView(this);
        cursorView = new CursorView(this, density);

        // Barra superior (atrás, adelante, actualizar, inicio, dirección, favorito)
        LinearLayout toolbar = buildToolbar();
        View divider = new View(this);
        divider.setBackgroundColor(0x409D4EDD);

        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.addView(toolbar, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(60)));
        content.addView(divider, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, Math.max(1, dp(1))));
        content.addView(webView, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        root = new FrameLayout(this);
        root.addView(content, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        root.addView(cursorView, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        setContentView(root);

        // Centra el cursor cuando ya se conoce el tamaño de la pantalla
        root.post(new Runnable() {
            @Override
            public void run() {
                cursorX = root.getWidth() / 2f;
                cursorY = root.getHeight() / 2f;
                cursorView.setPos(cursorX, cursorY);
            }
        });

        // Assets seguros
        assetLoader = new WebViewAssetLoader.Builder()
                .addPathHandler("/assets/", new WebViewAssetLoader.AssetsPathHandler(this))
                .build();

        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setMediaPlaybackRequiresUserGesture(false);
        settings.setSupportMultipleWindows(false); // DH Shield: Bloquea window.open / pop-ups
        settings.setJavaScriptCanOpenWindowsAutomatically(false); // DH Shield anti pop-under
        settings.setLoadWithOverviewMode(true);
        settings.setUseWideViewPort(true);

        webView.setFocusable(true);
        webView.setFocusableInTouchMode(true);

        webView.setWebChromeClient(new WebChromeClient());
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
                String host = request.getUrl().getHost();
                if (host != null) {
                    host = host.toLowerCase();
                    for (String bad : BLOCKED_HOSTS) {
                        if (host.equals(bad) || host.endsWith("." + bad)) {
                            return new WebResourceResponse("text/plain", "UTF-8",
                                new ByteArrayInputStream(new byte[0]));
                        }
                    }
                }

                return assetLoader.shouldInterceptRequest(request.getUrl());
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                Uri uri = request.getUrl();
                if ("dhbrowser".equals(uri.getScheme())) {
                    // Acciones internas: solo se aceptan desde la pantalla de inicio
                    if (isHome(view.getUrl())) {
                        handleHomeAction(uri);
                    }
                    return true;
                }
                return false;
            }

            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                super.onPageStarted(view, url, favicon);
                updateNavState(url);
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                if (isHome(url)) {
                    pushStateToHome();
                }
                updateNavState(url);
            }

            @Override
            public void doUpdateVisitedHistory(WebView view, String url, boolean isReload) {
                super.doUpdateVisitedHistory(view, url, isReload);
                updateNavState(url);
            }
        });

        updateNavState(HOME_URL);

        // Carga la interfaz visual completa de DH Browser
        webView.loadUrl(HOME_URL);
        webView.requestFocus();
    }

    // ------------------------------------------------------------------
    // Barra de herramientas (estilo cristal)
    // ------------------------------------------------------------------
    private LinearLayout buildToolbar() {
        LinearLayout bar = new LinearLayout(this);
        bar.setOrientation(LinearLayout.HORIZONTAL);
        bar.setGravity(Gravity.CENTER_VERTICAL);
        bar.setBackgroundColor(0xE6100C16);
        bar.setPadding(dp(12), dp(8), dp(12), dp(8));

        btnBack = makeIconButton(R.drawable.ic_nav_back, "Atrás");
        btnForward = makeIconButton(R.drawable.ic_nav_forward, "Adelante");
        btnRefresh = makeIconButton(R.drawable.ic_nav_refresh, "Actualizar");
        btnHome = makeIconButton(R.drawable.ic_nav_home, "Inicio");
        btnStar = makeIconButton(R.drawable.ic_nav_star, "Añadir a favoritos");

        addressBar = new EditText(this);
        addressBar.setSingleLine(true);
        addressBar.setTextColor(0xFFFFFFFF);
        addressBar.setHintTextColor(0xFFB0A8BA);
        addressBar.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
        addressBar.setBackgroundResource(R.drawable.bg_glass_bar);
        addressBar.setPadding(dp(16), 0, dp(16), 0);
        addressBar.setGravity(Gravity.CENTER_VERTICAL);
        addressBar.setCompoundDrawablesRelativeWithIntrinsicBounds(R.drawable.ic_nav_search, 0, 0, 0);
        addressBar.setCompoundDrawablePadding(dp(10));
        addressBar.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_URI);
        addressBar.setImeOptions(EditorInfo.IME_ACTION_GO | EditorInfo.IME_FLAG_NO_EXTRACT_UI);
        addressBar.setSelectAllOnFocus(true);
        addressBar.setOnEditorActionListener((v, actionId, ev) -> {
            boolean enterKey = ev != null
                    && ev.getKeyCode() == KeyEvent.KEYCODE_ENTER
                    && ev.getAction() == KeyEvent.ACTION_DOWN;
            if (actionId == EditorInfo.IME_ACTION_GO || enterKey) {
                submitAddress();
                return true;
            }
            return false;
        });
        LinearLayout.LayoutParams addressParams = new LinearLayout.LayoutParams(0, dp(44), 1f);
        addressParams.setMargins(dp(8), 0, dp(8), 0);
        addressBar.setLayoutParams(addressParams);

        bar.addView(btnBack);
        bar.addView(btnForward);
        bar.addView(btnRefresh);
        bar.addView(btnHome);
        bar.addView(addressBar);
        bar.addView(btnStar);

        btnBack.setOnClickListener(v -> {
            if (webView.canGoBack()) webView.goBack();
        });
        btnForward.setOnClickListener(v -> {
            if (webView.canGoForward()) webView.goForward();
        });
        btnRefresh.setOnClickListener(v -> webView.reload());
        btnHome.setOnClickListener(v -> webView.loadUrl(HOME_URL));
        btnStar.setOnClickListener(v -> toggleFavorite());

        return bar;
    }

    private ImageButton makeIconButton(int iconRes, String description) {
        ImageButton b = new ImageButton(this);
        b.setImageResource(iconRes);
        b.setBackgroundResource(R.drawable.bg_glass_button);
        b.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
        b.setPadding(dp(10), dp(10), dp(10), dp(10));
        b.setContentDescription(description);
        b.setFocusable(true);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(dp(44), dp(44));
        lp.setMargins(dp(4), 0, dp(4), 0);
        b.setLayoutParams(lp);
        return b;
    }

    private void setLook(View v, boolean active) {
        v.setAlpha(active ? 1f : 0.35f);
    }

    private void updateNavState(String url) {
        if (btnBack == null) return;
        boolean home = url == null || isHome(url);

        setLook(btnBack, webView.canGoBack());
        setLook(btnForward, webView.canGoForward());
        setLook(btnStar, !home);

        boolean fav = !home && indexOfFavorite(loadFavorites(), url) >= 0;
        btnStar.setImageResource(fav ? R.drawable.ic_nav_star_filled : R.drawable.ic_nav_star);
        btnStar.setContentDescription(fav ? "Quitar de favoritos" : "Añadir a favoritos");

        addressBar.setHint("Buscar en " + (ENGINE_DDG.equals(getEngine()) ? "DuckDuckGo" : "Google")
                + " o escribir una URL");
        if (!addressBar.hasFocus()) {
            addressBar.setText(home ? "" : url);
        }
    }

    private void submitAddress() {
        String target = resolveInput(addressBar.getText().toString());
        InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
        if (imm != null) {
            imm.hideSoftInputFromWindow(addressBar.getWindowToken(), 0);
        }
        addressBar.clearFocus();
        webView.requestFocus();
        if (target != null) {
            webView.loadUrl(target);
        }
    }

    // ------------------------------------------------------------------
    // Búsqueda y motores
    // ------------------------------------------------------------------
    private String getEngine() {
        return prefs.getString(KEY_ENGINE, ENGINE_GOOGLE);
    }

    private String searchUrl(String query) {
        String enc;
        try {
            enc = URLEncoder.encode(query, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            enc = query;
        }
        if (ENGINE_DDG.equals(getEngine())) {
            return "https://duckduckgo.com/?q=" + enc;
        }
        return "https://www.google.com/search?q=" + enc;
    }

    // Convierte lo escrito en una URL o, si no parece una dirección, en una búsqueda
    private String resolveInput(String raw) {
        if (raw == null) return null;
        String t = raw.trim();
        if (t.isEmpty()) return null;

        if (t.matches("(?i)^https?://\\S+$")) {
            return t;
        }
        if (!t.contains(" ")) {
            if (t.matches("(?i)^[a-z0-9-]+(\\.[a-z0-9-]+)*\\.[a-z]{2,}(:\\d+)?([/?#].*)?$")) {
                return "https://" + t;
            }
            if (t.matches("^\\d{1,3}(\\.\\d{1,3}){3}(:\\d+)?([/?#].*)?$")
                    || t.matches("(?i)^localhost(:\\d+)?([/?#].*)?$")) {
                return "http://" + t;
            }
        }
        return searchUrl(t);
    }

    // ------------------------------------------------------------------
    // Favoritos (guardados en el dispositivo)
    // ------------------------------------------------------------------
    private JSONArray loadFavorites() {
        try {
            return new JSONArray(prefs.getString(KEY_FAVORITES, "[]"));
        } catch (JSONException e) {
            return new JSONArray();
        }
    }

    private void saveFavorites(JSONArray favs) {
        prefs.edit().putString(KEY_FAVORITES, favs.toString()).apply();
    }

    private static String normUrl(String u) {
        if (u == null) return "";
        String s = u.trim().toLowerCase(Locale.ROOT);
        while (s.endsWith("/")) {
            s = s.substring(0, s.length() - 1);
        }
        return s;
    }

    private int indexOfFavorite(JSONArray favs, String url) {
        String n = normUrl(url);
        for (int i = 0; i < favs.length(); i++) {
            JSONObject o = favs.optJSONObject(i);
            if (o != null && normUrl(o.optString("url")).equals(n)) {
                return i;
            }
        }
        return -1;
    }

    private void toggleFavorite() {
        String url = webView.getUrl();
        if (url == null || isHome(url)) {
            toast("Abre un sitio para añadirlo a favoritos");
            return;
        }
        JSONArray favs = loadFavorites();
        int idx = indexOfFavorite(favs, url);
        if (idx >= 0) {
            favs.remove(idx);
            saveFavorites(favs);
            toast("Eliminado de favoritos");
        } else {
            String title = webView.getTitle();
            if (title == null || title.trim().isEmpty()) {
                Uri u = Uri.parse(url);
                title = u.getHost() != null ? u.getHost() : url;
            }
            title = title.trim();
            if (title.length() > 40) {
                title = title.substring(0, 40);
            }
            try {
                JSONObject o = new JSONObject();
                o.put("title", title);
                o.put("url", url);
                favs.put(o);
                saveFavorites(favs);
                toast("Añadido a favoritos");
            } catch (JSONException ignored) {
            }
        }
        updateNavState(url);
    }

    private void removeFavoriteByUrl(String url) {
        JSONArray favs = loadFavorites();
        int idx = indexOfFavorite(favs, url);
        if (idx >= 0) {
            favs.remove(idx);
            saveFavorites(favs);
        }
    }

    // ------------------------------------------------------------------
    // Pantalla de inicio <-> aplicación
    // ------------------------------------------------------------------
    private static boolean isHome(String url) {
        return url != null && url.startsWith(HOME_URL);
    }

    private void pushStateToHome() {
        try {
            JSONObject state = new JSONObject();
            state.put("engine", getEngine());
            state.put("favorites", loadFavorites());
            webView.evaluateJavascript("window.DH && DH.init(" + state.toString() + ");", null);
        } catch (JSONException ignored) {
        }
    }

    private void handleHomeAction(Uri uri) {
        String action = uri.getHost();
        if ("go".equals(action)) {
            final String target = resolveInput(uri.getQueryParameter("q"));
            if (target != null) {
                webView.post(() -> webView.loadUrl(target));
            }
        } else if ("engine".equals(action)) {
            String name = uri.getQueryParameter("name");
            if (ENGINE_GOOGLE.equals(name) || ENGINE_DDG.equals(name)) {
                prefs.edit().putString(KEY_ENGINE, name).apply();
                updateNavState(HOME_URL);
            }
        } else if ("remove".equals(action)) {
            String url = uri.getQueryParameter("url");
            if (url != null) {
                removeFavoriteByUrl(url);
                pushStateToHome();
            }
        }
    }

    private void toast(String msg) {
        Toast.makeText(this, msg, Toast.LENGTH_SHORT).show();
    }

    private int dp(int value) {
        return Math.round(value * density);
    }

    // ------------------------------------------------------------------
    // Cursor virtual controlado con el D-Pad del control remoto
    //  - Flechas: mueven el cursor (aceleran al mantener pulsado)
    //  - Al llegar al borde de la pantalla, la página hace scroll
    //  - OK / ENTER: clic (mantener = clic largo); funciona también en la barra
    //  - MENU: alterna entre modo cursor y navegación por foco
    //  - ATRÁS: volver
    // ------------------------------------------------------------------
    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        int code = event.getKeyCode();
        int action = event.getAction();

        if (code == KeyEvent.KEYCODE_MENU) {
            if (action == KeyEvent.ACTION_UP) {
                toggleCursorMode();
            }
            return true;
        }

        if (!cursorMode) {
            return super.dispatchKeyEvent(event);
        }

        // Con un teclado físico, ENTER dentro de la barra de dirección envía la búsqueda
        boolean isEnterKey = code == KeyEvent.KEYCODE_ENTER || code == KeyEvent.KEYCODE_NUMPAD_ENTER;
        if (isEnterKey && getCurrentFocus() instanceof EditText) {
            return super.dispatchKeyEvent(event);
        }

        switch (code) {
            case KeyEvent.KEYCODE_DPAD_UP:
            case KeyEvent.KEYCODE_DPAD_DOWN:
            case KeyEvent.KEYCODE_DPAD_LEFT:
            case KeyEvent.KEYCODE_DPAD_RIGHT:
                if (action == KeyEvent.ACTION_DOWN) {
                    float step = density * (7f + Math.min(event.getRepeatCount(), 20) * 1.6f);
                    float dx = 0f;
                    float dy = 0f;
                    if (code == KeyEvent.KEYCODE_DPAD_UP) dy = -step;
                    if (code == KeyEvent.KEYCODE_DPAD_DOWN) dy = step;
                    if (code == KeyEvent.KEYCODE_DPAD_LEFT) dx = -step;
                    if (code == KeyEvent.KEYCODE_DPAD_RIGHT) dx = step;
                    moveCursor(dx, dy);
                }
                return true;

            case KeyEvent.KEYCODE_DPAD_CENTER:
            case KeyEvent.KEYCODE_ENTER:
            case KeyEvent.KEYCODE_NUMPAD_ENTER:
                if (action == KeyEvent.ACTION_DOWN) {
                    if (event.getRepeatCount() == 0 && !pressed) {
                        pressed = true;
                        sendTouch(MotionEvent.ACTION_DOWN);
                    }
                } else if (action == KeyEvent.ACTION_UP) {
                    if (pressed) {
                        pressed = false;
                        sendTouch(MotionEvent.ACTION_UP);
                    }
                }
                return true;

            default:
                return super.dispatchKeyEvent(event);
        }
    }

    private void moveCursor(float dx, float dy) {
        int w = root.getWidth();
        int h = root.getHeight();
        if (w <= 0 || h <= 0) return;

        float nx = cursorX + dx;
        float ny = cursorY + dy;
        int scrollX = 0;
        int scrollY = 0;

        if (nx < 0f) {
            scrollX = (int) (nx * 2f);
            nx = 0f;
        } else if (nx > w - 1) {
            scrollX = (int) ((nx - (w - 1)) * 2f);
            nx = w - 1;
        }
        if (ny < 0f) {
            scrollY = (int) (ny * 2f);
            ny = 0f;
        } else if (ny > h - 1) {
            scrollY = (int) ((ny - (h - 1)) * 2f);
            ny = h - 1;
        }

        if (scrollX != 0 || scrollY != 0) {
            webView.scrollBy(scrollX, scrollY);
        }

        cursorX = nx;
        cursorY = ny;
        cursorView.setPos(cursorX, cursorY);

        if (!pressed) {
            sendHover();
        }
    }

    // Los toques se envían a toda la pantalla (barra + página), no solo al WebView
    private void sendTouch(int action) {
        long now = SystemClock.uptimeMillis();
        if (action == MotionEvent.ACTION_DOWN) {
            downTime = now;
        }
        MotionEvent ev = MotionEvent.obtain(downTime, now, action, cursorX, cursorY, 0);
        ev.setSource(InputDevice.SOURCE_TOUCHSCREEN);
        root.dispatchTouchEvent(ev);
        ev.recycle();
    }

    private void sendHover() {
        long now = SystemClock.uptimeMillis();
        MotionEvent ev = MotionEvent.obtain(now, now, MotionEvent.ACTION_HOVER_MOVE, cursorX, cursorY, 0);
        ev.setSource(InputDevice.SOURCE_MOUSE);
        root.dispatchGenericMotionEvent(ev);
        ev.recycle();
    }

    private void toggleCursorMode() {
        cursorMode = !cursorMode;
        if (pressed) {
            pressed = false;
            sendTouch(MotionEvent.ACTION_UP);
        }
        cursorView.setVisibility(cursorMode ? View.VISIBLE : View.GONE);
        toast(cursorMode ? "Modo cursor" : "Modo foco (D-Pad)");
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK && webView.canGoBack()) {
            webView.goBack();
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }

    // Vista que dibuja el puntero (flecha morada con borde blanco)
    private static class CursorView extends View {
        private final Paint fill = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Path path = new Path();
        private float px = -100f;
        private float py = -100f;

        CursorView(Context context, float d) {
            super(context);
            setFocusable(false);
            setClickable(false);

            fill.setColor(0xFF9D4EDD);
            fill.setStyle(Paint.Style.FILL);

            stroke.setColor(0xFFFFFFFF);
            stroke.setStyle(Paint.Style.STROKE);
            stroke.setStrokeWidth(2f * d);
            stroke.setStrokeJoin(Paint.Join.ROUND);

            // Flecha con la punta en (0,0)
            path.moveTo(0f, 0f);
            path.lineTo(0f, 22f * d);
            path.lineTo(5.5f * d, 17f * d);
            path.lineTo(9.5f * d, 25f * d);
            path.lineTo(13f * d, 23.3f * d);
            path.lineTo(9f * d, 15.5f * d);
            path.lineTo(15.5f * d, 15.5f * d);
            path.close();
        }

        void setPos(float x, float y) {
            px = x;
            py = y;
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            canvas.save();
            canvas.translate(px, py);
            canvas.drawPath(path, fill);
            canvas.drawPath(path, stroke);
            canvas.restore();
        }
    }
}
EOF

# 7. Recursos de diseño: colors.xml, styles.xml y strings.xml
cat << 'EOF' > app/src/main/res/values/colors.xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="bg_main">#100c16</color>
    <color name="surface_card">#1e1a24</color>
    <color name="ghost_primary">#9d4edd</color>
    <color name="ghost_accent">#c77dff</color>
    <color name="ghost_glow">#5a189a</color>
    <color name="text_primary">#ffffff</color>
    <color name="text_secondary">#b0a8ba</color>
    <color name="glass_fill">#B31E1A24</color>
    <color name="glass_fill_hover">#805A189A</color>
    <color name="glass_fill_active">#995A189A</color>
    <color name="glass_border">#409D4EDD</color>
</resources>
EOF

cat << 'EOF' > app/src/main/res/values/strings.xml
<resources>
    <string name="app_name">DH Browser</string>
</resources>
EOF

cat << 'EOF' > app/src/main/res/values/styles.xml
<resources>
    <style name="Theme.DHBrowserTV" parent="android:Theme.NoTitleBar.Fullscreen">
        <item name="android:windowBackground">@color/bg_main</item>
    </style>
</resources>
EOF

# 8. Icono vectorial y Banner de Android TV (El fantasma morado de DH Browser)
cat << 'EOF' > app/src/main/res/drawable/ic_dh_ghost.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <!-- Fondo circular púrpura oscuro -->
    <path
        android:fillColor="#16111c"
        android:pathData="M54,4 A50,50 0 1,1 53.9,4 Z" />
    <!-- Silueta del fantasma -->
    <path
        android:fillColor="#9d4edd"
        android:pathData="M54,20 C36,20 28,34 28,52 C28,74 36,86 42,86 C46,86 49,80 54,80 C59,80 62,86 66,86 C72,86 80,74 80,52 C80,34 72,20 54,20 Z" />
    <!-- Ojos brillantes -->
    <path
        android:fillColor="#ffffff"
        android:pathData="M42,42 L48,46 L42,48 Z" />
    <path
        android:fillColor="#ffffff"
        android:pathData="M66,42 L60,46 L66,48 Z" />
    <!-- Sonrisa enorme traviesa con colmillos -->
    <path
        android:fillColor="#16111c"
        android:pathData="M38,58 Q54,76 70,58 Q54,64 38,58 Z" />
    <path
        android:fillColor="#ffffff"
        android:pathData="M44,60 L46,65 L48,60 Z" />
    <path
        android:fillColor="#ffffff"
        android:pathData="M60,60 L62,65 L64,60 Z" />
</vector>
EOF

cat << 'EOF' > app/src/main/res/drawable/tv_banner.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="320dp"
    android:height="180dp"
    android:viewportWidth="320"
    android:viewportHeight="180">
    <path
        android:fillColor="#100c16"
        android:pathData="M0,0 H320 V180 H0 Z" />
    <!-- Fantasma miniatura en el banner -->
    <path
        android:fillColor="#9d4edd"
        android:pathData="M160,40 C144,40 136,52 136,70 C136,88 144,100 148,100 C152,100 156,94 160,94 C164,94 168,100 172,100 C176,100 184,88 184,70 C184,52 176,40 160,40 Z" />
    <path
        android:fillColor="#ffffff"
        android:pathData="M150,58 L155,62 L150,64 Z" />
    <path
        android:fillColor="#ffffff"
        android:pathData="M170,58 L165,62 L170,64 Z" />
    <path
        android:fillColor="#100c16"
        android:pathData="M146,74 Q160,88 174,74 Q160,78 146,74 Z" />
</vector>
EOF

# 8b. Iconos y fondos de cristal para la barra de herramientas
cat << 'EOF' > app/src/main/res/drawable/ic_nav_back.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="@color/text_primary">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M20,11H7.83l5.59,-5.59L12,4l-8,8 8,8 1.41,-1.41L7.83,13H20v-2z" />
</vector>
EOF

cat << 'EOF' > app/src/main/res/drawable/ic_nav_forward.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="@color/text_primary">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M12,4l-1.41,1.41L16.17,11H4v2h12.17l-5.58,5.59L12,20l8,-8z" />
</vector>
EOF

cat << 'EOF' > app/src/main/res/drawable/ic_nav_refresh.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="@color/text_primary">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M17.65,6.35C16.2,4.9 14.21,4 12,4c-4.42,0 -7.99,3.58 -7.99,8s3.57,8 7.99,8c3.73,0 6.84,-2.55 7.73,-6h-2.08c-0.82,2.33 -3.04,4 -5.65,4 -3.31,0 -6,-2.69 -6,-6s2.69,-6 6,-6c1.66,0 3.14,0.69 4.22,1.78L13,11h7V4l-2.35,2.35z" />
</vector>
EOF

cat << 'EOF' > app/src/main/res/drawable/ic_nav_home.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="@color/text_primary">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M10,20v-6h4v6h5v-8h3L12,3 2,12h3v8z" />
</vector>
EOF

cat << 'EOF' > app/src/main/res/drawable/ic_nav_star.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="@color/text_primary">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M22,9.24l-7.19,-0.62L12,2 9.19,8.62 2,9.24l5.46,4.73L5.82,21 12,17.27 18.18,21l-1.63,-7.03L22,9.24zM12,15.4l-3.76,2.27 1,-4.28 -3.32,-2.88 4.38,-0.38L12,6.1l1.71,4.04 4.38,0.38 -3.32,2.88 1,4.28L12,15.4z" />
</vector>
EOF

cat << 'EOF' > app/src/main/res/drawable/ic_nav_star_filled.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="@color/ghost_accent"
        android:pathData="M12,17.27L18.18,21l-1.64,-7.03L22,9.24l-7.19,-0.61L12,2 9.19,8.63 2,9.24l5.46,4.73L5.82,21z" />
</vector>
EOF

cat << 'EOF' > app/src/main/res/drawable/ic_nav_search.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="20dp"
    android:height="20dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="@color/text_secondary">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M15.5,14h-0.79l-0.28,-0.27C15.41,12.59 16,11.11 16,9.5 16,5.91 13.09,3 9.5,3S3,5.91 3,9.5 5.91,16 9.5,16c1.61,0 3.09,-0.59 4.23,-1.57l0.27,0.28v0.79l5,4.99L20.49,19l-4.99,-5zM9.5,14C7.01,14 5,11.99 5,9.5S7.01,5 9.5,5 14,7.01 14,9.5 11.99,14 9.5,14z" />
</vector>
EOF

cat << 'EOF' > app/src/main/res/drawable/bg_glass_button.xml
<?xml version="1.0" encoding="utf-8"?>
<selector xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:state_pressed="true">
        <shape android:shape="rectangle">
            <solid android:color="@color/glass_fill_active" />
            <stroke android:width="2dp" android:color="@color/ghost_accent" />
            <corners android:radius="14dp" />
        </shape>
    </item>
    <item android:state_focused="true">
        <shape android:shape="rectangle">
            <solid android:color="@color/glass_fill_hover" />
            <stroke android:width="2dp" android:color="@color/ghost_accent" />
            <corners android:radius="14dp" />
        </shape>
    </item>
    <item android:state_hovered="true">
        <shape android:shape="rectangle">
            <solid android:color="@color/glass_fill_hover" />
            <stroke android:width="2dp" android:color="@color/ghost_primary" />
            <corners android:radius="14dp" />
        </shape>
    </item>
    <item>
        <shape android:shape="rectangle">
            <solid android:color="@color/glass_fill" />
            <stroke android:width="1dp" android:color="@color/glass_border" />
            <corners android:radius="14dp" />
        </shape>
    </item>
</selector>
EOF

cat << 'EOF' > app/src/main/res/drawable/bg_glass_bar.xml
<?xml version="1.0" encoding="utf-8"?>
<selector xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:state_pressed="true">
        <shape android:shape="rectangle">
            <solid android:color="@color/glass_fill_active" />
            <stroke android:width="2dp" android:color="@color/ghost_accent" />
            <corners android:radius="22dp" />
        </shape>
    </item>
    <item android:state_focused="true">
        <shape android:shape="rectangle">
            <solid android:color="@color/glass_fill_hover" />
            <stroke android:width="2dp" android:color="@color/ghost_accent" />
            <corners android:radius="22dp" />
        </shape>
    </item>
    <item android:state_hovered="true">
        <shape android:shape="rectangle">
            <solid android:color="@color/glass_fill_hover" />
            <stroke android:width="2dp" android:color="@color/ghost_primary" />
            <corners android:radius="22dp" />
        </shape>
    </item>
    <item>
        <shape android:shape="rectangle">
            <solid android:color="@color/glass_fill" />
            <stroke android:width="1dp" android:color="@color/glass_border" />
            <corners android:radius="22dp" />
        </shape>
    </item>
</selector>
EOF

# 9. app/src/main/assets/www/index.html (Interfaz Visual Ghost Glass de DH Browser para TV)
cat << 'EOF' > app/src/main/assets/www/index.html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>DH Browser - Inicio</title>
  <style>
    * { box-sizing: border-box; }
    html, body { margin: 0; }
    body {
      background-color: #100c16; color: #ffffff; font-family: system-ui, sans-serif;
      padding: 24px 32px; min-height: 100vh; display: flex; flex-direction: column; gap: 16px;
    }
    button { font-family: inherit; color: #ffffff; }
    .glass-card { background: rgba(30, 26, 36, 0.7); backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px); border: 1px solid rgba(157, 78, 221, 0.25); }
    .glass-focus { transition: 0.2s ease; }
    .glass-focus:focus, .glass-focus:hover { outline: none; border-color: #c77dff; box-shadow: 0 0 20px #9d4edd; transform: scale(1.03); }

    /* Cabecera */
    header { display: flex; align-items: center; justify-content: space-between; padding: 12px 16px; border-radius: 16px; }
    .brand { display: flex; align-items: center; gap: 12px; }
    .logo { width: 44px; height: 44px; border-radius: 12px; background: rgba(88, 28, 135, 0.6); border: 1px solid #a855f7; display: flex; align-items: center; justify-content: center; font-size: 24px; }
    h1 { margin: 0; font-size: 20px; font-weight: 700; letter-spacing: 0.025em; color: #d8b4fe; }
    .sub { margin: 2px 0 0; font-size: 12px; color: rgba(192, 132, 252, 0.8); }
    .header-right { display: flex; align-items: center; gap: 16px; }
    .badge { padding: 4px 12px; background: #3b0764; border: 1px solid rgba(168, 85, 247, 0.4); border-radius: 9999px; font-size: 12px; color: #d8b4fe; }
    .clock { font-size: 12px; color: #9ca3af; }

    /* Buscador */
    .search { width: 100%; max-width: 820px; margin: 0 auto; padding: 18px 20px; border-radius: 24px; text-align: center; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5); }
    .search h2 { margin: 0 0 12px; font-size: 20px; font-weight: 700; }
    .search-row { display: flex; gap: 10px; align-items: stretch; }
    .engine { display: flex; gap: 6px; }
    .engine-btn { padding: 0 14px; border-radius: 12px; border: 1px solid rgba(88, 28, 135, 0.5); background: rgba(0, 0, 0, 0.4); color: #d8b4fe; font-size: 13px; font-weight: 700; cursor: pointer; }
    .engine-btn.active { background: #9333ea; border-color: #c77dff; color: #ffffff; }
    #q { flex: 1; min-width: 0; background: rgba(0, 0, 0, 0.4); border: 1px solid rgba(88, 28, 135, 0.5); border-radius: 12px; padding: 12px 16px; color: #ffffff; font-size: 14px; font-family: inherit; }
    .go-btn { width: 48px; background: #9333ea; border: 1px solid #9333ea; border-radius: 12px; display: flex; align-items: center; justify-content: center; cursor: pointer; padding: 0; }

    /* Secciones de sitios */
    .block { width: 100%; max-width: 920px; margin: 0 auto; }
    .section-title { margin: 0 0 8px; font-size: 13px; font-weight: 700; color: #d8b4fe; letter-spacing: 0.05em; text-transform: uppercase; display: flex; align-items: center; gap: 8px; }
    .grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; }
    .tile-wrap { position: relative; min-width: 0; }
    .tile { display: flex; align-items: center; gap: 10px; padding: 10px 12px; border-radius: 16px; color: #ffffff; text-decoration: none; min-height: 52px; }
    .tile-icon { width: 28px; height: 28px; flex: none; border-radius: 8px; background: rgba(255, 255, 255, 0.08); padding: 3px; object-fit: contain; }
    .tile-initial { width: 28px; height: 28px; flex: none; border-radius: 8px; background: rgba(88, 28, 135, 0.6); border: 1px solid rgba(168, 85, 247, 0.5); display: flex; align-items: center; justify-content: center; font-size: 13px; font-weight: 700; color: #d8b4fe; }
    .tile-label { font-size: 13px; font-weight: 700; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .tile-remove { position: absolute; top: -6px; right: -6px; width: 24px; height: 24px; padding: 0; border-radius: 50%; background: rgba(30, 26, 36, 0.95); border: 1px solid rgba(157, 78, 221, 0.5); display: flex; align-items: center; justify-content: center; cursor: pointer; }
    .empty { margin: 0; padding: 12px 14px; font-size: 13px; color: #9ca3af; border: 1px dashed rgba(157, 78, 221, 0.3); border-radius: 16px; }

    footer { margin-top: auto; display: flex; justify-content: center; gap: 32px; font-size: 12px; color: rgba(216, 180, 254, 0.7); border-top: 1px solid rgba(88, 28, 135, 0.3); padding-top: 14px; }
  </style>
</head>
<body>
  <!-- Top Bar -->
  <header class="glass-card">
    <div class="brand">
      <div class="logo">👻</div>
      <div>
        <h1>DH Browser</h1>
        <p class="sub">Android TV Edition • 10-Foot UI</p>
      </div>
    </div>
    <div class="header-right">
      <span class="badge">🛡️ DH Shield: 324,850 Reglas</span>
      <span class="clock">Hoy 09:15 AM</span>
    </div>
  </header>

  <!-- Buscador con selector de motor -->
  <section class="glass-card search">
    <h2>Navegación Limpia y Sin Anuncios</h2>
    <div class="search-row">
      <div class="engine" role="group" aria-label="Motor de búsqueda">
        <button class="engine-btn glass-focus" id="eng-google" type="button">Google</button>
        <button class="engine-btn glass-focus" id="eng-duckduckgo" type="button">DuckDuckGo</button>
      </div>
      <input id="q" class="glass-focus" type="text" autocomplete="off" placeholder="Buscar en Google o escribir una URL">
      <button id="go" class="go-btn glass-focus" type="button" aria-label="Buscar">
        <svg width="22" height="22" viewBox="0 0 24 24" aria-hidden="true"><path fill="#ffffff" d="M15.5,14h-0.79l-0.28,-0.27C15.41,12.59 16,11.11 16,9.5 16,5.91 13.09,3 9.5,3S3,5.91 3,9.5 5.91,16 9.5,16c1.61,0 3.09,-0.59 4.23,-1.57l0.27,0.28v0.79l5,4.99L20.49,19l-4.99,-5zM9.5,14C7.01,14 5,11.99 5,9.5S7.01,5 9.5,5 14,7.01 14,9.5 11.99,14 9.5,14z"/></svg>
      </button>
    </div>
  </section>

  <!-- Favoritos -->
  <section class="block">
    <h3 class="section-title">
      <svg width="16" height="16" viewBox="0 0 24 24" aria-hidden="true"><path fill="#c77dff" d="M12,17.27L18.18,21l-1.64,-7.03L22,9.24l-7.19,-0.61L12,2 9.19,8.63 2,9.24l5.46,4.73L5.82,21z"/></svg>
      Mis favoritos
    </h3>
    <div id="favs" class="grid"></div>
    <p id="favs-empty" class="empty">Aún no tienes favoritos. Abre un sitio y toca la estrella de la barra superior para guardarlo aquí.</p>
  </section>

  <!-- Sitios populares -->
  <section class="block">
    <h3 class="section-title">
      <svg width="16" height="16" viewBox="0 0 24 24" aria-hidden="true"><path fill="#c77dff" d="M12,2C6.48,2 2,6.48 2,12s4.48,10 10,10 10,-4.48 10,-10S17.52,2 12,2zM4,12c0,-0.61 0.08,-1.21 0.21,-1.78L8.99,15v1c0,1.1 0.9,2 2,2v1.93C7.06,19.43 4,16.07 4,12zM18.92,17.39C18.71,16.58 17.97,16 17,16h-1v-3c0,-0.55 -0.45,-1 -1,-1H9v-2h2c0.55,0 1,-0.45 1,-1V7h2c1.1,0 2,-0.9 2,-2v-0.41C17.92,5.77 20,8.65 20,12c0,2.08 -0.81,3.98 -2.08,5.39z"/></svg>
      Sitios populares
    </h3>
    <div id="sites" class="grid"></div>
  </section>

  <!-- Remote Control Help Bar -->
  <footer>
    <span>[D-PAD] Mover cursor</span>
    <span>[MENÚ] Cursor / Foco</span>
    <span>[OK] Seleccionar</span>
    <span>[ATRÁS] Volver</span>
    <span>[Y] Búsqueda por Voz</span>
  </footer>

  <script>
    var POPULAR = [
      { title: 'YouTube',     url: 'https://www.youtube.com' },
      { title: 'Netflix',     url: 'https://www.netflix.com' },
      { title: 'Prime Video', url: 'https://www.primevideo.com' },
      { title: 'Disney+',     url: 'https://www.disneyplus.com' },
      { title: 'Twitch',      url: 'https://www.twitch.tv' },
      { title: 'Spotify',     url: 'https://open.spotify.com' },
      { title: 'Pluto TV',    url: 'https://pluto.tv' },
      { title: 'Wikipedia',   url: 'https://es.wikipedia.org' }
    ];

    var state = { engine: 'google', favorites: [] };
    var qInput = document.getElementById('q');

    function isSafeUrl(u) { return typeof u === 'string' && /^https?:\/\//i.test(u); }

    function hostOf(u) {
      try { return new URL(u).hostname; } catch (e) { return ''; }
    }

    function makeIcon(item) {
      var host = hostOf(item.url);
      var img = document.createElement('img');
      img.className = 'tile-icon';
      img.alt = '';
      img.src = 'https://icons.duckduckgo.com/ip3/' + host + '.ico';
      img.onerror = function () {
        var initial = document.createElement('div');
        initial.className = 'tile-initial';
        initial.textContent = (item.title || host || '?').charAt(0).toUpperCase();
        if (img.parentNode) img.parentNode.replaceChild(initial, img);
      };
      return img;
    }

    function makeTile(item, removable) {
      var wrap = document.createElement('div');
      wrap.className = 'tile-wrap';

      var a = document.createElement('a');
      a.className = 'tile glass-card glass-focus';
      a.href = item.url;

      var label = document.createElement('span');
      label.className = 'tile-label';
      label.textContent = item.title || hostOf(item.url);

      a.appendChild(makeIcon(item));
      a.appendChild(label);
      wrap.appendChild(a);

      if (removable) {
        var x = document.createElement('button');
        x.type = 'button';
        x.className = 'tile-remove glass-focus';
        x.setAttribute('aria-label', 'Quitar de favoritos');
        x.innerHTML = '<svg width="12" height="12" viewBox="0 0 24 24" aria-hidden="true"><path fill="#ffffff" d="M19,6.41L17.59,5 12,10.59 6.41,5 5,6.41 10.59,12 5,17.59 6.41,19 12,13.41 17.59,19 19,17.59 13.41,12z"/></svg>';
        x.addEventListener('click', function (e) {
          e.preventDefault();
          window.location.href = 'dhbrowser://remove?url=' + encodeURIComponent(item.url);
        });
        wrap.appendChild(x);
      }
      return wrap;
    }

    function renderSites() {
      var box = document.getElementById('sites');
      box.innerHTML = '';
      POPULAR.forEach(function (s) { box.appendChild(makeTile(s, false)); });
    }

    function renderFavorites() {
      var box = document.getElementById('favs');
      var empty = document.getElementById('favs-empty');
      box.innerHTML = '';
      var count = 0;
      state.favorites.forEach(function (f) {
        if (f && isSafeUrl(f.url)) {
          box.appendChild(makeTile(f, true));
          count++;
        }
      });
      empty.style.display = count ? 'none' : 'block';
      box.style.display = count ? 'grid' : 'none';
    }

    function setEngine(engine, notify) {
      state.engine = engine === 'duckduckgo' ? 'duckduckgo' : 'google';
      document.getElementById('eng-google').className = 'engine-btn glass-focus' + (state.engine === 'google' ? ' active' : '');
      document.getElementById('eng-duckduckgo').className = 'engine-btn glass-focus' + (state.engine === 'duckduckgo' ? ' active' : '');
      qInput.placeholder = 'Buscar en ' + (state.engine === 'duckduckgo' ? 'DuckDuckGo' : 'Google') + ' o escribir una URL';
      if (notify) window.location.href = 'dhbrowser://engine?name=' + state.engine;
    }

    function submitSearch() {
      var v = qInput.value.trim();
      if (!v) return;
      window.location.href = 'dhbrowser://go?q=' + encodeURIComponent(v);
    }

    document.getElementById('eng-google').addEventListener('click', function () { setEngine('google', true); });
    document.getElementById('eng-duckduckgo').addEventListener('click', function () { setEngine('duckduckgo', true); });
    document.getElementById('go').addEventListener('click', submitSearch);
    qInput.addEventListener('keydown', function (e) { if (e.key === 'Enter') submitSearch(); });

    // La aplicación envía el motor y los favoritos guardados
    window.DH = {
      init: function (s) {
        if (s && s.engine) setEngine(s.engine, false);
        state.favorites = (s && Array.isArray(s.favorites)) ? s.favorites : [];
        renderFavorites();
      }
    };

    renderSites();
    setEngine('google', false);
    renderFavorites();
  </script>
</body>
</html>
EOF


echo "✨ ¡Proyecto DH Browser generado con éxito!"
echo "Ahora sólo haz:"
echo "  git init"
echo "  git add ."
echo "  git commit -m 'Initial DH Browser Android TV project'"
echo "  git remote add origin https://github.com/TU-USUARIO/dh-browser-tv.git"
echo "  git push -u origin main"

