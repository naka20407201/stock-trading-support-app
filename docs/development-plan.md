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

## Step 4: ウォッチリスト画面

目的:

- ユーザーが監視対象の銘柄を一覧できるようにする

作業候補:

- WatchlistItem モデル作成
- ウォッチリスト一覧表示
- 監視中フラグ表示
- 銘柄詳細への遷移
- 空状態の表示

表示方針:

- 「おすすめ」や「推奨」ではなく「ウォッチリスト」と表示する
- 条件一致件数などを出す場合も、売買判断に見えない文言にする

## Step 5: 銘柄追加画面

目的:

- 日経225銘柄候補と任意銘柄をウォッチリストに追加できるようにする

作業候補:

- 日経225銘柄検索
- ウォッチリスト追加
- 任意銘柄追加フォーム
- 銘柄コードと銘柄名の入力チェック
- 重複追加の抑制

## Step 6: 銘柄詳細・投資メモ画面

目的:

- 銘柄ごとのメモを管理できるようにする

作業候補:

- 銘柄詳細画面
- InvestmentMemo モデル作成
- メモ編集画面
- 買いたい理由、売る条件、損切り条件、目標株価、注意点、決算前メモ、自由メモの入力
- 保存・更新処理

注意:

- メモはユーザー自身が入力する判断材料として扱う
- アプリ側がメモを解釈して助言しない

## Step 7: アラート条件設定画面

目的:

- 銘柄ごとに AlertRule を設定できるようにする
- 初期版では、1つの AlertRule は1つの条件式だけを持つ
- 1つの銘柄には複数の AlertRule を登録できる

作業候補:

- AlertRule モデル作成
- 条件一覧画面
- 条件作成・編集画面
- 対象指標、比較演算子、しきい値の入力
- 有効・無効切り替え
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
