<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tr="http://transpect.io"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization"
  xmlns:saxon="http://saxon.sf.net/"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  version="3.0"
  extension-element-prefixes="ixsl" 
  xpath-default-namespace="http://www.w3.org/1999/xhtml">

  <xsl:import href="xpathle-lib.xsl"/>

  <xsl:template name="main">
    <ixsl:schedule-action document="config.txt">
      <xsl:call-template name="read-config"/>
    </ixsl:schedule-action>
    <ixsl:schedule-action wait="1000">
      <xsl:call-template name="uncollapse-details">
        <xsl:with-param name="href" select="ixsl:location()"/>
      </xsl:call-template>
    </ixsl:schedule-action>
  </xsl:template>
  
  <xsl:template name="read-config">
    <xsl:result-document href="#config" method="ixsl:replace-content">
      <xsl:value-of select="unparsed-text('config.txt')"/>
    </xsl:result-document>
    <ixsl:schedule-action wait="1">
      <xsl:call-template name="populate-controls"/>
    </ixsl:schedule-action>
  </xsl:template>
  
  <xsl:function name="tr:render-conf-item" as="item()*">
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="map" as="map(*)"/>
    <xsl:param name="type" as="xs:string"/>
    <p id="{$type}_{$name}">
      <xsl:if test="$type = 'daily'">
        <span class="date">
          <xsl:value-of select="fn:format-date(xs:date($name), '[MNn] [D], [Y]')"/>:  
        </span>
      </xsl:if> 
      <button name="{$type}" value="{$name}" class="load">
        <xsl:if test="$type = 'daily' and $name = tr:YYYY-MM-DD()">
          <xsl:attribute name="id" select="'daily'"/>
        </xsl:if>
        <xsl:value-of select="$map?description"/>
      </button></p>
  </xsl:function>
  
  <xsl:function name="tr:get-conf" as="map(*)">
    <xsl:sequence select="parse-json(ixsl:call(ixsl:window(), 'atob', [replace(string(id('config', ixsl:page())), '\s+', '', 's')]))"/>
  </xsl:function>
  
  <xsl:template name="populate-controls">
    <xsl:variable name="conf" select="tr:get-conf()"/>
    <xsl:result-document href="#controls">
      <h2>Examples</h2>
      <xsl:sequence select="sort(map:keys($conf?example), 'http://saxon.sf.net/collation?ignore-case=yes', 
                                 function($key) { $conf?example($key)?description })
                            ! tr:render-conf-item(., $conf?example(.), 'example')"/>
      <xsl:variable name="current-date" as="xs:string" select="tr:YYYY-MM-DD()"/>
      <xsl:variable name="daily" as="map(*)?" select="$conf?daily($current-date)"/>
      <xsl:variable name="archive" as="xs:string*" select="sort(map:keys($conf?daily)[xs:date(.) lt current-date()])"/>
      <xsl:if test="exists($daily) or exists($archive)">
        <h2>Daily</h2>
        <xsl:if test="exists($archive)">
          <xsl:if test="empty($daily)">
            <p>Sorry, no daily challenge today. But you can send a suggestion to <a 
              href="mailto:gerrit.imsieke@le-tex.de">Gerrit</a>. Or browse the archive.</p>
          </xsl:if>
          <details id="archive" open="open">
            <summary>Archive</summary>
            <xsl:for-each-group select="$archive" group-by="substring(., 1, 7)">
              <details>
                <summary>
                  <xsl:value-of select="current-grouping-key()"/>
                </summary>
                <xsl:sequence select="current-group() ! tr:render-conf-item(., $conf?daily(.), 'daily')"/>
              </details>
            </xsl:for-each-group>
          </details>
        </xsl:if>
        <xsl:if test="exists($daily)">
          <xsl:sequence select="tr:render-conf-item($current-date, $daily, 'daily')"/>
        </xsl:if>
      </xsl:if>
    </xsl:result-document>
  </xsl:template>

  <xsl:template mode="ixsl:onclick" match="button[@name=('example', 'daily')]">
    <xsl:variable name="conf" as="map(*)" select="tr:get-conf()"/>
    <xsl:variable name="name" as="xs:string" select="ixsl:get(., 'value')"/>
    <xsl:variable name="type" as="xs:string" select="@name"/>
    <xsl:result-document href="#controls2" method="ixsl:replace-content">
      <p><label for="doc-uri">Document URI:</label>  <input id="doc-uri" type="text" name="doc-uri" 
        autocomplete="off" size="110" autocapitalize="none" value="{$conf($type)($name)?url}">
        <xsl:if test="$conf($type)($name)?cache_url">
          <xsl:attribute name="data-cache-url" select="$conf($type)($name)?cache_url"/>
        </xsl:if>
      </input> 
        <span id="format-checkbox-wrapper"><input id="format" type="checkbox"/>
      <label for="format">Format &amp; indent</label></span>
      </p>
    <p id="guesspara"><label for="guesspath">Guess an XPath expression:</label>  <button 
        id="use-stats">use stats</button> <label for="use-stats">(see <a href="#tips_query">above</a>)</label>  <button 
        id="use-scatter">use scatter</button> <label for="use-scatter">(see <a href="#tips_scatter">above</a>)</label>  
      <input id="guesspath" type="text" name="guesspath" autocomplete="off" size="74" autocapitalize="none" value="()"/>  
      <button id="submit-guess" value="{$type}/{$name}">Submit</button>  <span id="computing">Computing…</span></p>
    </xsl:result-document>
    <xsl:if test="exists(id('iteration', ixsl:page()))">
      <xsl:result-document href="#iteration" method="ixsl:replace-content">0</xsl:result-document>
    </xsl:if>
    <xsl:result-document href="#previous" method="ixsl:replace-content"/>
    <ixsl:schedule-action wait="1">
      <xsl:call-template name="guess">
        <xsl:with-param name="reset" select="true()"/>
      </xsl:call-template>
    </ixsl:schedule-action>
  </xsl:template>

  <xsl:template mode="ixsl:onclick" match="button[@id='use-scatter']">
    <xsl:variable name="secret-count" as="xs:integer" 
      select="id('counts', ixsl:page())/table/tr[2]/td[. castable as xs:integer] => xs:integer()"/>
    <xsl:variable name="expression" as="xs:string" 
      select="'let $start := /*, $count := count($start/descendant-or-self::*), $dist := max(($count idiv ' ||
              tr:highlight-count($min-highlight, $max-highlight, $secret-count) || 
              ', 1)) return $start/descendant-or-self::*[position() mod $dist = $dist idiv 2]'"/>
    <ixsl:set-property name="value" select="$expression" object="id('guesspath', ixsl:page())"/>
  </xsl:template>

  <xsl:template mode="ixsl:onclick" match="button[@id='use-stats']">
    <ixsl:set-property name="value" object="id('guesspath', ixsl:page())"
      select="'sort(for $n in distinct-values(//*/name()) return $n || ''~'' || count(//*[name()=$n]), (), function($i) {-number(substring-after($i, ''~''))})'"/>
  </xsl:template>

  <xsl:template mode="ixsl:onclick" match="id('format')">
    <xsl:variable name="checked" as="xs:boolean" select="ixsl:get(., 'checked')"/>
      <ixsl:schedule-action wait="1">
        <xsl:call-template name="guess"/>
      </ixsl:schedule-action>
  </xsl:template>

  <xsl:template mode="ixsl:onclick" match="id('submit-guess')" name="guess">
    <xsl:param name="reset" as="xs:boolean" select="false()"/>
    <xsl:variable name="doc-uri" as="xs:string"
      select="(id('doc-uri',ixsl:page())/@data-cache-url, ixsl:get(id('doc-uri',ixsl:page()), 'value'))[1]"/>
    <xsl:variable name="conf" as="map(*)" select="tr:get-conf()"/>
    <xsl:variable name="type-and-name" as="xs:string" select="ixsl:get(id('submit-guess'), 'value')"/>
    <xsl:variable name="type" as="xs:string" select="substring-before($type-and-name, '/')"/>
    <xsl:variable name="previous" as="xs:string?" select="id('previous', ixsl:page())"/>
    <xsl:variable name="name" as="xs:string" select="substring-after($type-and-name, '/')"/>
    <xsl:variable name="iteration" as="xs:integer" 
      select="(-1[$reset], id('iteration',ixsl:page())[. castable as xs:integer] ! xs:integer(.), -1)[1]"/>
    <ixsl:set-style name="display" select="'inline'" object="id('computing', ixsl:page())"/>
    <ixsl:schedule-action document="{$doc-uri}">
      <xsl:call-template name="process">
        <xsl:with-param name="secret-path" select="$conf($type)($name)?secret" as="xs:string" tunnel="yes"/>
        <xsl:with-param name="guess-path" select="ixsl:get(id('guesspath',ixsl:page()), 'value')" as="xs:string?" tunnel="yes"/>
        <xsl:with-param name="previous" as="xs:string?" select="$previous" tunnel="yes"/>
        <xsl:with-param name="tries" select="$conf($type)($name)?tries ! xs:integer(.)" tunnel="yes" as="xs:integer"/>
        <xsl:with-param name="href" select="$doc-uri"/>
        <xsl:with-param name="iteration" as="xs:integer" select="$iteration" tunnel="yes"/>
        <xsl:with-param name="is-daily" as="xs:boolean" tunnel="yes" 
          select="tr:YYYY-MM-DD() = $name and $type = 'daily'"/>
        <xsl:with-param name="format" as="xs:boolean" tunnel="yes" select="ixsl:get(id('format', ixsl:page()), 'checked')"/>
        <xsl:with-param name="description" as="xs:string" tunnel="yes" select="$conf($type)($name)?description"/>
      </xsl:call-template>
    </ixsl:schedule-action>
  </xsl:template>
  
  <xsl:template name="process">
    <xsl:param name="href"/>
    <ixsl:schedule-action wait="1">
      <xsl:call-template name="process2">
        <xsl:with-param name="href" select="$href"/>
      </xsl:call-template>
    </ixsl:schedule-action>
  </xsl:template>
  
  <xsl:template name="process2">
    <xsl:param name="href"/>
    <xsl:param name="previous" tunnel="yes" as="xs:string?"/>
    <xsl:param name="guess-path" tunnel="yes" as="xs:string"/>
    <xsl:param name="iteration" tunnel="yes" as="xs:integer"/>
    <xsl:variable name="result" as="element(html:div)">
      <xsl:apply-templates select="doc($href)" mode="process-document-entrypoint">
        <xsl:with-param name="omit-html-scaffold" select="true()" as="xs:boolean" tunnel="yes"/>
        <xsl:with-param name="iteration" as="xs:integer" tunnel="yes"
          select="if ($previous = $guess-path) then $iteration - 1 else $iteration"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:result-document href="#rendition" method="ixsl:replace-content">
      <xsl:sequence select="$result/node()"/>
    </xsl:result-document>
    <ixsl:set-style name="display" select="'none'" object="id('computing', ixsl:page())"/>
    <xsl:if test="$result//html:p[@class = 'end']">
      <xsl:result-document href="#guesspara" method="ixsl:replace-content"/>
      <xsl:result-document href="#format-checkbox-wrapper" method="ixsl:replace-content"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="." mode="ixsl:onkeydown">
    <xsl:variable name="key" select="ixsl:get(ixsl:event(), 'key')"/>
    <xsl:if test="$key = 'Enter'">
      <xsl:call-template name="guess"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="." mode="ixsl:onhashchange">
    <xsl:variable name="new" select="ixsl:get(ixsl:event(), 'newURL')"/>
    <xsl:call-template name="uncollapse-details">
      <xsl:with-param name="href" select="$new"/>
    </xsl:call-template>
    <xsl:next-match/>
  </xsl:template>
  
  <xsl:template name="uncollapse-details">
    <xsl:param name="href" as="xs:string"/>
    <xsl:variable name="fragment-id" as="xs:string?" select="$href[contains(., '#')] => substring-after('#')"/>
    <xsl:variable name="details" as="element()*" select="id($fragment-id, ixsl:page())/ancestor-or-self::details"/>
    <xsl:for-each select="$details">
      <ixsl:set-property name="open" select="true()" object="."/>
    </xsl:for-each>
    <xsl:if test="$fragment-id">
      <ixsl:set-property name="location.hash" select="''"/>
      <ixsl:set-property name="location.hash" select="$fragment-id"/>
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>