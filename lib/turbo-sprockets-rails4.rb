require 'turbo-sprockets/railtie'

module TurboSprockets
  autoload :ParallelCompiler, 'turbo-sprockets/parallel_compiler'

  def self.logger
    Rails.application.assets_manifest.send(:logger)
  end
end
