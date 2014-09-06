# for more details see: http://emberjs.com/guides/models/defining-models/

EmberSerialize.Post = DS.Model.extend
  # ember_serialize:start
  title: DS.attr('string'),
  body: DS.attr('string'),
  createdAt: DS.attr('date'),
  authorDude: DS.belongsTo('user', {async: true}),
  comments: DS.hasMany('comments', {async: true})
  # ember_serialize:end