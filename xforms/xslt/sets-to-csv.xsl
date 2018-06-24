<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:numishare="https://github.com/ewg118/numishare"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
	xmlns:arch="http://purl.org/archival/vocab/arch#" xmlns:doap="http://usefulinc.com/ns/doap#" xmlns:edm="http://www.europeana.eu/schemas/edm/"
	xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:nwda="https://github.com/ewg118/nwda-editor#" xmlns:p="http://www.orbeon.com/oxf/pipeline"
	xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcmitype="http://purl.org/dc/dcmitype/"
	xmlns:prov="http://www.w3.org/ns/prov#" xmlns:vcard="http://www.w3.org/2006/vcard/ns#" xmlns:ore="http://www.openarchives.org/ore/terms/"
	xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:dpla="http://dp.la/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/"
	xmlns:xsd="http://www.w3.org/2001/XMLSchema#" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">

	<xsl:template match="/">
		<xsl:text>Publisher,"OAI URI","Digital Objects in Set","Set Title","Date most recently contributed","# for DPLA","# for Primo","for Archives West?"</xsl:text>
		<xsl:if test="//dcmitype:Collection[count(prov:generatedAtTime) &gt; 1]">
			<xsl:text>,"Error"</xsl:text>
		</xsl:if>
		<xsl:text>&#x0A;</xsl:text>
		<xsl:apply-templates select="//dcmitype:Collection"/>
	</xsl:template>

	<xsl:template match="dcmitype:Collection">
		<xsl:variable name="dates" as="item()">
			<dates>
				<xsl:for-each select="prov:generatedAtTime">
					<xsl:sort select="xs:dateTime(.)" order="ascending"/>
					<date>
						<xsl:value-of select="."/>
					</date>
				</xsl:for-each>
			</dates>			
		</xsl:variable>
		
		<xsl:value-of select="concat('&#x022;', foaf:name, '&#x022;')"/>
		<xsl:text>,</xsl:text>
		<xsl:value-of select="concat('&#x022;', @rdf:about, '&#x022;')"/>
		<xsl:text>,</xsl:text>
		<xsl:value-of select="concat('&#x022;', max(dcterms:extent), '&#x022;')"/>
		<xsl:text>,</xsl:text>		
		<xsl:value-of select="concat('&#x022;', dcterms:title, '&#x022;')"/>
		<xsl:text>,</xsl:text>
		<xsl:value-of select="concat('&#x022;', format-dateTime($dates/date[last()], '[Y0001][M01][D01]'), '&#x022;')"/>
		<xsl:text>,</xsl:text>
		<xsl:value-of select="if (doap:audience = 'dpla') then dcterms:extent else 0"/>
		<xsl:text>,</xsl:text>
		<xsl:value-of select="if (doap:audience = 'primo') then dcterms:extent else 0"/>
		<xsl:text>,</xsl:text>
		<xsl:value-of select="if (doap:audience = 'aw') then 'yes' else 'no'"/>
		<xsl:if test="count(prov:generatedAtTime) &gt; 1">
			<xsl:text>,"More than 1 date, implies set was not properly deleted before reingestion."</xsl:text>
		</xsl:if>
		<xsl:text>&#x0A;</xsl:text>
	</xsl:template>
</xsl:stylesheet>
