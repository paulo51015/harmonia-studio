package com.harmonia.harmonia_studio

import android.media.AudioManager
import android.media.MediaRecorder
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap

class MainActivity: FlutterActivity(), TextToSpeech.OnInitListener {
    private val RECORD_CHANNEL = "com.harmonia.harmonia_studio/recorder"
    private val TTS_CHANNEL = "com.harmonia.harmonia_studio/vocal_tts"
    private var mediaRecorder: MediaRecorder? = null
    private var isRecording = false

    private var tts: TextToSpeech? = null
    private var isTtsInitialized = false
    private val pendingTasks = ArrayList<() -> Unit>()
    private val mainHandler = Handler(Looper.getMainLooper())

    private val synthCallbacks = ConcurrentHashMap<String, MethodChannel.Result>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Inicializa TextToSpeech nativo do Android
        if (tts == null) {
            tts = TextToSpeech(applicationContext, this)
        }

        // Canal de Gravação
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RECORD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            val file = File(path)
                            file.parentFile?.mkdirs()

                            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                MediaRecorder(this)
                            } else {
                                @Suppress("DEPRECATION")
                                MediaRecorder()
                            }

                            mediaRecorder?.apply {
                                setAudioSource(MediaRecorder.AudioSource.MIC)
                                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                                setAudioEncodingBitRate(192000)
                                setAudioSamplingRate(44100)
                                setOutputFile(path)
                                prepare()
                                start()
                            }
                            isRecording = true
                            result.success(true)
                        } catch (e: Exception) {
                            e.printStackTrace()
                            result.error("RECORDER_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_PATH", "Path cannot be null", null)
                    }
                }
                "stopRecording" -> {
                    try {
                        if (isRecording) {
                            mediaRecorder?.apply {
                                stop()
                                reset()
                                release()
                            }
                            mediaRecorder = null
                            isRecording = false
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.error("STOP_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Canal de Voz Cantada / TTS Nativo em Português
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TTS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    val text = call.argument<String>("text")
                    val pitch = call.argument<Double>("pitch")?.toFloat() ?: 1.05f
                    val rate = call.argument<Double>("rate")?.toFloat() ?: 0.98f

                    if (text.isNullOrBlank()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }

                    val task = {
                        try {
                            tts?.setPitch(pitch)
                            tts?.setSpeechRate(rate)

                            val params = Bundle().apply {
                                putInt(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_MUSIC)
                                putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, 1.0f)
                            }
                            val utteranceId = "speak_${System.currentTimeMillis()}"
                            val speakStatus = tts?.speak(text, TextToSpeech.QUEUE_FLUSH, params, utteranceId)
                            Log.d("HarmoniaTTS", "speak text='$text' status=$speakStatus")
                            result.success(speakStatus == TextToSpeech.SUCCESS)
                        } catch (e: Exception) {
                            Log.e("HarmoniaTTS", "Error speaking", e)
                            result.error("TTS_ERROR", e.message, null)
                        }
                    }

                    if (isTtsInitialized && tts != null) {
                        task()
                    } else {
                        pendingTasks.add(task)
                    }
                }
                "stop" -> {
                    try {
                        tts?.stop()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("TTS_ERROR", e.message, null)
                    }
                }
                "synthesizeToFile" -> {
                    val text = call.argument<String>("text")
                    val path = call.argument<String>("path")
                    val pitch = call.argument<Double>("pitch")?.toFloat() ?: 1.05f
                    val rate = call.argument<Double>("rate")?.toFloat() ?: 0.98f

                    if (text.isNullOrBlank() || path.isNullOrBlank()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }

                    val task = {
                        try {
                            val file = File(path)
                            file.parentFile?.mkdirs()
                            tts?.setPitch(pitch)
                            tts?.setSpeechRate(rate)

                            val utteranceId = "synth_${System.currentTimeMillis()}"
                            synthCallbacks[utteranceId] = result

                            val params = Bundle().apply {
                                putInt(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_MUSIC)
                                putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, 1.0f)
                            }

                            val queueStatus = tts?.synthesizeToFile(text, params, file, utteranceId)
                            if (queueStatus != TextToSpeech.SUCCESS) {
                                synthCallbacks.remove(utteranceId)
                                result.success(false)
                            } else {
                                // Timeout de segurança de 15 segundos para síntese de arquivo
                                mainHandler.postDelayed({
                                    val pendingRes = synthCallbacks.remove(utteranceId)
                                    if (pendingRes != null) {
                                        val hasFile = file.exists() && file.length() > 0
                                        Log.d("HarmoniaTTS", "synth timeout check: file exists=$hasFile size=${file.length()}")
                                        pendingRes.success(hasFile)
                                    }
                                }, 15000)
                            }
                        } catch (e: Exception) {
                            Log.e("HarmoniaTTS", "Error synthesizing to file", e)
                            result.error("SYNTH_ERROR", e.message, null)
                        }
                    }

                    if (isTtsInitialized && tts != null) {
                        task()
                    } else {
                        pendingTasks.add(task)
                    }
                }
                "isReady" -> {
                    result.success(isTtsInitialized)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onInit(status: Int) {
        Log.d("HarmoniaTTS", "onInit status: $status")
        if (status == TextToSpeech.SUCCESS) {
            val locale = Locale("pt", "BR")
            val result = tts?.setLanguage(locale)
            Log.d("HarmoniaTTS", "setLanguage pt-BR result: $result")
            if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                val ptResult = tts?.setLanguage(Locale("pt"))
                Log.d("HarmoniaTTS", "setLanguage pt fallback result: $ptResult")
                if (ptResult == TextToSpeech.LANG_MISSING_DATA || ptResult == TextToSpeech.LANG_NOT_SUPPORTED) {
                    tts?.setLanguage(Locale.getDefault())
                }
            }

            tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {
                    Log.d("HarmoniaTTS", "Utterance onStart: $utteranceId")
                }

                override fun onDone(utteranceId: String?) {
                    Log.d("HarmoniaTTS", "Utterance onDone: $utteranceId")
                    if (utteranceId != null) {
                        val pendingRes = synthCallbacks.remove(utteranceId)
                        if (pendingRes != null) {
                            mainHandler.post {
                                pendingRes.success(true)
                            }
                        }
                    }
                }

                @Suppress("OVERRIDE_DEPRECATION")
                override fun onError(utteranceId: String?) {
                    Log.e("HarmoniaTTS", "Utterance onError: $utteranceId")
                    if (utteranceId != null) {
                        val pendingRes = synthCallbacks.remove(utteranceId)
                        if (pendingRes != null) {
                            mainHandler.post {
                                pendingRes.success(false)
                            }
                        }
                    }
                }

                override fun onError(utteranceId: String?, errorCode: Int) {
                    Log.e("HarmoniaTTS", "Utterance onError: $utteranceId code: $errorCode")
                    if (utteranceId != null) {
                        val pendingRes = synthCallbacks.remove(utteranceId)
                        if (pendingRes != null) {
                            mainHandler.post {
                                pendingRes.success(false)
                            }
                        }
                    }
                }
            })

            isTtsInitialized = true

            mainHandler.post {
                val tasks = ArrayList(pendingTasks)
                pendingTasks.clear()
                tasks.forEach { it.invoke() }
            }
        } else {
            Log.e("HarmoniaTTS", "TextToSpeech init failed with status: $status")
        }
    }

    override fun onDestroy() {
        tts?.stop()
        tts?.shutdown()
        tts = null
        super.onDestroy()
    }
}
