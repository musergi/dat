
angular.module('forumsApp').component('forum', {
  templateUrl: 'forum.template.html',

  controller: ['$routeParams','forumsApiSrv','breadcrumbSrv', function($routeParams, forumsApiSrv, breadcrumbSrv) {
    var self = this;
    //-----------------------------------------
    // Data
    self.forum = null;
    self.topics = []; // array of topics
                      // topic rep.: { user: String, started: String, title: String, ... }
    self.reversed = true;
    self.openedNewTopic = false;

    //-----------------------------------------
    // Operations

    self.maybeUser = forumsApiSrv.maybeUser;

    self.toggleReversed = function() {
        self.reversed = ! self.reversed;
    };

    self.openNewTopic = function() {
        self.openedNewTopic = true;
    };

    self.closeNewTopic = function() {
        self.openedNewTopic = false;
    };

    self.newTopic = function(formData) {
        forumsApiSrv.postForumTopics(self.forum.id, formData).then(
            function() {
                self.closeNewTopic();
                reloadTopics();
            }
        );
    };

    function reloadTopics() {
        forumsApiSrv.getForumTopics($routeParams.forumId).then(
            function(data) {
                self.topics = data.items;
            }
        );
    }

    //-----------------------------------------
    // Initial load
    forumsApiSrv.getForum($routeParams.forumId).then(
        function(data) {
            self.forum = data;
            breadcrumbSrv.set([
                { label:  'Home', url: '#!/' },
                { label: self.forum.title, url: '#!/forum-' + self.forum.id }
            ]);
        }
    );
    reloadTopics();
  }]
});

