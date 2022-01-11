module.exports = {
    template: {
        issue: function (pr) {
            return "- " + pr.name.toLowerCase() + " [" + pr.text + "](" + pr.url + ")";
        }
    }
  }