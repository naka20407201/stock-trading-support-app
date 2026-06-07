# 設計

## 画面構成

初期版では、iPhoneでの使いやすさを優先し、タブまたはナビゲーションスタックを中心にした構成にします。

主な画面は以下です。

- ウォッチリスト画面
- 銘柄検索・追加画面
- 任意銘柄追加画面
- 銘柄詳細画面
- 投資メモ編集画面
- アラート条件一覧画面
- アラート条件作成・編集画面
- 通知履歴画面
- 設定画面

初期版の最小構成では、ウォッチリスト画面、銘柄追加画面、銘柄詳細画面、投資メモ編集、アラート条件設定、通知履歴を優先します。

## 画面遷移

想定する基本遷移は以下です。

1. ウォッチリスト画面を起点にする
2. ウォッチリストから銘柄詳細画面へ遷移する
3. 銘柄詳細画面から投資メモ編集、アラート条件一覧、通知履歴へ遷移する
4. ウォッチリスト画面から銘柄追加画面へ遷移する
5. 銘柄追加画面では、日経225銘柄候補から追加、または任意銘柄を手入力して追加する
6. アラート条件一覧から条件作成・編集画面へ遷移する
7. 通知履歴画面では、履歴確認と確認済み状態の更新を行う

画面遷移の考え方:

- 銘柄を中心に情報へアクセスできる構成にする
- アラート条件や履歴は銘柄詳細の配下に置く
- 全体の履歴一覧は将来追加できるようにする
- 設定画面は、データリセット、モックデータ更新、通知設定などの受け皿にする

## 主な処理フロー

### ウォッチリスト追加

1. ユーザーが銘柄追加画面を開く
2. 日経225銘柄マスタから銘柄を検索する
3. 銘柄を選択してウォッチリストに追加する
4. WatchlistItem を作成する
5. 必要に応じて初期 InvestmentMemo を作成する

### 任意銘柄追加

1. ユーザーが任意銘柄追加画面を開く
2. 銘柄コードと銘柄名を入力する
3. ユーザー追加銘柄として StockMaster 相当のレコードを作成する
4. 作成した銘柄を WatchlistItem として追加する
5. 日経225銘柄と同じ詳細画面・メモ・アラート条件を利用する

### 投資メモ更新

1. ユーザーが銘柄詳細から投資メモ編集画面を開く
2. 買いたい理由、売る条件、損切り条件、目標株価、注意点などを入力する
3. InvestmentMemo を保存する
4. 保存後、銘柄詳細へ戻る

### アラート条件作成

1. ユーザーが銘柄詳細からアラート条件一覧を開く
2. 条件作成画面で、対象指標、比較演算子、しきい値、条件名を入力する
3. AlertRule を保存する
4. 条件一覧に表示する

### 条件判定

1. ManualInputStockDataProvider または MockStockDataProvider 相当の境界から、銘柄ごとの手入力値またはモックデータを取得する
2. 取得した値を StockSnapshot に変換する
3. 有効な AlertRule を取得する
4. AlertRule と StockSnapshot を AlertRuleEvaluator に渡す
5. AlertRuleEvaluator は、条件一致、条件不一致、判定不能のいずれかを返す
6. 判定結果が条件一致の場合、AlertHistory を作成する
7. 通知機能が有効な場合は通知候補として扱う

## SwiftUIでの構成案

初期版では、シンプルな SwiftUI 構成を想定します。

- App entry
- RootView
- WatchlistView
- WatchlistViewModel
- AddStockView
- StockSearchView
- CustomStockFormView
- StockDetailView
- InvestmentMemoView
- AlertRuleListView
- AlertRuleEditView
- AlertHistoryView
- SettingsView

View は表示とユーザー操作の受け取りを担当します。条件判定、データ変換、文言生成などは View 内に直接書き込まず、別の型やサービスに分離します。

## View / Model / 条件判定ロジックの分離方針

責務を以下のように分けます。

- View: 画面表示、入力、画面遷移
- ViewModel: View間で共有する画面状態とRepository呼び出し
- Model: SwiftDataで保存する永続化対象
- Domain: アラート条件、指標、判定結果などのアプリ固有概念
- StockSnapshot: 条件判定に渡す評価用データ。UIや外部APIレスポンスへ直接依存させない
- AlertRuleEvaluator: AlertRule と StockSnapshot を受け取り、条件一致、条件不一致、判定不能を返す
- DataProvider相当: 手入力、モック、外部APIなどのデータ取得元を StockSnapshot に変換する境界
- Service: 条件判定の呼び出し、履歴作成、通知候補作成
- Repository相当: SwiftData、将来バックエンド、外部APIに差し替える場合の保存・取得境界

初期版では過度に複雑なアーキテクチャにしません。ただし、条件判定ロジックは View から分離し、将来 Web/PC 版やバックエンドでも再利用しやすい形を目指します。

