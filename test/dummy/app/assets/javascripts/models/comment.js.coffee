# for more details see: http://emberjs.com/guides/models/defining-models/

EmberSerialize.Comment = DS.Model.extend
  # ember_serialize:start
  title: DS.attr('string'),
  body: DS.attr('text'),
  post: DS.belongsTo('post', {async: true}),
  author: DS.belongsTo('user', {async: true})
  # ember_serialize:end