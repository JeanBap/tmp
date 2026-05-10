package com.example.password_manager

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

/**
 * MainActivity con protezione FLAG_SECURE.
 *
 * Sicurezza:
 *  - FLAG_SECURE evita screenshot manuali, registrazione schermo e blocca la
 *    preview nel task switcher (Recent Apps), mostrando un placeholder.
 *  - Lo settiamo nel `onCreate` *prima* di `super.onCreate` per essere attivo
 *    dal primo frame ed evitare race condition con i primi compositor frames.
 *  - Lo manteniamo per tutta la vita dell'activity; non lo togliamo mai
 *    (rimuoverlo dinamicamente espone una finestra di leak).
 */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        super.onCreate(savedInstanceState)
    }
}
