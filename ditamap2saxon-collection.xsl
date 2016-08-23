<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xs"
  version="2.0">
  
  <xsl:template match="/">
    <xsl:variable name="base" select="substring-after(document-uri(.), '!/')"/>    
    <collection stable="true">
      <xsl:apply-templates mode="collect" select="document($base)"/>
   </collection>
  </xsl:template>
  
  <xsl:template match="/" mode="collect">
    <doc href="{document-uri(.)}"/>
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="*[contains(@class, ' map/topicref ') and @href and (@format='dita' or not(@format))]" 
    mode="collect">
    <xsl:variable name="topic" select="document(@href, .)"/>
    <xsl:apply-templates select="$topic" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="*[contains(@class, ' map/topicref ') and @format='ditamap']" priority="100" 
    mode="collect">
    <xsl:variable name="map" select="document(@href, .)"/>
    <xsl:apply-templates select="$map" mode="#current"/>
  </xsl:template>
  
    <!-- topicset reference -->
    <xsl:template match="*[contains(@class, ' mapgroup-d/topicsetref ')]" priority="150" 
      mode="collect">
        <xsl:variable name="map" select="document(substring-before(@href, '#'), .)"/>
        <xsl:variable name="id" select="substring-after(@href, '#')"/>
        <xsl:apply-templates select="$map//*[@id=$id]" mode="#current"/>
    </xsl:template>
    
    <!-- disable topic expasion inside reltables -->
    <xsl:template match="*[contains(@class, ' map/reltable ')]" mode="collect"/>
    
    <!-- Do not try to open resourse-only topics -->
    <xsl:template match="*[contains(@class, ' map/topicref ') and @processing-role='resource-only']" priority="200" 
      mode="collect"/>
</xsl:stylesheet>