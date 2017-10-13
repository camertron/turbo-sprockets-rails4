require 'benchmark'
require 'parallel'
require 'json'

module TurboSprockets
  class ParallelCompiler
    attr_reader :manifest

    def initialize(manifest)
      @manifest = manifest
    end

    def compile(*args)
      logger.warn "Precompiling with #{worker_count} workers"

      time = Benchmark.measure do
        results = compile_in_parallel(find_precompile_paths(*args))
        write_manifest(results)
      end

      logger.info "Completed precompiling assets (#{time.real.round(2)}s)"
    end

    private

    def write_manifest(results)
      File.write(manifest.filename, results.to_json)
    end

    def compile_in_parallel(paths)
      flatten_precomp_results(
        Parallel.map(paths, in_processes: worker_count) do |path|
          manifest.compile_without_parallelism([path])

          { 'files' => {}, 'assets' => {} }.tap do |data|
            manifest.find([path]) do |asset|
              next if File.exist?(asset.digest_path) # don't recompile
              logger.info("Writing #{asset.digest_path}")
              
              data['files'][asset.digest_path] = properties_for(asset)
              data['assets'][asset.logical_path] = asset.digest_path

              if alias_logical_path = manifest.class.compute_alias_logical_path(asset.logical_path)
                data['assets'][alias_logical_path] = asset.digest_path
              end
            end
          end
        end
      )
    end

    def flatten_precomp_results(results)
      results.each_with_object({}) do |result, ret|
        result.each_pair do |key, data|
          (ret[key] ||= {}).merge!(data)
        end
      end
    end

    def find_precompile_paths(*args)
      paths, filters = args.flatten.partition do |pre|
        manifest.class.simple_logical_path?(pre)
      end

      filters = filters.map do |filter|
        manifest.class.compile_match_filter(filter)
      end

      environment.logical_paths.each do |logical_path, filename|
        if filters.any? { |f| f.call(logical_path, filename) }
          paths << filename
        end
      end

      paths
    end

    def properties_for(asset)
      {
        'logical_path' => asset.logical_path,
        'mtime'        => asset.mtime.iso8601,
        'size'         => asset.bytesize,
        'digest'       => asset.hexdigest,
      }
    end

    def worker_count
      TurboSprockets.configuration.precompiler.worker_count
    end

    def environment
      manifest.environment
    end

    def logger
      TurboSprockets.configuration.precompiler.logger
    end
  end
end
