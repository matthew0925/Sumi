# ASOスクリーンショット制作ガイド

## 構図

実画面を主役にしたdevice-heroレイアウトを採用します。

- 上約1/5：短いベネフィット見出し＋補足1行
- 下約4/5：iPhone画面を左右余白を抑えて大きく配置
- 背景：Sumiのペーパーカラーを画面端まで敷くfull-bleed
- 端末：下端を少し画面外へ出し、アプリ画面を最大化

「full-bleed」は背景や画像を端まで敷く表現を指します。今回の情報設計は、短いコピーから大きな実画面へすぐ視線が移る「device-hero構図」です。

## 2026年版の掲載順

検索結果に表示される最初の3枚だけで、価値・仕組み・完了結果が伝わる順番にします。

1. `個人情報を隠して / 安心して共有` — 最終結果を先に見せる
2. `住所も番号も / すばやく発見` — 自動検出と手動確認を見せる
3. `位置情報を残さず / 安全に保存・共有` — 安全な書き出しを見せる
4. `端末内で完結 / 外部送信なし` — ライトモードのホーム画面でプライバシーを見せる
5. `暗い場所でも / 目にやさしく` — 編集画面でダークモード対応を見せる

見出しは句読点なしの2行、補足は句点なしの1行に統一します。見出しは短いベネフィット表現、補足は自然な「です・ます」調の説明文にします。中黒は並列する機能名にだけ使います。

## 生成方法

Simulatorで撮影したPNGを入力にして、App Store用1290×2796px画像を生成します。

```bash
swift Scripts/generate_aso_screenshot.swift \
  --input work/screenshots/style.png \
  --output docs/aso-screenshots/01-core-value.jpg \
  --headline $'個人情報を隠して\n安心して共有' \
  --subheadline "黒塗りとモザイクで必要な部分だけを保護します"
```

見出しは2行以内、補足は1行を基本とし、説明を増やすよりアプリ画面を大きく見せます。

## 運用

- App Storeには6.9インチ用の1290×2796px・アルファチャンネルなしのJPEGを登録する
- 1枚目は価値訴求、2枚目は検出、3枚目は書き出しの順番を維持する
- App Store ConnectのProduct Page Optimizationで、1枚目のコピーと画面の組み合わせをA/Bテストする
- 日本語以外は直訳せず、各ロケールで2行以内に再構成する
- UIが変わったら実画面を再撮影し、架空の画面を使わない
- Simulatorのステータスバーを9:41・バッテリー100%に固定し、全画像で時刻を統一する

参考：

- https://developer.apple.com/app-store/product-page/
- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/
