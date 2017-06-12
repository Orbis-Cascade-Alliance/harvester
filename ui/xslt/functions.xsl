<?xml version="1.0" encoding="UTF-8"?>
<!-- Author: Ethan Gruber
	Date: June 2017
	Function: XSLT functions used throughout Harvester to normalize data 
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:harvester="https://github.com/Orbis-Cascade-Alliance/harvester" exclude-result-prefixes="#all" version="2.0">

	<!-- used to render a human readable date in the RDF output for a DESCRIBE query (from Nomisma.org) -->
	<xsl:function name="harvester:normalizeDate">
		<xsl:param name="date"/>
		
		<xsl:if test="substring($date, 1, 1) != '-' and number(substring($date, 1, 4)) &lt; 500">
			<xsl:text>A.D. </xsl:text>
		</xsl:if>
		
		<xsl:choose>
			<xsl:when test="$date castable as xs:date">
				<xsl:value-of select="format-date($date, '[D] [MNn] [Y]')"/>
			</xsl:when>
			<xsl:when test="$date castable as xs:gYearMonth">
				<xsl:variable name="normalized" select="xs:date(concat($date, '-01'))"/>
				<xsl:value-of select="format-date($normalized, '[MNn] [Y]')"/>
			</xsl:when>
			<xsl:when test="$date castable as xs:gYear or $date castable as xs:integer">
				<xsl:value-of select="abs(number($date))"/>
			</xsl:when>
		</xsl:choose>
		
		<xsl:if test="substring($date, 1, 1) = '-'">
			<xsl:text> B.C.</xsl:text>
		</xsl:if>
	</xsl:function>
	
	<!-- the functions below are used to clean and normalize data (mainly dates) in the OAI to RDF transformation -->
	<xsl:function name="harvester:cleanText">
		<xsl:param name="val"/>
		<xsl:param name="element"/>

		<xsl:variable name="html-stripped" select="replace(replace($val, '&lt;[^&gt;]+&gt;', ' '), '\\s+', ' ')"/>

		<xsl:choose>
			<xsl:when
				test="$element = 'subject' or $element = 'creator' or $element = 'contributor' or $element = 'spatial' or $element = 'coverage' or $element = 'title' or $element = 'rights' or $element = 'description' or $element = 'language'">
				<!-- do not strip trailing period from these elements -->
				<xsl:value-of select="$html-stripped"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<!-- strip trailing period -->
					<xsl:when test="substring($html-stripped, string-length($html-stripped), 1) = '.'">
						<xsl:value-of select="substring($html-stripped, 1, string-length($html-stripped) - 1)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$html-stripped"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:function>

	<xsl:function name="harvester:date_dataType">
		<xsl:param name="dams"/>
		<xsl:param name="val"/>

		<xsl:choose>
			<!-- replace dateTime with the xs:date when not January 1: otherwise this is only a year -->
			<xsl:when test="$val castable as xs:dateTime">
				<xsl:variable name="date" select="substring($val, 1, 10)"/>
				<xsl:choose>
					<xsl:when test="substring($date, 6) = '01-01' and $dams = 'digital-commons'">http://www.w3.org/2001/XMLSchema#gYear</xsl:when>
					<xsl:otherwise>http://www.w3.org/2001/XMLSchema#date</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$val castable as xs:date">http://www.w3.org/2001/XMLSchema#date</xsl:when>
			<xsl:when test="$val castable as xs:gYearMonth">http://www.w3.org/2001/XMLSchema#gYearMonth</xsl:when>
			<xsl:when test="$val castable as xs:gYear">http://www.w3.org/2001/XMLSchema#gYear</xsl:when>
		</xsl:choose>
	</xsl:function>

	<xsl:function name="harvester:parseDateTime">
		<xsl:param name="dams"/>
		<xsl:param name="val"/>

		<xsl:choose>
			<xsl:when test="$val castable as xs:dateTime">
				<xsl:variable name="date" select="substring($val, 1, 10)"/>

				<xsl:choose>
					<xsl:when test="substring($date, 6) = '01-01' and $dams = 'digital-commons'">
						<xsl:value-of select="substring($date, 1, 4)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$date"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$val"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<xsl:function name="harvester:parseRightsStatement">
		<xsl:param name="id"/>

		<xsl:choose>
			<xsl:when test="substring($id, 1, 3) = 'RS_'">
				<xsl:value-of select="concat('http://rightsstatements.org/vocab/', substring-after($id, '_'), '/1.0/')"/>
			</xsl:when>
			<xsl:when test="substring($id, 1, 3) = 'CC_'">
				<xsl:choose>
					<xsl:when test="substring-after($id, '_') = 'pdm'">
						<xsl:text>https://creativecommons.org/share-your-work/public-domain/pdm/</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="concat('https://creativecommons.org/licenses/', substring-after($id, '_'), '/4.0/')"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
		</xsl:choose>
	</xsl:function>


</xsl:stylesheet>
