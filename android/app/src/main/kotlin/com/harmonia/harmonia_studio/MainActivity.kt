package com.harmonia.harmonia_studio

import android.media.MediaRecorder
import android.os.Build
import android.os.Bundle
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale

class MainActivity: FlutterActivity(), TextToSpeech.OnInitListener {
    private val RECORD_CHANNEL = "com.harmonia.harmonia_studio/recorder"
    private val TTS_CHANNEL = "com.harmonia.harmonia_studio/vocal_tts"
    private var mediaRecorder: MediaRecorder? = null
    private var isRecording = false
    private var tts: TextToSpeech? = null
    private var isTtsInitialized = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Inicializa TextToSpeech nativo do Android
        if (tts == null) {
            tts = TextToSpeech(this, this)
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
                    val pitch = call.argument<Double>("pitch")?.toFloat() ?: 1.0f
                    val rate = call.argument<Double>("rate")?.toFloat() ?: 1.0f
                    if (text != null && isTtsInitialized && tts != null) {
                        try {
                            tts?.setPitch(pitch)
                            tts?.setSpeechRate(rate)
                            val params = Bundle()
                            val utteranceId = "vocal_${System.currentTimeMillis()}"
                            tts?.speak(text, TextToSpeech.QUEUE_FLUSH, params, utteranceId)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("TTS_ERROR", e.message, null)
                        }
                    } else {
                        result.success(false)
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
                    val pitch = call.argument<Double>("pitch")?.toFloat() ?: 1.0f
                    val rate = call.argument<Double>("rate")?.toFloat() ?: 1.0f
                    if (text != null && path != null && isTtsInitialized && tts != null) {
                        try {
                            val file = File(path)
                            file.parentFile?.mkdirs()
                            tts?.setPitch(pitch)
                            tts?.setSpeechRate(rate)
                            val params = Bundle()
                            val utteranceId = "synth_${System.currentTimeMillis()}"
                            val status = tts?.synthesizeToFile(text, params, file, utteranceId)
                            result.success(status == TextToSpeech.SUCCESS)
                        } catch (e: Exception) {
                            result.error("SYNTH_ERROR", e.message, null)
                        }
                    } else {
                        result.success(false)
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
        if (status == TextToSpeech.SUCCESS) {
            val result = tts?.setLanguage(Locale("pt", "BR"))
            if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                tts?.setLanguage(Locale.getDefault())
            }
            isTtsInitialized = true
        }
    }

    override fun onDestroy() {
        tts?.stop()
        tts?.shutdown()
        tts = null
        super.onDestroy()
    }
}
