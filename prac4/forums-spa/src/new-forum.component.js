
angular.module('forumsApp').component('newForum', {
  templateUrl: 'new-forum.template.html',

  bindings: {
    onSubmit: '&',
    onCancel: '&',
  },

  controller: [function() {
    var self = this;

    self.submit = function() {
        self.onSubmit({data: self.model});
        self.model = { };
    }
  }]
});

