# for more details see: http://emberjs.com/guides/models/defining-models/

EmberSerialize.Post = DS.Model.extend
  # ember_serialize:start
  title: DS.attr('string'),
  body: DS.attr('text'),
  comments: DS.hasMany('comment')
  # ember_serialize:end
