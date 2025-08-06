module YoutubeToScript
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
end