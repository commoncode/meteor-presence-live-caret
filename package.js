Package.describe({
  summary: "Track caret position"
});

Package.on_use(function (api) {
  api.use('jquery', 'client');
  api.use(['coffeescript', 'presence', 'iron:router']);

  api.add_files(['lib/jquery.caret.js', 'lib/live-caret.coffee'], 'client');

  api.export('liveCaret', 'client');
});
