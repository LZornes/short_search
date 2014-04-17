#!/usr/bin/ruby

require 'rubygems'
require 'sinatra'
require 'uri'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] host_name"
  opts.on("-v", "--verbose", "run verbosely") do |v|
    options[:verbose] = v
  end
  opts.on("-l", "--logging", "run with logging") do |l|
    options[:logging] = l
  end
  opts.on("-p", "--port", Float, "port listend on") do |p|
    options[:port] = p
  end
  opts.on("-ip", "--ip_address", "ip listened on") do |ip|
    options[:ip] = ip
  end
  opt.on("-h","--help","help") do
    puts opt_parser
  end
end.parse!

set :port, options[:port] || 55535
set :bind, options[:ip] || '127.0.0.1'
set :logging, options[:logging] || false

ThisSite = ARGV[0]

#This program was inspired by facebook's bunny lol, hence the name of the struct
LOL = Struct.new(:shortcut, :redirect_fmt_str, :usage, :description) do
  def to_tr
    "<tr><td>#{self.shortcut}</td><td>#{self.usage}</td><td>#{self.description}</td><td>#{self.redirect_fmt_str}</td></tr>"
  end
end

#TODO: YAMLize or turn into DSL
Redirect_urls = {
  "g" => LOL.new("g", "https://google.com/search?q=%s", "g [term_to_google]", "performs a google search"),
  "f" => LOL.new("f", "https://facebook.com", "f", "goes to facebook.com"),
  "w" => LOL.new("w", "https://en.wikipedia.org/w/index.php?search=%s", "w [wiki_page]",  "performs a wiki search"),
  "sc" => LOL.new("sc", "https://soundcloud.com/search?q=%s", "sc [music_to_search_for]", "search soundlcoud"),
  "yt" => LOL.new("yt", "http://www.youtube.com/results?search_query=%s", "yt [youtube_video_to_search_for]", "performs a youtube search"),
  "r" => LOL.new("r", "https://reddit.com/r/%s", "r [subreddit]", "goes to specified subreddit")
}

get '/help' do
  %Q{
This app reads in a parameter (q) parses it and then redirects your browser<br><br>
If you would like to use this and you use chrome, check out: https://support.google.com/chrome/answer/95653<br>
If you would like to use this and you use firefox, check out: http://www.wikihow.com/Add-a-Custom-Search-Engine-to-Firefox's-Search-Bar-(Windows-Version)<br><br>
Possible redirects:<br><br>
<table border = '1'>
  #{Redirect_urls.values.map {|val|
    val.to_tr
  }.join("")}
</table>
  }
end

get '/' do
  %Q{
link rel="search" type="application/opensearchdescription+xml" title="short_search" href=#{ThisSite}/search/xml">
<form id="lol" method="get" action=#{ThisSite}/lol">
  <input type="search" name="q" />
  <input type="submit" />
</form>
<a href="/help">Get help?</a>
    }
end

get '/lol' do
  redirect to("/help") if params.empty?

  cmd, query_str = params["q"].split(' ', 2)

  redirect to("/help")  unless Redirect_urls[cmd]

  new_url = Redirect_urls[cmd].redirect_fmt_str
  if query_str.nil? or query_str.strip == ""
    redirect new_url
  else
    redirect new_url % URI.escape(query_str)
  end
end

#This allows you to add the search box at / as a default search in your browser
get '/search/xml' do
  %Q{
<?xml version='1.0' encoding='UTF-8'?>
  <OpenSearchDescription xmlns='http://a9.com/-/spec/opensearch/1.1/'>
  <ShortName>#{ThisSite}!</ShortName>
  <Description>Use #{ThisSite} to make your search bar more useful</Description>
  <Url type='text/html' template='#{ThisSite}/lol?q={searchTerms}'/>
</OpenSearchDescription>"
  }
end

not_found do
  redirect to("/help")
end
