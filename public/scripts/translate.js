// Generated by CoffeeScript 1.6.3
(function() {
  $(function() {
    return $("form").on("submit", function(e) {
      var formDataArray, request;
      e.preventDefault();
      formDataArray = $(this).serializeArray();
      request = $.ajax({
        type: "POST",
        url: "" + window.location.pathname,
        data: formDataArray[0]
      });
      request.done(function() {
        console.log("success");
        $(e.currentTarget).html('Thank you!');
        return setTimeout(function() {
          return $(e.currentTarget).animate({
            height: 0,
            width: 0,
            opacity: 0
          });
        }, 2000);
      });
      request.fail(function() {
        return console.log("fail");
      });
      return request.always(function() {
        return console.log("always");
      });
    });
  });

}).call(this);
