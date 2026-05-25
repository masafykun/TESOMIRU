# TESOMIRU - Claude セッション運用指示

## 最初にやること

1. **必ず最初に [BUILD_LOG.md](BUILD_LOG.md) を読む** - 前回どこまで進んだか・次に何をすべきかが書いてある
2. 必要に応じて [README.md](README.md) でプロジェクト全体像を確認

## 作業中のルール

- **作業の区切りごとに必ず BUILD_LOG.md を追記する**（忘れない）
- 新しいエントリは BUILD_LOG.md の**先頭**に追加（時系列で逆順）
- 各エントリには「やったこと」＋「次にやること」を必ず書く
- 日付は絶対日付（YYYY-MM-DD）で書く

## プロジェクト構成の要点

- **iOSアプリ本体**: 当フォルダ `~/XcodeProject/TESOMIRU/`
- **バックエンドAPI**: 本番VPS `163.44.117.33:43222` の `/root/palm-reading/`（FastAPI + OpenAI GPT-4o）
- **公開URL**: https://tesomiru.1qaz.jp
- **Bundle ID**: `org.masafy.TESOMIRU`
- 詳細は [README.md](README.md) 参照

## 使うMCPツール

| 作業 | ツール |
|---|---|
| iOS ビルド/実行/スクショ | `xcode-mcp` |
| VPS（バックエンド）操作 | `ssh-server` (host 163.44.117.33, port 43222) |
| App Store Connect | ブラウザ作業（Claudeは指示出すだけ） |

## ハマりポイント（CLAUDE記憶用）

- `Products.storekit` は **Xcode IDE経由でしか読まれない**。`xcodebuild` (MCP) からの起動時はPaywallで「プラン情報を取得できませんでした」になる。本番では問題なし。
- App Store価格ティアは固定。¥480/¥2,400は存在しない。¥500/¥2,500を採用済み。
- iOS 26.5 でビルドするには iOS 26.5 simruntime が必要。iOS 26.4 sim + Xcode 26.5 では destination 不一致でビルド不可。
- App Store Connect の説明文は罫線記号(`━━`)・一部絵文字を「無効な文字」と判定する。

## 関連メモリ

- [[project-tesomiru]] - プロジェクト全体メモリ
- [[feedback-project-folder-method]] - プロジェクトフォルダ構成ルール
- [[feedback-screenshot-policy]] - スクショ撮影ポリシー
