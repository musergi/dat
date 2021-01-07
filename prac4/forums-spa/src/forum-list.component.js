
angular.module('forumsApp').component('forumList', {
  templateUrl: 'forum-list.template.html',

  controller: ['forumsApiSrv','breadcrumbSrv', function(forumsApiSrv, breadcrumbSrv) {
    var self = this;
    //-----------------------------------------
    // Data
    self.forums = [];

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

