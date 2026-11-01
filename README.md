# Genalgo

Genalgoは実数値の染色体を扱う遺伝的アルゴリズムのRubyライブラリです。
Minimal Generation Gap（MGG）モデルで集団を更新し、評価値を最小化します。
交叉にはBLX-alphaとSimplexを使えます。Ruby 3.4以上が必要です。

## インストール

Gemfileに追加し、`bundle install`を実行します。

```ruby
gem "genalgo", github: "mkatoo/genalgo"
```

## 使い方

探索範囲と実行条件を`Configuration`に渡し、`Optimizer#run`のブロックに評価関数を書きます。

```ruby
require "genalgo"

bounds = Genalgo::Bounds.new(
  lower: Array.new(10, -100.0),
  upper: Array.new(10, 100.0)
)
configuration = Genalgo::Configuration.new(
  bounds: bounds,
  population_size: 100,
  max_evaluations: 10_000,
  crossover: Genalgo::Crossovers::BlxAlpha.new(alpha: 0.36),
  seed: 12345
)

optimizer = Genalgo::Optimizer.new(configuration)
result = optimizer.run do |chromosome|
  chromosome.sum { |gene| gene * gene }
end

result.best_individual.chromosome
result.best_individual.fitness
result.evaluations # => 10000
result.seed        # => 12345
```

`run`は実行ごとに独立した`Result`を返します。
設定、結果、個体、染色体と履歴は変更できません。
同じ`Optimizer`を繰り返し使えます。実行途中で評価に失敗しても、取得済みの結果には影響しません。

## 座標ごとの探索範囲

`Bounds`では座標ごとに下限と上限を指定します。

```ruby
bounds = Genalgo::Bounds.new(
  lower: [-5.0, 10.0, 3.0],
  upper: [5.0, 20.0, 3.0]
)
bounds.dimension # => 3
bounds.within_bounds?([0.0, 15.0, 3.0]) # => true
```

この例では第1座標が-5から5、第2座標が10から20の範囲を取り、第3座標は3に固定されます。
次元数は配列の長さから決まります。
両配列は空でなく、長さが同じで、各座標の下限が上限以下である必要があります。
境界値には有限な実数を指定し、内部では`Float`に変換します。
`Float`の範囲を超える値、`NaN`、無限大、複素数は受け付けません。
入力した配列はコピーされるため、呼び出し元で配列を変更しても探索範囲は変わりません。

## 設定の変更

`Configuration`は生成時に検証されます。
`population_size`と`max_evaluations`は正の整数で、評価予算は初期集団の個体数以上である必要があります。
設定を変えるときは`with`で新しい設定を作ります。

```ruby
longer_run = configuration.with(max_evaluations: 20_000)
second_result = Genalgo::Optimizer.new(longer_run).run do |chromosome|
  chromosome.sum { |gene| gene * gene }
end

configuration.max_evaluations # => 10000
second_result.evaluations      # => 20000
```

`with`は変更しない設定とseedを引き継ぎます。
探索範囲や次元数を変えるときは、新しい`Bounds`を渡します。
評価関数は実行ごとのブロックで指定します。

## 交叉と世代更新

交叉オブジェクトを設定に渡します。どちらも変更不可で、実行間で共有できます。

| 交叉 | 指定方法 | 必要な親数 |
|---|---|---|
| BLX-alpha | `Genalgo::Crossovers::BlxAlpha.new(alpha: 0.36)` | 2 |
| Simplex | `Genalgo::Crossovers::Simplex.new` | 次元数 + 1 |

交叉を省略すると、`alpha: 0.36`のBLX-alphaを使います。
`alpha`には有限な0以上の実数を指定します。
集団には交叉に必要な親数以上の個体が必要です。固定された座標も次元数に含みます。

各世代では2個の子を評価し、置換対象の親2個体と子2個体から生存個体を選びます。
最良個体を残し、もう1個体を評価値に基づくルーレット選択で選びます。
Simplexでは次元数+1個体を交叉に使い、そのうち無作為に選んだ2個体だけを置換対象にします。
残りの親と集団の他の個体は保持します。

BLX-alphaは拡張した親の区間を探索範囲で切り詰めてからサンプリングします。
Simplexは拡張した単体から子を生成したあと、探索範囲を外れた座標を下限または上限に丸めます。

## 評価関数と評価予算

評価関数には変更不可の`Float`配列を渡します。
有限な実数を返してください。負数と0も使え、評価値は`Float`で保持します。
`nil`、文字列、`NaN`、無限大、複素数、`Float`の範囲を超える値は受け付けません。

初期集団の評価も予算に含みます。
初期化後は2評価ずつ進めるため、残り予算が1の場合は使わずに終了します。
`result.evaluations`には実際に呼び出した評価関数の回数を記録します。

評価関数が例外を投げた場合や不正な値を返した場合は、`Genalgo::EvaluationError`で実行を中断します。
元の例外は`cause`、失敗した評価番号と染色体は`context`から取得できます。

```ruby
begin
  optimizer.run { |_chromosome| nil }
rescue Genalgo::EvaluationError => error
  error.context[:evaluations] # => 1
  error.context[:chromosome]
  error.cause.class           # => ArgumentError
end
```

不正な設定値は`Genalgo::ConfigurationError`になります。
必須キーワードの不足や未知のキーワードは`ArgumentError`になります。

## 履歴と再現性

履歴には初期集団の評価後と各世代の更新後に、最良個体と累積評価回数を記録します。

```ruby
result.history.each do |entry|
  puts [entry.evaluations, entry.best_individual.fitness].join(", ")
end
```

同じ設定、seedと決定的な評価関数を使えば、同じ実装・Ruby環境で同じ結果を再現できます。
実行ごとに専用の乱数生成器を使い、グローバルな`rand`や`srand`、別の実行による乱数の利用から影響を受けません。
Genalgoもグローバルな乱数の状態を変更しません。
評価関数が乱数を使う場合は、その乱数を評価関数側で管理してください。
実装やRubyのバージョンが変わると、探索履歴も変わる場合があります。

seedを省略すると、設定の生成時に一度だけ生成します。
使用した値は`configuration.seed`や`result.seed`で確認できます。
`configuration.with(seed: nil)`は新しいseedを生成し、整数を指定するとその値に変更します。

## 開発

依存関係をインストールし、テストとRuboCopを実行します。

```sh
bundle install
bundle exec rake
```

GitHub ActionsでもRuby 3.4で同じチェックとgemのビルドを実行します。
性能を計測する場合は、次のコマンドを使います。

```sh
bundle exec ruby benchmark/optimizer.rb
```

両交叉方式を個体数・次元数の異なる条件で各3回実行し、処理時間とオブジェクト割り当て数の中央値をJSONで出力します。

## ライセンス

MIT。詳細は[LICENSE.txt](LICENSE.txt)を参照してください。
