$().ready(function() {
  $.ajax(window.SITE.toc)
  .then(function(html) {
    root = $('<div>' + html + '</div>');
    title = root.children('title').contents();
    toc = root.find('ol').first();

    window.BOOK = {title: title, toc: toc};

    // Build the sidebar
    $('.sidebar').remove();
    sidebar = $('<div class="sidebar"></div>');
    sidebar.append(toc);
    sidebar.insertAfter('#sidebar-checkbox');
  });
});
