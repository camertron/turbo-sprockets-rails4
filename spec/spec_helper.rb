# encoding: UTF-8

$:.push(File.dirname(__FILE__))

require 'rspec'
require 'pry-byebug'

require 'rails'
require 'rake'
require 'sprockets/railtie'

ENV['RAILS_ENV'] ||= 'test'

require 'turbo-sprockets-rails4'

Dir.chdir('spec') do
  require File.expand_path('../config/application', __FILE__)
  TurboSprockets::DummyApplication.initialize!
  TurboSprockets::DummyApplication.load_tasks  # used by precompilation specs
end

module LetDeclarations
  extend RSpec::SharedContext

  let(:app) { Rails.application }
  let(:assets) { app.assets }
  let(:logger) { CapturingLogger.new }

  let(:assets_dir) do
    TurboSprockets::DummyApplication.root.join('public/assets')
  end

  let(:tmp_dir) do
    TurboSprockets::DummyApplication.root.join('tmp')
  end
end

class CapturingLogger
  attr_reader :messages

  def initialize
    @messages = []
  end

  def info(msg)
    messages << [:info, msg]
  end

  def warn(msg)
    messages << [:warn, msg]
  end

  def error(msg)
    messages << [:error, msg]
  end
end

RSpec.configure do |config|
  config.include(LetDeclarations)

  config.before do
    FileUtils.rm_rf(tmp_dir)
    FileUtils.rm_rf(assets_dir)
    FileUtils.mkdir_p(assets_dir)

    TurboSprockets.configure do |config|
      config.preloader.logger = logger
      config.precompiler.logger = logger
    end
  end

  config.after(:each) do
    TurboSprockets.instance_variable_set(:@configuration, nil)
  end
end
