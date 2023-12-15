# DeepLink

> Lembre-se de consultar a documentação oficial para fazer a configuração de rotas

Para configurar o deep link ao projeto, é necessário modificadar ou criar a referência na publicação.

## Android

A configuração no android, é necessário que o aplicativo esteja publicado na Play Store primeiramente.

### Configuração no aplicativo

1. Abra o arquivo `android/app/src/main/AndroidManifest.xml`
2. Encontre a `tag` `<activity>` contendo o atributo de `android:name=".MainActivity"`
3. Adicione dentro desta `tag` encontrada no passo acima, o código abaixo:

```xml

 <meta-data android:name="flutter_deeplinking_enabled" android:value="true" />
 <intent-filter android:autoVerify="true">
     <action android:name="android.intent.action.VIEW" />
     <category android:name="android.intent.category.DEFAULT" />
     <category android:name="android.intent.category.BROWSABLE" />
      <data android:scheme="http" android:host="example.com" />
     <data android:scheme="https" />
 </intent-filter>

```
> Troque o valor do atributo `android:host` para o dominio do seu site

### Configuração no site externo

1. Entre no Google Play Console do seu aplicativo publicado, vá em `Versões > Configuração > Assinatura de apps > Certificado da chave de assinatura do app` (`Release > Setup > App Integrity > App Signing tab`).

2. Crie um arquivo com o nome de `assetlinks.json` contendo a seguinte estrutura base:
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.example.deeplink_cookbook",
    "sha256_cert_fingerprints":
    ["FF:2A:CF:7B:DD:CC:F1:03:3E:E8:B2:27:7C:A2:E3:3C:DE:13:DB:AC:8E:EB:3A:B9:72:A1:0E:26:8A:F5:EC:AF"]
  }
}]
```

Segue o arquivo configurado deste aplicativo:
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "telemed_neurondata",
      "package_name": "com.neurondata.telemed_ha",
      "sha256_cert_fingerprints": [
        "36:11:C2:64:87:D6:95:23:24:3E:B3:E9:52:F8:6A:5B:64:6D:8A:EB:73:94:09:39:DE:5A:E7:4B:17:33:9F:37"
      ]
    }
  }
]

```

3. Defina o `package_name` com o valor do seu Android application ID.

4. Defina o `sha256_cert_fingerprints` com o valor disponível na página ao finalizar o passo 1.

5. Hospede o arquivo no site que está acesso ao `deep link`, criando o caminho: <publicFolder>/.well-known/assetlinks.json

6. Verifique se consegue ter o acesso


