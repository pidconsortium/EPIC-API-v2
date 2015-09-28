# Copyright ©2011-2012 Pieter van Beek <pieterb@sara.nl>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'rackful'

module EPIC

# @todo re-enable `dl-horizontal` in the header.
class XHTML < Rackful::XHTML


  def self.breadcrumbs
    segments = Rackful::Request.current.path.split('/')
    segments.pop
    return '' if segments.empty?
    bc_path = ''
    '<ul class="breadcrumb">' + segments.collect do
      |segment|
      bc_path += segment + '/'
      '<li><a href="' + bc_path.to_path.relative + '" rel="' + (
        segment.empty? ? 'home' : 'contents'
      ) + '">' + (
        segment.empty? ? 'home' : segment.to_path.unescape
      ) + '</a><span class="divider">/</span></li>'
    end.join + '</ul>'
  end


  header {
    |serializer|
    inc = '/inc/'.to_path.relative
    retval = <<EOS
<link rel="stylesheet" href="#{inc}bootstrap/css/bootstrap.min.css"/>
<link rel="stylesheet" href="#{inc}bootstrap/css/bootstrap-responsive.min.css"/>
<!--<link rel="stylesheet/less" type="text/css" href="#{inc}epic.less"/>-->
<script src="#{inc}jquery.js" type="text/javascript"></script>
<script src="#{inc}bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript">
  $(document).ready( function() {
    $("dl.rackful-object").addClass("dl-horizontal");
    $("table.rackful-objects").addClass("table table-striped table-condensed table-bordered");
  } );
  $(".collapse").collapse();
</script>
</head><body>#{EPIC::XHTML.breadcrumbs}
<div class="container-fluid">
EOS
    if serializer.resource.respond_to?(:xhtml_help)
      retval += <<EOS
<button id="epic_help_button" class="pull-right btn btn-info btn-mini" data-toggle="collapse" data-target="#epic_help">Help</button>
<div class="collapse" id="epic_help"><div class="row-fluid"><div class="span12">
<h1>Help</h1>#{serializer.resource.xhtml_help}</div></div><hr style="border-color: #000"/></div>
EOS
    end
    if serializer.resource.respond_to?(:xhtml_start)
      retval += serializer.resource.xhtml_start
    end
    retval
  }


  footer {
    |serializer|
    retval = ''
    if serializer.resource.respond_to?(:xhtml_end)
      retval += serializer.resource.xhtml_end
    end
    retval += <<EOS
<div class="row-fluid"><div align="right" class="span12"><em style="font-size: smaller;">
<abbr class="initialism">ePIC</abbr> PID-Service version <a href="#{Rack::Utils::escape_html(EPIC::VERSION_URL)}">#{EPIC::VERSION}</a><br/>
Developed by the <a href="http://pidconsortium.eu/"><abbr class="initialism">ePIC</abbr> Consortium</a>:
  <a href="http://www.csc.fi/">CSC</a>,
  <a href="http://www.dkrz.de/">DKRZ</a>,
  <a href="http://www.gwdg.de/">GWDG</a>, and
  <a href="http://www.surfsara.nl/">SURFsara</a><br/>
Sponsored by:
  <a href="http://www.catchplus.nl/">CATCH+</a>,
  <a href="http://de.dariah.eu/">DARIAH-DE</a> and
  <a href="http://www.eudat.eu/">EUDAT</a><br/>
Powered by <a href="http://github.com/pieterb/Rackful">Rackful</a>
</em></div></div></div></body></html>
EOS
    retval
  }


end # class XHTML


# Base class of all resources in this web service.
class Resource


  include Rackful::Resource


  GLOBAL_LOCK_MUTEX = Mutex.new
  GLOBAL_LOCK_HASH = {}


  # @param path [#to_s] The path of this resource. This is a `path-absolute` as
  #   defined in {http://tools.ietf.org/html/rfc3986#section-3.3 RFC3986, section 3.3}.
  # @see #path
  def initialize path
    self.path = path
  end


  def lock unlock = false
    self.class.lock self.path, unlock
  end


  def unlock
    self.lock true
  end


  def self.lock path, unlock
    GLOBAL_LOCK_MUTEX.synchronize do
      if unlock
        GLOBAL_LOCK_HASH.delete path
      elsif GLOBAL_LOCK_HASH[path]
        raise HTTP503ServiceUnavailable, 'Another client is modifying the resource.'
      else
        GLOBAL_LOCK_HASH[path] = true
      end
    end
  end


  def xhtml_help
    <<EOS
<h2>General</h2>
All resources honor the <code>Accept:</code> HTTP request header, and can be represented in the following formats:
<dl class="dl-horizontal">
  <dt>XHTML5</dt>
  <dd>by specifying one of
    <code>application/xhtml+xml</code> (prefered),
    <code>text/xml</code> or
    <code>application/xml</code>;</dd>
  <dt>HTML5</dt>
  <dd>by specifying <code>text/html</code>;</dd>
  <dt>JSON</dt>
  <dd>by specifying one of
    <code>application/json</code> (prefered) or
    <code>application/x-json</code> (deprecated);</dd>
</dl>
EOS
  end


  add_serializer EPIC::XHTML
  add_serializer Rackful::JSON


end # class Resource


end # module EPIC

