# 開発計画

## 方針

初期版は、小さく作って後から拡張できる構成にします。最初から外部API、バックエンド、リアルタイム通知を組み込まず、ローカル保存、モックデータ、手入力値でアプリの骨格を固めます。

各ステップでは、実装とあわせて必要なドキュメント更新を行います。

## Step 1: ドキュメント作成

目的:

- アプリの目的、範囲、設計方針を明確にする
- 売買推奨を行わない方針を明文化する
- データモデルとアラート条件の拡張方針を整理する

成果物:

- README.md
- docs/requirements.md
- docs/design.md
- docs/alert-rule.md
- docs/data-model.md
- docs/development-plan.md
- AGENTS.md

## Step 2: SwiftUIプロジェクト作成 完了

目的:

- XcodeでiOSアプリの土台を作る
- SwiftUI と SwiftData を使う前提を整える

作業候補:

- Xcodeプロジェクト作成
- 最低対応iOSバージョンの決定
- SwiftData の有効化
- アプリ名、Bundle Identifier の仮決定
- ビルド確認

完了内容:

- Xcodeプロジェクト作成済み
- Xcodeプロジェクトの場所: `StockTradingSupportApp/StockTradingSupportApp.xcodeproj`
- アプリ本体の場所: `StockTradingSupportApp/StockTradingSupportApp/`
- SwiftUIアプリの初期画面作成済み
- RootView、WatchlistView、StockSearchView、StockDetailView、SettingsView を作成済み
- SwiftData利用前提の ModelContainer 構成準備済み
- Xcode標準テンプレートの ContentView / Item をアプリ向け初期構成に整理済み
- App、Views、Models、Domain、Services、DataProviders、Repositories、Resources の基本フォルダを作成済み
- 次の Step 3「日経225モック銘柄マスタ作成」に進める状態

ビルド確認方法:

```sh
xcodebuild -project StockTradingSupportApp/StockTradingSupportApp.xcodeproj -scheme StockTradingSupportApp -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/StockTradingSupportAppDerivedData build
```

テスト実行方法:

```sh
xcodebuild -project StockTradingSupportApp/StockTradingSupportApp.xcodeproj -scheme StockTradingSupportApp -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/StockTradingSupportAppDerivedData test
```

Codex実行環境で CoreSimulatorService へ接続できない場合は、Mac上のXcodeで `StockTradingSupportApp/StockTradingSupportApp.xcodeproj` を開き、iPhoneシミュレータを選択してビルド・テスト実行を確認する。

## Step 3: 日経225モック銘柄マスタ作成 完了

目的:

- 初期状態で選択できる銘柄候補を用意する

完了内容:

- 日経225モック銘柄JSONを作成済み
- JSONの場所: `StockTradingSupportApp/StockTradingSupportApp/Resources/nikkei225_mock_stocks.json`
- sourceName、asOfDate、description、stocks のメタ情報を付与済み
- sourceName: `nikkei225Mock`
- asOfDate: `2026-06-07`
- 登録件数: 25件
- 銘柄コード、銘柄名、市場区分、業種、日経225採用フラグ、ユーザー追加フラグを保持
- JSON読み込み用の `StockMasterSeedFile` / `StockMasterSeed` を作成済み
- ローカルJSON読み込み用の `StockMasterProviding` / `LocalStockMasterProvider` を作成済み
- StockSearchView で日経225モック銘柄候補を仮表示済み
- 読み込み失敗時と空データ時の表示を用意済み
- ウォッチリストへの追加・保存は未実装のまま、候補表示の土台だけを作成済み
- 次の Step 4「ウォッチリスト画面」に進める状態

注意:

- 日経225採用銘柄は変更される可能性があるため、初期データは固定のモックとして扱う
- asOfDate により、モック銘柄一覧がいつ時点のものか分かるようにする
- 正式な銘柄マスタ更新は将来機能にする
- このStepでは外部API、リアルタイム株価取得、ウォッチリスト保存、任意銘柄追加は実装しない

ビルド確認方法:

```sh
xcodebuild -project StockTradingSupportApp/StockTradingSupportApp.xcodeproj -scheme StockTradingSupportApp -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/StockTradingSupportAppDerivedData build
```

テスト実行方法:

```sh
xcodebuild -project StockTradingSupportApp/StockTradingSupportApp.xcodeproj -scheme StockTradingSupportApp -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/StockTradingSupportAppDerivedData test
```

## Step 4: ウォッチリスト基盤作成 完了

目的:

- ユーザーが監視対象の銘柄を一覧できるようにする

完了内容:

