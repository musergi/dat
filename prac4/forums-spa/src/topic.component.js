
angular.module('forumsApp').component('topic', {
    templateUrl: 'topic.template.html',

    controller: ['$routeParams','forumsApiSrv','breadcrumbSrv', function($routeParams, forumsApiSrv, breadcrumbSrv) {
        var self = this;
        //-----------------------------------------
        // Data
        self.topic = null;
        self.firstPost = null;
        self.posts = []
        self.reversed = false;
        self.openedNewPost = false;

        //-----------------------------------------
        // Operations

        self.maybeUser = forumsApiSrv.maybeUser;

        self.toggleReversed = function() {
            self.reversed = ! self.reversed;
        };

        self.openNewPost = function() {
            self.openedNewPost = true;
        };

        self.closeNewPost = function() {
            self.openedNewPost = false;
        };

        self.newPost = function(formData) {
            forumsApiSrv.postTopicPosts(self.topic.id, formData).then(
                function() {
                    self.closeNewPost();
                    reloadPosts();
                }
            );
        };

        self.deletePost = function(postId) {
            forumsApiSrv.deletePost(postId).then(
                function() {
                    reloadPosts();
                }
            );
        };

        function reloadPosts() {
            forumsApiSrv.getTopicPosts($routeParams.topicId).then(
                function(data) {
                    self.posts = data.items;
                    self.posts.shift();
                }
            );
        }

        //-----------------------------------------
        // Initial load
        forumsApiSrv.getTopic($routeParams.topicId).then(
            function(data) {
                self.topic = data;
                forumsApiSrv.getForum(data.forumId).then(
                    function(data) {
                        breadcrumbSrv.set([
                            {label: 'Home', url: '#!/'},
                            {label: data.title, url: '#!/forum-' + data.id},
                            {label: self.topic.title, url: '#!/topic-' + self.topic.id}
                        ]);
                    }
                );
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