Step 5 時点では、RootView が `WatchlistViewModel` を保持し、WatchlistView と AddStockView に同じインスタンスを渡します。これにより、日経225候補または任意入力銘柄を AddStockView で追加したあと、WatchlistView の一覧に同じウォッチリスト状態を反映できます。View は InMemoryWatchlistRepository を直接操作せず、ViewModel 経由で追加、削除、重複確認を行います。

## 株価・指標値取得の抽象化方針

条件判定ロジックは、手入力画面、モックデータ、外部API、リアルタイムデータを直接参照しません。データ取得元を DataProvider 相当の境界に閉じ込め、AlertRuleEvaluator は StockSnapshot だけを入力として扱います。

初期版の流れ:

1. 手入力値またはモックデータを取得する
2. ManualInputStockDataProvider または MockStockDataProvider 相当の境界で StockSnapshot を生成する
3. StockSnapshot と AlertRule を AlertRuleEvaluator に渡す
4. 条件一致、条件不一致、判定不能を返す

将来版の流れ:

1. 外部API、Web取得、リアルタイムデータなどから値を取得する
2. ExternalApiStockDataProvider、WebStockDataProvider、RealtimeStockDataProvider 相当の境界で StockSnapshot を生成する
3. StockSnapshot と AlertRule を AlertRuleEvaluator に渡す
4. 条件一致、条件不一致、判定不能を返す

この分離により、外部API連携を追加しても AlertRuleEvaluator の基本責務を変えずに済みます。データ不足や取得失敗は StockSnapshot の欠損として表現し、判定結果は「判定不能」として扱います。

## アラート条件の初期範囲

初期版では、1つの AlertRule は1つの条件式のみを持ちます。ただし、1つの銘柄に対して複数の AlertRule を登録できます。複数条件の AND / OR 組み合わせは後続対応とします。

初期版で対応する基本比較演算子:

- greaterThan
- greaterThanOrEqual
- lessThan
- lessThanOrEqual
- equal
- notEqual

後続対応にする比較演算子:

- withinDays
- ratioGreaterThanOrEqual

対象指標と比較演算子は分離します。初期版では currentPrice を最優先にし、per、pbr、volume は手入力値またはモック値として対応できる余地を残します。

## 銘柄マスタとウォッチリストの分離方針

銘柄マスタとウォッチリストは別の概念として扱います。

銘柄マスタ:

- 日経225採用銘柄やユーザー追加銘柄の基本情報を保持する
- 銘柄コード、銘柄名、市場区分、業種、日経225採用フラグなどを持つ
- 将来的に外部データ更新の対象になる
- 日経225ローカルJSONには、可能であれば sourceName、asOfDate、stocks のようなメタ情報を持たせる

ウォッチリスト:

- ユーザーが監視対象として選んだ銘柄を保持する
- 監視中フラグ、ユーザーメモ、表示順などを持つ
- 銘柄マスタへの参照を持つ
- 投資メモ、アラート条件、通知履歴の起点になる

この分離により、同じ銘柄マスタを複数の用途で使い回せます。また、将来マスタデータを更新しても、ユーザーのウォッチリストやメモを壊しにくくなります。

## 将来バックエンド化する場合の考え方

初期版は SwiftData によるローカル保存を前提にしますが、将来的にバックエンド化できるように、以下を意識します。

- 各モデルにローカルIDとは別に将来のサーバーIDを持てる余地を残す
- 作成日時、更新日時、削除状態を持てるようにする
- 銘柄マスタとユーザーデータを分離する
- 条件判定ロジックをデータ保存方式に依存させない
- 外部APIから取得した指標値を、画面や判定処理に直接渡さず StockSnapshot として整形する
- DataProvider 相当の境界を差し替えることで、手入力・モック・外部API・リアルタイムデータの違いを吸収する
- 同期処理や競合解決は初期版では実装しないが、将来の設計課題として残す

将来の構成案:

- iOSアプリ: SwiftUI
- APIサーバー: REST または GraphQL
- DB: PostgreSQL
- 認証: ユーザーアカウント管理
- 同期: 端末間同期、履歴同期、条件同期
- バッチ処理: 株価・指標・決算日などの定期取得

## 将来Web/PC版を追加する場合の考え方

Web/PC版を追加する場合は、UI実装は別になりますが、データモデルと条件判定の考え方は共有できるようにします。

設計上の注意点:

- View固有の状態とアプリ共通のドメイン概念を分ける
- アラート条件をJSON化しやすい構造にする
- 条件判定の入力データを明確に定義する
- 表示文言は売買推奨に見えない方針を共通ルール化する
- 銘柄マスタ、ウォッチリスト、メモ、条件、履歴の境界を維持する

Web/PC版では、一覧性や検索性を強化し、iPhone版では入力と確認のしやすさを優先します。
