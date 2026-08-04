package com.example.bms_mobile_apps

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.reactivex.exceptions.UndeliverableException
import io.reactivex.plugins.RxJavaPlugins
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.OutputStream
import java.util.UUID

class MainActivity : FlutterActivity() {
    private data class CsvSession(
        val output: OutputStream,
        val location: String,
        val uri: Uri? = null,
    )

    private val csvSessions = mutableMapOf<String, CsvSession>()

    override fun onCreate(savedInstanceState: Bundle?) {
        installBleRxErrorHandler()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.elbi.smart_bms/downloads_csv",
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "requiresLegacyStoragePermission" ->
                        result.success(requiresLegacyStoragePermission())
                    "create" -> createCsv(
                        call.argument<String>("filename"),
                        call.argument<String>("header"),
                        result,
                    )
                    "append" -> appendCsv(
                        call.argument<String>("id"),
                        call.argument<String>("content"),
                        result,
                    )
                    "finish" -> finishCsv(call.argument<String>("id"), result)
                    else -> result.notImplemented()
                }
            } catch (error: Exception) {
                result.error("csv_write_failed", error.message, null)
            }
        }
    }

    override fun onDestroy() {
        csvSessions.values.forEach { session ->
            runCatching { session.output.close() }
        }
        csvSessions.clear()
        super.onDestroy()
    }

    private fun requiresLegacyStoragePermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
            PackageManager.PERMISSION_GRANTED
    }

    private fun createCsv(
        requestedFilename: String?,
        header: String?,
        result: MethodChannel.Result,
    ) {
        require(!requestedFilename.isNullOrBlank()) { "CSV filename is required." }
        require(header != null) { "CSV header is required." }
        if (requiresLegacyStoragePermission()) {
            result.error(
                "storage_permission_required",
                "Storage permission is required on this Android version.",
                null,
            )
            return
        }

        val filename = requestedFilename.replace(Regex("[^A-Za-z0-9._-]"), "_")
        val session = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            createMediaStoreCsv(filename)
        } else {
            createLegacyCsv(filename)
        }
        session.output.write(header.toByteArray(Charsets.UTF_8))
        session.output.flush()

        val id = UUID.randomUUID().toString()
        csvSessions[id] = session
        result.success(mapOf("id" to id, "location" to session.location))
    }

    private fun createMediaStoreCsv(filename: String): CsvSession {
        val relativeDirectory = "${Environment.DIRECTORY_DOWNLOADS}/ELBI Smart BMS"
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, filename)
            put(MediaStore.MediaColumns.MIME_TYPE, "text/csv")
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativeDirectory)
        }
        val uri = checkNotNull(
            contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values),
        ) { "Could not create the CSV file in Downloads." }
        val output = checkNotNull(contentResolver.openOutputStream(uri, "w")) {
            "Could not open the CSV file in Downloads."
        }
        return CsvSession(
            output = BufferedOutputStream(output),
            location = "$relativeDirectory/$filename",
            uri = uri,
        )
    }

    @Suppress("DEPRECATION")
    private fun createLegacyCsv(filename: String): CsvSession {
        val directory = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            "ELBI Smart BMS",
        )
        check(directory.exists() || directory.mkdirs()) {
            "Could not create the ELBI Smart BMS Downloads folder."
        }
        val file = uniqueFile(directory, filename)
        return CsvSession(
            output = BufferedOutputStream(FileOutputStream(file)),
            location = "${Environment.DIRECTORY_DOWNLOADS}/ELBI Smart BMS/${file.name}",
        )
    }

    private fun uniqueFile(directory: File, filename: String): File {
        val requested = File(directory, filename)
        if (!requested.exists()) return requested
        val extensionIndex = filename.lastIndexOf('.')
        val stem = if (extensionIndex > 0) filename.substring(0, extensionIndex) else filename
        val extension = if (extensionIndex > 0) filename.substring(extensionIndex) else ""
        var suffix = 2
        while (true) {
            val candidate = File(directory, "${stem}_$suffix$extension")
            if (!candidate.exists()) return candidate
            suffix++
        }
    }

    private fun appendCsv(
        id: String?,
        content: String?,
        result: MethodChannel.Result,
    ) {
        require(!id.isNullOrBlank()) { "CSV session ID is required." }
        require(content != null) { "CSV content is required." }
        val session = checkNotNull(csvSessions[id]) { "CSV session was not found." }
        session.output.write(content.toByteArray(Charsets.UTF_8))
        session.output.flush()
        result.success(null)
    }

    private fun finishCsv(id: String?, result: MethodChannel.Result) {
        require(!id.isNullOrBlank()) { "CSV session ID is required." }
        val session = checkNotNull(csvSessions.remove(id)) { "CSV session was not found." }
        session.output.flush()
        session.output.close()
        result.success(session.location)
    }

    private fun installBleRxErrorHandler() {
        RxJavaPlugins.setErrorHandler { throwable ->
            val error =
                if (throwable is UndeliverableException) {
                    throwable.cause ?: throwable
                } else {
                    throwable
                }

            val isExpectedCancellation =
                error is IOException ||
                    error is InterruptedException ||
                    error.javaClass.name.startsWith("com.polidea.rxandroidble2.exceptions.")

            if (isExpectedCancellation) {
                return@setErrorHandler
            }

            val thread = Thread.currentThread()
            thread.uncaughtExceptionHandler?.uncaughtException(thread, error)
        }
    }
}
