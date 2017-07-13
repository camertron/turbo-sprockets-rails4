require 'parallel'

# The asset preloader is designed to precompute and cache all precompilable
# assets in parallel to avoid doing it in serial on the first request. As of
# Sprockets 3, all assets on the precompile list (i.e. config.assets.precompile)
# are compiled on the first request whether the current page has asked for them
# or not. Obviously such behavior can mean a very slow initial request (we were
# seeing load times on the order of 10-11 minutes). By preloading, or warming the
# sprockets cache, initial page load times can be reduced to ~15 seconds (with
# an additional ~2 minutes spent during boot). Preloading only happens once, so
# subsequent requests should be fast. Preloading is different from precompiling,
# as the latter does not appear to cache the assets once they've been compiled.
# Generally speaking, preloading should be done in development and precompiling
# should be done in production.
module TurboSprockets
  class ParallelPreloader
    class << self
      def preload!
        list = precompile_list

        count = 0
        count_mutex = Mutex.new

        options = {
          in_processes: worker_count,
          finish: -> (*) {
            count_mutex.synchronize { count += 1 }

            if count % 10 == 0 || count == list.size
              logger.info("#{count}/#{list.size} preloading assets... ")
            end
          }
        }

        Parallel.each(list, options) do |path|
          # compat: false causes #resolve to return fully resolved asset URIs,
          # complete with correct MIME type, etc
          uri, _ = assets.resolve(path, compat: false)
          next unless uri

          # only load the asset if it hasn't been cached yet
          unloaded = Sprockets::UnloadedAsset.new(uri, assets)
          key = unloaded.dependency_history_key
          assets.load(uri) unless assets.cache.get(key)

          nil
        end

        logger.info('done')
      end

      private

      # find all assets that have been added to the precompile list
      # code adapted from Sprockets::Manifest and Sprockets::Legacy
      def precompile_list
        paths, filters = config.assets.precompile.partition do |arg|
          Sprockets::Manifest.simple_logical_path?(arg)
        end

        filters = filters.map do |arg|
          Sprockets::Manifest.compile_match_filter(arg)
        end

        paths + assets.logical_paths.each_with_object([]) do |(logical_path, filename), ret|
          if filters.any? { |f| f.call(logical_path, filename) }
            ret << logical_path
          end
        end
      end

      def worker_count
        TurboSprockets.configuration.preloader.worker_count
      end

      def config
        Rails.application.config
      end

      def assets
        Rails.application.assets
      end

      def logger
        TurboSprockets.configuration.preloader.logger
      end
    end
  end
end
