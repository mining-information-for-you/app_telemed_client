package com.example.mvp_chime_flutter

class MethodChannelResult(val result: Boolean, val arguments: Any?) {

    fun toFlutterCompatibleType(): Map<String, Any?> {
        return mapOf("result" to result, "arguments" to arguments)
    }
}
