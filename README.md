# SKK dictionary files

Refer to the following URL for the distribution files.

https://skk-dev.github.io/dict/


# 辞書ファイルの編集をお考えの方へ

[committers.md](committers.md) には、次の内容を掲載してあります。

- 各辞書ファイルに適用しているライセンス
- 各辞書の編集方針
- ChangeLog の記述方法
- 辞書の形式

いずれも、SKK 辞書ファイルの編纂に向け役立つ内容ですので、ぜひご確認ください。


# 配布用の gzip アーカイブを作る

`make archive` を実行すると、配布用の gzip ファイルを作ることができます。
この過程では `skktools` を用いて `csv/china_taiwan.csv` から `SKK-JISYO.china_taiwan` を
生成しているため、あらかじめ Ruby 処理系と `skktools` をインストールしておいてく
ださい。

具体的には、次のようにコマンドを実行すると、

```
$ make archive TOOLS_DIR=../github.skktools
```

カレントディレクトリに `SKK-JISYO.*.gz`, `SKK-JISYO.*.md5`, `zipdoce.*.gz`,
`zipdoce.*.md5` が生成されます。

これらのファイルは、いったん退避しておきましょう。

```
$ mv SKK-JISYO.*.gz ../
$ mv SKK-JISYO.*.md5 ../
$ mv zipdoce.*.gz ../
$ mv zipdoce.*.md5 ../
```


## make の副作用

`make archive` の実行過程で、いくつかのファイルが更新される場合があります。

```
$ git status

On branch master
Your branch is up to date with 'origin/master'.

Changes not staged for commit:
        modified:   SKK-JISYO.L.unannotated
        modified:   SKK-JISYO.wrong
```

更新内容に問題がなければ、そのまま commit してください。

```
$ git add -u && git commit
```


## 配布用の gzip アーカイブをブランチ gh-pages に配置

さきほど退避しておいた `SKK-JISYO.*.gz`, `SKK-JISYO.*.md5`, `zipdoce.*.gz`, `zipdoce.*.md5` を
ブランチ gh-pages に mv して add && push します。

```
$ git co gh-pages
$ mv ../SKK-JISYO.*.gz .
$ mv ../SKK-JISYO.*.md5 .
$ mv ../zipdoce.*.gz .
$ mv ../zipdoce.*.md5 .
$ git add -u && git commit -m "update"
$ git push
```


# JSON 形式の辞書について

辞書データと相互変換が可能な JSON 形式のテキストファイルです。
変換には Deno が必要です。

JSON から SKK 辞書を作成するコマンドは単純に `make all` です。

しかし通常の SKK 辞書から JSON ファイルを生成するためには
いったん JSON を rm しなければいけません。
これは Makefile 内の記述として、JSON が SKK 辞書に依存しておらず、
ファイルが存在していれば常に最新として扱われるためです。

```
$ rm json/SKK-JISYO.L.json
$ make json/SKK-JISYO.L.json
```

