Package.describe({
  summary: "Track caret position"
});

Package.on_use(function (api) {
  api.use(['accounts-base', 'coffeescript']);
  api.use(['iron:router', 'jquery', 'presence'], 'client');

  api.imply('accounts-base', 'client');

  api.add_files('lib/common.coffee');
  api.add_files(['lib/jquery.caret.js', 'lib/client.coffee'], 'client');
  api.add_files('lib/server.coffee', 'server');

  api.export('liveCaret', 'client');
});
