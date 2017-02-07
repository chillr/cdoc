# Cdoc

Cdoc generates a simple single page api documentation from the rails application source code comments.
To use cdoc you need to add a directive `#doc` for every comment block in the api.

For example

```
#doc
# @endpoint /api/v1/accounts/list
# @params
#  {
#    user_id: '123456'
#  }
# @response
#  {
#    accounts: [
#      {
#        id: 100,
#        account_number: '11111111111',
#        ifsc_code: 'IFSC111111'
#      },
#      {
#        id: 101,
#        account_number: '111111111112',
#        ifsc_code: 'IFSC111112'
#      }
#    ]
#  }
```

The code sections will be highligted if a 2 space indentation is used. Alos if the code section is a valid json then the section will be highlighted.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cdoc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cdoc

## Usage

cd to your rails application and run

    $ cdoc
    $ open doc/index.html

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/cdoc. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