- 通常のSwift構造体として `WatchlistItem` を作成済み
- `WatchlistItem` は id、銘柄コード、銘柄名、市場区分、業種、日経225標準候補フラグ、作成日時を保持
- `WatchlistRepository` プロトコルを作成済み
- `InMemoryWatchlistRepository` を作成済み
- ウォッチリスト一覧取得、銘柄追加、銘柄削除、銘柄コードによる重複確認の操作を用意済み
- WatchlistView でサンプル監視銘柄を一覧表示済み
- 空状態を ContentUnavailableView で表示する構成を用意済み
- 各行から StockDetailView へ遷移し、銘柄名、銘柄コード、市場区分、業種を表示済み
- Repository と日経225モック銘柄マスタのテストを追加済み
- 次の Step 5「銘柄追加画面」に進める状態

注意:

- このStepでは、日経225候補からの追加ボタン、任意銘柄追加フォーム、SwiftDataによる本格永続化は実装しない
- InMemoryWatchlistRepository は開発用の一時的な保存境界として扱う
- 外部API、リアルタイム株価取得、自動売買、証券口座連携、板情報取得は実装しない

表示方針:

- 「おすすめ」や「推奨」ではなく「ウォッチリスト」と表示する
- 条件一致件数などを出す場合も、売買判断に見えない文言にする

ビルド確認方法:

```sh
xcodebuild -project StockTradingSupportApp/StockTradingSupportApp.xcodeproj -scheme StockTradingSupportApp -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/StockTradingSupportAppDerivedData build
```

テスト実行方法:

```sh
xcodebuild -project StockTradingSupportApp/StockTradingSupportApp.xcodeproj -scheme StockTradingSupportApp -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/StockTradingSupportAppDerivedData test
```

## Step 5: 銘柄追加画面 完了

目的:

- 日経225銘柄候補と任意銘柄をウォッチリストに追加できるようにする

完了内容:

- `WatchlistViewModel` を作成済み
- RootView で `WatchlistViewModel` を保持し、WatchlistView と AddStockView で同じウォッチリスト状態を共有する構成にした
- WatchlistView の右上に銘柄追加ボタンを追加済み
- AddStockView を作成済み
- 日経225モック銘柄候補を LocalStockMasterProvider から読み込み、銘柄名、銘柄コード、市場区分、業種を表示済み
- 未登録銘柄には「追加」ボタン、登録済み銘柄には「登録済み」を表示済み
- 日経225候補から WatchlistItem を作成してウォッチリストに追加できるようにした
- 任意銘柄追加フォームを作成済み
- 任意銘柄では銘柄コード、銘柄名、市場区分、業種を入力できるようにした
- 銘柄コード4桁数字、銘柄名空不可、市場区分空不可、業種空不可、重複コード不可の入力チェックを追加済み
- 任意銘柄追加時は `isNikkei225 = false` とする
- 重複追加は ViewModel / Repository 側でも防ぐ
- UI文言は「銘柄を追加」「日経225候補」「登録済み」「ウォッチリストに追加しました」など中立的な表現に統一した
- SwiftData による本格永続化は未実装で、初期版は InMemoryWatchlistRepository で動作確認する

注意:

- 外部API、リアルタイム株価取得、自動売買、証券口座連携、板情報取得は実装しない
- InMemoryWatchlistRepository の状態はアプリ起動中の確認用であり、永続化は後続対応にする

## Step 6: 銘柄詳細・投資メモ画面 完了

目的:

- 銘柄ごとのメモを管理できるようにする

完了内容:

- `InvestmentMemo` を通常の Swift 構造体として作成済み
- `InvestmentMemo` は id、stockCode、title、body、createdAt、updatedAt を保持する
- stockCode によって WatchlistItem と確認メモを紐づける
- `InvestmentMemoRepository` プロトコルを作成済み
- `InMemoryInvestmentMemoRepository` を作成済み
- 指定銘柄コードのメモ一覧取得、メモ追加、メモ更新、メモ削除の操作を用意済み
- `InvestmentMemoViewModel` を作成済み
- 確認メモのタイトル空不可、本文空可の入力チェックを追加済み
- StockDetailView で銘柄情報と確認メモ一覧を表示済み
- 確認メモがない場合の空状態表示を用意済み
- `InvestmentMemoEditorView` を作成し、メモ追加と編集の両方で利用する構成にした
- メモの追加、編集、削除を画面上から実行できるようにした
- RootView 側で `InMemoryInvestmentMemoRepository` を保持し、WatchlistView 経由で StockDetailView に渡す構成にした
- 任意銘柄コードの入力チェックを半角数字4桁のみ許可する形に厳密化済み
- Repository、ViewModel、入力チェックのテストを追加済み
- 将来 SwiftData 永続化へ差し替えやすいように、View は InMemory 実装を直接操作しない

