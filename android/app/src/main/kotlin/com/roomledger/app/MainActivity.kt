package com.roomledger.app

import android.Manifest
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val SMS_CHANNEL = "roomledger/sms"
    private val REQUEST_SMS_PERMISSION_CODE = 4852

    private var pendingSmsResult: MethodChannel.Result? = null
    private var pendingRecipient: String? = null
    private var pendingMessage: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SMS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method == "sendSms") {
                val recipient = call.argument<String>("recipient")
                val message = call.argument<String>("message")
                if (recipient == null || message == null) {
                    result.error("INVALID_ARGS", "recipient and message are required", null)
                    return@setMethodCallHandler
                }

                if (ContextCompat.checkSelfPermission(
                        this, Manifest.permission.SEND_SMS
                    ) == PackageManager.PERMISSION_GRANTED
                ) {
                    sendSmsDirectly(recipient, message, result)
                } else {
                    pendingSmsResult = result
                    pendingRecipient = recipient
                    pendingMessage = message
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.SEND_SMS),
                        REQUEST_SMS_PERMISSION_CODE
                    )
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun sendSmsDirectly(recipient: String, message: String, result: MethodChannel.Result) {
        try {
            val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                context.getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }

            val sentIntent = PendingIntent.getBroadcast(
                context,
                0,
                Intent("SMS_SENT"),
                PendingIntent.FLAG_IMMUTABLE,
            )
            val parts = smsManager.divideMessage(message)
            if (parts.size == 1) {
                smsManager.sendTextMessage(recipient, null, message, sentIntent, null)
            } else {
                val sentIntents = ArrayList<PendingIntent>(parts.size).apply {
                    repeat(parts.size) { add(sentIntent) }
                }
                smsManager.sendMultipartTextMessage(
                    recipient, null, parts, sentIntents, null,
                )
            }
            result.success(null)
        } catch (e: Exception) {
            result.error("SMS_ERROR", e.message ?: "Unknown SMS sending error", null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_SMS_PERMISSION_CODE) {
            val result = pendingSmsResult
            val recipient = pendingRecipient
            val message = pendingMessage

            pendingSmsResult = null
            pendingRecipient = null
            pendingMessage = null

            if (result != null && recipient != null && message != null) {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    sendSmsDirectly(recipient, message, result)
                } else {
                    result.error(
                        "PERMISSION_DENIED",
                        "SMS sending permission was denied by the user.",
                        null
                    )
                }
            }
        }
    }
}

