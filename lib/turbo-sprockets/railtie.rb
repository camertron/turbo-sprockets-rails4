module TurboSprockets
  class Railtie < ::Rails::Railtie
    initializer 'turbo-sprockets' do
      unless Sprockets::Manifest.method_defined?(:compile_with_parallelism)
        Sprockets::Manifest.class_eval do
          def compile_with_parallelism(*args)
            if TurboSprockets.configuration.precompiler.enabled?
              TurboSprockets::ParallelCompiler.new(self).compile(*args)
            else
              compile_without_parallelism
            end
          end

          alias_method_chain :compile, :parallelism
        end
      end
    end

    config.after_initialize do
      if ::TurboSprockets.configuration.preloader.enabled?
        # make sure routes are available before attempting to preload, since
        # assets may make use of route helpers
        Rails.application.reload_routes!

        # actually do the preloading
        TurboSprockets::ParallelPreloader.preload!

        # for some reason parallel operations may cause activerecord to
        # disconnect
        if const_defined?(:ActiveRecord)
          ActiveRecord::Base.connection.reconnect!
        end
      end
    end
  end
end
