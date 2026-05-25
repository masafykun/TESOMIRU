# BUILD_LOG - TESOMIRU

> 作業日誌。新しいエントリは先頭に。各エントリに「やったこと」＋「次にやること」を必ず書く。

---

## 2026-05-18: Apple 却下対応 - AI対話・タイムライン実装で4.3差別化

### Apple からのリジェクト（2026-05-18 受信）

提出ID `478ece38-9ee1-43e0-a781-c0a5600115c3` (Build 1.0(2)) が **3項目** で却下:

1. **Guideline 2.1(b)** - IAP がバージョンと一緒に提出されていなかった
2. **Guideline 4.3(b) Spam** - 占い/手相は飽和カテゴリ、差別化が必要 ← 最重要
3. **Guideline 2.1(a)** - iPad で premium 画面がエラー表示（IAPが本番にないため）

### やったこと

**4.3 対応として差別化機能を実装** （コミット `cc2d544`）:

- **AI 対話機能** (`ChatView.swift`)
  - 鑑定結果について追加質問できる
  - 入力欄上に質問サジェスチョン（横スクロールチップ）常時表示
  - 会話履歴は鑑定ごとに永続化
- **タイムライン機能** (`TimelineView.swift`, `ReadingDetailView.swift`)
  - 過去鑑定を UserDefaults で最大50件保存
  - 各鑑定の詳細とチャット履歴を再閲覧可能
- **永続化レイヤ** (`ReadingStore.swift`)
  - SavedReading struct, Codable
- **フリーミアム制限**
  - 鑑定: 無料は **1日2回** まで → 以降 Paywall
  - AI 会話: 無料は **1回** まで → 以降 Paywall
  - タイムライン: **プレミアム限定**
- **バックエンド** `/api/palm-chat` エンドポイント追加 (GPT-4o-mini, max_tokens=250, 80〜120字制限)
- App Store 説明文を新機能訴求版に書き換え（ローカルに案だけ作成、App Store Connect 反映はユーザーの手動作業）

### 次にやること

1. ユーザーが App Store Connect 上で **概要・プロモテキスト** を新版に貼り替え＆保存
2. **ビルド番号を 2 → 3** に上げる（`TESOMIRU.xcodeproj/project.pbxproj` の `CURRENT_PROJECT_VERSION`）
3. Xcode で **Any iOS Device** ターゲットに切り替え → **Product → Archive**
4. Organizer から **Distribute App → App Store Connect → Upload**
5. App Store Connect でビルド処理完了を待つ（TestFlightタブで「準備完了」確認）
6. **「コンプライアンスがありません」**警告が出るので「管理」→「**上記のアルゴリズムのどれでもない**」選択
7. 「配信」タブ → ビルドセクションで **新ビルド (1.0(3))** に変更
8. **IAP も一緒に審査提出**（前回はこれを忘れた）:
   - サブスクリプション「月額プレミアム鑑定」「年額プレミアム鑑定」両方とも審査スクショ＆メモが入っていることを確認
   - バージョン1.0の「App内課金とサブスクリプション」セクションで両方を選択
9. 「審査用に追加」 → 質問に回答 → 提出

---

## 2026-05-16: 初回実装 → App Store 提出

### やったこと

1日で「Apple Developer登録待ちで止まってた」状態から App Store 提出までを完走。

**実装**:
- iOS 26.5 シミュレータ環境構築
- 画面遷移＋API実装 (`ee058d1`)
- AppIcon設定（1024x1024、ChatGPTで生成: 手のひら+金の手相線+宇宙紫グラデ）
- **StoreKit 2 サブスク本実装** (`13fc5eb`): StoreManager + PaywallSheet で月額/年額プラン
- ResultView ↔ StoreManager リアクティブ連携 (`ed5b6e9`)
- 共有スキーム + .gitignore (`e8a6445`)
- 価格を Apple ティアに合わせて月¥500/年¥2,500 (`83f388b`)
- iPhone専用化 (`8e1b91e`, `TARGETED_DEVICE_FAMILY = 1`)

**バックエンド/インフラ**:
- VPS本番 `163.44.117.33` の FastAPI `/root/palm-reading/` を整備
- nginx: `/api/`, `/privacy`, `/support` を tesomiru.1qaz.jp で公開
- プライバシーポリシー/サポートページHTMLをデプロイ
- GPT応答パースエラー修正、プロンプト緩和（手検出を緩く）

**App Store Connect**:
- アプリレコード作成、スクショ7枚（iPhone 17 Pro Max 1320×2868）アップロード
- サブスク商品2件登録（月額・年額）
- アプリ情報、App Privacy、Age Rating 入力
- ビルド アップロード、コンプライアンス設定
- **2026-05-16 20:29 審査提出** (提出ID `478ece38-9ee1-43e0-a781-c0a5600115c3`)

### 次にやること

- 審査結果を待つ（24-48時間想定）
- 却下されたら理由対応、承認されたら自動公開

→ **2026-05-18 に却下通知受信。上のエントリへ続く。**
