// all_toggled = false;
// function toggle_all() {
//   if (all_toggled) {
//     $$(".diff").each(function(e) { set_log_visibility($(e).readAttribute("branch"), $(e).readAttribute("rev"), false )});
//     all_toggled = false;
//     $('toggle_all').update("Expand all");
//   }
//   else
//   {
//     $$(".diff").each(function(e) { set_log_visibility($(e).readAttribute("branch"), $(e).readAttribute("rev"), true )});
//     all_toggled = true;
//     $('toggle_all').update("Collapse all");
//   }
// }

function detail_div_for(branch, rev) { return $("detail_" + branch + "_" + rev) }

function set_log_visibility(branch, rev, state) {
  link = $("toggle_link_" + rev);
  detail_div = detail_div_for(branch, rev);
  if (state) {
    link.update("-");
    detail_div.show();
  }
  else
  {
    link.update("+");
    detail_div.hide()
  }
}

function toggle_diff(branch, rev) {
  e = detail_div_for(branch, rev);
  if (! e.readAttribute("loaded")) {
    e.update(dispatch({controller: 'diff', action: 'diff', branch: branch, revision: rev, git_path: e.readAttribute("git_path"), path: (e.readAttribute("path") || ""), layout: false}))
    e.setAttribute("loaded");
  }
  
  set_log_visibility( branch, rev, ! e.visible() );
}
