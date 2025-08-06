module YoutubeToScript
  class MarkdownGenerator
    def initialize(api_key)
      @api_key = api_key
    end
    
    def generate(topics_with_screenshots, video_title = "動画")
      topics_json = JSON.pretty_generate(topics_with_screenshots)
      
      prompt = <<~PROMPT
        以下の動画トピック情報から、読みやすく整理されたMarkdownドキュメントを生成してください。
        
        重要な注意事項：
        - これは動画の字幕とスクリーンショットから生成された要約です
        - 各トピックにはその時点の動画のスクリーンショット画像URLが含まれています
        - スクリーンショット画像は必ず表示し、その時点で何が映っているかを理解する重要な要素として扱ってください
        
        Markdown生成の要件：
        - タイトルは「# #{video_title}」とする
        - 簡潔な目次を作成（各トピックのタイトルとタイムスタンプのリスト）
        - 各トピックごとに番号付きセクションを作成
        - タイムスタンプを見やすく表示（例: 【00:01:23】）
        - screenshot_urlがある場合は必ずMarkdown画像として含める
        - 画像の前後に適切な改行を入れて見やすくする
        - 画像のalt textは意味のあるものにする
        - 内容説明（description）は段落分けして読みやすくする
        - セクション間は水平線（---）で区切る
        - 絵文字は使用しない
        - シンプルで読みやすい構成を心がける
        
        トピック情報（timestamp, title, description, screenshot_urlを含む）：
        #{topics_json}
        
        動画タイトル：#{video_title}
        
        上記の情報を元に、動画を見ていない人でも内容が理解できる、構造化されたMarkdownドキュメントを生成してください。
      PROMPT
      
      response = call_openai_api(prompt)
      response["choices"][0]["message"]["content"]
    end
    
    private
    
    def call_openai_api(prompt)
      uri = URI('https://api.openai.com/v1/chat/completions')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@api_key}"
      request['Content-Type'] = 'application/json'
      
      request.body = {
        model: "gpt-4.1",
        messages: [
          {
            role: "system",
            content: "あなたは動画の要約をMarkdown形式で整理する専門家です。字幕とスクリーンショットから、読みやすく理解しやすいドキュメントを作成します。"
          },
          {
            role: "user",
            content: prompt
          }
        ],
        temperature: 0.3
      }.to_json
      
      response = http.request(request)
      JSON.parse(response.body)
    end
  end
end