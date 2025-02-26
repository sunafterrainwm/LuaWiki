local title = ngx.unescape_uri(ngx.var.arg_title)

local fetch_wikitext = require('fetch_wikitext')
local flag, wikitext = fetch_wikitext(title)

local parser_output = ''
if flag then
  local nonparse = require('core/nonparse')
  local parser = require('core/parser')
  local wiki_state = {
    title = title,
    npb_index = 0,
    nw_index = 0,
    npb_cache = {},
    nw_cache = {},
    links = {}
  }

  -- start timer
  ngx.update_time()
  local begin_time = ngx.now()

  wikitext = nonparse.decorate(wiki_state, wikitext)

  local preprocessor = require('core/preprocessor').new(wiki_state)
  wikitext = preprocessor:process(wikitext)
  parser_output = parser.parse(wiki_state, wikitext)

  -- end timer
  ngx.update_time()

  local html_utils = require('utils/html_utils')
  
  parser_output = '<h1>' .. title:gsub('_', ' ') .. '</h1>' .. html_utils.expand_single(parser_output) ..
    '<!-- Total parse time: ' .. (ngx.now() - begin_time) .. '-->'
  
  local postprocessor = require('core/postprocessor')
  parser_output = postprocessor.process(parser_output, wiki_state)
else
  parser_output = wikitext or 'Page not found'
end

local mainpage_html = [=[<!DOCTYPE html>
<html>
<head>
  <title>]=] .. title:gsub('_', ' ') .. ' - 维基百科，自由的百科全书' .. [=[</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes, minimum-scale=0.25, maximum-scale=5.0">
  <!--<link rel="stylesheet" href="https://picocss.com/css/pico.min.css">-->
  <link rel="stylesheet" href="https://cdn.staticfile.org/normalize/8.0.1/normalize.css">
  <link rel="stylesheet" href="/milligram.css">
  <link rel="stylesheet" href="/ooicon/style.css">
  <link rel="stylesheet" href="https://cdn.staticfile.org/KaTeX/0.15.6/katex.min.css">
  <link rel="stylesheet" href="https://cdn.staticfile.org/highlight.js/11.5.1/styles/default.min.css">
  <link rel="stylesheet" type="text/css" href="/wiki.css">
</head>
<style>
html, body {
  height: 100%;
}
body {
  font-family: 'Roboto', 'Helvetica Neue', 'Helvetica', 'Arial', 'Noto Sans CJK SC', sans-serif;
  font-weight: 400;
  color: #2b3135;
}
body > nav {
  display: flex;
  justify-content: space-between;
  background: #5c87a6;
}
body > nav ul {
  display: flex;
  margin-bottom: 0;
  list-style: none;
}
body > nav li {
  margin-bottom: 0;
  padding: 0.5em 1em;
  color: #fff;
}
body > nav a, body > nav a:focus, body > nav a:hover {
  color: #fff;
}
body > nav a:hover {
  opacity: 0.8;
}
.logo {
  display: inline-block;
  padding: 0.2em;
  line-height: 1;
  background: black;
  border-radius: 50%;
  color: #fff;
}
#content {
  height: calc(100% - 41.6px);
}
#content.has-toc {
  display: grid;
  grid-template-columns: 13em 1fr;
  grid-column-gap: 2em;
}
#content aside {
  height: 100%;
  overflow: auto;
}
#content aside ul {
  list-style: none;
}
#content aside > ul > li {
  padding-left: 1em;
  padding-top: 0.5rem;
  padding-bottom: 0.5rem;
  margin-bottom: 0;
}
#content aside li a {
  color: #2b3135;
  opacity: 0.7;
}
#content aside li:hover > a, #content aside li.active > a {
  opacity: 1;
  font-weight: bold;
}
.parser-output {
  height: 100%;
  overflow: auto;
  position: relative;
}
@supports (-moz-appearance:none) {
  .parser-output {
    text-align: justify;
    hyphens: auto;
  }
}
@media only screen and (max-width: 600px) {
  #content aside {
    display: none;
  }
  #content.has-toc {
    display: block;
  }
}
</style>
<body>
  <nav class="container-fluid">
    <ul>
      <li onclick="location.href='/'" style="cursor: pointer">
        <span class="logo"><i class="icon icon-logo-Wikipedia"></i></span>
        <strong>LUAWIKI</strong>
      </li>
    </ul>
    <ul style="position: absolute; left: 15em;">
      <li>
        <a href="javascript:viewArticle()" title="article"><i class="icon icon-home"></i></a>
      </li>
      <li>
        <a href="javascript:historyPage()" title="history"><i class="icon icon-history"></i></a>
      </li>
    </ul>
    <ul>
      <li v-show="showEdit">
        <a href="javascript:editPage()" title="edit"><i class="icon icon-edit"></i></a>
      </li>
      <li v-show="showSubmit">
        <a href="javascript:submitPage()" title="submit"><i class="icon icon-check"></i></a>
      </li>
      <li v-show="showSubmit">
        <a href="javascript:cancelEdit()" title="cancel"><i class="icon icon-cancel"></i></a>
      </li>
      <li>
        <a href="javascript:openSearch()" title="search"><i class="icon icon-search"></i></a>
      </li>
      <li>
        <a href="javascript:gotoLogin()" title="login"><i class="icon icon-logIn-ltr"></i></a>
      </li>
    </ul>
  </nav>
  <div id="content" class="has-toc">
    <aside>
    </aside>
    <article id="content-text" class="parser-output">]=] .. parser_output .. [=[</article>
  </div>
  
<script src="/simplequery.js"></script>
<script defer src="https://cdn.staticfile.org/KaTeX/0.15.6/katex.min.js"></script>
<script defer src="https://cdn.staticfile.org/KaTeX/0.15.6/contrib/mhchem.min.js"></script>
<script defer src="https://cdn.staticfile.org/highlight.js/11.5.1/highlight.min.js"></script>
<script src="/zh_convert.js"></script>
<script src="/wiki.js"></script>
<script src="/app.js"></script>
<script src="/modal.js"></script>
</body>
</html>
]=]

ngx.say(mainpage_html)
