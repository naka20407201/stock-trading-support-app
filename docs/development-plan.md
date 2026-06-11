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

## Step 7: アラート条件モデル・条件設定画面 完了

目的:

- 銘柄ごとに AlertRule を設定できるようにする
- 初期版では、1つの AlertRule は1つの条件式だけを持つ
- 1つの銘柄には複数の AlertRule を登録できる
- まだリアルタイム判定は行わず、まずは条件を登録できるところまで実装する

完了内容:

- `AlertMetric` を作成済み
- 初期選択対象は `currentPrice` とし、将来 `per`、`pbr`、`volume` を選択対象へ広げやすい構成にした
- `ComparisonOperator` を作成済み
- 初期版の基本比較演算子 greaterThan、greaterThanOrEqual、lessThan、lessThanOrEqual、equal、notEqual を定義済み
- `AlertRule` を通常の Swift 構造体として作成済み
- `AlertRule` は id、stockCode、name、metric、comparisonOperator、thresholdValue、isEnabled、createdAt、updatedAt を保持する
- stockCode によって WatchlistItem とユーザー設定条件を紐づける
- `AlertRuleRepository` プロトコルを作成済み
- `InMemoryAlertRuleRepository` を作成済み
- 指定銘柄コードの条件一覧取得、条件追加、条件更新、条件削除の操作を用意済み
- `AlertRuleViewModel` を作成済み
- 条件名空不可、しきい値は数値、しきい値は0以上の入力チェックを追加済み
- `AlertRuleEditorView` を作成し、条件追加と編集の両方で利用する構成にした
- `AlertRuleListView` を作成し、StockDetailView に組み込んだ
- 銘柄詳細画面で条件一覧、条件追加、条件編集、条件削除、有効/無効切り替えができるようにした
- RootView 側で `InMemoryAlertRuleRepository` を保持し、WatchlistView 経由で StockDetailView に渡す構成にした
- 複数件削除時の index ズレを避けるため、WatchlistView と StockDetailView の削除処理で先に削除対象IDを配列化するように修正済み
- Repository、ViewModel、比較演算子、入力チェックのテストを追加済み
- 将来 SwiftData 永続化へ差し替えやすいように、View は InMemory 実装を直接操作しない

注意:

- このStepでは条件の評価、通知送信、条件一致履歴の作成は実装しない
- 条件はユーザー自身が設定する確認条件として扱う
- アプリ側が条件内容を売買判断として解釈しない
- 外部API、リアルタイム株価取得、自動売買、証券口座連携、板情報取得はこのStepでも実装しない
- InMemoryAlertRuleRepository の状態はアプリ起動中の確認用であり、永続化は後続対応にする

初期版で後続対応にする比較演算子:

- withinDays
- ratioGreaterThanOrEqual

初期対応条件:

- currentPrice、PER、PBR、出来高と基本比較演算子の組み合わせ

後続条件:

- 前日比
- 決算日までの日数
- 目標株価
- 損切りライン
- 出来高の過去平均比較
- 移動平均線、RSI、MACD など

## Step 8: 条件判定ロジック・モック評価（完了）

目的:

- View とデータ取得元から分離した条件判定処理を作る
- 外部APIやリアルタイム取得を使わず、固定モック株価でユーザー設定条件を評価できるようにする

完了内容:

- `StockSnapshot` 評価用データ構造を作成済み
- `StockDataProviding` と `MockStockDataProvider` を作成済み
- `MockStockDataProvider` は代表銘柄コードに固定モック株価を返す
- `AlertEvaluationResult` を作成し、matched / notMatched / unavailable / disabled を表現済み
- `AlertRuleEvaluator` を作成し、`AlertRule` と `StockSnapshot` だけを入力として評価する構成にした
- greaterThan、greaterThanOrEqual、lessThan、lessThanOrEqual、equal、notEqual の6種類を評価済み
- 対象指標値がない場合は unavailable、無効条件は disabled として扱う
- `AlertMatchHistory`、`AlertMatchHistoryRepository`、`InMemoryAlertMatchHistoryRepository` を作成済み
- `AlertEvaluationViewModel` を作成し、条件一覧取得、Snapshot取得、評価、条件一致履歴作成を集約済み
- 銘柄詳細画面に条件評価結果と条件一致履歴を表示済み
- 条件に一致した場合のみ履歴を作成する
- 同じ `snapshot.capturedAt` と条件IDの組み合わせでは、連続評価しても重複履歴を作成しない
- `AlertRuleViewModel.toggleEnabled(id:)` はエラーを握りつぶさず `throws` で呼び出し側に伝える構成に修正済み
- 条件値の表示は `AlertMetric.formattedValue(_:)` に寄せ、表示形式を指標ごとに整理済み

