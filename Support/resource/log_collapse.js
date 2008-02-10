all_toggled = true;
function toggle_all() {
  if (all_toggled) {
    $$(".diff").each(function(e) { set_detail_visibility($(e).readAttribute("rev"), false )});
    all_toggled = false;
    $('toggle_all').update("Expand all");
  }
  else
  {
    $$(".diff").each(function(e) { set_detail_visibility($(e).readAttribute("rev"), true )});
    all_toggled = true;
    $('toggle_all').update("Collapse all");
  }
}

function set_detail_visibility(rev, state) {
  link = "toggle_link_" + rev;
  detail_div = "detail_" + rev;
  
  if (state) {
    $(link).update("Collapse");
    $(detail_div).show();
  }
  else
  {
    $(link).update("Expand");
    $(detail_div).hide()
  }
}

function toggle(rev) {
  set_detail_visibility( rev, ! $('detail_' + rev).visible() );
}
