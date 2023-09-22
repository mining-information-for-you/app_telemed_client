package com.neurondata.telemed_neurondata

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
  var methodChannel: MethodChannelCoordinator? = null
  
  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel =
            MethodChannelCoordinator(
                flutterEngine.dartExecutor.binaryMessenger,
                getActivity()
            )
        methodChannel?.setupMethodChannel()

        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory("videoTile", NativeViewFactory())
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissionsList: Array<String>,
        grantResults: IntArray
    ) {
        val permissionsManager = methodChannel?.permissionsManager ?: return
        when (requestCode) {
            permissionsManager.AUDIO_PERMISSION_REQUEST_CODE -> {
                methodChannel?.permissionsManager?.audioCallbackReceived()
            }
            permissionsManager.VIDEO_PERMISSION_REQUEST_CODE -> {
                methodChannel?.permissionsManager?.videoCallbackReceived()
            }
        }
    }
}
