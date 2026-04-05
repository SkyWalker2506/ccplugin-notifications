# ccplugin-notifications — Yönlendirici

> **Bu dosya sadece yönlendiricidir.** Tüm kurallar `~/Projects/claude-config/CLAUDE.md` dosyasındadır.

---

## Her oturum başında

1. **`~/Projects/claude-config/CLAUDE.md` dosyasını oku** ve talimatlarını uygula
2. Yanıt başında model etiketi: `(Model Adı)`
3. Dil: kullanıcıya Türkçe; kod/commit İngilizce

## Bu plugin hakkında

Tek giriş noktası: `notify.sh`

```bash
bash notify.sh --message "text" --channel [telegram|macos|sound|all]
bash notify.sh --event [build-error|ai-question|task-done] --message "text"
```

claude-config entegrasyonu: `config/notify.sh` → `channels/telegram.sh` symlink.