注意:

- メモはユーザー自身が入力する判断材料として扱う
- アプリ側がメモを解釈して助言しない
- 外部API、リアルタイム株価取得、自動売買、証券口座連携、板情報取得はこのStepでも実装しない
- InMemoryInvestmentMemoRepository の状態はアプリ起動中の確認用であり、永続化は後続対応にする

## Step 7: アラート条件モデル・条件設定画面

目的:

- 銘柄ごとに AlertRule を設定できるようにする
- 初期版では、1つの AlertRule は1つの条件式だけを持つ
- 1つの銘柄には複数の AlertRule を登録できる
- まだリアルタイム判定は行わず、まずは条件を登録できるところまで実装する

作業候補:

- AlertRule モデル作成
- 条件一覧画面
- 条件作成・編集画面
- 対象指標、比較演算子、しきい値の入力
- 有効・無効切り替え
- 条件一覧表示
- 基本比較演算子 greaterThan、greaterThanOrEqual、lessThan、lessThanOrEqual、equal、notEqual の選択

初期版で後続対応にする比較演算子:

- withinDays
- ratioGreaterThanOrEqual

初期優先条件:

- currentPrice と基本比較演算子の組み合わせ

初期版で手入力・モック値として対応余地を残す指標:

- PER
- PBR
- 出来高

後続条件:

- 前日比
- 決算日までの日数
- 目標株価
- 損切りライン
- 出来高の過去平均比較
- 移動平均線、RSI、MACD など

## Step 8: 条件判定ロジック

目的:

- View とデータ取得元から分離した条件判定処理を作る

作業候補:

- StockSnapshot 評価用データ構造の作成
- ManualInputStockDataProvider 相当の境界作成
- MockStockDataProvider 相当の境界作成
- AlertRuleEvaluator の作成
- AlertRuleEvaluator が StockSnapshot と AlertRule だけを入力として受け取る構成にする
- matched / notMatched / unavailable の判定結果
- モックデータまたは手入力値による判定
- 条件一致時の履歴作成

注意:

- 判定結果は売買判断ではなく条件一致の事実として扱う
- データ不足時は「判定不能」とする
- AlertRuleEvaluator は手入力画面、モックデータ、外部APIを直接参照しない

## Step 9: 通知履歴画面

目的:

- 条件一致履歴を確認できるようにする

作業候補:

- AlertHistory モデル作成
- 履歴一覧画面
- 銘柄別履歴表示
- 条件内容、実値、しきい値、日時の表示
- 確認済みフラグ更新

初期版では、iPhone通知はモックまたは画面内表示でよいです。

## Step 10: モックデータから外部API連携への拡張

目的:

- 手入力・モック値から外部データ取得へ段階的に拡張する

作業候補:

- データ取得サービスの抽象化
- ExternalApiStockDataProvider、WebStockDataProvider、RealtimeStockDataProvider 相当の検討
- 外部株価APIの選定
- APIレスポンスを StockSnapshot に変換
- レート制限、取得失敗、欠損値への対応
- 日足データや指標データの保存方針検討

注意:

- 外部APIを追加しても、アプリが売買推奨を行わない方針は維持する
- 外部APIを追加しても AlertRuleEvaluator の入力は StockSnapshot のままにする
- リアルタイム性は要件とコストを確認してから検討する

## Step 11: Web/PC版への拡張方針

目的:

- iPhone版で固めたデータモデルと条件判定の考え方を、Web/PC版に広げる

作業候補:

- バックエンドAPI設計
- PostgreSQL等のDB設計
- ユーザーアカウント管理
- 複数端末同期
- Web UI設計
- PC向け一覧・検索・比較画面

注意:

- SwiftUI固有の実装とドメインロジックを分離しておく
- 条件定義はJSON化しやすい構造にする
- StockSnapshot と DataProvider 相当の境界を、Web/PC版やバックエンドでも再利用できる考え方にしておく
- iPhone版とWeb/PC版で表示文言の方針を統一する

## 次の実装に進む前の注意点

- Xcodeプロジェクトは作成済みのため、次は Step 3 の日経225モック銘柄マスタ作成に進む
- 日経225モックJSONには sourceName、asOfDate、stocks のメタ情報を持たせる
- SwiftDataを使う場合、モデル変更時の移行方針を早めに意識する
- 日経225銘柄マスタは変更されるため、初期データの更新方法を後で設計する
- UI文言は売買推奨に見えないようにレビューする
- 条件判定ロジックは View に直接書かない
- 条件判定ロジックはデータ取得元にも直接依存させない
- 外部API、リアルタイム板情報、自動売買は初期版に入れない
- 大きな変更前には作業計画を提示し、関連ドキュメントも更新する
