<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:my="URN:my"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xs my"
  version="2.0">
  
  <xsl:output method="xml" indent="yes"/>

  <xsl:template name="main">
    <xsl:apply-templates select="$input" />
  </xsl:template>

  <xsl:variable name="input" as="element(foo)">
    <foo>
      <seq><k/><o/><p/><c/><f/></seq>
      <seq><d/><e/><f/><g/></seq>
      <seq><k/><f/><z/></seq>
      <seq><a/><b/><c/><d/></seq>
    </foo>
  </xsl:variable>

  <xsl:template match="foo">
    <xsl:copy>
      <xsl:for-each-group select="seq/*" group-by="name(.)" >
        <xsl:sort select="my:sortkey(., ())"/>
        <xsl:element name="{current-grouping-key()}" />
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="my:sortkey" as="xs:integer">
    <xsl:param name="input" as="element(*)" />
    <xsl:param name="seen" as="xs:string*" />
    <xsl:if test="name($input) = $seen">
      <xsl:message terminate="yes">Element
        <xsl:value-of select="name($input)"/>
        doesn't seem to occur at a deterministic
        position.
      </xsl:message>
    </xsl:if>
    <xsl:variable
      name="preceding-siblings"
      select="$input/../../seq/*[
                name() = name($input)
              ]/preceding-sibling::*[1]"
      as="element(*)*" />
    <xsl:variable name="seen" select="($seen, name($input))" />
    <xsl:sequence select="(
                            max(
                              for $ps in $preceding-siblings
                                return my:sortkey($ps, $seen)
                            ) + 1,
                            1
                          )[1]"/>
	<!-- short form of if(not(empty($preceding-siblings))) -->
  </xsl:function>
  
</xsl:stylesheet>