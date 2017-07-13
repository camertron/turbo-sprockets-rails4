require 'turbo-sprockets/railtie'

module TurboSprockets
  autoload :AssetResolver,     'turbo-sprockets/asset_resolver'
  autoload :ParallelCompiler,  'turbo-sprockets/parallel_compiler'
  autoload :ParallelPreloader, 'turbo-sprockets/parallel_preloader'

  DEFAULT_WORKER_COUNT = 2

  class Config
    FIELDS = [:preload_in_parallel, :precompile_in_parallel]

    attr_accessor *FIELDS

    FIELDS.each { |f| alias_method :"#{f}?", f }

    def initialize(options = {})
      options.each_pair do |key, value|
        send("#{key}=", value)
      end
    end
  end

  class << self
    def configure
      yield configuration
    end

    def logger
      Rails.application.assets_manifest.send(:logger)
    end

    def worker_count
      ENV.fetch('TURBO_SPROCKETS_WORKER_COUNT', DEFAULT_WORKER_COUNT).to_i
    end

    def configuration
      @configuration ||= Config.new(
        preload_in_parallel: true,
        precompile_in_parallel: true
      )
    end
  end
end
