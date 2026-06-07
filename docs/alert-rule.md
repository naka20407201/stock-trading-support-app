# アラート条件設計

## アラート条件の考え方

アラート条件は、ユーザーが自分で定義した確認条件です。アプリはその条件に一致したかどうかを判定し、事実として記録します。

アラート条件は売買推奨ではありません。例えば「株価が損切りライン以下」という条件が一致しても、アプリは「売るべき」とは表示せず、「ユーザー設定条件に一致しました」と表示します。

初期版では、1つの AlertRule が1つの条件式だけを持つシンプルな設計にします。ただし、1つの銘柄に対して複数の AlertRule を登録できます。

ここでいう「1条件アラート」は、1銘柄につきアラート条件を1つだけに制限する意味ではありません。複数条件の AND / OR 組み合わせは後続対応とし、初期版では複数の AlertRule を個別に評価します。

## 条件のデータ構造案

AlertRule は、以下の要素を持つ想定です。

| 項目 | 内容 |
| --- | --- |
| id | アラート条件ID |
| stockCode | 対象銘柄コード |
| name | 条件名 |
| metric | 対象指標 |
| comparisonOperator | 比較演算子 |
| thresholdValue | しきい値 |
| isEnabled | 有効フラグ |
| createdAt | 作成日時 |
| updatedAt | 更新日時 |

将来の複合条件では、AlertRule を親として、AlertConditionNode のような子要素を持たせる構成に拡張できます。

Step 10 時点では、条件の登録、編集、削除、有効/無効切り替えに加えて、固定モック株価を使った条件評価と条件一致履歴作成までを実装しています。ユーザー設定条件と条件一致履歴はSwiftDataへ永続化します。通知送信は後続Stepで扱います。

## 条件種別の一覧

対象指標と比較演算子は分離して設計します。これにより、同じ比較演算ロジックを currentPrice、per、pbr、volume などへ使い回せるようにします。

初期版または将来版で扱う条件種別は以下です。

| 条件種別 | 指標 | 初期版での扱い |
| --- | --- | --- |
| 株価がしきい値より大きい / 以上 / 未満 / 以下 / 等しい / 等しくない | currentPrice | 最優先 |
| PERがしきい値と比較条件に一致 | per | 手入力・モック値として対応余地 |
| PBRがしきい値と比較条件に一致 | pbr | 手入力・モック値として対応余地 |
| 出来高がしきい値と比較条件に一致 | volume | 手入力・モック値として対応余地 |
| 前日比が○%以上 | priceChangePercent | 後続 |
| 前日比が○%以下 | priceChangePercent | 後続 |
| 決算日まで○日以内 | daysUntilEarnings | 後続 |
| 目標株価との比較 | targetPrice | 後続 |
| 損切りラインとの比較 | stopLossPrice | 後続 |
| 出来高が過去平均の○倍以上 | volumeAverageRatio | 後続 |
| 移動平均線との差が○%以上 | movingAverageDeviation | 後続 |
| RSIが○以上または以下 | rsi | 後続 |
| MACD条件 | macd | 後続 |

初期実装では、まず currentPrice と基本比較演算子の組み合わせを最優先にします。per、pbr、volume は、外部APIなしでも手入力値またはモック値から StockSnapshot に含められる設計余地を残します。

## 比較演算子の考え方

比較演算子は、対象指標としきい値の関係を表します。

| 演算子 | 意味 | 例 | 初期版での扱い |
| --- | --- | --- | --- |
| greaterThan | より大きい | 株価が1,000円より大きい | 対応 |
| greaterThanOrEqual | 以上 | 株価が1,000円以上 | 対応 |
| lessThan | より小さい | PERが15倍より小さい | 対応 |
| lessThanOrEqual | 以下 | 株価が800円以下 | 対応 |
| equal | 等しい | 入力値がしきい値と等しい | 対応 |
| notEqual | 等しくない | 入力値がしきい値と等しくない | 対応 |
| withinDays | 指定日数以内 | 決算日まで7日以内 | 後続 |
| ratioGreaterThanOrEqual | 倍率が以上 | 出来高が20日平均の2倍以上 | 後続 |

初期版では、greaterThan、greaterThanOrEqual、lessThan、lessThanOrEqual、equal、notEqual の基本比較演算子に対応します。これらは数値比較として共通化しやすく、後から追加すると UI、判定ロジック、履歴表示、テスト、ドキュメントの修正範囲が広がるためです。

withinDays は決算日などの日付データが必要になるため後続対応にします。ratioGreaterThanOrEqual は過去平均や基準値などの追加データ設計が必要になるため後続対応にします。

## AND / OR 拡張の考え方

将来的には、複数条件を組み合わせます。

例:

- PERが18倍以上 AND 株価が25日移動平均線より5%以上高い
- 株価が損切りライン以下 OR 前日比が-5%以下
- 出来高が20日平均の2倍以上 AND 前日比が3%以上

拡張案は以下です。

- AlertRule を条件グループとして扱う
- AlertConditionNode を条件ツリーとして扱う
- ノード種別として group と condition を持つ
- group ノードは AND または OR を持つ
- condition ノードは metricType、comparisonOperator、thresholdValue を持つ

初期版では、1つの AlertRule は単一条件式だけを保存します。1つの銘柄には複数の AlertRule を登録でき、それぞれを独立して判定します。将来以下のように移行できるようにしておきます。

- 既存 AlertRule を、AND グループ内の単一 condition として扱う
- UIは最初は1条件入力だけにする
- データ構造には groupOperator を後から追加できる余地を残す

## 条件判定処理の流れ

条件判定は View とデータ取得元から分離します。AlertRuleEvaluator は、手入力画面、モックデータ、外部APIを直接参照しません。AlertRule と StockSnapshot を入力として受け取り、条件一致、条件不一致、判定不能のいずれかを返します。

初期版の流れ:

1. 手入力値またはモックデータを取得する
2. ManualInputStockDataProvider または MockStockDataProvider 相当の境界で StockSnapshot を生成する
3. 対象銘柄の有効な AlertRule を取得する
4. AlertRule と StockSnapshot を AlertRuleEvaluator に渡す
5. AlertRuleEvaluator は、条件一致、条件不一致、判定不能、無効のいずれかを返す
6. 条件一致の場合、AlertMatchHistory を作成する
7. 通知送信は後続対応とし、Step 8 では画面内の履歴表示にとどめる

将来版の流れ:

1. 外部API、Web取得、リアルタイムデータなどから値を取得する
2. ExternalApiStockDataProvider、WebStockDataProvider、RealtimeStockDataProvider 相当の境界で StockSnapshot を生成する
3. 対象銘柄の有効な AlertRule を取得する
4. AlertRule と StockSnapshot を AlertRuleEvaluator に渡す
5. AlertRuleEvaluator は、条件一致、条件不一致、判定不能、無効のいずれかを返す
6. 条件一致の場合、AlertMatchHistory を作成する
7. 通知機能を追加する場合も、通知文言は条件一致の事実として扱う

DataProvider 相当の候補:

- ManualInputStockDataProvider
- MockStockDataProvider
- ExternalApiStockDataProvider
- WebStockDataProvider
- RealtimeStockDataProvider

判定結果の考え方:

- matched: 条件に一致した
- notMatched: 条件に一致しなかった
- unavailable: 必要なデータがないため判定できない
- disabled: 条件が無効化されているため評価対象外

unavailable の場合は、アプリが推測や補完をして売買判断のような表示をしないようにします。

## 通知履歴の考え方

AlertMatchHistory は、条件一致の事実を記録するためのモデルです。Step 8 では通知送信を行わず、銘柄詳細画面内の「条件一致履歴」として表示します。

保存する項目:

- 銘柄
- 条件名
- 条件内容
- 条件一致日時
- 観測値
- しきい値
- 比較演算子
- データソース

履歴は、将来的に条件設定を変更しても過去の内容が分かるように、条件名、対象指標、比較演算子、しきい値、観測値、データソースのスナップショットを保存します。AlertRule への参照だけにすると、後から条件を変更した場合に過去履歴の意味が変わってしまうためです。

Step 10 時点では、条件一致履歴は `AlertMatchHistoryRecord` としてSwiftDataへ保存します。条件変更後も過去履歴の意味が変わらないように、AlertRule への参照だけではなく、条件名、対象指標、比較演算子、しきい値、観測値、データソースをスナップショットとして保存します。対象指標や比較演算子のRawValueが復元できない場合は、アプリをクラッシュさせず復元できない履歴Recordとして読み飛ばします。

Step 8 以降、同じ `snapshot.capturedAt` と条件IDの組み合わせでは重複履歴を作成しません。異なる取得時刻の Snapshot で再評価した場合は、同じ条件でも新しい条件一致履歴として扱えます。

## 売買推奨にならないための注意点

アラート機能では、以下の表現を避けます。

- 買い時です
- 売り時です
- 利益が出ます
- 勝率が高いです
- おすすめです
- 今すぐ確認してください
- 投資チャンスです

代わりに、以下のような事実ベースの表現を使います。

- ユーザー設定条件に一致しました
- 条件「株価が1,000円以上」に一致しました
- 入力値: 1,020円 / しきい値: 1,000円
- 条件一致日時: 2026-06-06 10:00
- この履歴を確認済みにする

UI、通知、履歴、ログ、テストデータ、サンプル文言でも同じ方針を守ります。