注意:

- 判定結果は売買判断ではなく条件一致の事実として扱う
- データ不足時は「判定不能」とする
- AlertRuleEvaluator は手入力画面、モックデータ、外部APIを直接参照しない
- このStepでは通知送信は実装しない
- 固定モック株価はローカル開発用の値であり、実際の株価や最新データを保証しない

## Step 9: SwiftData永続化（ウォッチリスト完了）

目的:

- Repository境界を維持したまま、InMemory実装からSwiftData永続化へ段階的に差し替える

完了内容:

- SwiftData用Recordモデルとして `WatchlistItemRecord` を追加済み
- 後続永続化に備えて `InvestmentMemoRecord`、`AlertRuleRecord`、`AlertMatchHistoryRecord` を追加済み
- `WatchlistItem` と `WatchlistItemRecord` の相互変換を追加済み
- `SwiftDataWatchlistRepository` を追加済み
- `WatchlistRepository` プロトコルを維持したまま、アプリ本体のウォッチリストをSwiftDataへ差し替え済み
- View は SwiftData の `ModelContext` を直接操作せず、Repository / ViewModel 経由の構成を維持済み
- `InMemoryWatchlistRepository` はPreviewとテスト用に維持済み
- `AlertEvaluationViewModel` の条件一致履歴保存失敗時にエラーメッセージを保持するよう修正済み
- `AlertEvaluationView` で評価前と固定モック株価未登録時の表示を分離済み
- `AlertRuleEditorView` に、初期版では現在値のみ設定できる旨を追記済み
- `MockStockDataProvider` は通常利用時に `snapshot(for:)` 実行時刻を使い、テストでは固定時刻を注入できる構成に修正済み
- SwiftData Repository、Record変換、履歴保存失敗、モックSnapshot時刻方針のテストを追加済み

注意:

- SwiftDataモデルを追加しても、銘柄マスタ、ウォッチリスト、確認メモ、ユーザー設定条件、条件一致履歴の責務を混ぜない
- 条件一致履歴は条件変更後も意味が変わらないように、条件内容のスナップショットを保存する
- 外部API、リアルタイム株価、通知送信、自動売買、証券口座連携、板情報取得はこのStepでも実装しない

残課題:

- 確認メモはまだ `InMemoryInvestmentMemoRepository` で扱う
- ユーザー設定条件はまだ `InMemoryAlertRuleRepository` で扱う
- 条件一致履歴はまだ `InMemoryAlertMatchHistoryRepository` で扱う
- 日経225モック銘柄マスタ自体はローカルJSONのままで、SwiftDataへの取り込みは未実装
- 初回起動時のサンプルデータ投入方針は未実装

## Step 10: SwiftData永続化の対象拡張（完了）

目的:

- ウォッチリスト以外のユーザーデータも、Repository境界を維持したままSwiftDataへ差し替える

完了内容:

- `InvestmentMemoRecord` と `InvestmentMemo` の相互変換を追加済み
- `AlertRuleRecord` と `AlertRule` の相互変換を追加済み
- `AlertMatchHistoryRecord` と `AlertMatchHistory` の相互変換を追加済み
- `SwiftDataInvestmentMemoRepository` を追加済み
- `SwiftDataAlertRuleRepository` を追加済み
- `SwiftDataAlertMatchHistoryRepository` を追加済み
- アプリ本体の確認メモ、ユーザー設定条件、条件一致履歴をSwiftData Repositoryへ差し替え済み
- View は SwiftData の `ModelContext` を直接操作せず、Repository / ViewModel 経由の構成を維持済み
- `InMemoryInvestmentMemoRepository`、`InMemoryAlertRuleRepository`、`InMemoryAlertMatchHistoryRepository` はPreviewとテスト用に維持済み
- 条件一致履歴は、条件名、対象指標、比較演算子、しきい値、観測値、データソースをスナップショットとして保存済み
- `AlertRuleRecord`、`AlertMatchHistoryRecord` のRawValue復元に失敗してもクラッシュせず、復元できないRecordを読み飛ばす構成にした
- SwiftData Repository の取得失敗時UI改善はTODOとして残し、後続でViewModelへエラーを伝える方針にした
- 銘柄コードの一意性は現時点ではRepository側で抑制し、将来SwiftData側制約や移行時の重複統合方針を検討することを設計書に追記済み
- Record変換、SwiftData Repository、ViewModel経由、RawValue復元失敗ケースのテストを追加済み

注意:

- 外部API、リアルタイム株価、通知送信、自動売買、証券口座連携、板情報取得はこのStepでも実装しない
- View が SwiftData の `ModelContext` を直接操作しない構成を維持する

残課題:

