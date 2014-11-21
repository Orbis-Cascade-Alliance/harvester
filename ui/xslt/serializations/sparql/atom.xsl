<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/2005/Atom" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:res="http://www.w3.org/2005/sparql-results#"
	exclude-result-prefixes="xs" version="2.0">
	<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

	<!-- config variable -->
	<xsl:variable name="url" select="/content/config/url"/>

	<!-- request params -->
	<xsl:param name="page" select="doc('input:request')/request/parameters/parameter[name='page']/value"/>
	<xsl:variable name="offset">
		<xsl:choose>
			<xsl:when test="string-length($page) &gt; 0 and $page castable as xs:integer and number($page) > 0">
				<xsl:value-of select="($page - 1) * 10"/>
			</xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>	
	<xsl:param name="rows" as="xs:integer">10</xsl:param>

	<xsl:template match="/">
		<xsl:variable name="numFound" select="descendant::res:binding[@name='numFound']/res:literal"/>
		<xsl:variable name="last" select="ceiling($numFound div $rows)"/>
		<xsl:variable name="next" select="($offset div 10) + 2"/>

		<feed xmlns="http://www.w3.org/2005/Atom">
			<title>Orbis Cascade Alliance: Cultural Heritage Objects</title>
			<id>
				<xsl:value-of select="$url"/>
			</id>
			<link href="{$url}"/>
			<link href="{$url}feed" rel="self"/>
			<xsl:if test="$next &lt; $last">
				<link rel="next" href="{$url}feed?page={$next}"/>
			</xsl:if>
			<link rel="last" href="{$url}feed?page={$last}"/>
			<author>
				<name>Orbis Cascade Alliance</name>
			</author>
			<xsl:apply-templates select="descendant::res:sparql[2]//res:result" mode="entry"/>
		</feed>

	</xsl:template>

	<xsl:template match="res:result" mode="entry">
		<entry>
			<title>
				<xsl:value-of select="res:binding[@name='title']/res:literal"/>
			</title>
			<author>
				<name><xsl:value-of select="res:binding[@name='repository']/res:uri"/></name>
			</author>
			<link href="{res:binding[@name='cho']/res:uri}"/>		
			
			<updated>
				<xsl:value-of select="res:binding[@name='modified']/res:literal"/>
			</updated>
			<xsl:if test="res:binding[@name='thumbnail'] or res:binding[@name='description']">
				<content type="html">
					<![CDATA[
     <img alt="thumbnail" src="]]><xsl:value-of select="res:binding[@name='thumbnail']/res:uri"/><![CDATA["/>]]>
					<xsl:for-each select="res:binding[@name='description']">
						<![CDATA[<p>]]><xsl:value-of select="res:literal"/><![CDATA[</p>]]>
					</xsl:for-each>
				</content>
			</xsl:if>
		</entry>
	</xsl:template>
</xsl:stylesheet>
