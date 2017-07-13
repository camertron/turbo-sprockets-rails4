require 'spec_helper'

describe TurboSprockets::ParallelCompiler do
  def precompile!
    Rake::Task['assets:precompile'].reenable
    Rake::Task['assets:precompile'].invoke
  end

  def with_env(env)
    # ENV can't be duped, so use select instead to make a copy
    old_env = ENV.select { true }
    env.each_pair { |k, v| ENV[k] = v }
    yield
  ensure
    # reset back to old vars
    env.each_pair { |k, _| ENV[k] = old_env[k] }
  end

  let(:files) do
    {
      'file1.js' => 'file1-9461265d541718e5776632b202c4ccdd21f13d9cd7d0b4d92c1b43131292749a.js',
      'file2.js' => 'file2-e2a24754a5ca8cb2f9c645a80ad4d4ca375c4d9914f1d962b4fb3e779dc4ad34.js'
    }
  end

  it 'precompiles all assets' do
    # make sure we have _some_ way of knowing parallel compliation is happening
    expect(Parallel).to receive(:map).and_call_original

    precompile!

    files.each do |logical_path, digest_path|
      expect(assets_dir.join(digest_path)).to exist
      expect(assets_dir.join("#{digest_path}.gz")).to exist
    end
  end

  it 'writes a manifest' do
    precompile!
    expect(Pathname(app.config.assets.manifest)).to exist
    manifest = JSON.parse(File.read(app.config.assets.manifest))
    expect(manifest['assets']).to eq(files)
  end

  it 'uses the specified number of workers' do
    with_env('TURBO_SPROCKETS_WORKER_COUNT' => '4') do
      precompile!
    end

    expect(logger.messages).to include([:warn, 'Precompiling with 4 workers'])
  end

  it 'does not compile in parallel when configured not to' do
    TurboSprockets.configure do |config|
      config.precompile_in_parallel = false
    end

    precompile!

    expect(logger.messages).to be_empty
  end
end
