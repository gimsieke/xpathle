<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:my="bogo:my"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
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
  </xsl:template>
  
  <xsl:template name="read-config">
    <xsl:result-document href="#config" method="ixsl:replace-content">
      <xsl:value-of select="unparsed-text('config.txt')"/>
    </xsl:result-document>
    <ixsl:schedule-action wait="1">
      <xsl:call-template name="populate-controls"/>
    </ixsl:schedule-action>
  </xsl:template>
  
  <xsl:function name="my:render-conf-item" as="item()*">
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="map" as="map(*)"/>
    <xsl:param name="type" as="xs:string"/>
    <p><button name="{$type}" value="{$name}" class="load"><xsl:value-of select="$map?description"/></button></p>
  </xsl:function>
  
  <xsl:function name="my:get-conf" as="map(*)">
    <xsl:sequence select="parse-json(ixsl:call(ixsl:window(), 'atob', [replace(string(id('config', ixsl:page())), '\s+', '', 's')]))"/>
  </xsl:function>
  
  <xsl:template name="populate-controls">
    <xsl:variable name="conf" select="my:get-conf()"/>
    <xsl:result-document href="#controls">
      <h2>Examples</h2>
      <xsl:sequence select="map:keys($conf?example) ! my:render-conf-item(., $conf?example(.), 'example')"/>
      <xsl:variable name="current-date" as="xs:string" 
        select="current-date() => string() => replace('^(\d{4}-\d\d-\d\d).+$', '$1')"/>
      <xsl:variable name="daily" as="map(*)?" select="$conf?daily($current-date)"/>
      <xsl:if test="exists($daily)">
        <h2>Daily</h2>
        <xsl:sequence select="my:render-conf-item($current-date, $daily, 'daily')"/>        
      </xsl:if>

    </xsl:result-document>
  </xsl:template>
  
  <xsl:template mode="ixsl:onclick" match="button[@name=('example', 'daily')]">
    <xsl:variable name="conf" as="map(*)" select="my:get-conf()"/>
    <xsl:variable name="name" as="xs:string" select="ixsl:get(., 'value')"/>
    <xsl:variable name="type" as="xs:string" select="@name"/>
    <xsl:result-document href="#controls2" method="ixsl:replace-content">
      <p><label for="doc-uri">Document URI:</label>  <input id="doc-uri" type="text" name="doc-uri" 
        autocomplete="off" size="90" autocapitalize="none" value="{$conf($type)($name)?url}">
        <xsl:if test="$conf($type)($name)?cache_url">
          <xsl:attribute name="data-cache-url" select="$conf($type)($name)?cache_url"/>
        </xsl:if>
      </input></p>
    <p><label for="guesspath">Guess an XPath expression:</label>  <input id="guesspath" type="text" 
      name="guesspath" autocomplete="off" size="40" autocapitalize="none" value="()"/>  <button 
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
    <xsl:variable name="conf" as="map(*)" select="my:get-conf()"/>
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
      </xsl:call-template>
    </ixsl:schedule-action>
  </xsl:template>

  <xsl:template name="process">
    <xsl:param name="href"/>
    <xsl:result-document href="#rendition" method="ixsl:replace-content">
      <xsl:apply-templates select="doc($href)" mode="process-document-entrypoint">
        <xsl:with-param name="omit-html-scaffold" select="true()" as="xs:boolean" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:result-document>
  </xsl:template>

  <xsl:template match="." mode="ixsl:onkeydown">
    <xsl:variable name="key" select="ixsl:get(ixsl:event(), 'key')"/>
    <xsl:if test="$key = 'Enter'">
      <xsl:call-template name="guess"/>
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>