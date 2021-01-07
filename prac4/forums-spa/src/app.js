
// Define the `forumsApp` module
angular.module('forumsApp', ['ngRoute']);

// Register the `config` object in the `forumsApp` module.
// Provides the configuration params.
angular.module('forumsApp').constant('config',
    {
      // Settings for the OAuth2 Authorization Server
      serverSettings : {
        authorizationEndpoint: 'http://soft0.upc.edu/~WEBprofe/oauth2/as.cgi/oauth2/authorization'
      },
      // Settings for the OAuth2 registered client.
      // Please, change to your settings !
      clientSettings : {
        client_id: '0d07c82c-0c80-4313-b72f-5d98e46583b5',
        callback_url: 'http://soft0.upc.edu/dat/practica4/tutorial/src/step_5/oauth2/callback.html'
      },
      // Settings for the Forums web service
      forumsApiUrl: 'http://soft0.upc.edu/~WEBprofe/oauth2/forums-service.cgi/api',
      forumsApiScopes: ['dat-forums']
    }
);

angular.module('forumsApp').config(['$routeProvider', function($routeProvider) {
    $routeProvider.
        when('/', {
            template: '<forum-list></forum-list>'
        }).
        when('/forum-:forumId', {
            template: '<forum></forum>'
        }).
        when('/topic-:topicId', {
            template: '<topic></topic>'
        }).
        otherwise('/');
}]);

