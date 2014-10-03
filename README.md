# Docker::Testing
[![Build Status](https://travis-ci.org/mdouchement/docker-api-testing.svg?branch=master)](https://travis-ci.org/mdouchement/docker-api-testing)
[![Code Climate](https://codeclimate.com/github/mdouchement/docker-api-testing/badges/gpa.svg)](https://codeclimate.com/github/mdouchement/docker-api-testing)
[![Test Coverage](https://codeclimate.com/github/mdouchement/docker-api-testing/badges/coverage.svg)](https://codeclimate.com/github/mdouchement/docker-api-testing)


This gem aims to provide a few options for testing your [docker-api](https://github.com/swipely/docker-api) integration.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'docker-api-testing'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install docker-api-testing

## Usage

```ruby
require 'docker/testing'

Docker::Testing.fake! # default mode
Docker::Testing.disable!
```

## Actions
- Image: not supported
- Container:
 - Most of features are supported, but without advanced functionalities
 - `logs`, `changes`, `export`, `attach` are not supported

## Contributing

1. Fork it ( https://github.com/[my-github-username]/docker-api-testing/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
