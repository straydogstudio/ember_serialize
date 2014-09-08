# for more details see: http://emberjs.com/guides/models/defining-models/

EmberSerialize.Post = DS.Model.extend
  # ember_serialize:start
  title: DS.attr('string'),
  comments: DS.hasMany('comment')
  authorDude: DS.belongsTo('user'),
  # ember_serialize:end
