$(function() {

  // Add header links
  $('.page-inner').find('h1, h2, h3, h4, h5, h6').each(function(i, el) {
    var $el, icon, id;
    $el = $(el);
    id = $el.attr('id') || $el.parent().attr('id'); // HACK: IDs are on sections (for now)
    icon = '<i class="fa fa-paragraph"></i>';
    if (id) {
      return $el.prepend($("<a />").addClass("header-link").attr("href", "#" + id).html(icon));
    } else {
      console.log('header id not found', el);
    }
  });


  $('.toggle-summary').on('click', function(evt) {
    $('.book').toggleClass('with-summary');
    evt.preventDefault();
  });

  $.ajax(window.SITE.toc)
  .then(function(html) {
    root = $('<div>' + html + '</div>');
    title = root.children('title').contents();
    toc = root.find('ol').first();

    tocList = [];
    toc.find('a').each(function(i, el) {
      tocList.push(el.getAttribute('href'));
    });

    // HACK. Should use URIJS to convert path relative to toc file
    currentPageIndex = function(currentHref) {
      if ('/' == currentHref[currentHref.length - 1]) {
        currentHref = currentHref.substring(0, currentHref.length - 1);
      }
      components = currentHref.split('/');
      currentBase = components[components.length - 1];
      return tocList.indexOf('../' + currentBase);
    };

    window.BOOK = BOOK = {title: title, toc: toc, tocList: tocList};
    BOOK.prevPageHref = function(currentHref) {
      currentIndex = currentPageIndex(currentHref);
      return tocList[currentIndex - 1]; // returns undefined if no previous page
    };
    BOOK.nextPageHref = function(currentHref) {
      currentIndex = currentPageIndex(currentHref);
      return tocList[currentIndex + 1]; // returns undefined if no next page
    };

    // Build the sidebar
    summary = $('<ul class="summary"></ul>');
    summary.append('<li class="divider"/>');
    summary.append(toc.children('li'));
    $('.book-summary').append(summary);

    // Add next/prev buttons
    prevPage = $('<a class="navigation navigation-prev" href="' + BOOK.prevPageHref(window.location.href) + '"><i class="fa fa-chevron-left"></i></a>');
    nextPage = $('<a class="navigation navigation-next" href="' + BOOK.nextPageHref(window.location.href) + '"><i class="fa fa-chevron-right"></i></a>');
    contentContainer = $('.book-body');
    contentContainer.append(prevPage);
    contentContainer.append(nextPage);
  });
});
