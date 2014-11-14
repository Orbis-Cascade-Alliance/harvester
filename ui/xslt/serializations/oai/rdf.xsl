<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
	xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:oai="http://www.openarchives.org/OAI/2.0/" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:dpla="http://dp.la/terms/" xmlns:edm="http://www.europeana.eu/schemas/edm/" xmlns:ore="http://www.openarchives.org/ore/terms/" exclude-result-prefixes="oai_dc oai xs" version="2.0">
	<xsl:output indent="yes" encoding="UTF-8"/>

	<xsl:param name="repository" select="/content/controls/repository"/>
	<xsl:param name="ark" select="/content/controls/ark"/>

	<xsl:template match="/">

		<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"
			xmlns:ore="http://www.openarchives.org/ore/terms/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:edm="http://www.europeana.eu/schemas/edm/" xmlns:dpla="http://dp.la/terms/">
			<!-- either process only those objects with a matching $ark when the process is instantiated by the finding aid upload, or process all objects that contain an ARK URI in dc:relations when bulk harvesting -->

			<xsl:choose>
				<xsl:when test="string($ark)">
					<xsl:apply-templates select="descendant::oai_dc:dc[dc:relation=$ark]"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="descendant::oai_dc:dc[contains(dc:relation, 'ark:/')]"/>
					<!--<xsl:apply-templates select="descendant::oai_dc:dc"/>-->
				</xsl:otherwise>
			</xsl:choose>
		</rdf:RDF>
	</xsl:template>

	<xsl:template match="oai_dc:dc">
		<dpla:SourceResource rdf:about="{dc:identifier[matches(., 'https?://')]}">
			<dcterms:title>
				<xsl:value-of select="dc:title"/>
			</dcterms:title>
			<xsl:apply-templates select="dc:date"/>
			<dcterms:relation rdf:resource="http://nwda.orbiscascade.org/{$ark}"/>
			<dcterms:isPartOf rdf:resource="{$repository}"/>
		</dpla:SourceResource>
	</xsl:template>
	
	<xsl:template match="dc:date">
		<dcterms:date>
			<xsl:choose>
				<xsl:when test=". castable as xs:dateTime">
					<xsl:attribute name="rdf:datatype">xsd:dateTime</xsl:attribute>
				</xsl:when>
				<xsl:when test=". castable as xs:date">
					<xsl:attribute name="rdf:datatype">xsd:date</xsl:attribute>
				</xsl:when>
				<xsl:when test=". castable as xs:gYearMonth">
					<xsl:attribute name="rdf:datatype">xsd:gYearMonth</xsl:attribute>
				</xsl:when>
				<xsl:when test=". castable as xs:gYear">
					<xsl:attribute name="rdf:datatype">xsd:gYear</xsl:attribute>
				</xsl:when>
			</xsl:choose>
			<xsl:value-of select="."/>
		</dcterms:date>
	</xsl:template>

</xsl:stylesheet>
