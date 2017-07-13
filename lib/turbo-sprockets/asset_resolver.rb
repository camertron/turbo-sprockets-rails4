module TurboSprockets
  class AssetResolver
    class << self
      # Returns a relative, digested asset path for the given logical path.
      #
      # For example:
      #   AssetResolver.resolve('lux/checkmark_2x.png')
      #     => lux/checkmark_2x-7177b0151ec35ffb6d.png
      #
      def resolve(logical_path)
        # If compile is true we're running in development and have access to the
        # sprockets environment. If compile is false the sprockets environment
        # will not be available, so we have to fall back to the asset manifest.
        if Rails.application.config.assets.compile
          asset = Rails.application.assets.find_asset(logical_path)

          if Rails.application.config.assets.digest
            asset.try(&:digest_path)
          else
            asset.try(&:logical_path)
          end
        else
          Rails.application.assets_manifest.assets[logical_path]
        end
      end

      # Returns an absolute, undigested asset path for the given logical path.
      # This is the original asset path from app/assets or similar.
      #
      # For example:
      #   AssetResolver.resolve_naked('lux/checkmark_2x.png')
      #     => /data/lumoslabs/shared/bundle/ruby/2.4.0/gems/lux-2.11.0/app/assets/images/lux/checkmark_2x.png
      #
      def resolve_naked(logical_path)
        # check to see if logical_path exists within any of the current asset paths
        Rails.application.config.assets.paths.each do |path|
          candidate = File.join(path, logical_path)
          return candidate if File.exist?(candidate)
        end
      end

      # Returns the absolute, digested URL for the given logical path. This
      # includes important stuff like the CDN host/port and asset prefix
      # (i.e. /compiled).
      #
      # For example:
      #   AssetResolver.resolve_url_for('lux/checkmark_2x.png')
      #     => https://asset.lumosity.com:443/compiled/lux/checkmark_2x-7177b0151ec35ffb6d.png
      #
      def resolve_url_for(logical_path)
        url_join(
          Rails.application.config.action_controller.asset_host,
          Rails.application.config.assets.prefix,
          resolve(logical_path)
        )
      end

      # Operates like File.join, but on segments of a URL. Specifically, it makes
      # sure the segments are conjoined by only one forward slash. The URI class
      # is also capable of doing this, but is much more difficult to use. Note
      # that this method doesn't consider whether or not the segments are relative
      # or absolute - it simply joins them.
      #
      # Examples:
      #   UrlMethods.join('/foo/', '/bar', '/baz/')
      #     => 'foo/bar/baz'
      #
      #   UrlMethods.join('http://foo.com', 'bar/', '/baz')
      #     # => 'http://foo.com/bar/baz'
      #
      def url_join(*segments)
        segments.compact!

        # this regex strips off leading and trailing forward slashes
        joined = segments.map { |p| p.sub(/\A\/?(.*?)\/?\z/, "\\1") }.join('/')

        # handle absolute URLs
        segments.first.start_with?('/') ? "/#{joined}" : joined
      end
    end
  end
end
