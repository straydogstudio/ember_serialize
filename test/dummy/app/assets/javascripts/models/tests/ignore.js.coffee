# for more details see: http://emberjs.com/guides/models/defining-models/

EmberSerialize.Post = DS.Model.extend
  # ember_serialize:start
  # ember_serialize:ignore body
  id: DS.attr('integer'),
  title: DS.attr('string'),
  comments: DS.hasMany('comments')
  authorDude: DS.belongsTo('user'),
  # ember_serialize:end
