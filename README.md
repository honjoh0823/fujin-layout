# 風神配列（Fujin Layout）

**左手だけで両手タイピング以上の速度を実現する、日本語入力に最適化されたキーボード配列**

[![Download](https://img.shields.io/github/downloads/honjoh0823/fujin-layout/total?label=%E3%83%80%E3%82%A6%E3%83%B3%E3%83%AD%E3%83%BC%E3%83%89%E6%95%B0&style=flat-square)](https://github.com/honjoh0823/fujin-layout/releases)
[![License](https://img.shields.io/github/license/honjoh0823/fujin-layout?style=flat-square)](LICENSE)

## 概要

風神配列は、左手のみで高速な日本語入力を可能にするキーボード配列です。  
[大和配列](https://honjoh.dev/yamato/)をベースに、片手入力用に再設計されています。

個人検証では、1日2〜3時間、2週間ほどの練習で、**両手QWERTYの全国平均スコア（e-typing 220点前後）を上回る** スコアに到達しました（e-typing A+ランク 259点）。

## オープンソース化の目的

風神配列は、片手に障がい・怪我・一時的な制約がある人でも、通常のキーボードだけで高速な日本語入力を続けられるようにするアクセシビリティ研究プロジェクトです。

現在はWindows / AutoHotkey v2向けの初期実装ですが、今後は利用者フィードバック、ベンチマーク、右手版・クロスプラットフォーム版の検討を進めます。改善提案、検証結果、移植、ドキュメント整備を歓迎します。

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

📝 [片手のキーボード入力を最適化したら練習2週間で両手タイピングより速くなった](https://note.com/honjoh_/n/nd629dd645255)

入力デモ：

- [片手タイピング e-typingスコア「A」231点](https://www.youtube.com/watch?v=n7-D5fHuksI)
- 最高到達点: e-typing 259点 / A+ / WPM 267.73 / 正確率 99.01%

![e-typing score 259 with Fujin Layout](docs/assets/fujin-e-typing-259.webp)

## プロジェクト文書

- [オープンソースとしての意義](OPEN_SOURCE_IMPACT.md)
- [ベンチマークと研究メモ](BENCHMARKS.md)
- [ロードマップ](ROADMAP.md)
- [コントリビューションガイド](CONTRIBUTING.md)
- [ガバナンス](GOVERNANCE.md)

## 関連プロジェクト

- [大和配列（Yamato Layout）](https://honjoh.dev/yamato/) — 両手用の日本語最適化キーボード配列

## フィードバック

不具合の報告や改善の提案は、[Issues](https://github.com/honjoh0823/fujin-layout/issues) からお願いします。

## 作者

**本城 靖大**（[note](https://note.com/honjoh_)）

## ライセンス

MIT License. 詳細は [LICENSE](LICENSE) を参照してください。
