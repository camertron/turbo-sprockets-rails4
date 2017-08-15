## turbo-sprockets-rails4
Speed up asset precompliation by compiling assets in parallel.

## Installation

`gem install turbo-sprockets-rails4`

or put it in your Gemfile:

```ruby
gem 'turbo-sprockets-rails4'
```

### Rationale

Sprockets is slow. Turbo-sprockets uses parallelism to speed it up so your life isn't spent waiting for assets.

Said a little more long-form, a large, long-lived Rails application can have a ton of static assets. It can be a real drag on productivity and deployments to have to wait for Rails to chew through them all. Although the slowness can be attributed to a number of factors, one of the most significant has to do with Ruby's single-threaded execution model. Most servers and laptops these days come with multiple processors or cores, but Rails doesn't take advantage of them. Wouldn't it be nice if we could put all our CPU cores to work precompiling assets? That's where turbo-sprockets comes in.

### What's Included?

Turbo-sprockets includes two major components: the asset precompiler and the asset preloader.

#### Asset Precompiler

The turbo-sprockets precompiler precompiles assets in parallel using potentially all the CPU cores available on your laptop or server. Generally this translates into a substantial speed increase. In one of the large codebases I've worked on, turbo-sprockets decreased the total precompile time from ~12 minutes to ~2 minutes using the four cores on my laptop. Obviously that's a micro benchmark that doesn't mean much, so your mileage may vary. Intuitively however, tasks get done faster when you can do more than one at a time.

#### Asset Preloader

The asset preloader is a little different. As of Sprockets 3, a Rails server running in the development environment will attempt to compile and cache every asset your application might need _on the first page request_. This is different from how things used to work. In the old days, Rails would compile assets on-the-fly. For example, if your app requested dashboard.css but not home_page.css, Rails would only compile dashboard.css. For applications with a large number of assets, compiling all of them on the first page request can be prohibitively time-consuming. The asset preloader tries to allieviate this pain by compiling and caching assets in parallel when your app boots. It's like the precompiler, but for development.

### Configuration

By default, asset preloading is enabled only in the development environment, and only if you're running `rails server`. Precompiling is enabled in every environment _except_ development. You can enable or disable these two components by configuring turbo-sprockets (generally in one of your environment files, or maybe an initializer):

```ruby
TurboSprockets.configure do |config|
  config.preloader.enabled = false
  config.precompiler.enabled = false
end
```

#### Parallelism

By default, parallel preloading and precompiling will spin up two processes to perform the necessary work. You can set this number in one of two ways. Use the `TURBO_SPROCKETS_WORKER_COUNT` environment variable, eg. `TURBO_SPROCKETS_WORKER_COUNT=2 bundle exec rake assets:precompile` or set it when configuring turbo-sprockets:

```ruby
TurboSprockets.configure do |config|
  config.preloader.worker_count = 2
  config.precompiler.worker_count = 2
end
```

### How Does it Work?

Under the hood, turbo-sprockets uses the [parallel](https://github.com/grosser/parallel) gem to divide your assets up amongst the available CPU cores. It works by [forking](https://en.wikipedia.org/wiki/Fork_(system_call)) into multiple system processes which are executed in parallel by your operating system.

### Supported Platforms

turbo-sprockets works with any Ruby that supports `Process#fork` such as the Rubies that run on most flavors of Unix, Linux, BSD, and MacOS. It won't work on Windows. Specifically, if `Process#fork` isn't available, turbo-sprockets won't raise an error, but it also won't provide any sort of speed improvement.

### Disclaimer

Everybody's setup is a little different, so please remember that, with respect to turbo-sprockets, your mileage may vary. You may see an increase in precompliation speed or none at all depending on the mix of assets in your application.

## License

Licensed under the MIT license. See LICENSE for details.

## Authors

* Cameron C. Dutro: http://github.com/camertron
