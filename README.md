# TESOMIRU

> AI が手のひらを読む — iOS 手相鑑定アプリ（個人開発・App Store 申請まで完走、4.3(b) で却下）

手のひらを撮影すると、バックエンドの LLM が生命線・感情線・頭脳線・運命線を解析して鑑定結果を返します。鑑定結果に対して AI と追加対話したり、過去の鑑定をタイムラインで振り返ることもできます。

![Swift](https://img.shields.io/badge/Swift-5.9+-FA7343?style=flat-square&logo=swift)
![Xcode](https://img.shields.io/badge/Xcode-26+-147EFB?style=flat-square&logo=xcode)
![iOS](https://img.shields.io/badge/iOS-26+-000000?style=flat-square&logo=apple)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)

---

## 公開ステータス

このアプリは **App Store でのリリースには至っていません**。Apple のレビューで Guideline **4.3(b) Design - Spam**（占い/手相は飽和カテゴリで差別化が不十分）として却下されました。AI 対話とタイムラインを差別化機能として実装しましたが、Apple の判断としては「カテゴリ自体を再考すべき」というものでした。

リジェクト体験談は Qiita に別途まとめています。コード自体は学習用に MIT で公開します。

---

## ✨ 機能

- **AI 手相鑑定** — 手のひらの写真をバックエンドに送り、4 線をスコア付きで解析
- **ラッキーカラー / ラッキーナンバー** — 鑑定結果に応じて提示
- **AI 対話** — 鑑定結果について自然言語で追加質問できる。サジェスチョンチップ常時表示
- **タイムライン** — 過去の鑑定を最大 50 件保存・再閲覧（チャット履歴付き）
- **フリーミアム制限**
  - 無料: 鑑定 1 日 2 回 / AI 会話 1 回
  - プレミアム: 無制限 + タイムライン解放
- **StoreKit 2** によるサブスクリプション（月額 / 年額）

---

## 🛠 技術スタック

| カテゴリ | 技術 |
|---|---|
| 言語 | Swift |
| UI | SwiftUI |
| 最低対応 OS | iOS 26+ |
| 永続化 | UserDefaults (Codable JSON) |
| 課金 | StoreKit 2 |
| ネットワーク | URLSession (multipart/form-data, JSON) |
| バックエンド | FastAPI + uvicorn (Python) |
| LLM | OpenAI GPT-4o (analyze) / GPT-4o-mini (chat) |

---

## 📁 ディレクトリ構成

```
TESOMIRU/
├── TESOMIRU/
│   ├── TESOMIRUApp.swift          # エントリポイント
│   ├── ContentView.swift          # ルート View / 画面遷移
│   ├── HomeView.swift             # ホーム（鑑定回数表示・タイムライン導線）
│   ├── CaptureView.swift          # 手のひら撮影 / 写真選択
│   ├── AnalyzingView.swift        # 解析中アニメーション
│   ├── ResultView.swift           # 鑑定結果・AI 対話導線
│   ├── ChatView.swift             # AI 占い師との対話
│   ├── TimelineView.swift         # 過去鑑定一覧（プレミアム限定）
│   ├── ReadingDetailView.swift    # 過去鑑定詳細 + チャット履歴
│   ├── PaywallSheet.swift         # サブスク販売 UI
│   ├── PalmReadingService.swift   # API 通信
│   ├── StoreManager.swift         # StoreKit 2 ラッパー
│   ├── ReadingStore.swift         # 鑑定の永続化 + 日次回数カウンタ
│   ├── Config.swift.example       # 設定テンプレ（実体は gitignored）
│   ├── Products.storekit.example  # StoreKit Config テンプレ（実体は gitignored）
│   └── Assets.xcassets/
├── TESOMIRU.xcodeproj/
├── DevTeam.xcconfig.example       # 署名 Team ID テンプレ
├── .gitignore
└── README.md
```

---

## 🚀 セットアップ

```bash
git clone https://github.com/masafykun/TESOMIRU.git
cd TESOMIRU

# 1. Config をローカル設定として作成
cp TESOMIRU/Config.swift.example TESOMIRU/Config.swift
# → 自分のバックエンドURL / IAP製品ID を書き込む

# 2. StoreKit Configuration をローカル設定として作成
cp TESOMIRU/Products.storekit.example TESOMIRU/Products.storekit
# → 自分の IAP 製品 ID に書き換える

# 3. Apple Developer Team ID をローカル設定として作成（実機ビルドする場合）
cp DevTeam.xcconfig.example DevTeam.xcconfig
# → 自分の Team ID を書き込む
# Xcode で Project → Info → Configurations → 各ビルド設定に DevTeam.xcconfig を割当

# 4. Xcode で開く
open TESOMIRU.xcodeproj
```

`Config.swift` / `Products.storekit` / `DevTeam.xcconfig` は `.gitignore` 済み（API URL や Team ID を含むため）。

---

## 🌐 バックエンド API

手相画像は `multipart/form-data` でアップロードし、JSON で鑑定結果が返ります。

### 鑑定

```
POST /api/palm-reading
Content-Type: multipart/form-data
field "image": JPEG bytes

→ {
    "summary": String,
    "lines": [{ "name": String, "description": String, "score": Int }],
    "luckyColor": String,
    "luckyNumber": Int
  }
```

### 鑑定後の AI 対話

```
POST /api/palm-chat
Content-Type: application/json
{
  "reading":  { summary, lines, luckyColor, luckyNumber },
  "history":  [{ "role": "user"|"assistant", "content": String }],
  "message":  String
}

→ { "reply": String }
```

バックエンド本体（FastAPI 実装）はこのリポジトリには含まれていません。

---

## 💸 サブスクリプション

| プラン | 価格 | 製品 ID（例） |
|---|---|---|
| 月額 | ¥500 | `org.example.PalmReading.premium.monthly` |
| 年額 | ¥2,500 | `org.example.PalmReading.premium.yearly` |

App Store Connect 側で本番製品 ID と価格を登録し、`Config.swift` に同じ ID を書く運用です。

---

## 📝 ライセンス

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)

このプロジェクトは **MIT ライセンス** のもとで公開しています。

© 2026 masafykun
