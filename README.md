# 株式売買支援アプリ

このリポジトリは、ユーザー自身が銘柄ごとに投資判断メモ、確認したい指標、通知条件を登録し、条件に一致した事実を記録するための iPhone アプリ開発用リポジトリです。

本アプリは「この銘柄を買うべき」「今売るべき」「勝率○%」「必ず儲かる」「推奨銘柄」のような売買推奨、利益保証、投資助言に見える表現を行いません。あくまで、ユーザーが自分で定義した条件に一致したことを知らせる投資判断メモ・ユーザー定義条件アラートアプリとして設計します。

## アプリ概要

- ユーザーが監視したい銘柄をウォッチリストに登録する
- 銘柄ごとに買いたい理由、売る条件、損切り条件、目標株価、注意点などをメモする
- 株価、PER、PBR、出来高、決算日などのユーザー入力値またはモック値をもとに、ユーザー定義の条件一致を記録する
- 条件一致時の履歴を保存し、ユーザーが後から確認できるようにする
- 初期版では日本株を対象とし、日経225採用銘柄を標準候補として扱う
- 日経225以外の任意銘柄も、銘柄コードと銘柄名を手入力して追加できるようにする

## 技術構成

初期版の想定技術構成は以下です。

- iOS アプリ: Swift / SwiftUI
- ローカル保存: SwiftData を第一候補
- 開発環境: MacBook / Xcode / Codex
- 初期データ: 日経225採用銘柄のローカルJSONまたはモックデータ。`sourceName` と `asOfDate` などのメタ情報を持たせる方針
- 条件判定: View から分離した `AlertRuleEvaluator` として設計
- 評価用データ: 手入力値またはモック値から `StockSnapshot` を生成し、条件判定へ渡す
- データ取得境界: 初期版では `ManualInputStockDataProvider` / `MockStockDataProvider` 相当、将来版では外部API用Providerに差し替える
- 外部連携: 初期版では外部株価API、リアルタイム株価、板情報、自動売買を扱わない

## 初期版の範囲

初期版では、小さく動くローカルアプリを目指します。

- 日経225銘柄マスタ候補の表示
- 任意銘柄の手入力追加
- ウォッチリスト管理
- 銘柄ごとの投資メモ管理
- 1つの AlertRule が1つの条件式を持つアラート設定
- 1つの銘柄に対する複数 AlertRule の登録
- 基本比較演算子の対応: greaterThan、greaterThanOrEqual、lessThan、lessThanOrEqual、equal、notEqual
- 初期優先指標: currentPrice
- 手入力・モック値として対応余地を残す指標: per、pbr、volume
- モック値または手入力値による条件判定
- 条件一致履歴の保存
- 確認済みフラグの管理

初期版では、以下は実装しません。

- 自動売買
- 証券口座連携
- リアルタイム株価取得
- リアルタイム板情報取得
- 板読みアラート
- 売買推奨
- 利益保証
- 勝率表示
- 有料投資助言のように見える機能
- SNS投稿機能
- 他ユーザーへの銘柄推奨機能
- 複雑なAI予測機能

## 将来的な拡張方針

将来的には、以下を追加できるように設計上の余地を残します。

- 外部株価API連携
- 日足データ取得
- PER、PBR、配当利回りなどの自動更新
- 出来高の過去平均比較
- 移動平均線、RSI、MACD などのテクニカル指標
- 決算日自動取得
- iPhone通知
- Web版、PC版
- バックエンド化
- PostgreSQL などのDB利用
- APIサーバー
- ユーザーアカウント管理
- 複数端末同期
- 将来的な板情報対応

## 起動方法

Xcodeプロジェクトは作成済みです。現時点の画面は、今後の開発に向けた仮画面です。

プロジェクト構成:

