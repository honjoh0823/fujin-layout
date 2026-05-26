# 風神配列（Fujin Layout）

**左手だけで両手タイピング以上の速度を実現する、日本語入力に最適化されたキーボード配列**

[![Download](https://img.shields.io/github/downloads/honjoh0823/fujin-layout/total?label=%E3%83%80%E3%82%A6%E3%83%B3%E3%83%AD%E3%83%BC%E3%83%89%E6%95%B0&style=flat-square)](https://github.com/honjoh0823/fujin-layout/releases)
[![License](https://img.shields.io/github/license/honjoh0823/fujin-layout?style=flat-square)](LICENSE)

## 概要

風神配列は、左手のみで高速な日本語入力を可能にするキーボード配列です。  
[大和配列](https://honjoh.dev/yamato/)をベースに、片手入力用に再設計されています。

1日2〜3時間、1週間ほどの練習で、**両手QWERTYの全国平均スコア（e-typing 220点前後）を上回る** ことが実証されています（e-typing Aランク 231点を達成）。

## 特徴

- 🖐️ **左手のみで完結** — 特殊なハードウェア不要。通常のキーボードでそのまま使用可能
- ⚡ **高速入力** — Spaceキーの母音化やロールオーバー入力による効率的な打鍵
- 🎯 **覚えやすい設計** — 子音と母音の分離構造によるシンプルな配列設計
- 🔄 **QWERTY共存** — 右手側は通常のQWERTY配列のまま。既存のタイピングスキルを失いません

## こんな方に

- 片手に障がいや怪我をお持ちの方
- 片手入力の速度を向上させたい方
- 新しいキーボード配列に挑戦してみたい方

## 動作環境

- **OS**: Windows
- **必要ソフト**: [AutoHotkey v2.0](https://www.autohotkey.com/)

## インストール

### 1. AutoHotkey v2.0 のインストール

[https://www.autohotkey.com/](https://www.autohotkey.com/) から AutoHotkey v2.0 をダウンロード・インストールしてください。

### 2. スクリプトのダウンロード・実行

[Releases ページ](https://github.com/honjoh0823/fujin-layout/releases) から最新の `fujin-1.0.ahk` をダウンロードし、任意の場所に保存して実行してください。

### スタートアップへの登録（任意）

PC起動時に自動で起動させたい場合は、スタートアップフォルダにショートカットを配置してください：

1. `Win + R` で「ファイル名を指定して実行」を開く  
2. `shell:startup` と入力して Enter  
3. 開いたフォルダに `fujin-1.0.ahk` のショートカットを作成

## 操作方法

| 操作 | 説明 |
|------|------|
| `Alt + F9` | スクリプトの一時停止 / 再開 |
| `Alt + F10` | デバッグログの切替 |

### 入力の仕組み

- **通常入力**: 左手キーを単独で押すと子音が入力されます
- **母音入力（Spaceキー）**: Spaceを押しながらキーを押すと母音が入力されます。Spaceの母音はキーに応じて変化します
- **母音入力（Alt/無変換キー）**: Alt または無変換キーで「U」を入力できます
- **CapsLockレイヤー**: CapsLockを押しながらで追加の子音にアクセスできます

## 設計思想

詳しい設計思想やコンセプトについては以下の記事をご覧ください：

📝 [片手のキーボード入力を研究したらタイピング練習1週間で両手より速くなってしまった話](https://note.com/_honjoh/n/nd629dd645255)

## 関連プロジェクト

- [大和配列（Yamato Layout）](https://honjoh.dev/yamato/) — 両手用の日本語最適化キーボード配列

## フィードバック

不具合の報告や改善の提案は、[Issues](https://github.com/honjoh0823/fujin-layout/issues) からお願いします。

## 作者

**本城 靖大**（[@_honjoh](https://note.com/_honjoh)）

## ライセンス

Copyright (c) 2025 本城 靖大. All Rights Reserved.

個人の非商用目的での使用のみ許可します。再配布・改変・商用利用は禁止です。詳細は [LICENSE](LICENSE) を参照してください。
