# 株式売買支援アプリ

このリポジトリは、ユーザー自身が銘柄ごとに投資判断メモ、確認したい指標、通知条件を登録し、条件に一致した事実を記録するための iPhone アプリ開発用リポジトリです。

本アプリは「この銘柄を買うべき」「今売るべき」「勝率○%」「必ず儲かる」「推奨銘柄」のような売買推奨、利益保証、投資助言に見える表現を行いません。あくまで、ユーザーが自分で定義した条件に一致したことを知らせる投資判断メモ・ユーザー定義条件アラートアプリとして設計します。

## アプリ概要

- ユーザーが監視したい銘柄をウォッチリストに登録する
- 銘柄ごとに確認理由、見直し条件、注意点、決算前メモなどを記録する
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

- 画面は今後の開発に向けた基盤段階です
- RootView が `WatchlistViewModel` を保持し、ウォッチリスト画面と銘柄追加画面で同じウォッチリスト状態を共有します
- ウォッチリスト画面では、SwiftDataに保存された監視銘柄を一覧表示し、銘柄詳細へ遷移できます
- ウォッチリスト画面右上の追加ボタン、または「銘柄を追加」タブから AddStockView を開けます
- 銘柄追加画面では、日経225候補からの追加と任意銘柄の手入力追加ができます
- 任意銘柄追加では、銘柄コード半角数字4桁、銘柄名空不可、市場区分空不可、業種空不可、重複コード不可の入力チェックを行います
- ウォッチリストは `WatchlistRepository` 境界を通して扱い、アプリ本体では `SwiftDataWatchlistRepository` によりSwiftDataへ永続化します
- Previewや一部テストでは `InMemoryWatchlistRepository` を引き続き利用します
- 銘柄詳細画面では、銘柄情報と確認メモの一覧を表示し、確認メモの追加、編集、削除ができます
- 確認メモは `InvestmentMemoRepository` 境界を通して扱い、アプリ本体では `SwiftDataInvestmentMemoRepository` によりSwiftDataへ永続化します
- 確認メモはタイトル空不可、本文は空でも保存できる仕様です
- 銘柄詳細画面では、ユーザー設定条件の一覧を表示し、条件の追加、編集、削除、有効/無効切り替えができます
- ユーザー設定条件は `AlertRuleRepository` 境界を通して扱い、アプリ本体では `SwiftDataAlertRuleRepository` によりSwiftDataへ永続化します
- 条件名は空不可、しきい値は0以上の数値として入力します
- 初期版の条件設定画面では、対象指標は `currentPrice` を選択対象にし、比較演算子は6種類を選択できます
- 銘柄詳細画面では、ユーザー設定条件を固定モック株価に対して評価できます
- 条件評価は `StockSnapshot`、`StockDataProviding`、`AlertRuleEvaluator` の境界を通して行います
- 現時点の `MockStockDataProvider` は、代表的な銘柄コードに固定モック株価を返します
- 固定モック株価の代表コードは `7203`、`6758`、`9984`、`8035`、`9432` です
- 固定モック株価はローカル開発用の値であり、実際の株価や最新データを保証しません
- 条件評価結果は「条件に一致」「条件未一致」「評価できません」「無効」として表示します
- 条件に一致した場合のみ、`AlertMatchHistory` として条件一致履歴を作成します
- 同じ `snapshot.capturedAt` と条件IDの組み合わせでは、連続評価しても重複履歴を作成しません
- 条件一致履歴は `AlertMatchHistoryRepository` 境界を通して扱い、アプリ本体では `SwiftDataAlertMatchHistoryRepository` によりSwiftDataへ永続化します
- 通知送信は未実装です
- SwiftData用Recordモデルとして `WatchlistItemRecord`、`InvestmentMemoRecord`、`AlertRuleRecord`、`AlertMatchHistoryRecord` を用意しています
- Step 10時点で、ウォッチリスト、確認メモ、ユーザー設定条件、条件一致履歴はSwiftData Repositoryへ差し替え済みです
- Step 11前半では、SwiftData Repository の取得処理を `FetchDescriptor` の predicate / sort に寄せ、読み込み失敗時にViewModel経由で中立的なエラー文言を表示できるようにしました
- 削除処理が失敗した場合は、ViewModelで「データを削除できませんでした」と表示できるようにしました。ただし、条件一致履歴の全削除は既存プロトコルの戻り値を変えず、失敗理由の詳細表示は後続課題です
- Previewや一部テストでは `InMemoryInvestmentMemoRepository`、`InMemoryAlertRuleRepository`、`InMemoryAlertMatchHistoryRepository` を引き続き利用します
- `MockStockDataProvider` は、固定モック値として currentPrice、PER、PBR、出来高を `StockSnapshot` に含められる土台を持ちます
- 条件追加画面で選択できる対象指標は、現時点では引き続き currentPrice のみです。PER、PBR、出来高のUI選択解放は後続対応です
- 固定モック値はローカル開発用の値であり、実際の株価、指標値、出来高、最新データを保証しません
- `.gitignore` で `.DS_Store`、Xcodeユーザー状態、DerivedData、ビルド生成物を除外します
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
