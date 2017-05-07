module TurboSprockets
  class Railtie < ::Rails::Railtie
    initializer 'turbo-sprockets' do
      unless Sprockets::Manifest.method_defined?(:compile_with_parallelism)
        Sprockets::Manifest.class_eval do
          def compile_with_parallelism(*args)
            ::TurboSprockets::ParallelCompiler.new(self).compile(*args)
          end

          alias_method_chain :compile, :parallelism
        end
      end
    end
  end
end
