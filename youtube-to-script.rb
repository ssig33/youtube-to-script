#!/usr/bin/env ruby

def require_gem(gem_name)
  begin
    require gem_name
  rescue LoadError
    puts "Error: gem '#{gem_name}' is not installed"
    puts "Please run: gem install #{gem_name}"
    exit 1
  end
end

require 'json'
require 'net/http'
require 'uri'
require 'tempfile'
require 'fileutils'

class WebVTTParser
  def initialize(vtt_file_path)
    @vtt_file_path = vtt_file_path
  end

  def parse
    content = File.read(@vtt_file_path)
    
    subtitles = []
    current_subtitle = {}
    
    lines = content.split("\n")
    i = 0
    
    while i < lines.length
      line = lines[i].strip
      
      if line =~ /(\d{2}:\d{2}:\d{2}\.\d{3})\s*-->\s*(\d{2}:\d{2}:\d{2}\.\d{3})/
        if !current_subtitle.empty?
          subtitles << current_subtitle
        end
        
        current_subtitle = {
          start_time: $1,
          end_time: $2,
          start_seconds: time_to_seconds($1),
          end_seconds: time_to_seconds($2),
          text: ""
        }
        
        i += 1
        while i < lines.length && !lines[i].strip.empty? && !(lines[i] =~ /-->/)
          current_subtitle[:text] += lines[i].strip + " "
          i += 1
        end
        current_subtitle[:text] = current_subtitle[:text].strip
      else
        i += 1
      end
    end
    
    subtitles << current_subtitle if !current_subtitle.empty?
    
    subtitles
  end
  
  private
  
  def time_to_seconds(time_str)
    parts = time_str.split(':')
    hours = parts[0].to_i
    minutes = parts[1].to_i
    seconds = parts[2].to_f
    
    hours * 3600 + minutes * 60 + seconds
  end
end

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
      model: "gpt-4.1",
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

class ScreenshotCapture
  def initialize(video_path)
    @video_path = video_path
  end
  
  def capture(timestamp)
    temp_file = Tempfile.new(['screenshot', '.png'])
    temp_path = temp_file.path
    temp_file.close
    
    success = system(
      "ffmpeg",
      "-ss", timestamp,
      "-i", @video_path,
      "-vframes", "1",
      "-q:v", "2",
      "-y",
      temp_path,
      err: File::NULL
    )
    
    if success && File.exist?(temp_path) && File.size(temp_path) > 0
      temp_path
    else
      nil
    end
  rescue => e
    puts "Screenshot capture error: #{e.message}"
    nil
  end
end

class GyazoUploader
  def initialize(api_token)
    @api_token = api_token
  end
  
  def upload(image_path)
    uri = URI('https://upload.gyazo.com/api/upload')
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_token}"
    
    File.open(image_path, 'rb') do |file|
      request.set_form([['imagedata', file]], 'multipart/form-data')
      
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
      
      if response.code == '200'
        result = JSON.parse(response.body)
        result['url']
      else
        nil
      end
    end
  end
end

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

class VideoToScriptPipeline
  def initialize(video_path, vtt_path, output_path)
    @video_path = video_path
    @vtt_path = vtt_path
    @output_path = output_path
    
    @openai_key = ENV['OPENAI_API_KEY']
    @gyazo_token = ENV['GYAZO_TOKEN']
    
    validate_environment!
  end
  
  def run
    puts "1. WebVTT字幕を解析中..."
    parser = WebVTTParser.new(@vtt_path)
    subtitles = parser.parse
    puts "  -> #{subtitles.length}個の字幕を解析しました"
    
    puts "2. AI（gpt-4.1）でトピックを分析中..."
    analyzer = TopicAnalyzer.new(@openai_key)
    topics = analyzer.analyze(subtitles)
    puts "  -> #{topics.length}個のトピックを抽出しました"
    
    puts "3. スクリーンショットを取得中..."
    capture = ScreenshotCapture.new(@video_path)
    uploader = GyazoUploader.new(@gyazo_token)
    
    topics_with_screenshots = []
    topics.each_with_index do |topic, index|
      print "  -> トピック #{index + 1}/#{topics.length}: #{topic['title']}..."
      
      screenshot_path = capture.capture(topic['timestamp'])
      
      if screenshot_path
        screenshot_url = uploader.upload(screenshot_path)
        FileUtils.rm_f(screenshot_path)
        
        if screenshot_url
          puts " ✓"
          topics_with_screenshots << {
            timestamp: topic['timestamp'],
            title: topic['title'],
            description: topic['description'],
            screenshot_url: screenshot_url
          }
        else
          puts " × (Gyazoアップロード失敗)"
          topics_with_screenshots << {
            timestamp: topic['timestamp'],
            title: topic['title'],
            description: topic['description'],
            screenshot_url: nil
          }
        end
      else
        puts " × (スクリーンショット取得失敗)"
        topics_with_screenshots << {
          timestamp: topic['timestamp'],
          title: topic['title'],
          description: topic['description'],
          screenshot_url: nil
        }
      end
    end
    
    puts "4. Markdownを生成中..."
    generator = MarkdownGenerator.new(@openai_key)
    video_title = File.basename(@video_path, File.extname(@video_path))
    markdown = generator.generate(topics_with_screenshots, video_title)
    
    File.write(@output_path, markdown)
    puts "  -> #{@output_path}に保存しました"
    
    puts "\n完了しました！"
  end
  
  private
  
  def validate_environment!
    if @openai_key.nil? || @openai_key.empty?
      puts "Error: OPENAI_API_KEY環境変数が設定されていません"
      exit 1
    end
    
    if @gyazo_token.nil? || @gyazo_token.empty?
      puts "Error: GYAZO_TOKEN環境変数が設定されていません"
      exit 1
    end
    
    unless File.exist?(@video_path)
      puts "Error: 動画ファイルが見つかりません: #{@video_path}"
      exit 1
    end
    
    unless File.exist?(@vtt_path)
      puts "Error: 字幕ファイルが見つかりません: #{@vtt_path}"
      exit 1
    end
    
    unless system("which ffmpeg > /dev/null 2>&1")
      puts "Error: ffmpegがインストールされていません"
      puts "Please install ffmpeg first"
      exit 1
    end
  end
end

if __FILE__ == $0
  if ARGV.length != 3
    puts "Usage: #{$0} <video_file> <vtt_file> <output_markdown>"
    puts "Example: #{$0} video.mp4 subtitles.vtt output.md"
    exit 1
  end
  
  video_path = ARGV[0]
  vtt_path = ARGV[1]
  output_path = ARGV[2]
  
  pipeline = VideoToScriptPipeline.new(video_path, vtt_path, output_path)
  pipeline.run
end
