require 'turbo-sprockets/railtie'

module TurboSprockets
  autoload :AssetResolver,     'turbo-sprockets/asset_resolver'
  autoload :ParallelCompiler,  'turbo-sprockets/parallel_compiler'
  autoload :ParallelPreloader, 'turbo-sprockets/parallel_preloader'

  class Config
    attr_reader :precompiler, :preloader

    def initialize(options = {})
      @precompiler = ComponentConfig.new(options.fetch(:precompiler, {}))
      @preloader = ComponentConfig.new(options.fetch(:preloader, {}))
    end
  end

  class ComponentConfig
    DEFAULT_WORKER_COUNT = 2

    attr_accessor :enabled, :worker_count, :logger
    alias_method :enabled?, :enabled

    def initialize(options = {})
      options.each_pair do |key, value|
        send("#{key}=", value)
      end
    end

    def worker_count
      worker_count_from_env || @worker_count || DEFAULT_WORKER_COUNT
    end

    def logger
      @logger || Rails.logger
    end

    private

    def worker_count_from_env
      if count = ENV['TURBO_SPROCKETS_WORKER_COUNT']
        count.to_i
      end
    end
  end

  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Config.new(
        precompiler: { enabled: true },
        preloader:   { enabled: true }
      )
    end
  end
end
