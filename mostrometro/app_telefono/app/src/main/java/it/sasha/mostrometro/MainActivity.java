package it.sasha.mostrometro;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.VibrationEffect;
import android.speech.tts.TextToSpeech;
import android.speech.tts.Voice;
import android.os.Vibrator;
import android.view.View;
import android.view.WindowInsets;
import android.webkit.JavascriptInterface;
import android.webkit.PermissionRequest;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Il Mostrometro sul telefono.
 * Tutta l'app (disegno, suoni, famiglia, carte) e' una pagina dentro assets/www, mostrata qui a schermo intero.
 * La pagina viene servita come https://mostrometro.app/ (finto indirizzo, non va su internet): cosi' puo' usare
 * microfono e fotocamera e i dati restano salvati sul telefono.
 */
public class MainActivity extends Activity {
    private static final String BASE = "https://mostrometro.app/";
    private static final int CHIEDI_PERMESSI = 7;

    private WebView web;
    private PermissionRequest richiestaInAttesa;
    private String linkInAttesa;
    private TextToSpeech voce;
    private boolean voceOk = false;

    @Override
    protected void onCreate(Bundle stato) {
        super.onCreate(stato);
        web = new WebView(this);
        web.setBackgroundColor(Color.parseColor("#1B1030"));
        setContentView(web);

        // Android 15 disegna sotto le barre di sistema: lascio lo spazio giusto sopra e sotto
        web.setOnApplyWindowInsetsListener((v, insets) -> {
            int alto, basso;
            if (Build.VERSION.SDK_INT >= 30) {
                android.graphics.Insets i = insets.getInsets(WindowInsets.Type.systemBars());
                alto = i.top; basso = i.bottom;
            } else {
                alto = insets.getSystemWindowInsetTop(); basso = insets.getSystemWindowInsetBottom();
            }
            v.setPadding(0, alto, 0, basso);
            return insets;
        });

        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setAllowFileAccess(false);
        s.setTextZoom(100);

        web.addJavascriptInterface(new Ponte(), "Telefono");
        web.setWebViewClient(new WebViewClient() {
            @Override
            public WebResourceResponse shouldInterceptRequest(WebView v, WebResourceRequest r) {
                Uri u = r.getUrl();
                if (!"mostrometro.app".equals(u.getHost())) return null;
                String p = u.getPath();
                if (p == null || p.equals("/") || p.isEmpty()) p = "/index.html";
                try {
                    InputStream in = getAssets().open("www" + p);
                    return new WebResourceResponse(tipo(p), tipo(p).startsWith("text") ? "utf-8" : null, in);
                } catch (IOException e) {
                    return new WebResourceResponse("text/plain", "utf-8", 404, "Non trovato",
                            null, new java.io.ByteArrayInputStream(new byte[0]));
                }
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest r) {
                return !"mostrometro.app".equals(r.getUrl().getHost());   // niente siti esterni dentro l'app
            }

            @Override
            public void onPageFinished(WebView v, String url) {
                if (linkInAttesa != null) { apriLink(linkInAttesa); linkInAttesa = null; }
            }
        });
        web.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onPermissionRequest(PermissionRequest richiesta) {
                runOnUiThread(() -> chiediPermessi(richiesta));
            }
        });

        // la voce: quella italiana del telefono (Google), un po' piu' acuta e allegra
        voce = new TextToSpeech(this, stato2 -> {
            if (stato2 != TextToSpeech.SUCCESS) return;
            Locale it = Locale.ITALIAN;
            if (voce.isLanguageAvailable(it) < TextToSpeech.LANG_AVAILABLE) return;
            voce.setLanguage(it);
            try {                                      // la voce italiana migliore che funziona anche senza internet
                Voice migliore = null;
                for (Voice v : voce.getVoices()) {
                    if (!"it".equals(v.getLocale().getLanguage()) || v.isNetworkConnectionRequired()) continue;
                    if (v.getFeatures() != null && v.getFeatures().contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED)) continue;
                    if (migliore == null || v.getQuality() > migliore.getQuality()) migliore = v;
                }
                if (migliore != null) voce.setVoice(migliore);
            } catch (Exception ignorata) { }
            voce.setPitch(1.12f);
            voce.setSpeechRate(1.0f);
            voceOk = true;
        });

        linkInAttesa = linkDa(getIntent());
        web.loadUrl(BASE + "index.html");
    }

    @Override
    protected void onDestroy() {
        if (voce != null) voce.shutdown();
        super.onDestroy();
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        String l = linkDa(intent);
        if (l != null) apriLink(l);
    }

    private String linkDa(Intent i) {
        if (i != null && Intent.ACTION_VIEW.equals(i.getAction()) && i.getData() != null) return i.getData().toString();
        return null;
    }

    private void apriLink(String link) {
        web.evaluateJavascript("window.apriLinkCarta && apriLinkCarta(" + org.json.JSONObject.quote(link) + ")", null);
    }

    // ---- permessi: la pagina chiede microfono (urlo) o fotocamera (QR) ----
    private void chiediPermessi(PermissionRequest richiesta) {
        List<String> servono = new ArrayList<>();
        for (String r : richiesta.getResources()) {
            if (PermissionRequest.RESOURCE_AUDIO_CAPTURE.equals(r)) servono.add(Manifest.permission.RECORD_AUDIO);
            if (PermissionRequest.RESOURCE_VIDEO_CAPTURE.equals(r)) servono.add(Manifest.permission.CAMERA);
        }
        List<String> mancano = new ArrayList<>();
        for (String p : servono) if (checkSelfPermission(p) != PackageManager.PERMISSION_GRANTED) mancano.add(p);
        if (mancano.isEmpty()) { richiesta.grant(richiesta.getResources()); return; }
        richiestaInAttesa = richiesta;
        requestPermissions(mancano.toArray(new String[0]), CHIEDI_PERMESSI);
    }

    @Override
    public void onRequestPermissionsResult(int codice, String[] permessi, int[] risultati) {
        if (codice != CHIEDI_PERMESSI || richiestaInAttesa == null) return;
        boolean ok = risultati.length > 0;
        for (int r : risultati) ok &= r == PackageManager.PERMISSION_GRANTED;
        if (ok) richiestaInAttesa.grant(richiestaInAttesa.getResources());
        else richiestaInAttesa.deny();
        richiestaInAttesa = null;
    }

    // ---- tasto indietro: prima chiude i pannelli aperti nella pagina ----
    @Override
    @SuppressWarnings("deprecation")
    public void onBackPressed() {
        web.evaluateJavascript("window.indietro ? indietro() : false", valore -> {
            if (!"true".equals(valore)) MainActivity.super.onBackPressed();
        });
    }

    private static String tipo(String p) {
        if (p.endsWith(".html")) return "text/html";
        if (p.endsWith(".js")) return "text/javascript";
        if (p.endsWith(".css")) return "text/css";
        if (p.endsWith(".json")) return "application/json";
        if (p.endsWith(".wav")) return "audio/wav";
        if (p.endsWith(".jpg")) return "image/jpeg";
        if (p.endsWith(".png")) return "image/png";
        if (p.endsWith(".svg")) return "image/svg+xml";
        if (p.endsWith(".ttf")) return "font/ttf";
        return "application/octet-stream";
    }

    /** Piccole cose che la pagina chiede al telefono. */
    class Ponte {
        @JavascriptInterface
        public void vibra(int ms) {
            Vibrator v = (Vibrator) getSystemService(VIBRATOR_SERVICE);
            if (v == null) return;
            if (Build.VERSION.SDK_INT >= 26) v.vibrate(VibrationEffect.createOneShot(Math.max(1, ms), VibrationEffect.DEFAULT_AMPLITUDE));
        }

        @JavascriptInterface
        public void parla(String testo) {
            if (voceOk) voce.speak(testo, TextToSpeech.QUEUE_FLUSH, null, "mostro");
        }

        @JavascriptInterface
        public void schermoAcceso(boolean acceso) {
            runOnUiThread(() -> {
                if (acceso) getWindow().addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
                else getWindow().clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            });
        }
    }
}
