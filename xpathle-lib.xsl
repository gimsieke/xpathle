<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tr="http://transpect.io"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:err="http://www.w3.org/2005/xqt-errors"
  default-mode="process-document-entrypoint"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="xs html tr" version="3.0"> 

  <!-- These two params are for standalone invocation using this stylesheet.
       In the interactive stylesheet, tunnel params with the same names
       need to be passed to the template matching the document node of
       the target document. -->
  <xsl:param name="secret-path" as="xs:string"/>
  <xsl:param name="guess-path" as="xs:string" select="'()'"/>

  <xsl:mode name="process-document-entrypoint"/>

  <xsl:output method="xhtml" include-content-type="no"/>

  <xsl:variable name="color-range" as="xs:integer" select="12"/>
  <xsl:variable name="max-highlight" as="xs:integer" select="20"/>

  <xsl:template match="/" mode="#default">
    <xsl:param name="secret-path" as="xs:string" tunnel="yes" select="$secret-path"/>
    <xsl:param name="guess-path" as="xs:string" tunnel="yes" select="$guess-path"/>
    
    <xsl:variable name="selected-by-secret-path" as="item()*">
      <xsl:evaluate xpath="$secret-path" context-item="." namespace-context="/*"/>
    </xsl:variable>
    <xsl:variable name="selected-by-guess-path" as="item()*">
      <xsl:try>
        <xsl:evaluate xpath="$guess-path" context-item="." namespace-context="/*"/>
        <xsl:catch>
          <p class="error">
            <xsl:attribute name="id" select="'xpathle_error'"/>
            There was an error (code <xsl:value-of select="$err:code"/>) evaluating the expression
            <code><xsl:value-of select="$guess-path"/></code>:
          <xsl:value-of select="$err:description"/></p>
        </xsl:catch>
      </xsl:try>
    </xsl:variable>
    <xsl:variable name="solved" as="xs:boolean"
        select="(count($selected-by-guess-path) = count($selected-by-secret-path)) 
                    and 
                    (empty($selected-by-guess-path except $selected-by-secret-path))"/>
    <xsl:call-template name="render">
      <xsl:with-param name="secret-path" select="$secret-path" tunnel="yes"/>
      <xsl:with-param name="guess-path" select="$guess-path" tunnel="yes"/>
      <xsl:with-param name="selected-by-secret-path" as="item()*" select="$selected-by-secret-path" tunnel="yes"/>
      <xsl:with-param name="selected-by-guess-path" as="item()*" tunnel="yes" select="$selected-by-guess-path"/>
      <xsl:with-param name="solved" as="xs:boolean" tunnel="yes" select="$solved"/>
      <xsl:with-param name="highlight-items" as="item()*" tunnel="yes" 
        select="($selected-by-guess-path)[$solved 
                                          or 
                                          (position() = (1 to xs:integer(min(($max-highlight, count($selected-by-secret-path) * 2)))))]"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="render">
    <xsl:param name="omit-html-scaffold" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="guess-path" as="xs:string" tunnel="yes"/>
    <xsl:variable name="prelim" as="element()">
      <div id="rendition">
        <xsl:try>
          <!-- the error may be deferred, for example, if $guess-path = 'false()' -->
          <xsl:apply-templates select="/" mode="serialize"/>
          <xsl:catch>
            <xsl:apply-templates select="/" mode="serialize">
              <xsl:with-param name="error-para" as="element(html:p)" tunnel="yes">
                <p class="error">
                  <xsl:attribute name="id" select="'xpathle_error3'"/> There was an error (code <xsl:value-of
                    select="$err:code"/>) evaluating the expression <code><xsl:value-of select="$guess-path"/></code>:
                    <xsl:value-of select="$err:description"/></p>    
              </xsl:with-param>
            </xsl:apply-templates>
          </xsl:catch>
        </xsl:try>
      </div>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$omit-html-scaffold">
        <xsl:sequence select="$prelim"/>
      </xsl:when>
      <xsl:otherwise>
        <html>
          <head>
            <meta charset="UTF-8"/>
            <title>XPathle</title>
            <link type="text/css" rel="stylesheet" href="xpathle.css"/>
          </head>
          <body>
            <xsl:sequence select="$prelim"/>
          </body>
        </html>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template name="test">
    <xsl:choose>
    <xsl:when test="namespace-uri(/*) = 'http://transpect.io'">
      <xsl:message select="'DDDDDDDD ', tr:node-distance(//*:param[@name='publisher-prefix-for-style-mapping']/@name, //*:param[@name='rule-category-span-class']/@value)"/>
    </xsl:when>
    <xsl:when test="namespace-uri(/*) = 'http://relaxng.org/ns/structure/1.0'">
      <xsl:message select="'EEEEEEEE ', tr:node-distance(//*:define[@name = 'a.name']/*:attribute/@name, //*:define[@name = 'a.name']/*:attribute)"/>
    </xsl:when>      
    <xsl:when test="namespace-uri(/*) = 'http://www.akomantoso.org/2.0'">
      <xsl:message select="'FFFFFFFF ', tr:node-distance((//*:point)[1]/@id, (//*:point)[1]/text()[1])"/>
    </xsl:when>
    <xsl:when test="namespace-uri(/*) = 'http://www.w3.org/1999/xhtml' and /html:html/html:head/html:title = 'XPathle'">
      <xsl:message select="'GGGGGGGG ', tr:node-distance((//html:details)[1]/html:p[1], 
                                      (//html:details)[1]/@id)"/>
    </xsl:when>
    <xsl:when test="namespace-uri(/*) = 'http://www.w3.org/1999/xhtml' and not(/html:html/html:head/html:title = 'XPathle')">
      <xsl:message select="'HHHHHHHH ', tr:node-distance((//text()[. = 'Styles are retained as '])[1], 
                                      //text()[starts-with(., '. Generation is')])"/>
    </xsl:when>
      
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="distance-to-closest-secret-item" as="xs:integer?">
    <xsl:param name="selected-by-guess-path" as="item()*" tunnel="yes"/>
    <xsl:param name="selected-by-secret-path" as="item()*" tunnel="yes"/>
    <xsl:if test="every $g in $selected-by-guess-path satisfies ($g instance of node())">
      <xsl:if test="generate-id() = $selected-by-guess-path ! generate-id(.)">
        <xsl:sequence select="xs:integer(min($selected-by-secret-path ! tr:node-distance(., current())))"/>
      </xsl:if>  
    </xsl:if>
  </xsl:template>
  
  <xsl:function name="tr:result-is-error" as="xs:boolean">
    <xsl:param name="result" as="item()*"/>
    <xsl:try select="exists($result/self::html:p[@id = 'xpathle_error'][@class = 'error'])">
      <xsl:catch select="true()"/>
    </xsl:try>
  </xsl:function>
  
  <xsl:template match="/" mode="serialize" priority="3">
    <xsl:param name="secret-path" as="xs:string" tunnel="yes"/>
    <xsl:param name="guess-path" as="xs:string" tunnel="yes"/>
    <xsl:param name="selected-by-guess-path" as="item()*" tunnel="yes"/>
    <xsl:param name="selected-by-secret-path" as="item()*" tunnel="yes"/>
    <xsl:param name="highlight-items" as="item()*" tunnel="yes"/>
    <xsl:param name="solved" as="xs:boolean" tunnel="yes"/>
    <xsl:param name="iteration" as="xs:integer" tunnel="yes" select="0"/>
    <xsl:param name="tries" as="xs:integer" tunnel="yes" select="6"/>
    <xsl:param name="error-para" as="element(html:p)?" tunnel="yes"/>
    <xsl:variable name="guess-count" as="xs:integer" 
      select="if (exists($error-para)) then 0
              else count($selected-by-guess-path[not(tr:result-is-error(.))])"/>
    <xsl:variable name="secret-count" as="xs:integer" select="count($selected-by-secret-path)"/>
    <xsl:if test="$secret-count = 0">
      <xsl:message terminate="yes" error-code="XPathle01">The secret XPath expression <xsl:value-of select="$secret-path"/> does not select anything.</xsl:message>
    </xsl:if>
    <xsl:variable name="zero-distance-cell-number" as="xs:integer" 
      select="xs:integer(min(($secret-count, $color-range)))"/>
    <xsl:variable name="cell-count" as="xs:integer" 
      select="$zero-distance-cell-number + $color-range"/>
    <xsl:if test="count($highlight-items) lt $guess-count">
      <p>The guess selected <xsl:value-of select="$guess-count"/> items. Only the first <xsl:value-of 
        select="count($highlight-items)"/> will be highlighted.</p>
    </xsl:if>
    <xsl:try>
      <!-- the error may be deferred, for example, if $guess-path = 'false()' -->
      <xsl:choose>
        <xsl:when test="some $g in $selected-by-guess-path satisfies (not($g instance of node()))
                        or (exists($error-para) and not($error-para instance of node()))">
          <p class="warning">
          <xsl:attribute name="id" select="'xpathle_error3'"/> Warning (code XPathle03): <code><xsl:value-of
            select="$selected-by-guess-path[not(. instance of node())], $error-para"/></code> is not a node from the document.</p>
        </xsl:when>
        <xsl:when test="exists($error-para)">
          <xsl:sequence select="$error-para"/>
        </xsl:when>
        <xsl:when test="tr:result-is-error($selected-by-guess-path)">
          <xsl:sequence select="$selected-by-guess-path"/>
        </xsl:when>
      </xsl:choose>
      <xsl:catch>
        <p class="error">
          <xsl:attribute name="id" select="'xpathle_error2'"/> There was an error (code <xsl:value-of select="$err:code"
          />) evaluating the expression <code><xsl:value-of select="$guess-path"/></code>: <xsl:value-of
            select="$err:description"/></p>
      </xsl:catch>
    </xsl:try>
    <xsl:sequence select="$error-para"/>
    <p>Attempts so far: <span id="iteration"><xsl:value-of select="$iteration + 1"/></span> of <xsl:value-of select="$tries"/></p>
    <div id="counts">
      <xsl:choose>
        <xsl:when test="$solved">
          <h2>Congratulations!</h2>
          <p>You needed <xsl:value-of select="$iteration + 1"/> attempt<xsl:if test="$iteration ge 1">s</xsl:if> to solve this puzzle.</p>
          <p id="winning" class="end">The items selected by <code><xsl:value-of select="$guess-path"/></code> are
            identical to the items selected by the secret XPath expression.</p>
          <p>The secret expression is: <code><xsl:value-of select="$secret-path"/></code>.</p>
        </xsl:when>
        <xsl:when test="$iteration + 1 = $tries">
          <p id="losing" class="end">Unfortunately, you couldn’t solve the puzzle in <xsl:value-of select="$tries"/> attempt<xsl:if test="$iteration ge 1">s</xsl:if>.
          Hopefully you learned a bit of XPath nevertheless.</p>
        </xsl:when>
      </xsl:choose>
      <table>
        <tr>
          <th>Number of items selected by guess:</th>
          <xsl:for-each select="0 to $cell-count">
            <td class="{tr:distance-class(xs:integer(abs(. - $zero-distance-cell-number)))}">
              <xsl:choose>
                <xsl:when test=". = min((max((0, $guess-count - $secret-count + $zero-distance-cell-number)), $color-range + $zero-distance-cell-number))">
                  <xsl:value-of select="$guess-count"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>&#x2002;</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </td>
          </xsl:for-each>
        </tr>
        <tr>
          <th>Number of items selected by secret expression:</th>
          <xsl:for-each select="0 to $cell-count">
            <td class="grey">
              <xsl:choose>
                <xsl:when test=". = $zero-distance-cell-number">
                  <xsl:value-of select="$secret-count"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>&#x2002;</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </td>
          </xsl:for-each>
        </tr>
      </table>
    </div>
    <div id="code">
      <xsl:next-match/>
    </div>
  </xsl:template>

  <xsl:function name="tr:distance-class" as="xs:string">
    <xsl:param name="distance" as="xs:integer"/>
    <xsl:sequence select="concat('distance', if ($distance gt $color-range - 2) then 'Far' else string($distance))"/>
  </xsl:function>

  <xsl:template match="* | @* | processing-instruction() | comment() | text()" mode="serialize" priority="2">
    <xsl:param name="highlight-items" as="item()*" tunnel="yes"/>
    <xsl:param name="selected-by-guess-path" as="item()*" tunnel="yes"/>
    <xsl:variable name="path" as="xs:string" select="tr:path-without-default-namespace(.)"/>
    <xsl:variable name="distance" as="xs:integer?">
      <xsl:call-template name="distance-to-closest-secret-item"/>
    </xsl:variable>
    <span title="{string-join(($path, 'Distance:'[exists($distance)], $distance), ' ')}">
      <xsl:choose>
        <xsl:when test="some $g in $selected-by-guess-path satisfies (not($g instance of node()))">
          <!-- the guess was 'false()', for example -->
        </xsl:when>
        <xsl:when test="generate-id() = ($selected-by-guess-path except $highlight-items) ! generate-id(.)">
          <xsl:attribute name="class" select="'white hidden'"/>
        </xsl:when>
        <xsl:when test="generate-id() = $highlight-items ! generate-id(.)">
          <xsl:attribute name="class" select="string-join(('guess', tr:distance-class($distance)), ' ')"/>
        </xsl:when>
      <!-- intersect doesn’t seem to work correctly with attributes in SaxonJS (tested on v1.2 and v2.4),
           therefore reverting to comparing generated IDs, which works. -->
        <!--<xsl:when test="exists(. intersect ($selected-by-guess-path except $highlight-items))">
          <xsl:attribute name="class" select="'white hidden'"/>
        </xsl:when>
        <xsl:when test="exists(. intersect $highlight-items)">
          <xsl:attribute name="class" select="string-join(('guess', tr:distance-class($distance)), ' ')"/>
        </xsl:when>-->
        <xsl:otherwise>
          <xsl:attribute name="class" select="'white'"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:next-match/>
    </span>
  </xsl:template>
  
  <xsl:template match="*" mode="serialize" priority="1">
    <span class="name elt">
      <xsl:text>&lt;</xsl:text>
      <xsl:value-of select="name()"/>
    </span>
    <xsl:apply-templates select="." mode="xmlns"/>
    <xsl:apply-templates select="@*" mode="#current"/>
    <xsl:choose>
      <xsl:when test="empty(node())">
        <span class="name elt">/></span>
      </xsl:when>
      <xsl:otherwise>
        <span class="name elt">></span>
        <xsl:apply-templates mode="#current"/>
        <span class="name elt">
          <xsl:text>&lt;/</xsl:text>
          <xsl:value-of select="name()"/>
          <xsl:text>></xsl:text>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="@*" mode="serialize" priority="1">
    <xsl:text> </xsl:text>
    <span class="name att">
      <xsl:value-of select="name()"/>
    </span>
    <span class="val att">
      <xsl:text>="</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>"</xsl:text>
    </span>
  </xsl:template>

  <xsl:template match="*" mode="xmlns">
    <xsl:if test="not(namespace-uri(.) = namespace-uri(..))">
      <span class="name att">
        <xsl:text> xmlns="</xsl:text>
        <xsl:value-of select="namespace-uri(.)"/>
        <xsl:text>"</xsl:text>
      </span>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="text()" mode="serialize" priority="1">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="comment()" mode="serialize" priority="1">
    <span class="comment{if(empty(parent::*)) then ' unselectable' else''}">
      <xsl:attribute name="title" select="'this comment cannot be selected'"/>
      <xsl:value-of select="string-join(('&lt;!--', ., '-->'))"/>
    </span>
    <xsl:if test="empty(parent::*)">&#xa0;&#xa;</xsl:if>
  </xsl:template>
  
  <xsl:template match="processing-instruction()" mode="serialize" priority="1">
    <span class="pi{if(empty(parent::*)) then ' unselectable' else''}">
      <xsl:if test="empty(parent::*)">
        <xsl:attribute name="title" select="'this PI cannot be selected'"/>
      </xsl:if>
      <xsl:value-of select="string-join(('&lt;?', name(), ' ', ., '?>'))"/>  
    </span>
    <xsl:if test="empty(parent::*)">&#xa0;&#xa;</xsl:if>
  </xsl:template>

  <xsl:function name="tr:path-without-default-namespace" as="xs:string">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="path($node) => replace('Q\{' || namespace-uri(($node/self::*|$node/..)[1]) || '\}', '')"/>
  </xsl:function>

  <xsl:function name="tr:node-distance" as="xs:integer">
    <xsl:param name="node1" as="node()"/>
    <xsl:param name="node2" as="node()"/>
    <xsl:variable name="common-ancestor" as="element()" 
      select="($node1/ancestor-or-self::* intersect $node2/ancestor-or-self::*)[last()]"/>
    <xsl:variable name="element-distance" as="xs:integer"
      select="count($node1/ancestor-or-self::* intersect $common-ancestor/descendant::*)
              + count($node2/ancestor-or-self::* intersect $common-ancestor/descendant::*)"/>
     <xsl:variable name="same-axis" as="xs:boolean" 
      select="exists(
                      $node1/ancestor::* intersect $node2/ancestor-or-self::*[1]
                      union
                      $node2/ancestor::* intersect $node1/ancestor-or-self::*[1]
                    )"/>
    <xsl:variable name="identical" as="xs:boolean" select="$node1/generate-id() = $node2/generate-id()"/>
    <xsl:variable name="potential-sibling1" as="node()?" select="$node1/ancestor-or-self::node()[.. is $common-ancestor]"/>
    <xsl:variable name="potential-sibling2" as="node()?" select="$node2/ancestor-or-self::node()[.. is $common-ancestor]"/>
    <xsl:variable name="intermediate-siblings" as="node()*" 
      select="$potential-sibling1/following-sibling::node()[empty(self::text()[not(normalize-space())])]
                                                           [. &lt;&lt; $potential-sibling2]
              union
              $potential-sibling2/following-sibling::node()[empty(self::text()[not(normalize-space())])]
                                                           [. &lt;&lt; $potential-sibling1]"/>
    <xsl:message select="'ED: ', $element-distance, ' corr: ', 
      if ($same-axis[exists($node1/self::* | $node2/self::*)]) then 0 else 1,
      ' inter: ', count($intermediate-siblings/generate-id()), count($intermediate-siblings),
      ' non-elt: ', count(($node1 | $node2)[not(self::*)])"/>
    <xsl:choose>
      <xsl:when test="$identical">
        <xsl:sequence select="0"/>
      </xsl:when>
      <xsl:when test="$element-distance = 0 
                      and $node1/self::attribute()
                      and $node2/self::attribute()
                      and (not($identical))">
        <!-- different attributes on the same element -->
        <xsl:sequence select="1"/>
      </xsl:when>
      <xsl:when test="$element-distance = 0 
                      and ($node1/self::attribute() or $node2/self::attribute())">
        <!-- one attribute, one text, comment, or PI node on the same element -->
        <xsl:sequence select="1 + count($node1[not(self::attribute())][not(self::*)]
                                        union 
                                        $node2[not(self::attribute())][not(self::*)])"/>
      </xsl:when>
      <xsl:when test="$node1[empty(self::attribute())]/.. is $common-ancestor
                      and
                      $node2[empty(self::attribute())]/.. is $common-ancestor">
        <xsl:sequence select="count($intermediate-siblings) + 1"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$element-distance - (if ($same-axis[exists($node1/self::* | $node2/self::*)]) then 0 else 1) 
                                (: instead of going up to the common ancestor and down again,
                                we count the intermediate nodes, add them, add one for jumping from the last
                                intermediate item to the other node, and subtract 2 for not going to the common
                                ancestor from the penultimate ancestors :)
                                + count($intermediate-siblings/generate-id())
                                + count(($node1 | $node2)[not(self::*)]
                                (:[not(self::attribute())])
                                + count($node1[self::attribute()]) + count($node2[self::attribute()]:)
                                )"/>
      </xsl:otherwise>
      <!--<xsl:otherwise>
        <xsl:message error-code="XPathle02" terminate="yes" select="'This case should not happen. Element distance: ',
          $element-distance"></xsl:message>
      </xsl:otherwise>-->
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
