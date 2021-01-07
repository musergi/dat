
angular.module('forumsApp').component('topic', {
  templateUrl: 'topic.template.html',

  controller: ['$routeParams','forumsApiSrv','breadcrumbSrv', function($routeParams, forumsApiSrv, breadcrumbSrv) {
    var self = this;
    //-----------------------------------------
    // Data
    self.forum = null;
    self.topics = []; // array of topics
                      // topic rep.: { user: String, started: String, title: String, ... }
    self.reversed = true;
    self.openedNewTopic = false;

    self.topic = null;
    self.firstPost = null;
    self.posts = []

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

    function reloadPosts() {
        forumsApiSrv.getTopicPosts($routeParams.topicId).then(
            function(data) {
                self.posts = data.items;
            }
        );
    }

    //-----------------------------------------
    // Initial load
    forumsApiSrv.getTopic($routeParams.topicId).then(
        function(data) {
            self.topic = data;
            breadcrumbSrv.set([
                {label: 'Home', url: '#!/'},
                {label: self.topic.title, url: '#!/topic-' + self.topic.id}
            ]);
            forumsApiSrv.getPost(data.firstPostId).then(
                function(data) {
                    self.firstPost = data;
                }
            );
        }
    );
    reloadPosts();
  }]
});

