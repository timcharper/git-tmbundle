all_toggled = false;
function toggle_all() {
  if (all_toggled) {
    $$(".diff").each(function(e) { set_detail_visibility($(e).readAttribute("branch"), $(e).readAttribute("rev"), false )});
    all_toggled = false;
    $('toggle_all').update("Expand all");
  }
  else
  {
    $$(".diff").each(function(e) { set_detail_visibility($(e).readAttribute("branch"), $(e).readAttribute("rev"), true )});
    all_toggled = true;
    $('toggle_all').update("Collapse all");
  }
}

function detail_div_for(branch, rev) { return $("detail_" + branch + "_" + rev) }

function set_detail_visibility(branch, rev, state) {
  link = $("toggle_link_" + rev);
  detail_div = detail_div_for(branch, rev);
  if (state) {
    link.update("Hide Changes");
    detail_div.show();
  }
  else
  {
    link.update("Show Changes");
    detail_div.hide()
  }
}

function toggle(branch, rev) {
  e = detail_div_for(branch, rev);
  set_detail_visibility( branch, rev, ! e.visible() );
}
