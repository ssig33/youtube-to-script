module YoutubeToScript
  class Pipeline
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
end