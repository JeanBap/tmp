package com.example.password_manager.autofill

import android.app.assist.AssistStructure
import android.os.Build
import android.os.CancellationSignal
import android.service.autofill.AutofillService
import android.service.autofill.FillCallback
import android.service.autofill.FillRequest
import android.service.autofill.SaveCallback
import android.service.autofill.SaveRequest
import android.util.Log
import androidx.annotation.RequiresApi

/**
 * Stub di Autofill Service (Android 8.0+, API 26).
 *
 * Sicurezza:
 *  - L'app rimane offline-first: il riempimento avviene SOLO se il vault è
 *    sbloccato. Se non lo è, mostriamo un Authentication Intent che apre la
 *    MainActivity per sblocco con master password / biometria.
 *  - Non logghiamo mai username/password: solo metadati (package, hostname).
 *
 * NOTA: questa è la "skeleton" funzionale; il matching reale fra dataset KDBX
 * e campi visti dall'AssistStructure va completato lato Kotlin con il proprio
 * dominio (lookup per hostname/package) e l'esposizione dei dataset come
 * `FillResponse`. Mantenuto minimale per chiarezza.
 */
@RequiresApi(Build.VERSION_CODES.O)
class KdbxAutofillService : AutofillService() {

    override fun onFillRequest(
        request: FillRequest,
        cancellationSignal: CancellationSignal,
        callback: FillCallback
    ) {
        try {
            val context = request.fillContexts.lastOrNull() ?: run {
                callback.onSuccess(null)
                return
            }
            val structure: AssistStructure = context.structure
            val pkg = structure.activityComponent?.packageName ?: "unknown"
            Log.d(TAG, "onFillRequest from package=$pkg")
            // TODO: enumerare i campi (username/password/email) e produrre
            // un FillResponse con dataset criptati dal KDBX.
            callback.onSuccess(null)
        } catch (e: Throwable) {
            Log.w(TAG, "Autofill error: ${e.javaClass.simpleName}")
            callback.onSuccess(null)
        }
    }

    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        // TODO: ricevere i nuovi valori e proporne il salvataggio nel vault.
        callback.onSuccess()
    }

    companion object {
        private const val TAG = "KdbxAutofill"
    }
}
