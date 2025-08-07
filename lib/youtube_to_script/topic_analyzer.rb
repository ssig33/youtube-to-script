module YoutubeToScript
  class TopicAnalyzer
    def initialize(api_key)
      @api_key = api_key
    end
    
    def analyze(subtitles)
      subtitle_text = subtitles.map { |s| "#{s[:start_time]}: #{s[:text]}" }.join("\n")
      
      prompt = <<~PROMPT
        以下の動画の字幕から、最も重要なトピックやセクションを最大8個まで抽出してください。
        細かすぎる区切りは避け、意味のあるまとまりごとにトピックを分けてください。
        各トピックについて、開始時刻（HH:MM:SS形式）、わかりやすいタイトル、そして詳細な内容説明を日本語で提供してください。
        
        説明は以下の要素を含めて、読者が動画を見なくても内容が理解できるようにしてください：
        - そのセクションで話されている主要な内容の詳しい要約
        - 登場する重要なキーワード、概念、用語の説明
        - 話者の主張、意見、結論
        - 具体的な例、データ、エピソードがあれば含める
        - そのトピックがなぜ重要か、どういう文脈で語られているか
        
        出力形式は以下のJSONでお願いします：
        {
          "topics": [
            {
              "timestamp": "00:01:23",
              "title": "わかりやすいタイトル（30文字以内）",
              "description": "このセクションでは〜について詳しく説明されています。まず〜という点から話が始まり、〜という重要な概念が紹介されます。話者は〜と主張し、その根拠として〜を挙げています。特に興味深いのは〜という点で、これは〜を意味しています。また、〜という具体例も示され、〜ということがわかります。このトピックの重要性は〜にあり、全体の文脈では〜という位置づけになっています。（300-500文字程度の充実した説明）"
            }
          ]
        }
        
        字幕：
        #{subtitle_text}
      PROMPT
      
      response = call_openai_api(prompt)
      JSON.parse(response["choices"][0]["message"]["content"])["topics"]
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
        model: "gpt-5-mini",
        messages: [
          {
            role: "system",
            content: "あなたは動画の内容を分析し、重要なトピックを抽出する専門家です。"
          },
          {
            role: "user",
            content: prompt
          }
        ],
        temperature: 0.7,
        response_format: { type: "json_object" }
      }.to_json
      
      response = http.request(request)
      JSON.parse(response.body)
    end
  end
end
