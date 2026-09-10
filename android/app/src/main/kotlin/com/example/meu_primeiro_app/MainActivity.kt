package com.example.meu_primeiro_app

import android.app.Activity
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    companion object {
        private const val PICK_RINGTONE_REQUEST = 7104
    }

    private var alarmRingtone: Ringtone? = null
    private var alarmToneGenerator: ToneGenerator? = null
    private var pendingSoundPickerResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "leet_clock/device",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getTimeZone" -> result.success(TimeZone.getDefault().id)
                "startAlarm" -> startAlarm(call, result)
                "stopAlarm" -> {
                    stopAlarm()
                    result.success(null)
                }
                "pickAlarmSound" -> pickAlarmSound(call, result)
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(null)
                }
                "openAlarmSettings" -> {
                    openAlarmSettings()
                    result.success(null)
                }
                "openSoundSettings" -> {
                    startActivity(Intent(Settings.ACTION_SOUND_SETTINGS))
                    result.success(null)
                }
                "isBatteryOptimizationDisabled" -> {
                    val powerManager = getSystemService(POWER_SERVICE) as PowerManager
                    result.success(powerManager.isIgnoringBatteryOptimizations(packageName))
                }
                "openBatterySettings" -> {
                    openBatterySettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startAlarm(call: MethodCall, result: MethodChannel.Result) {
        try {
            stopAlarm()
            val soundType = call.argument<String>("soundType") ?: "systemAlarm"
            if (soundType == "strongBeep") {
                startStrongBeep(result)
                return
            }

            val preferredUris = mutableListOf<Uri>()
            if (soundType == "custom") {
                call.argument<String>("uri")?.let { preferredUris.add(Uri.parse(it)) }
            } else {
                val preferredType = when (soundType) {
                    "ringtone" -> RingtoneManager.TYPE_RINGTONE
                    "notification" -> RingtoneManager.TYPE_NOTIFICATION
                    else -> RingtoneManager.TYPE_ALARM
                }
                RingtoneManager.getDefaultUri(preferredType)?.let(preferredUris::add)
            }
            listOf(
                RingtoneManager.TYPE_ALARM,
                RingtoneManager.TYPE_RINGTONE,
                RingtoneManager.TYPE_NOTIFICATION,
            ).forEach { type ->
                RingtoneManager.getDefaultUri(type)?.let { uri ->
                    if (!preferredUris.contains(uri)) preferredUris.add(uri)
                }
            }

            for (uri in preferredUris) {
                if (playRingtone(uri)) {
                    result.success(true)
                    return
                }
            }

            // Alguns emuladores e aparelhos sem toque configurado devolvem uma
            // URI inválida. Um tom no stream de alarme garante retorno sonoro.
            startStrongBeep(result)
        } catch (error: Exception) {
            result.error("alarm_start_failed", error.message, null)
        }
    }

    private fun playRingtone(uri: Uri): Boolean {
        val ringtone = RingtoneManager.getRingtone(applicationContext, uri) ?: return false
        ringtone.audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            ringtone.isLooping = true
        }
        ringtone.play()
        if (ringtone.isPlaying) {
            alarmRingtone = ringtone
            return true
        }
        ringtone.stop()
        return false
    }

    private fun startStrongBeep(result: MethodChannel.Result) {
        val toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, 100)
        val started = toneGenerator.startTone(ToneGenerator.TONE_DTMF_5)
        if (!started) {
            toneGenerator.release()
            throw IllegalStateException("Não foi possível iniciar o áudio do alarme")
        }
        alarmToneGenerator = toneGenerator
        result.success(true)
    }

    private fun pickAlarmSound(call: MethodCall, result: MethodChannel.Result) {
        if (pendingSoundPickerResult != null) {
            result.error("picker_active", "O seletor de som já está aberto", null)
            return
        }
        pendingSoundPickerResult = result
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(
                RingtoneManager.EXTRA_RINGTONE_TYPE,
                RingtoneManager.TYPE_ALARM or
                    RingtoneManager.TYPE_RINGTONE or
                    RingtoneManager.TYPE_NOTIFICATION,
            )
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            call.argument<String>("uri")?.let {
                putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, Uri.parse(it))
            }
        }
        startActivityForResult(intent, PICK_RINGTONE_REQUEST)
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != PICK_RINGTONE_REQUEST) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val pendingResult = pendingSoundPickerResult
        pendingSoundPickerResult = null
        if (resultCode != Activity.RESULT_OK) {
            pendingResult?.success(null)
            return
        }
        val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            data?.getParcelableExtra(
                RingtoneManager.EXTRA_RINGTONE_PICKED_URI,
                Uri::class.java,
            )
        } else {
            data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        }
        if (uri == null) {
            pendingResult?.success(null)
            return
        }
        val label = RingtoneManager.getRingtone(applicationContext, uri)
            ?.getTitle(applicationContext)
            ?: "Som personalizado"
        pendingResult?.success(mapOf("uri" to uri.toString(), "label" to label))
    }

    private fun openNotificationSettings() {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        }
        startActivity(intent)
    }

    private fun openAlarmSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                startActivity(
                    Intent(
                        Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                        Uri.parse("package:$packageName"),
                    ),
                )
            } else {
                openAppDetails()
            }
        } catch (_: Exception) {
            openAppDetails()
        }
    }

    private fun openBatterySettings() {
        try {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
        } catch (_: Exception) {
            openAppDetails()
        }
    }

    private fun openAppDetails() {
        startActivity(
            Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:$packageName"),
            ),
        )
    }

    private fun stopAlarm() {
        alarmRingtone?.stop()
        alarmRingtone = null
        alarmToneGenerator?.stopTone()
        alarmToneGenerator?.release()
        alarmToneGenerator = null
    }

    override fun onDestroy() {
        stopAlarm()
        super.onDestroy()
    }
}
