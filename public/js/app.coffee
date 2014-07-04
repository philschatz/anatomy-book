BookConfig = window.Book or {}
BookConfig.includes ?= {}
BookConfig.includes.jquery       ?= '//code.jquery.com/alsjkdsad'
BookConfig.includes.fontawesome  ?= '//bootstrapcdn.com/asdasdas'
BookConfig.includes.theme        ?= '//philschatz.com/gh-book/default.css'
BookConfig.toc ?= {}
BookConfig.toc.url       ?= '../toc'   # or '../SUMMARY' for GitBook
BookConfig.toc.selector  ?= 'nav, ol'  # picks the first one that matches
BookConfig.baseHref ?= null # or '//archive.cnx.org/contents' (for loading resources)
BookConfig.serverAddsTrailingSlash ?= false




# Inject the <script> and <link> tags for jQuery and FontAwesome
if BookConfig.includes.jquery
  jq = document.createElement('script')
  jq.src = BookConfig.includes.jquery
  document.head.appendChild(jq)

if BookConfig.includes.fontawesome
  fa = document.createElement('link')
  fa.rel = 'stylesheet'
  fa.href = BookConfig.includes.fontawesome
  document.head.appendChild(fa)






BOOK_TEMPLATE = '''
  <div class="book without-animation with-summary font-size-2 font-family-1">

    <div class="book-header">
      <a href="#" class="btn pull-left toggle-summary" aria-label="Toggle summary"><i class="fa fa-align-justify"></i></a>
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

  $toggleSummary.on 'click', (evt) ->
    $book.toggleClass('with-summary')
    evt.preventDefault()

  renderToc = ->
    $summary = $('<ul class="summary"></ul>')
    $summary.append('<li class="divider"/>')
    $summary.append(tocHelper.$toc.children('li'))

    $bookSummary.contents().remove()
    $bookSummary.append($summary)

    renderNextPrev()

  renderNextPrev = ->
    # Add next/prev buttons to the page
    $bookBody.children('.navigation').remove()
    prev = tocHelper.prevPageHref(removeTrailingSlash(window.location.href))
    next = tocHelper.nextPageHref(removeTrailingSlash(window.location.href))
    if prev
      $prevPage = $("<a class='navigation navigation-prev' href='#{prev}'><i class='fa fa-chevron-left'></i></a>")
      $bookBody.append($prevPage)
    if next
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
    loadToc: (@_tocHref, @$toc, $title) ->
      tocUrl = URI(BookConfig.toc.url).absoluteTo(removeTrailingSlash(window.location.href))

      @_tocTitles = {}
      @_tocList = for el in $toc.find('a')
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


  $.ajax(url: BookConfig.toc.url, accept: 'text/html')
  .then (html) ->
    $root = $('<div>' + html + '</div>')
    $title = $root.children('title').contents()
    $toc = $root.find(BookConfig.toc.selector).first()
    tocHelper.loadToc(BookConfig.toc.url, $toc, $title)


  $bookPage.append($originalPage)

  changePage = (href) ->
    $.ajax(url: href, accept: 'text/html')
    .then (html) ->
      $html = $("<div>#{html}</div>")
      $html.children('meta, link, script, title').remove()

      $bookPage.contents().remove()
      $bookPage.append($html) # TODO: Strip out title and meta tags

  # Listen to clicks and handle them without causing a page reload
  $('body').on 'click', 'a[href]:not([href^="#"])', (evt) ->
    href = addTrailingSlash(@href)
    changePage(href)
    .then ->
      window.history.pushState(null, null, href)
      renderNextPrev()

    evt.preventDefault()
