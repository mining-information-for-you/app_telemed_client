package com.neurondata.telemed_ha

class MethodChannelResult(val result: Boolean, val arguments: Any?) {

    fun toFlutterCompatibleType(): Map<String, Any?> {
        return mapOf("result" to result, "arguments" to arguments)
    }
}
