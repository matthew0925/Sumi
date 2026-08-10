# ミセルダケ

本人確認書類・個人情報を含む画像を、撮影するだけで自動マスキングするiOSアプリ。

必要な情報だけ、見せる。

## 特徴

- 画像は端末外へ一切送信しない（サーバーなし・オフライン完結）
- 撮影/選択した書類から、Visionで個人情報らしき領域（テキスト・バーコード/QR）を自動検出
- 検出候補はタップでON/OFF、最終確認は必ず人の目を通す設計
- 黒塗り／モザイクの2種類のマスキングスタイル
- フリーミアム（透かし入り無料、透かし解除は買い切り・StoreKit 2）

詳細な企画・仕様は [docs/](docs/) を参照。

## 構成

```
Miserudake/
├── App/            アプリのエントリポイントと画面遷移状態（MaskingFlow）
├── Models/         DocumentType, MaskRegion, MaskingStyle
├── Services/        DetectionService (Vision), ImageMaskingService (Core Graphics/Image), PurchaseManager (StoreKit 2)
└── Features/        Home / DocumentType / Detection / MaskingStyle / Export / Purchase の各画面
```

プロジェクトファイル（`Miserudake.xcodeproj`）は [XcodeGen](https://github.com/yonaskolb/XcodeGen) で `project.yml` から生成している。`.xcodeproj` はコミット済みだが、構成を変更した場合は再生成すること。

## セットアップ

```bash
brew install xcodegen  # 未導入の場合
xcodegen generate
open Miserudake.xcodeproj
```

## ビルド確認（CLI）

```bash
xcodebuild -project Miserudake.xcodeproj -scheme Miserudake \
  -destination 'generic/platform=iOS Simulator' -configuration Debug build
```

## 未着手

- App Store Connectで買い切り商品ID `com.matthew0925.miserudake.watermark_removal` を作成
- 実機の身分証サンプルでの検出精度検証
- アプリアイコン・アクセントカラーの用意
