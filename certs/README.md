# certs/

`debug.keystore` é a chave de **debug** usada para assinar o APK Android
(`export_presets.cfg` → `keystore/debug`).

- Alias: `androiddebugkey`
- Store/key password: `android`
- DN: `CN=Android Debug, O=Android, C=US`

É uma chave pública de desenvolvimento, sem qualquer segredo: serve apenas
para que `adb install` aceite o pacote. **Não** usar para publicação na Play
Store. Para uma versão de distribuição, gere a sua própria chave e altere
`keystore/release*` no preset Android.

O APK gerado é verificado com `apksigner verify` (esquemas v2 e v3).
