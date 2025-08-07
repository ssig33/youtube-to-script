# youtube-to-script

YouTube動画とWebVTT字幕から、AIを活用して日本語の要約Markdownドキュメントを自動生成するRubyツールです。

## 機能

- WebVTT字幕の解析
- OpenAI API (gpt-5モデル) を使った重要トピックの抽出
- ffmpegで動画の各トピック時点のスクリーンショット取得
- Gyazoへの画像アップロード
- スクリーンショット付きMarkdownドキュメントの生成

## インストール

```bash
gem install youtube-to-script
```

## 必要な環境

### 環境変数

以下の環境変数を設定する必要があります：

- `OPENAI_API_KEY` - OpenAI のAPIキー
- `GYAZO_TOKEN` - Gyazo のアクセストークン

### 外部ツール

- ffmpeg がインストールされている必要があります

```bash
# macOS
brew install ffmpeg

# Ubuntu/Debian
sudo apt install ffmpeg
```

## 使用方法

```bash
youtube-to-script input.mp4 input.vtt output.md
```

### 引数

- `input.mp4` - YouTube動画ファイル（または任意の動画ファイル）
- `input.vtt` - WebVTT形式の字幕ファイル
- `output.md` - 出力するMarkdownファイルのパス

## 出力例

生成されるMarkdownドキュメントには以下が含まれます：

- 動画タイトル
- 目次（各トピックへのリンク付き）
- 各トピックごとのセクション
  - タイムスタンプ
  - トピックタイトル
  - スクリーンショット画像
  - 詳細な内容説明（300-500文字程度）

## 開発

```bash
git clone https://github.com/ssig33/youtube-to-script.git
cd youtube-to-script
bundle install
```

## ライセンス

WTFPL

## 作者

ssig33

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ssig33/youtube-to-script.
