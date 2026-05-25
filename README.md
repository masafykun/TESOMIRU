# TESOMIRU - AI手相鑑定アプリ

写真を撮るだけでAIが手相を鑑定。さらにその結果についてAI占い師と対話できる、iOS手相アプリ。

## 現状

- **2026-05-16** 初回 App Store 審査提出
- **2026-05-18** Apple から 4.3(b) Spam 却下 → AI対話・タイムライン機能を追加して再提出準備中

詳細な進捗は [BUILD_LOG.md](BUILD_LOG.md) を参照。

## 構成

### iOS アプリ
- **場所**: 当フォルダ `~/XcodeProject/TESOMIRU/`
- **言語**: Swift / SwiftUI
- **Bundle ID**: `org.masafy.TESOMIRU`
- **Team ID**: `8XG6989CB4`
- **Deployment Target**: iOS 26.4+
- **Device**: iPhone専用（TARGETED_DEVICE_FAMILY = 1）
- **Signing**: Automatic

### バックエンド
- **稼働VPS**: `163.44.117.33` (port 43222 SSH, port 8010 内部)
- **コード**: `/root/palm-reading/main.py`
- **サービス**: `systemd: palm-reading.service`
- **フレームワーク**: FastAPI + uvicorn
- **AI**: OpenAI GPT-4o（鑑定）/ GPT-4o-mini（対話）
- **画像保存**: しない（メモリ処理のみ）

### 公開URL
- API: https://tesomiru.1qaz.jp/api/palm-reading (POST, JPEG)
- API: https://tesomiru.1qaz.jp/api/palm-chat (POST, JSON)
- プライバシーポリシー: https://tesomiru.1qaz.jp/privacy
- サポート: https://tesomiru.1qaz.jp/support

## 主要画面

| ファイル | 役割 |
|---|---|
| `HomeView.swift` | スタート画面、鑑定回数表示、タイムライン導線 |
| `CaptureView.swift` | 手のひら撮影/選択 |
| `AnalyzingView.swift` | 解析中アニメーション、解析成功時に鑑定回数加算 |
| `ResultView.swift` | 鑑定結果、AI質問導線、Paywall呼び出し |
| `PaywallSheet.swift` | サブスク販売UI、StoreKit 2 |
| `ChatView.swift` | AI占い師との対話 |
| `TimelineView.swift` | 過去鑑定一覧（プレミアム限定） |
| `ReadingDetailView.swift` | 過去鑑定詳細＋チャット履歴 |

## データ・ロジック層

| ファイル | 役割 |
|---|---|
| `PalmReadingService.swift` | API呼び出し（analyze, chat）、モデル定義 |
| `StoreManager.swift` | StoreKit 2 ラッパー、サブスク状態管理 |
| `ReadingStore.swift` | 過去鑑定の永続化（UserDefaults JSON）、日次回数カウンタ |
| `Products.storekit` | シミュレータ用 StoreKit Configuration |

## サブスク

- 商品グループ: `Premium`
- 月額: `org.masafy.TESOMIRU.premium.monthly` (¥500/月)
- 年額: `org.masafy.TESOMIRU.premium.yearly` (¥2,500/年, 実質¥208/月相当)

## フリーミアム制限

| 機能 | 無料プラン | プレミアム |
|---|---|---|
| 手相鑑定 | 1日2回まで | 無制限 |
| AI 会話 | 1回まで | 無制限 |
| 各線詳細 | ロック（概要のみ） | 全解放 |
| タイムライン | 不可 | 可 |
| チャット履歴保存 | 不可 | 可 |

## ビルド & 実行

### Simulator（開発）

```bash
# Xcode で開く
open TESOMIRU.xcodeproj

# またはCLIから（StoreKit Configurationを読みたいなら IDE推奨）
xcodebuild -project TESOMIRU.xcodeproj \
  -scheme TESOMIRU \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  build
```

**StoreKit Configurationが読まれない問題**: Xcode IDE経由じゃないと `Products.storekit` が読まれず、Paywallで「プラン情報を取得できませんでした」となる。本番では問題なし。

### Release（提出用）

```
1. Xcodeでターゲットを「Any iOS Device (arm64)」に
2. CURRENT_PROJECT_VERSION を上げる
3. Product → Archive
4. Organizer → Distribute App → App Store Connect → Upload
```

## バックエンド作業（VPS）

```bash
# SSH接続
ssh -i ~/.ssh/key-2026-05-01-20-25.pem -p 43222 root@163.44.117.33

# サービス再起動
systemctl restart palm-reading

# ログ
journalctl -u palm-reading -n 30 --no-pager

# 設定ファイル
/root/palm-reading/main.py        # FastAPI
/etc/nginx/sites-available/palm-reading  # nginx
```

## App Store Connect

- アプリレコード: TESOMIRU - AI手相鑑定（Bundle: org.masafy.TESOMIRU）
- カテゴリ: ライフスタイル / エンターテインメント
- 年齢制限: 4+ または 9+（占いカテゴリで微変動）
- スクショ場所: `screenshots/iphone-17-pro-max-6.9/` (7枚)
- 説明文ドラフト: `app-store-content/01_metadata.md`
- 審査ノートドラフト: `app-store-content/03_review_info.md`

## .gitignoreされてるもの

- `screenshots/` （個人写真含むためGitHub非公開）
- `app-store-content/` （価格・売上情報含む）
- `**/xcuserdata/`
- `DerivedData/`

## ハマりポイント記録

- Apple価格ティアは固定。¥480/¥2,400は存在しない → ¥500/¥2,500採用
- App Store Connect の説明文で罫線記号(`━━`)・絵文字の一部が「無効」判定
- TARGETED_DEVICE_FAMILY が "1,2" だと iPad スクショ必須。iPhone専用にするなら "1"
- iOS 26.5 でビルドするには iOS 26.5 simruntime が必要
- ChatGPTで AppIcon 生成時は「角丸なし、透過なし、1024x1024 PNG、テキストなし」を強調

## 関連ドキュメント

- [BUILD_LOG.md](BUILD_LOG.md) - 作業日誌
- [CLAUDE.md](CLAUDE.md) - Claude セッション運用指示
- [app-store-content/](app-store-content/) - App Store 提出用テキストドラフト
- [screenshots/](screenshots/) - App Store提出スクショ
