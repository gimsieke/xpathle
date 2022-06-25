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
    <ixsl:schedule-action wait="3000">
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
        <xsl:value-of select="fn:format-date(xs:date($name), '[MNn] [D], [Y]')"/>: 
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
          <details>
            <summary>Archive</summary>
            <xsl:sequence select="$archive ! tr:render-conf-item(., $conf?daily(.), 'daily')"/>
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
        autocomplete="off" size="90" autocapitalize="none" value="{$conf($type)($name)?url}">
        <xsl:if test="$conf($type)($name)?cache_url">
          <xsl:attribute name="data-cache-url" select="$conf($type)($name)?cache_url"/>
        </xsl:if>
      </input></p>
    <p id="guesspara"><label for="guesspath">Guess an XPath expression:</label>  <input id="guesspath" type="text" 
      name="guesspath" autocomplete="off" size="74" autocapitalize="none" value="()"/>  <button 
        id="submit-guess" value="{$type}/{$name}">Submit</button></p>
    </xsl:result-document>
    <xsl:if test="exists(id('iteration', ixsl:page()))">
      <xsl:result-document href="#iteration" method="ixsl:replace-content"></xsl:result-document>
    </xsl:if>
    <ixsl:schedule-action wait="1">
      <xsl:call-template name="guess"/>
    </ixsl:schedule-action>
  </xsl:template>

  <xsl:template mode="ixsl:onclick" match="id('submit-guess')" name="guess">
    <xsl:variable name="doc-uri" as="xs:string" 
      select="(id('doc-uri',ixsl:page())/@data-cache-url, ixsl:get(id('doc-uri',ixsl:page()), 'value'))[1]"/>
    <xsl:variable name="conf" as="map(*)" select="tr:get-conf()"/>
    <xsl:variable name="type-and-name" as="xs:string" select="ixsl:get(id('submit-guess'), 'value')"/>
    <xsl:variable name="type" as="xs:string" select="substring-before($type-and-name, '/')"/>
    <xsl:variable name="name" as="xs:string" select="substring-after($type-and-name, '/')"/>
    <xsl:variable name="iteration" as="xs:integer" 
      select="(id('iteration',ixsl:page())[. castable as xs:integer] ! xs:integer(.), -1)[1]"/>
    <ixsl:schedule-action document="{$doc-uri}">
      <xsl:call-template name="process">
        <xsl:with-param name="secret-path" select="$conf($type)($name)?secret" as="xs:string" tunnel="yes"/>
        <xsl:with-param name="guess-path" select="ixsl:get(id('guesspath',ixsl:page()), 'value')" as="xs:string?" tunnel="yes"/>
        <xsl:with-param name="tries" select="$conf($type)($name)?tries ! xs:integer(.)" tunnel="yes" as="xs:integer"/>
        <xsl:with-param name="href" select="$doc-uri"/>
        <xsl:with-param name="iteration" as="xs:integer" select="$iteration" tunnel="yes"/>
        <xsl:with-param name="is-daily" as="xs:boolean" tunnel="yes" 
          select="tr:YYYY-MM-DD() = $name and $type = 'daily'"/>
        <xsl:with-param name="description" as="xs:string" tunnel="yes" select="$conf($type)($name)?description"/>
      </xsl:call-template>
    </ixsl:schedule-action>
  </xsl:template>

  <xsl:template name="process">
    <xsl:param name="href"/>
    <xsl:variable name="result" as="element(html:div)">
      <xsl:apply-templates select="doc($href)" mode="process-document-entrypoint">
        <xsl:with-param name="omit-html-scaffold" select="true()" as="xs:boolean" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:result-document href="#rendition" method="ixsl:replace-content">
      <xsl:sequence select="$result"/>
    </xsl:result-document>
    <xsl:if test="$result//html:p[@class = 'end']">
      <xsl:result-document href="#guesspara" method="ixsl:replace-content"/>
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
      <ixsl:set-property name="location.hash" select="$fragment-id"/>
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>