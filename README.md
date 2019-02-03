# Display CSV in Tabular Form

## 概要
**csv2tabular.sh** は標準入力からCSV形式のデータを受け取り、標準出力に表形式で出力するシェルスクリプトです。UTF-8に対応しています。


## 動作条件
* Bash
* GNU Awk 4.0 以降が必要です


## 使い方

csv2tabular.sh へCSVを入力するには、以下のようにファイルリダイレクトまたはコマンドのパイプを使います。

* $ csv2tabular.sh < sample.csv
* $ cat sample.csv | csv2tabular.sh

実行例：
* $ cat sample.csv
```
  "Sample No.","Project Name",Score,Status
  880221,"Super-X alpha",1500,Pass
  21012,"Extreme DX",30,Fail
  9910903,Hypernova,12000,Pass
```
* $ csv2tabular.sh < sample.csv
```
  +------------+---------------+-------+--------+
  | Sample No. | Project Name  | Score | Status |
  +------------+---------------+-------+--------+
  | 880221     | Super-X alpha | 1500  | Pass   |
  | 21012      | Extreme DX    | 30    | Fail   |
  | 9910903    | Hypernova     | 12000 | Pass   |
  +------------+---------------+-------+--------+
```

## オプション

以下のオプションが用意されています。

| オプション         | 説明 |
| :---               | :--- |
| -s {0..3}          | ボーダースタイル <br> 0:枠なし &nbsp;&nbsp; 1:外枠と列の仕切り &nbsp;&nbsp; 2:ヘッダーとボディ（デフォルト） &nbsp;&nbsp; 3:行毎に仕切り |
| -r &nbsp; -l &nbsp; -c <br> (組み合わせ可)| 列のアライメント <br> r:右寄せ &nbsp;&nbsp; l:左寄せ（デフォルト） &nbsp;&nbsp; c:中央揃え <br> 例： -lrcr 1～4列目を 左,右,中,右 に揃える （5列目以降は左） |
| -p &lt;整数&gt;    | セル内のパディング量（初期値=1） |
| -i &lt;整数&gt;    | 表のインデント量（初期値=2） |
| -t &lt;文字列&gt;...| ヘッダー行の挿入 <br> ヘッダー行が含まれないCSVデータに、コマンドラインからヘッダー行を挿入できます。|
| -v                 | バージョンとライセンス情報の表示 |
| -h                 | ヘルプ |

以下、オプションの例を示します。

### ボーダースタイルの例
* ___Style 0___ : 枠なし  
$ cat sample.csv | csv2tabular.sh -s0
```
    Sample No.   Project Name    Score   Status
    880221       Super-X alpha   1500    Pass
    21012        Extreme DX      30      Fail
    9910903      Hypernova       12000   Pass
```
* ___Style 1___ : 外枠と列の仕切り  
$ cat sample.csv | csv2tabular.sh -s1
```
  +------------+---------------+-------+--------+
  | Sample No. | Project Name  | Score | Status |
  | 880221     | Super-X alpha | 1500  | Pass   |
  | 21012      | Extreme DX    | 30    | Fail   |
  | 9910903    | Hypernova     | 12000 | Pass   |
  +------------+---------------+-------+--------+
```
* ___Style 2___ : ヘッダーとボディ（デフォルト）  
$ cat sample.csv | csv2tabular.sh -s2
```
  +------------+---------------+-------+--------+
  | Sample No. | Project Name  | Score | Status |
  +------------+---------------+-------+--------+
  | 880221     | Super-X alpha | 1500  | Pass   |
  | 21012      | Extreme DX    | 30    | Fail   |
  | 9910903    | Hypernova     | 12000 | Pass   |
  +------------+---------------+-------+--------+
```
* ___Style 3___ : 行毎に仕切り  
$ cat sample.csv | csv2tabular.sh -s3
```
  +------------+---------------+-------+--------+
  | Sample No. | Project Name  | Score | Status |
  +------------+---------------+-------+--------+
  | 880221     | Super-X alpha | 1500  | Pass   |
  +------------+---------------+-------+--------+
  | 21012      | Extreme DX    | 30    | Fail   |
  +------------+---------------+-------+--------+
  | 9910903    | Hypernova     | 12000 | Pass   |
  +------------+---------------+-------+--------+
```

### アライメントオプションの例
アライメントは列毎に設定できます。オプションを省略した場合は左揃えになります。
* ___e.g.1:___ **-r** 先頭の1列だけ右揃え。残りは左揃え。  
$ cat sample.csv | csv2tabular.sh -r
```
  +------------+---------------+-------+--------+
  | Sample No. | Project Name  | Score | Status |
  +------------+---------------+-------+--------+
  |     880221 | Super-X alpha | 1500  | Pass   |
  |      21012 | Extreme DX    | 30    | Fail   |
  |    9910903 | Hypernova     | 12000 | Pass   |
  +------------+---------------+-------+--------+
```
* ___e.g.2:___ **-rrrr** 先頭から４列目まで全て右揃え。  
$ cat sample.csv | csv2tabular.sh -rrrr
```
  +------------+---------------+-------+--------+
  | Sample No. |  Project Name | Score | Status |
  +------------+---------------+-------+--------+
  |     880221 | Super-X alpha |  1500 |   Pass |
  |      21012 |    Extreme DX |    30 |   Fail |
  |    9910903 |     Hypernova | 12000 |   Pass |
  +------------+---------------+-------+--------+
```
* ___e.g.3:___ **-rlrc** １および３列目を右揃え、２列目を左揃え、４列目を中央揃え。  
$ cat sample.csv | csv2tabular.sh -rlrc
```
  +------------+---------------+-------+--------+
  | Sample No. | Project Name  | Score | Status |
  +------------+---------------+-------+--------+
  |     880221 | Super-X alpha |  1500 |  Pass  |
  |      21012 | Extreme DX    |    30 |  Fail  |
  |    9910903 | Hypernova     | 12000 |  Pass  |
  +------------+---------------+-------+--------+
```

### ヘッダー行の挿入
* 入力されたCSVデータの先頭に、-t 以降のコマンドライン引数を挿入します。  
$ cat sample.csv | csv2tabular.sh -t "a,b,c" -p0 -i10 "g h"
```
  +------------+---------------+-------+--------+
  | a,b,c      | -p0           | -i10  | g h    |
  +------------+---------------+-------+--------+
  | Sample No. | Project Name  | Score | Status |
  | 880221     | Super-X alpha | 1500  | Pass   |
  | 21012      | Extreme DX    | 30    | Fail   |
  | 9910903    | Hypernova     | 12000 | Pass   |
  +------------+---------------+-------+--------+
```
このように、-t 以降はヘッダーデータとして扱われるため、-t より後ろにオプションを指定することはできません。


## License
csv2tabular.sh  1.0.0  
Copyright (C) 2019 kitanokitsune

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.


---
kitanokitsune / 北乃きつね
