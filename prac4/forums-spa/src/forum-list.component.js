angular.module('forumsApp').component('forumList', {
  templateUrl: 'forum-list.template.html',

  controller: ['forumsApiSrv','breadcrumbSrv', function(forumsApiSrv, breadcrumbSrv) {
    var self = this;
    //-----------------------------------------
    // Data
    self.forums = [];
    self.openedNewForum = false;
    self.maybeUser = forumsApiSrv.maybeUser;

    self.isMod = function(modId) {
        let user = self.maybeUser();
        return user != null && user.name == modId;
    }

    self.openNewForum = function() {
        self.openedNewForum = true;
    };

    self.closeNewForum = function() {
        self.openedNewForum = false;
    };

    self.newForum = function(formData) {
        forumsApiSrv.postForums(formData).then(
            function() {
                self.closeNewForum();
                reloadForums();
            }
        );
    };

    self.deleteForum = function(forumId) {
        forumsApiSrv.deleteForum(forumId).then(
            function() {
                reloadForums();
            }
        );
    };

    function reloadForums() {
        forumsApiSrv.getForums().then(function(data) {
            self.forums = data.items;
        });
    };

    //-----------------------------------------
    // Initial load
    reloadForums();
    breadcrumbSrv.set([
        { label:  'Home', url: '#!/' }
    ]);
  }]
});

