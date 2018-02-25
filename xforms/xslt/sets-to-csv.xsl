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
		<xsl:text>title,set,publisher,publisher_uri,count,target,date&#x0A;</xsl:text>
		<xsl:apply-templates select="//dcmitype:Collection"/>
	</xsl:template>

	<xsl:template match="dcmitype:Collection">		
		<xsl:value-of select="concat('&#x022;', dcterms:title, '&#x022;')"/>
		<xsl:text>,</xsl:text>
		<xsl:value-of select="concat('&#x022;', @rdf:about, '&#x022;')"/>
		<xsl:text>,</xsl:text>
		<xsl:value-of select="concat('&#x022;', foaf:name, '&#x022;')"/>
		<xsl:text>,</xsl:text>
		<xsl:value-of select="concat('&#x022;', dcterms:publisher/@rdf:resource, '&#x022;')"/>
		<xsl:text>,</xsl:text>
		<xsl:value-of select="concat('&#x022;', dcterms:extent, '&#x022;')"/>
		<xsl:text>,</xsl:text>
		<xsl:value-of select="concat('&#x022;', string-join(doap:audience, ';'), '&#x022;')"/>
		<xsl:text>,</xsl:text>
		<xsl:value-of select="concat('&#x022;', format-dateTime(prov:generatedAtTime, '[MNn] [D1], [Y0001]. [H01]:[m01]:[s01]'), '&#x022;')"/>
		<xsl:text>&#x0A;</xsl:text>
	</xsl:template>
</xsl:stylesheet>