- 日経225モック銘柄マスタ自体はローカルJSONのままで、SwiftDataへの取り込みは未実装
- 初回起動時のサンプルデータ投入方針は未実装
- SwiftData Repository の取得失敗時に、空状態と読み込み失敗をUI上で分ける改善は後続対応
- SwiftData側の一意性制約やデータ移行時の重複統合方針は後続対応

## Step 11: 手入力評価データと指標UI解放（完了）

目的:

- 外部API連携へ進む前に、ユーザーが評価用データを手入力できるようにする
- currentPrice だけでなく PER、PBR、出来高もユーザー設定条件の対象指標として扱えるようにする
- 手入力値、固定モック値、将来の外部取得値を StockSnapshot に変換して評価する境界を整理する

完了内容:

- `ManualStockSnapshotInput` を追加し、currentPrice、PER、PBR、出来高を任意入力できるDomainモデルを用意
- `ManualStockSnapshotInputRecord` とDomainモデルの相互変換を追加
- `ManualStockSnapshotInputRepository`、`InMemoryManualStockSnapshotInputRepository`、`SwiftDataManualStockSnapshotInputRepository` を追加
- App entry の SwiftData Schema に `ManualStockSnapshotInputRecord` を登録し、アプリ本体では手入力評価データをSwiftDataへ保存
- `ManualInputStockDataProvider` を追加し、手入力評価データを StockSnapshot に変換
- `FallbackStockDataProvider` を追加し、有効な手入力評価データがある場合は手入力値を優先し、未登録または全項目空欄の場合は固定モック値へフォールバックする構成にした
- StockDetailView に評価用データセクションを追加し、現在値、PER、PBR、出来高の表示、追加、編集、削除を行えるようにした
- `ManualStockSnapshotInputEditorView` と `ManualStockSnapshotInputViewModel` を追加し、空欄は nil、数値以外と0未満はエラーとして扱う
- 条件追加画面で `currentPrice`、`per`、`pbr`、`volume` を選択できるようにした
- 未入力または欠損している指標を使う条件は「評価できません」として扱う
- 条件一致履歴には、対象指標、比較演算子、しきい値、観測値、データソースを従来通り保存する
- 手入力評価データ、SwiftData Repository、Provider優先順位、4指標評価、未入力指標の判定不能、入力バリデーションのテストを追加
- 補修として、全項目空欄の手入力評価データは有効な手入力評価データなしとして扱い、固定モック値へのフォールバックを妨げないようにした
- 全項目空欄の保存は許可せず、削除したい場合は削除ボタンを使う方針にした

注意:

- 外部API、リアルタイム株価、通知送信、自動売買、証券口座連携、板情報取得はこのStepでも実装しない
- 条件一致は売買判断ではなく、ユーザー設定条件と入力値またはモック値の照合結果として扱う
- 未入力指標は推測せず、判定不能として扱う
- 全項目空欄の手入力評価データは保存しない
- 条件一致履歴の全削除は既存プロトコルの戻り値を変えていないため、削除失敗理由の詳細表示は後続対応

## Step 12: 外部API連携の第一段階（完了）

目的:

- 手入力値・固定モック値で固めた StockSnapshot / DataProvider / AlertRuleEvaluator の境界を維持したまま、外部データ取得へ進む
- 実通信の前に、外部APIレスポンス相当のデータを `StockSnapshot` に変換する土台を作る

完了内容:

- 外部データ取得候補メモ `docs/external-data-provider.md` を追加済み
- `ExternalStockSnapshotResponse` を追加し、外部APIレスポンス相当DTOを用意済み
- `ExternalStockSnapshotResponse` から `StockSnapshot` への変換処理を追加済み
- currentPrice、PER、PBR、出来高のうち少なくとも1つがある場合だけ有効な `StockSnapshot` として扱う
- 全指標が nil の外部API疑似レスポンスは有効な `StockSnapshot` として扱わない
- `ExternalApiStockDataProvider` はネットワーク通信を行わず、ローカルに渡された疑似レスポンスから `StockSnapshot` を返せるようにした
- `CompositeStockDataProvider` を追加し、複数Providerを順番に試せるようにした
- 評価データ取得の設計を、有効な手入力評価データ、外部API由来データ、固定モック値の順に整理済み
- APIレスポンスを直接 AlertRuleEvaluator に渡さず、DataProvider境界で StockSnapshot に変換する方針を明記済み
- APIキー未設定、取得失敗、レート制限、欠損値はDataProvider層で扱い、ViewModel/UIでは中立的なエラーまたは判定不能として扱う方針を整理済み
- DTO変換、外部API疑似Provider、3段階フォールバック、外部API由来Snapshotでの条件評価のテストを追加済み

注意:

