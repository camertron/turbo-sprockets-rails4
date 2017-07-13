require 'spec_helper'

describe TurboSprockets::ParallelPreloader do
  let(:logical_paths) { %w(file1.js file2.js) }

  def get_cached_asset(path)
    uri, _ = assets.resolve(path, compat: false)
    key = Sprockets::UnloadedAsset.new(uri, assets).dependency_history_key
    assets.cache.get(key)
  end

  describe '.preload!' do
    it 'preloads all assets' do
      logical_paths.each do |path|
        expect(get_cached_asset(path)).to be_nil
      end

      described_class.preload!

      logical_paths.each do |path|
        expect(get_cached_asset(path)).to_not be_nil
      end
    end
  end
end
