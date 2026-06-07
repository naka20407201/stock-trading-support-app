# Codex 作業ルール

このリポジトリで Codex が作業するときは、以下のルールを守ること。

## 基本方針

- このアプリは「ユーザー定義条件による通知・記録アプリ」として扱う。
- アプリ側から売買推奨、投資助言、利益保証、勝率表示を行わない。
- 「買うべき」「売るべき」「推奨銘柄」「勝率○%」「必ず儲かる」のような表現を入れない。
- 条件一致は、ユーザーが設定した条件に入力値または取得値が一致した事実として表現する。
- 実際の売買判断はユーザー自身が行う前提を維持する。

## 作業前の確認

- 実装前に docs/ 配下の設計書を確認する。
- 特に以下を確認する。
  - docs/requirements.md
  - docs/design.md
  - docs/alert-rule.md
  - docs/data-model.md
  - docs/development-plan.md
- 仕様変更時は、関連する設計書も更新する。
- 大きな変更の前には作業計画を提示する。

## 実装方針

- SwiftUIでは View、Model、条件判定ロジックを分離する。
- View に条件判定やデータ取得の詳細を詰め込まない。
- 条件判定ロジックは、将来 Web/PC版やバックエンドでも考え方を再利用できるようにする。
- AlertRuleEvaluator は手入力画面、モックデータ、外部APIを直接参照しない。
- AlertRuleEvaluator は AlertRule と StockSnapshot を入力として、条件一致、条件不一致、判定不能を返す。
- 手入力、モック、外部API、Web取得、リアルタイムデータは DataProvider 相当の境界で StockSnapshot に変換する。
- 初期版では ManualInputStockDataProvider / MockStockDataProvider 相当を優先し、将来版では ExternalApiStockDataProvider / WebStockDataProvider / RealtimeStockDataProvider 相当に差し替えられるようにする。
- 銘柄マスタとユーザーのウォッチリストを分離する。
- StockMaster、WatchlistItem、InvestmentMemo、AlertRule、AlertMatchHistory の責務を混ぜない。
- 初期版では、1つの AlertRule は1つの条件式だけを持つ。ただし、1つの銘柄に複数の AlertRule を登録できる。
- 複数条件の AND / OR 組み合わせは後続対応とする。
- 初期版の比較演算子は greaterThan、greaterThanOrEqual、lessThan、lessThanOrEqual、equal、notEqual に対応する。
- withinDays と ratioGreaterThanOrEqual は後続対応とする。
- 初期版では外部APIに依存しすぎない。
- 初期版では手入力値またはモックデータで動作確認できるようにする。
- 初期版ではリアルタイム板情報や自動売買を実装しない。
- 証券口座連携は初期版では実装しない。

## 文言ルール

避ける表現:

- この銘柄を買うべき
- 今売るべき
- 推奨銘柄
- 勝率○%
- 必ず儲かる
- 投資チャンス
- 上昇確実
- 損しない

使う表現:

- ユーザー設定条件に一致しました
- 条件一致
- 条件履歴
- ウォッチリスト
- 確認済み
- 入力値
- しきい値
- 判定不能
- 必要な値が未入力です

UI、通知、履歴、サンプルデータ、テスト名、コメント、ドキュメントでも同じ方針を守る。

## データ設計ルール

- 銘柄マスタとウォッチリストは分離する。
- 日経225銘柄は標準候補として扱い、ユーザーの監視対象とは別に管理する。
- 日経225ローカルJSONには、可能であれば sourceName、asOfDate、stocks のようなメタ情報を持たせる。
- 日経225以外の任意銘柄も、日経225銘柄と同じようにメモ、アラート条件、通知履歴を設定できるようにする。
- 条件一致履歴には、条件変更後も意味が変わらないように条件内容のスナップショットを保存する。
- 対象指標と比較演算子を分離し、同じ比較ロジックを currentPrice、per、pbr、volume などに使い回せるようにする。
- 将来バックエンド化する可能性を考え、作成日時、更新日時、削除状態、サーバーIDの追加余地を意識する。

## 開発品質

- ビルドできる状態を維持する。
- コード実装後、必要に応じてドキュメントも更新する。
- 仕様に関わる変更をした場合は docs/ 配下の該当ファイルを更新する。
- 条件種別を追加した場合は docs/alert-rule.md を更新する。
- 比較演算子を追加・変更した場合は docs/alert-rule.md、docs/data-model.md、docs/requirements.md、docs/development-plan.md を更新する。
- データ取得元や StockSnapshot の構造を変更した場合は docs/design.md と docs/data-model.md を更新する。
- モデルを変更した場合は docs/data-model.md を更新する。
- 画面構成や遷移を変更した場合は docs/design.md を更新する。
- 初期版の範囲を広げる場合は docs/requirements.md と docs/development-plan.md を更新する。

## 初期版で実装しないこと

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