- 外部APIを追加しても、アプリが売買推奨を行わない方針は維持する
- 外部APIを追加しても AlertRuleEvaluator の入力は StockSnapshot のままにする
- リアルタイム性は要件とコストを確認してから検討する
- Step 12 では実ネットワーク通信、APIキー保存、認証、URLSession通信、レート制限処理、キャッシュ、バックグラウンド更新は実装しない

残課題:

- 採用する外部APIと利用プランの確定
- APIキー保存方式の設計
- URLSession通信とレスポンスパース
- レート制限、取得失敗、欠損値の画面表示
- 外部取得値のキャッシュ方針
- バックグラウンド更新の要否
- 取得データの保存範囲
- 外部API利用規約に合わせた表示・再配布制約の確認

## Step 12.5: 無料API前提の外部API設計確定（完了）

目的:

- 無料APIを前提に、実通信へ進む前のAPI選定方針とProvider責務を整理する
- 日本株、日経225、東証銘柄コードとの相性を重視して候補を比較する
- APIキー管理、URLSession通信層、DTO変換、キャッシュ、エラー表示の方針を決める

完了内容:

- 初期方針を「まずは無料APIで開始する」と明記
- 第一候補を J-Quants とし、採用確定前に公式情報で無料プラン、利用規約、再配布制約、レート制限、取得可能期間を再確認する方針にした
- Alpha Vantage と Finnhub は代替候補として残し、日本株コード体系や無料枠の制限リスクを整理
- 無料APIで取得する対象を currentPrice、PER、PBR、出来高に整理
- 無料APIでは難しい可能性がある対象として、リアルタイム株価、直近当日データ、高頻度更新、長期間一括取得などを整理
- 有料APIは、無料APIのレート制限、取得範囲、遅延、任意銘柄対応、利用規約の制約が明確な場合だけ後続検討にする
- `ExternalApiStockDataProvider` と疑似レスポンスProviderの責務を分離
- `StubExternalStockDataProvider` を疑似レスポンス用Providerとして追加
- `ExternalApiStockDataProvider` は将来の `ExternalStockDataClient` を使うProviderとして整理
- `JQuantsStockDataClient` と `JQuantsStockDataMapper` を設計スタブとして追加
- 通常起動時のProviderチェーンから空の外部API Providerを外し、手入力評価データ、固定モック値の順にした
- 開発・テスト用では、手入力評価データ、疑似外部データ、固定モック値の3段階フォールバックを維持
- APIキーをソースコードやGitHubに含めない方針を明記
- APIキー未設定時は外部APIを使わず、手入力値または固定モック値で評価できる方針を明記
- レート制限、通信失敗、銘柄コード未対応、一部指標欠損、全指標欠損、データ遅延、キャッシュ利用時のUI表示方針を整理
- 無料APIのレート制限に備え、currentPrice、PER、PBR、出来高、capturedAt、sourceName のキャッシュ方針を整理
- APIキー未設定、レート制限相当、疑似外部Provider、3段階フォールバックのテストを追加済み

注意:

- このStepでは実際のURLSession通信、APIキー保存、認証、キャッシュ保存、バックグラウンド更新は実装しない
- 有料API契約、有料API前提の実装、課金前提の設計は行わない
- 外部APIを追加しても、AlertRuleEvaluator の入力は `StockSnapshot` のまま維持する
- 外部データ取得状態のUI文言は中立的にし、売買判断を促す表現は使わない

残課題:

- J-Quants無料プランの正確なAPIコール制限、取得可能期間、直近データ遅延、対象エンドポイントを公式情報で再確認する
- J-QuantsでPER / PBRを直接取得できるか、または算出に必要なデータを無料枠で取得できるか確認する
- APIキーのローカル設定方式を決める
- URLSession通信層とレスポンスパースを実装する
- 外部取得値のキャッシュRecord設計を決める
- レート制限時の再試行や待機方針を決める

## Step 13: Web/PC版への拡張方針

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

- Step 12 で外部API疑似レスポンスから `StockSnapshot` へ変換する土台は完了したため、次は実通信、APIキー管理、キャッシュ、レート制限対応の設計に進める
- 外部データ取得の実通信へ進む場合も、StockSnapshot / DataProvider / AlertRuleEvaluator の境界を維持する
- SwiftDataを使う場合、モデル変更時の移行方針を早めに意識する
- 日経225銘柄マスタは変更されるため、初期データの更新方法を後で設計する
- UI文言は売買推奨に見えないようにレビューする
- 条件判定ロジックは View に直接書かない
- 条件判定ロジックはデータ取得元にも直接依存させない
- 外部API、リアルタイム板情報、自動売買は初期版に入れない
- 大きな変更前には作業計画を提示し、関連ドキュメントも更新する
