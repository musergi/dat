
// Register the `forumsApiSrv` service in the `forumsApp` module.
// Provides the access to the Forums Web Service.
angular.module('forumsApp').service('forumsApiSrv', ['config','oauth2Srv','$http','$window', function(config, oauth2Srv, $http, $window) {
    var self = this;

    var user = null; // User cache

    self.maybeUser = function() {
        return user;
    };

    self.getUser = function() {
        if (user == null) {
            return doGet(true, '/user').then(
                function(u) { user = u; return u; }
            );
        }
        return user;
    };

    self.getForums = function() {
        return doGet(false, '/forums');
    };

    self.getForum = function(fid) {
        return doGet(false, '/forums/' + fid);
    };

    self.getForumTopics = function(fid) {
        return doGet(false, '/forums/' + fid + '/topics');
    };

    self.postForumTopics = function(fid, reqdata) {
        return doPost('/forums/' + fid + '/topics', reqdata);
    };

    //-----------------------------------------
    // Internal functions

    function resultData(response) { return response.data; }

    function errorFun(response) {
        $window.alert(JSON.stringify(response.data));
        //$q.reject(response.data);
    }

    function doGet(requireAuth, path) {
        if (requireAuth) {
            return oauth2Srv.getToken(config.forumsApiScopes, null, false).then(
                function(access_token) {
                    var httpConfig = { method: 'GET',
                                       url: config.forumsApiUrl + path,
                                       headers: { 'Authorization': 'Bearer ' + access_token }
                                     };
                    return $http(httpConfig).then(resultData, errorFun)
                }
            );
        } else {
            return $http.get(config.forumsApiUrl + path).then(resultData, errorFun);
        }
    }

    function doPost(path, reqdata) {
        return oauth2Srv.getToken(config.forumsApiScopes, null, false).then(
            function(access_token) {
                var httpConfig = { method: 'POST',
                                   url: config.forumsApiUrl + path,
                                   headers: { 'Authorization': 'Bearer ' + access_token },
                                   data: reqdata
                                 };
                return $http(httpConfig).then(resultData, errorFun)
            }
        );
    }
}]);

