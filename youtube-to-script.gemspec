# frozen_string_literal: true

require_relative "lib/youtube_to_script/version"

Gem::Specification.new do |spec|
  spec.name = "youtube-to-script"
  spec.version = YoutubeToScript::VERSION
  spec.authors = ["ssig33"]
  spec.email = ["mail@ssig33.com"]

  spec.summary = "AIを活用してYouTube動画と字幕から要約Markdownを生成"
  spec.description = "YouTube動画とWebVTT字幕から、OpenAI APIを使用して重要なトピックを抽出し、スクリーンショット付きの日本語要約Markdownドキュメントを自動生成するツールです。"
  spec.homepage = "https://github.com/ssig33/youtube-to-script"
  spec.license = "WTFPL"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ssig33/youtube-to-script"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "bin"
  spec.executables = ["youtube-to-script"]
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
