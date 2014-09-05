Ember-Serialize &mdash; Generate ember models from Rails serializers
===================================================

[![Gem
Version](https://badge.fury.io/rb/ember_serialize.png)](http://badge.fury.io/rb/ember_serialize)
[![Build Status](https://secure.travis-ci.org/straydogstudio/ember_serialize.png?branch=master)](http://travis-ci.org/straydogstudio/ember_serialize)
[![Dependency Status](https://gemnasium.com/straydogstudio/ember_serialize.png?branch=master)](https://gemnasium.com/straydogstudio/ember_serialize)
[![Coverage
Status](https://coveralls.io/repos/straydogstudio/ember_serialize/badge.png)](https://coveralls.io/r/straydogstudio/ember_serialize)

##About

Ember-Serialize intelligently updates your Ember.js models from your serializers. It uses introspection to keep model names correct. It also tries to be unobtrusive, and will not overwrite or replace anything you have in your ember model.

Inspiration for this gem came from [this article](http://techblog.fundinggates.com/blog/2013/03/automatically-generate-ember-models-from-rails-serializers/) by Matt Rogish. Instead of creating a JSON schema that is parsed by Ember.js, I chose to directly edit the Ember.js models.

##Installation

In your Gemfile:

```ruby
gem 'ember_serialize'
```

##Requirements

* Rails 3.2, tested on 3.2, 4.0 and 4.1
* ActiveModel::Serializers 0.8.x is required. 0.9.x was decoupled from ActiveRecord and no longer exports a schema. Support for AMS 0.10.x is planned.

##Usage

Ember-Serialize provides a rake task that parses your serializers and updates your Ember.js models. For basic usage, simply call:

```bash
rake db:schema:ember
```

###Existing Files

ES will only update existing files that have ES start/end markers in them:

```ruby
EmberSerialize.Post = DS.Model.extend
  # ember_serialize:start
  author: DS.belongsTo('user',{inverse: 'post'}),
  # ember_serialize:end

  comments: DS.hasMany('comments')
```

Things to keep in mind:
* Any javascript outside the markers will be left as is. So, in the above example, `comments` will not only be left as is, it will not be added inside either.
* Any line inside the markers will not be changed. So you can hand edit any line and it will not be overwritten. In the above example, `author` has had `inverse` added to it, and it will not be changed.

###New Files

ES will not create models unless you pass the `:create` parameter:

```bash
rake db:schema:ember[:create]
```

###Async: true

ES defaults to `async: true` for any new association. To prevent this, pass `async:false` to the rake task:

```bash
rake db:schema:ember[async:false]
```

###As-is and Belongs to or Has one

If ES finds a `post_id` parameter, and a `post` association, it will by default convert it to a `DS.belongsTo` association. It will also reflect on the assocation and use the receiving class inside the `belongsTo` call. For instance, if a `Post` has an `author_id` parameter, an `author` association, which lead to a `User` class, ES will insert the following line:

```ruby
author: DS.belongsTo('user'),
```

To prevent this, and in this case include `authorId`, use an `as_is` setting inside your model:

```ruby
EmberSerialize.Post = DS.Model.extend
  # ember_serialize:start
  # ember_serialize:as_is authorId
  authorId: DS.attr('integer')
  # ember_serialize:end
```

###Has many and Associations

Similar to the Belongs to case, ES will reflect on the association and use the receiving class in the declaration:

```ruby
EmberSerialize.Manager = DS.Model.extend
  employees: hasMany('users')
```

###Ignoring parameters

To ignore any parameter, use an `ignore` setting:

```ruby
EmberSerialize.Post = DS.Model.extend
  # ember_serialize:start
  # ember_serialize:ignore authorId
  # ember_serialize:end
```

###CamelCase or under_score?

In settings, you can use either underScore or camel_case:

```ruby
  # ember_serialize:ignore authorId
  # is the same as
  # ember_serialize:ignore author_id
```

###Multiple arguments

Remember, when you are passing multiple arguments to rake, _DO NOT USE SPACES!_

This will work:

```bash
rake db:schema:ember[:create,async:false]
```

_THIS WILL NOT:_

```bash
rake db:schema:ember[:create, async:false]
```

##Dependencies

- [Rails](https://github.com/rails/rails)
- [ActiveModel::Serializers](https://github.com/rails-api/active_model_serializers)

##Authors

* [Noel Peden](https://github.com/straydogstudio)

##Contributors


##Change log

- **September 5, 2014**: 0.0.6 - Force ignore of id
- **September 5, 2014**: 0.0.5 - Skip missing models
- **September 5, 2014**: 0.0.4 - Railtie for proper inclusion
- **August 27, 2014**: 0.0.2 - Fix async detection: defaults to true
- **August 27, 2014**: 0.0.1 - Initial release
