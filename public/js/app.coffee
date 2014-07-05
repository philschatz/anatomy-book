BookConfig = window.Book or {}
BookConfig.includes ?= {}
BookConfig.includes.fontawesome  ?= '//maxcdn.bootstrapcdn.com/font-awesome/4.1.0/css/font-awesome.min.css'
BookConfig.urlFixer ?= (val) -> val
BookConfig.toc ?= {}
BookConfig.toc.url       ?= '../toc'   # or '../SUMMARY' for GitBook
BookConfig.toc.selector  ?= 'nav, ol, ul'  # picks the first one that matches
BookConfig.baseHref ?= null # or '//archive.cnx.org/contents' (for loading resources)
BookConfig.serverAddsTrailingSlash ?= false # Used because jekyll adds trailing slashes




# Inject the <link> tags for FontAwesome
if BookConfig.includes.fontawesome
  fa = document.createElement('link')
  fa.rel = 'stylesheet'
  fa.href = BookConfig.includes.fontawesome
  document.head.appendChild(fa)






BOOK_TEMPLATE = '''
  <div class="book without-animation with-summary font-size-2 font-family-1">

    <div class="book-header">
      <a href="#" class="btn pull-left toggle-summary" aria-label="Toggle summary"><i class="fa fa-align-justify"></i></a>
      <h1><i class="fa fa-spinner fa-spin book-spinner"></i><span class="book-title"></span></h1>
    </div>

    <div class="book-summary">
    </div>

    <div class="book-body">
      <div class="body-inner">
        <div class="page-wrapper" tabindex="-1">
          <div class="book-progress">
          </div>
          <div class="page-inner">
            <section class="normal">
              <!-- content -->
            </section>
          </div>
        </div>
      </div>
    </div>

  </div>
'''

$ () ->
  # Squirrel the body and replace it with the template:
  $body = $('body')
  $originalPage = $body.contents()

  $body.contents().remove()
  $body.append(BOOK_TEMPLATE)

  # Pull out all the interesting DOM nodes from the template
  $book = $body.find('.book')
  $toggleSummary = $book.find('.toggle-summary')
  $bookSummary = $book.find('.book-summary')
  $bookBody = $book.find('.book-body')
  $bookPage = $book.find('.page-inner > .normal')
  $bookTitle = $book.find('.book-title')


  $toggleSummary.on 'click', (evt) ->
    $book.toggleClass('with-summary')
    evt.preventDefault()

  renderToc = ->
    $summary = $('<ul class="summary"></ul>')
    if BookConfig.issuesUrl
      $summary.append("<li class='issues'><a href='#{BookConfig.issuesUrl}'>Questions and Issues</a></li>")
    $summary.append("<li class='edit-contribute'><a href='#{BookConfig.url}'>Edit and Contribute</a></li>")
    $summary.append('<li class="divider"/>')
    $summary.append(tocHelper.$toc.children('li'))

    $bookSummary.contents().remove()
    $bookSummary.append($summary)

    renderNextPrev()

  renderNextPrev = ->
    # Add next/prev buttons to the page
    $bookBody.children('.navigation').remove()
    current = removeTrailingSlash(window.location.href)
    prev = tocHelper.prevPageHref(current)
    next = tocHelper.nextPageHref(current)
    if prev
      prev = URI(addTrailingSlash(prev)).relativeTo(URI(window.location.href)).toString()
      $prevPage = $("<a class='navigation navigation-prev' href='#{prev}'><i class='fa fa-chevron-left'></i></a>")
      $bookBody.append($prevPage)
    if next
      next = URI(addTrailingSlash(next)).relativeTo(URI(window.location.href)).toString()
      $nextPage = $("<a class='navigation navigation-next' href='#{next}'><i class='fa fa-chevron-right'></i></a>")
      $bookBody.append($nextPage)

  addTrailingSlash = (href) ->
    if BookConfig.serverAddsTrailingSlash and href[href.length - 1] isnt '/'
      href += '/'
    href

  removeTrailingSlash = (href) ->
    if BookConfig.serverAddsTrailingSlash and href[href.length - 1] is '/'
      href = href.substring(0, href.length - 1)
    href


  tocHelper = new class TocHelper
    _tocHref: null
    _tocList: []
    _tocTitles: {}
    loadToc: (@_tocHref, @$toc, @$title) ->
      tocUrl = URI(BookConfig.toc.url).absoluteTo(removeTrailingSlash(window.location.href))

      @_tocTitles = {}
      @_tocList = for el in $toc.find('a[href]')
        href = URI(el.getAttribute('href')).absoluteTo(tocUrl).toString()
        @_tocTitles[href] = $(el).text()
        href

      # Fix up the ToC links if the server has trailing slashes
      if BookConfig.serverAddsTrailingSlash
        for a in @$toc.find('a')
          $a = $(a)
          href = $a.attr('href')
          href = '../' + href
          $a.attr('href', href)

      renderToc()

    # HACK. Should use URIJS to convert path relative to toc file
    _currentPageIndex: (currentHref) ->
      #currentHref = currentHref.substring(0, currentHref.length - 1)  if "/" is currentHref[currentHref.length - 1]
      @_tocList.indexOf(currentHref)

    prevPageHref: (currentHref) ->
      currentIndex = @_currentPageIndex(currentHref)
      @_tocList[currentIndex - 1] # returns undefined if no previous page

    nextPageHref: (currentHref) ->
      currentIndex = @_currentPageIndex(currentHref)
      @_tocList[currentIndex + 1] # returns undefined if no next page


  $.ajax(url: BookConfig.urlFixer(BookConfig.toc.url), headers: {'Accept': 'application/xhtml+xml'}, dataType: 'html')
  .then (html) ->
    $root = $('<div>' + html + '</div>')
    $toc = $root.find(BookConfig.toc.selector).first()
    if $toc[0].tagName.toLowerCase() is 'ul'
      # HACK for collection HTML
      $title = $toc.children().first().contents()
      $toc = $toc.find('ul').first()
    else
      $title = $root.children('title').contents()
    tocHelper.loadToc(BookConfig.toc.url, $toc, $title)
    $bookTitle.html(tocHelper.$title)

  # Fetch resources without fixing up their paths
  if BookConfig.baseHref
    $book.find('base').remove()
    $book.prepend("<base href='#{BookConfig.baseHref}'/>")

  $bookPage.append($originalPage)

  changePage = (href) ->
    $book.addClass('loading')
    $.ajax(url: BookConfig.urlFixer(href), headers: {'Accept': 'application/xhtml+xml'}, dataType: 'html')
    .then (html) ->
      $html = $("<div>#{html}</div>")
      $html.children('meta, link, script, title').remove()

      $bookPage.contents().remove()

      # Fetch resources without fixing up their paths
      if BookConfig.baseHref
        $book.find('base').remove()
        $book.prepend("<base href='#{BookConfig.urlFixer(href)}'/>")

      $bookPage.append($html.children()) # TODO: Strip out title and meta tags
      $book.removeClass('loading')

  # Listen to clicks and handle them without causing a page reload
  $('body').on 'click', 'a[href]:not([href^="#"])', (evt) ->
    href = addTrailingSlash($(@).attr('href'))
    href = URI(href).absoluteTo(URI(window.location.href)).toString()

    changePage(href)
    .then ->
      # Use `window.location.origin` to get around a <base href=""> pointing to another hostname
      unless /https?:\/\//.test(href)
        href = "#{window.location.origin}#{href}"
      window.history.pushState(null, null, href)
      renderNextPrev()

    evt.preventDefault()
