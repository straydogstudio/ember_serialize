# for more details see: http://emberjs.com/guides/models/defining-models/

EmberSerialize.Post = DS.Model.extend
  # ember_serialize:start
  # ember_serialize:async false
  id: DS.attr('integer'),
  title: DS.attr('string'),
  body: DS.attr('text'),
  comments: DS.hasMany('comments')
  # ember_serialize:end