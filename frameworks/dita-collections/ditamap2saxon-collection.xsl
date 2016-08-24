<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:df="http://dita2indesign.org/dita/functions"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  exclude-result-prefixes="xs df relpath"
  version="2.0">
  <!-- =============================================================
       Construct a Saxon collection from a DITA map.
       
       The collection reflects all referenced maps and normal-role
       topics (by default).
       
       Set parameter "includeResourceOnly" to "true" to also include
       resource-only topics.
       
       Author: W. Eliot Kimber, George Bina
       
       Copyright (c) 2016 DITA Community Project
       
       May be used without restriction.
       
       ============================================================== -->
  
  <xsl:import href="lib/dita-support-lib.xsl"/>
  <xsl:import href="lib/relpath_util.xsl"/>
  <xsl:import href="lib/resolve-map.xsl"/>
  
  <xsl:output indent="yes"/>
  
  <xsl:param name="debug" select="'false'"/>
  <xsl:variable name="debugBoolean" as="xs:boolean"
    select="matches($debug, '1|yes|on|true', 'i')"
  />
  
  <!-- When true, include resource-only topics in addition
       to normal-role topics.
       
       Default is "false".
    -->
  <xsl:param name="includeResourceOnly" select="'false'"/>
  <xsl:variable name="isIncludeResourceOnly" as="xs:boolean"
    select="matches($includeResourceOnly, '1|yes|true|on', 'i')"
  />
  
  <xsl:key name="elementByMatchKey" match="*[@df:matchKey]" use="@df:matchKey"/>
  
  <xsl:template name="standalone">
    <xsl:param name="doDebug" as="xs:boolean" select="$debugBoolean"/>
    
    <xsl:variable name="inputURI" as="xs:string" 
      select="'urn:ditamap2saxon-collection.xsl!/file:/Users/ekimber/workspace/veracode/temp/wek-fixed-integration-guide/dita/Integration_Guide.ditamap'"/>

    <xsl:variable name="base" select="substring-after($inputURI, '!/')"/>  
    
    <xsl:message> + [DEBUG] standalone: base="<xsl:value-of select="$base"/>"</xsl:message>
    
    <xsl:variable name="inputDoc" as="document-node()?" 
      select="document($base)"
    />
    
    <xsl:variable name="resolvedMap" as="document-node()">
      <xsl:document>
        <xsl:apply-templates select="$inputDoc" mode="resolve-map">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>        
          <xsl:with-param name="map-base-uri" as="xs:string" tunnel="yes" select="base-uri(.)"/>
          <xsl:with-param name="parentHeadLevel" as="xs:integer" tunnel="yes" select="0"/>
        </xsl:apply-templates>
      </xsl:document>
    </xsl:variable>

<!--    <xsl:variable name="doDebug" as="xs:boolean" select="true()"/>-->
    
    <xsl:if test="$doDebug">
      <xsl:variable name="resultUri" select="relpath:newFile(relpath:getParent(string(base-uri(.))), 'resolved-map.xml')"/>
      <xsl:message> + [DEBUG] standalone: Saving resolved map as '<xsl:value-of select="$resultUri"/>'      </xsl:message>
      <xsl:result-document href="{$resultUri}" indent="yes">
        <xsl:sequence select="$resolvedMap"/>
      </xsl:result-document>
    </xsl:if>
    
    <collection stable="true">
      <xsl:apply-templates mode="collect" select="root(.)">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="resolvedMap" as="document-node()" tunnel="yes" select="$resolvedMap"/>
      </xsl:apply-templates>
    </collection>
    
  </xsl:template>
  
  <xsl:template match="/">
    <xsl:param name="doDebug" as="xs:boolean" select="$debugBoolean"/>
    
    <xsl:variable name="base" select="substring-after(document-uri(.), '!/')"/>    
    <xsl:variable name="inputDoc" as="document-node()?" 
      select="document($base)"
    />
    
    <xsl:variable name="resolvedMap" as="document-node()">
      <xsl:document>
        <xsl:apply-templates select="$inputDoc" mode="resolve-map">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>        
          <xsl:with-param name="map-base-uri" as="xs:string" tunnel="yes" select="$base"/>
          <xsl:with-param name="parentHeadLevel" as="xs:integer" tunnel="yes" select="0"/>
        </xsl:apply-templates>
      </xsl:document>
    </xsl:variable>
    
    <collection stable="true">
      <xsl:apply-templates mode="collect" select="$inputDoc">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="resolvedMap" as="document-node()" tunnel="yes" select="$resolvedMap"/>
      </xsl:apply-templates>
    </collection>
  </xsl:template>
  
  <xsl:template match="/" mode="collect">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <doc href="{document-uri(.)}"/>
    <xsl:if test="df:class(/*, 'map/map')">
      <xsl:apply-templates mode="#current"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="*[contains(@class, ' map/topicref ') and (@href|@keyref) and (@format='dita' or not(@format))]" 
    mode="collect">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="resolvedMap" as="document-node()" tunnel="yes"/>
    
    <xsl:variable name="matchKey" as="xs:string" select="generate-id(.)"/>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] collect: topicref match key="<xsl:value-of select="$matchKey"/>"</xsl:message>
    </xsl:if>
    
    <!-- FIXME: Probably a logic bug in how we generate the match keys
                as there can be duplicates (same map included multiple times?)
                This is a workaround to just get the first one.
      -->
    <xsl:variable name="resolvedMapTopicref" as="element()*"
      select="key('elementByMatchKey', $matchKey, $resolvedMap)[1]"
    />
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] collect: Resolving topicref (@keyref="<xsl:value-of select="$resolvedMapTopicref/@keyref"/>", href="<xsl:value-of select="$resolvedMapTopicref/@href"/>")</xsl:message>
    </xsl:if>

    <xsl:variable name="topic" select="df:resolveTopicRef($resolvedMapTopicref, $doDebug)" as="element()?"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] collect: Got topic="<xsl:value-of select="exists($topic)"/></xsl:message>
    </xsl:if>
    
    <xsl:apply-templates select="root($topic)" mode="#current"/>
  </xsl:template>
  
  
  <xsl:template match="*[contains(@class, ' map/topicref ') and @format='ditamap']" priority="100" 
    mode="collect">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>

    <xsl:variable name="map" select="document(@href, .)"/>
    <xsl:apply-templates select="$map" mode="#current"/>
  </xsl:template>
  
    <!-- topicset reference -->
    <xsl:template match="*[contains(@class, ' mapgroup-d/topicsetref ')]" priority="150" 
      mode="collect">
      <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
      
      <xsl:variable name="map" select="document(substring-before(@href, '#'), .)"/>
        <xsl:variable name="id" select="substring-after(@href, '#')"/>
        <xsl:apply-templates select="$map//*[@id=$id]" mode="#current"/>
    </xsl:template>
    
    <!-- disable topic expasion inside reltables -->
    <xsl:template match="*[contains(@class, ' map/reltable ')]" mode="collect">
      <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
      
    </xsl:template>
    
    <!-- Do not try to open resourse-only topics unless includeResourceOnly has been set to true -->
    <xsl:template match="*[contains(@class, ' map/topicref ') and @processing-role='resource-only']" priority="200" 
      mode="collect">
      <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
      <xsl:if test="$isIncludeResourceOnly">
        <xsl:next-match/>
      </xsl:if>
    </xsl:template>
  
  <xsl:template match="text()" mode="#all">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
  </xsl:template>
</xsl:stylesheet>