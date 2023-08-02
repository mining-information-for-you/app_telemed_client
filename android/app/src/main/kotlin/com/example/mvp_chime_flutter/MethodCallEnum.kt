package com.example.mvp_chime_flutter

enum class MethodCall(val call: String) {
    manageAudioPermissions("manageAudioPermissions"),
    manageVideoPermissions("manageVideoPermissions"),
    initialAudioSelection("initialAudioSelection"),
    join("join"),
    stop("stop"),
    leave("leave"),
    drop("drop"),
    mute("mute"),
    unmute("unmute"),
    startLocalVideo("startLocalVideo"),
    stopLocalVideo("stopLocalVideo"),
    videoTileAdd("videoTileAdd"),
    videoTileRemove("videoTileRemove"),
    listAudioDevices("listAudioDevices"),
    updateAudioDevice("updateAudioDevice"),
    switchCamera("switchCamera"),
    audioSessionDidStop("audioSessionDidStop")
}
