package dev.nariinfo.evensies

import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.TextRecognizerOptionsInterface
import com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// A FragmentActivity: local_auth's biometric prompt needs one (App lock, docs/API.md, Appearance and app lock).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Receipt scan (docs/API.md, Receipts): the photo's text lines, read on the phone with ML Kit. `recognize`
        // {path, script} → [{text, left, top, right, bottom}] in pixels of the upright image, origin top left. The script
        // ("korean", "japanese", else Latin) picks the model; a failed Korean or Japanese one retries with Latin.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "evensies/ocr").setMethodCallHandler { call, result ->
            val path = call.argument<String>("path")
            if (call.method != "recognize" || path == null) {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val image = try {
                InputImage.fromFilePath(this, Uri.fromFile(File(path))) // applies the EXIF rotation
            } catch (e: Exception) {
                result.error("OCR", e.message, null)
                return@setMethodCallHandler
            }
            fun recognize(options: TextRecognizerOptionsInterface) {
                val recognizer = TextRecognition.getClient(options)
                recognizer.process(image)
                    .addOnSuccessListener { text ->
                        result.success(text.textBlocks.flatMap { it.lines }.mapNotNull { line ->
                            val b = line.boundingBox ?: return@mapNotNull null
                            mapOf(
                                "text" to line.text,
                                "left" to b.left.toDouble(),
                                "top" to b.top.toDouble(),
                                "right" to b.right.toDouble(),
                                "bottom" to b.bottom.toDouble(),
                            )
                        })
                    }
                    .addOnFailureListener { e ->
                        if (options == TextRecognizerOptions.DEFAULT_OPTIONS) result.error("OCR", e.message, null)
                        else recognize(TextRecognizerOptions.DEFAULT_OPTIONS)
                    }
                    .addOnCompleteListener { recognizer.close() }
            }
            recognize(when (call.argument<String>("script")) {
                "korean" -> KoreanTextRecognizerOptions.Builder().build()
                "japanese" -> JapaneseTextRecognizerOptions.Builder().build()
                else -> TextRecognizerOptions.DEFAULT_OPTIONS
            })
        }
    }
}
