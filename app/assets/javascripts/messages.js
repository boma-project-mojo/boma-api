updateRemainingCharacters = function(input,counter){
  var input = $(input);
  var counter = $(counter);
  var max_length  = counter.data("maximum-length");

  input.keyup(function() {
      counter.text(max_length - $(this).val().length);
  });
}

$(document).ready(function() {
  updateRemainingCharacters("#message_subject", "#message_subject_counter");
  updateRemainingCharacters("#message_body", "#message_body_counter");
});	