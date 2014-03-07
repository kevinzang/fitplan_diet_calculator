function send_json(addr, data, good, bad) {
  $.ajax({
    type: 'POST',
    url: addr,
    data: JSON.stringify(data),
    contentType: "application/json",
    dataType: "json",
    success: good,
    error: bad
  });
}

$.fn.form_to_dict = function() {
  var dict = {};
  var list = this.serializeArray();
  for (var i=0; i<list.length; i++) {
    dict[list[i].name] = list[i].value || '';
  }
  return dict;
};

function show_error() {
	alert("error occurred on request")
}