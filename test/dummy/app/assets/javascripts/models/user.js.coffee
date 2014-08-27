# for more details see: http://emberjs.com/guides/models/defining-models/

EmberSerialize.User = DS.Model.extend
  # ember_serialize:start
  # ember_serialize:async false
  id: DS.attr('integer'),
  name: DS.attr('string')
  # ember_serialize:end