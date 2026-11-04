package com.faddgraphics.faddompet

import android.content.Intent
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.faddgraphics.faddompet/update")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openApk" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) {
                            result.success(
                                mapOf(
                                    "opened" to false,
                                    "permissionDenied" to false,
                                    "message" to "invalid_path",
                                ),
                            )
                        } else {
                            openApk(path, result)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.faddgraphics.faddompet/theme")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSystemPalette" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            result.success(systemPalette())
                        } else {
                            result.success(null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // Palet warna sistem (Material You). Urutan nada: 0, 10, 50, 100, 200, 300,
    // 400, 500, 600, 700, 800, 900, 1000.
    @RequiresApi(Build.VERSION_CODES.S)
    private fun systemPalette(): Map<String, List<Long>> {
        return mapOf(
            "accent1" to colors(
                android.R.color.system_accent1_0,
                android.R.color.system_accent1_10,
                android.R.color.system_accent1_50,
                android.R.color.system_accent1_100,
                android.R.color.system_accent1_200,
                android.R.color.system_accent1_300,
                android.R.color.system_accent1_400,
                android.R.color.system_accent1_500,
                android.R.color.system_accent1_600,
                android.R.color.system_accent1_700,
                android.R.color.system_accent1_800,
                android.R.color.system_accent1_900,
                android.R.color.system_accent1_1000,
            ),
            "accent2" to colors(
                android.R.color.system_accent2_0,
                android.R.color.system_accent2_10,
                android.R.color.system_accent2_50,
                android.R.color.system_accent2_100,
                android.R.color.system_accent2_200,
                android.R.color.system_accent2_300,
                android.R.color.system_accent2_400,
                android.R.color.system_accent2_500,
                android.R.color.system_accent2_600,
                android.R.color.system_accent2_700,
                android.R.color.system_accent2_800,
                android.R.color.system_accent2_900,
                android.R.color.system_accent2_1000,
            ),
            "accent3" to colors(
                android.R.color.system_accent3_0,
                android.R.color.system_accent3_10,
                android.R.color.system_accent3_50,
                android.R.color.system_accent3_100,
                android.R.color.system_accent3_200,
                android.R.color.system_accent3_300,
                android.R.color.system_accent3_400,
                android.R.color.system_accent3_500,
                android.R.color.system_accent3_600,
                android.R.color.system_accent3_700,
                android.R.color.system_accent3_800,
                android.R.color.system_accent3_900,
                android.R.color.system_accent3_1000,
            ),
            "neutral1" to colors(
                android.R.color.system_neutral1_0,
                android.R.color.system_neutral1_10,
                android.R.color.system_neutral1_50,
                android.R.color.system_neutral1_100,
                android.R.color.system_neutral1_200,
                android.R.color.system_neutral1_300,
                android.R.color.system_neutral1_400,
                android.R.color.system_neutral1_500,
                android.R.color.system_neutral1_600,
                android.R.color.system_neutral1_700,
                android.R.color.system_neutral1_800,
                android.R.color.system_neutral1_900,
                android.R.color.system_neutral1_1000,
            ),
            "neutral2" to colors(
                android.R.color.system_neutral2_0,
                android.R.color.system_neutral2_10,
                android.R.color.system_neutral2_50,
                android.R.color.system_neutral2_100,
                android.R.color.system_neutral2_200,
                android.R.color.system_neutral2_300,
                android.R.color.system_neutral2_400,
                android.R.color.system_neutral2_500,
                android.R.color.system_neutral2_600,
                android.R.color.system_neutral2_700,
                android.R.color.system_neutral2_800,
                android.R.color.system_neutral2_900,
                android.R.color.system_neutral2_1000,
            ),
        )
    }

    private fun colors(vararg ids: Int): List<Long> {
        return ids.map { resources.getColor(it, theme).toLong() and 0xFFFFFFFFL }
    }

    private fun openApk(path: String, result: MethodChannel.Result) {
        val file = File(path)
        if (!file.exists()) {
            result.success(
                mapOf(
                    "opened" to false,
                    "permissionDenied" to false,
                    "message" to "file_not_found",
                ),
            )
            return
        }

        try {
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.updateFileProvider",
                file,
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(
                mapOf(
                    "opened" to true,
                    "permissionDenied" to false,
                    "message" to "opened",
                ),
            )
        } catch (_: SecurityException) {
            result.success(
                mapOf(
                    "opened" to false,
                    "permissionDenied" to true,
                    "message" to "permission_denied",
                ),
            )
        } catch (_: Exception) {
            result.success(
                mapOf(
                    "opened" to false,
                    "permissionDenied" to false,
                    "message" to "open_failed",
                ),
            )
        }
    }
}