- Xcodeプロジェクト: `StockTradingSupportApp/StockTradingSupportApp.xcodeproj`
- アプリ本体: `StockTradingSupportApp/StockTradingSupportApp/`
- App entry: `StockTradingSupportApp/StockTradingSupportApp/App/`
- 画面: `StockTradingSupportApp/StockTradingSupportApp/Views/`
- SwiftDataモデル: `StockTradingSupportApp/StockTradingSupportApp/Models/`
- Domain: `StockTradingSupportApp/StockTradingSupportApp/Domain/`
- Services: `StockTradingSupportApp/StockTradingSupportApp/Services/`
- DataProviders: `StockTradingSupportApp/StockTradingSupportApp/DataProviders/`
- Repositories: `StockTradingSupportApp/StockTradingSupportApp/Repositories/`
- Resources: `StockTradingSupportApp/StockTradingSupportApp/Resources/`

日経225モック銘柄マスタ:

- JSON: `StockTradingSupportApp/StockTradingSupportApp/Resources/nikkei225_mock_stocks.json`
- sourceName: `nikkei225Mock`
- asOfDate: `2026-06-07`
- 登録件数: 25件
- このデータはローカル開発用の固定モックデータであり、最新の日経225採用銘柄を保証しません
- 初期版では外部APIやリアルタイムデータ取得を行わず、アプリ内のローカルJSONから標準候補を読み込みます
- 将来、外部マスタやAPI取得に差し替える場合は、DataProvider相当の境界を通して銘柄候補を取得します

開発環境:

- 推奨Xcodeバージョン: Xcode 26.4.1 以降
- 最低対応iOSバージョン: iOS 26.4
- SwiftUI / SwiftData を利用

ローカル実行手順:

1. Xcodeで `StockTradingSupportApp/StockTradingSupportApp.xcodeproj` を開く
2. Scheme に `StockTradingSupportApp` を選択する
3. 実行先に iPhone シミュレータを選択する
4. Run を実行する

テスト実行手順:

1. Xcodeで `StockTradingSupportApp/StockTradingSupportApp.xcodeproj` を開く
2. Scheme に `StockTradingSupportApp` を選択する
3. Test を実行する

コマンドラインで確認する場合:

```sh
xcodebuild -project StockTradingSupportApp/StockTradingSupportApp.xcodeproj -scheme StockTradingSupportApp -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/StockTradingSupportAppDerivedData build
xcodebuild -project StockTradingSupportApp/StockTradingSupportApp.xcodeproj -scheme StockTradingSupportApp -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/StockTradingSupportAppDerivedData test
```

Codex実行環境で CoreSimulatorService への接続やユーザーキャッシュ領域へのアクセスが制限される場合は、Mac上のXcodeから上記手順で実行・テストしてください。

現時点の注意:

- 初期画面は仮画面です
- 銘柄追加画面では、日経225モック銘柄候補の仮表示までを実装しています
- ウォッチリストへの追加・保存は未実装です
- SwiftData利用前提の構成は残していますが、本格的な永続化モデルは未実装です
- SwiftDataの詳細モデルを追加するまでは、ModelContainer 用の最小プレースホルダモデルを利用します
- 外部APIやリアルタイムデータ取得は行いません
- 自動売買、証券口座連携、板情報取得は行いません

## ドキュメント

- [要件定義](docs/requirements.md)
- [設計](docs/design.md)
- [アラート条件設計](docs/alert-rule.md)
- [データモデル設計](docs/data-model.md)
- [開発計画](docs/development-plan.md)
- [Codex作業ルール](AGENTS.md)

## 注意事項

- 本アプリは投資判断を補助するためのメモ・条件一致通知アプリです。
- 本アプリは売買推奨、投資助言、利益保証、勝率提示を行いません。
- 条件一致は、ユーザーが設定したルールに対して入力値または取得値が一致した事実を示すものです。
- 実際の売買判断はユーザー自身が行う前提です。
- 将来、外部APIや通知、バックエンドを追加する場合も、この方針を維持します。
