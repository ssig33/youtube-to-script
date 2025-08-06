require 'json'
require 'net/http'
require 'uri'
require 'tempfile'
require 'fileutils'

require_relative 'youtube_to_script/version'
require_relative 'youtube_to_script/webvtt_parser'
require_relative 'youtube_to_script/topic_analyzer'
require_relative 'youtube_to_script/screenshot_capture'
require_relative 'youtube_to_script/gyazo_uploader'
require_relative 'youtube_to_script/markdown_generator'
require_relative 'youtube_to_script/pipeline'

module YoutubeToScript
  class Error < StandardError; end
end