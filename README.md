## turbo-sprockets-rails4
Speed up asset precompliation by compiling assets in parallel.

## Installation

`gem install turbo-sprockets-rails4`

or put it in your Gemfile:

```ruby
gem 'turbo-sprockets-rails4'
```

### Rationale

In a large Rails application, assets can take a very long time to precompile. It can be a real drag on productivity and deployments to have to wait until your assets are done precompiling. Although the slowness can be attributed to a number of factors, one of the most significant has to do with Ruby's single-threaded execution model. Most servers and laptops these days come with multiple processors or cores, but Rails doesn't take advantage of them. Wouldn't it be nice if we could put all our CPU cores to work precompiling assets?

That's where this gem comes in. turbo-sprockets is capable of precompiling assets in parallel, using all the CPU cores available on your laptop or server. Generally this translates into a substantial speed increase. In one of the large codebases I've worked on, turbo-sprockets decreased the total precompile time from ~12 minutes to ~2 minutes using the four cores on my laptop.

### Getting Started

turbo-sprockets is designed to work as a drop-in addition to your Rails app. Adding it to your Gemfile and running `bundle install` should be all that's necessary to enable your application to precompile assets in parallel.

### Configuration

Rather than guess how many CPU cores your computer has (which can be error prone), turbo-sprockets asks that you set the `SPROCKETS_WORKER_COUNT` environment variable (2 cores are used by default). For example, to precompile using 4 workers, you might run:

```bash
SPROCKETS_WORKER_COUNT=4 bundle exec rake assets:precompile
```

### How Does it Work?

Under the hood, turbo-sprockets uses the [parallel](https://github.com/grosser/parallel) gem to divide your assets up amongst the available CPUs. It works by [forking](https://en.wikipedia.org/wiki/Fork_(system_call)) into multiple system processes which are executed in parallel by your operating system.

### Supported Platforms

turbo-sprockets works with any Ruby that supports `Process#fork` such as the Rubies that run on most flavors of Unix, Linux, BSD, and MacOS. It won't work on Windows. Specifically, if `Process#fork` isn't available, turbo-sprockets won't raise an error, but it also won't provide any sort of speed improvement.

### Disclaimer

Everybody's setup is a little different, so please remember that, with respect to turbo-sprockets, your mileage may vary. You may see an increase in precompliation speed or none at all depending on the mix of assets in your application.

## License

Licensed under the MIT license. See LICENSE for details.

## Authors

* Cameron C. Dutro: http://github.com/camertron
