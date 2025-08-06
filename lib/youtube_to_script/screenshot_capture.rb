module YoutubeToScript
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
end