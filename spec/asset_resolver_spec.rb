require 'spec_helper'
require 'securerandom'

describe TurboSprockets::AssetResolver do
  RSpec::Matchers.define :match_digested do |expected|
    match do |actual|
      extname = File.extname(expected)
      re = /#{expected.chomp(extname)}-[a-f0-9]+#{extname}/
      !!(re =~ actual)
    end
  end

  let(:environment) { Sprockets::Environment.new(Rails.root) }
  let(:manifest_path) { 'manifest.json' }
  let(:logical_path) { 'file1.js' }
  let(:asset_host) { 'http://localhost:3000' }

  # sprockets options
  let(:prefix) { '' }
  let(:digest) { true }
  let(:compile) { true }

  # adapted from:
  # https://github.com/rails/sprockets-rails/blob/v3.2.0/lib/sprockets/railtie.rb#L198
  let(:manifest) do
    path = File.join('public', prefix)
    Sprockets::Manifest.new(environment, path, manifest_path)
  end

  def logical_to_digested_path(logical_path)
    extname = File.extname(logical_path)
    digest_hash = SecureRandom.hex
    "#{logical_path.chomp(extname)}-#{digest_hash}#{extname}"
  end

  before do
    allow(Rails.application).to receive(:assets).and_return(environment)
    allow(Rails.application).to receive(:assets_manifest).and_return(manifest)
    allow(Rails.application.config.assets).to receive(:digest).and_return(digest)
    allow(Rails.application.config.assets).to receive(:compile).and_return(compile)
    allow(Rails.application.config.assets).to receive(:prefix).and_return(prefix)
    allow(Rails.application.config.action_controller).to receive(:asset_host).and_return(asset_host)
  end

  describe '.url_join' do
    it 'joins url segments with mismatched leading/trailing slashes' do
      expect(described_class.url_join('foo/', '/bar/', '/baz')).to eq('foo/bar/baz')
    end

    it 'keeps absolute URLs absolute' do
      expect(described_class.url_join('/foo', '/bar/', '/baz')).to eq('/foo/bar/baz')
    end

    it "doesn't modify domain names and schemes" do
      expect(described_class.url_join('https://foo.com', '/bar/', '/baz')).to(
        eq('https://foo.com/bar/baz')
      )
    end
  end

  context 'with a sprockets environment' do
    before do
      Rails.application.config.assets.paths.each do |path|
        environment.append_path(path)
        environment.context_class.send(:include, ::Sprockets::Rails::Context)
        environment.context_class.digest_assets = digest
        environment.context_class.assets_prefix = prefix
      end
    end

    context 'when digesting is disabled' do
      let(:digest) { false }

      describe '.resolve' do
        it 'returns a relative undigested path' do
          expect(described_class.resolve(logical_path)).to eq(logical_path)
        end
      end

      describe '.resolve_naked' do
        it 'returns the original, absolute, undigested asset path' do
          expect(described_class.resolve_naked(logical_path)).to eq(
            Rails.root.join(File.join(%w[app assets javascripts])).join(logical_path).to_s
          )
        end
      end

      describe '.resolve_url_for' do
        it 'returns the full undigested URL' do
          expect(described_class.resolve_url_for(logical_path)).to eq(
            "#{asset_host}/#{prefix}/#{logical_path}"
          )
        end
      end
    end

    context 'when digesting is enabled' do
      describe '.resolve' do
        it 'returns a relative digested asset path' do
          result = described_class.resolve(logical_path)
          expect(result).to match_digested(logical_path)
        end
      end

      describe '.resolve_naked' do
        it 'returns the original, absolute, undigested asset path' do
          expect(described_class.resolve_naked(logical_path)).to eq(
            Rails.root.join(File.join(%w[app assets javascripts])).join(logical_path).to_s
          )
        end
      end

      describe '.resolve_url_for' do
        it 'returns the full digested URL' do
          uri = URI.parse(described_class.resolve_url_for(logical_path))
          expect(uri.path.sub(/\/?#{prefix}\/?/, '')).to match_digested(logical_path)
          expect(uri.to_s).to start_with(asset_host)
        end
      end
    end
  end

  context 'without a sprockets environment' do
    let(:environment) { nil }
    let(:compile) { false }

    before do
      manifest.assets[logical_path] = logical_to_digested_path(logical_path)
    end

    describe '.resolve' do
      it 'returns the relative digested path from the manifest' do
        result = described_class.resolve(logical_path)
        expect(result).to eq(manifest.assets[logical_path])
      end
    end

    describe '.resolve_naked' do
      it 'returns the original, absolute, undigested asset path' do
        expect(described_class.resolve_naked(logical_path)).to eq(
          Rails.root.join(File.join(%w[app assets javascripts])).join(logical_path).to_s
        )
      end
    end

    describe '.resolve_url_for' do
      it 'returns the full digested URL' do
        uri = URI.parse(described_class.resolve_url_for(logical_path))
        expect(uri.path.sub(/\/?#{prefix}\/?/, '')).to match_digested(logical_path)
        expect(uri.to_s).to start_with(asset_host)
      end
    end
  end
end
