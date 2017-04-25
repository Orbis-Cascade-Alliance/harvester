<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.openarchives.org/OAI/2.0/"
	xmlns:digest="org.apache.commons.codec.digest.DigestUtils" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:arch="http://purl.org/archival/vocab/arch#" xmlns:edm="http://www.europeana.eu/schemas/edm/" xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:vcard="http://www.w3.org/2006/vcard/ns#" xmlns:prov="http://www.w3.org/ns/prov#"
	xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:nwda="https://github.com/Orbis-Cascade-Alliance/nwda-editor#"
	xmlns:ore="http://www.openarchives.org/ore/terms/" xmlns:dpla="http://dp.la/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/"
	xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:doap="http://usefulinc.com/ns/doap#" xmlns:skos="http://www.w3.org/2004/02/skos/core#"
	exclude-result-prefixes="xs res rdf arch edm dcterms vcard nwda dpla ore digest prov geo dcmitype skos" version="2.0">
	<xsl:include href="../sparql/oai-pmh-templates.xsl"/>

	<xsl:variable name="url" select="//config/url"/>
	<xsl:variable name="publisher" select="//config/publisher"/>
	<xsl:variable name="publisher_email" select="//config/publisher_email"/>
	<xsl:variable name="publisher_code" select="//config/publisher_code"/>
	<xsl:variable name="repositoryIdentifier" select="substring-before(substring-after($url, 'http://'), '/')"/>

	<xsl:template match="/">
		<xsl:apply-templates select="descendant::ore:Aggregation"/>
	</xsl:template>
	
	<xsl:template match="ore:Aggregation">
		<xsl:variable name="uri" select="edm:isShownAt/@rdf:resource"/>
		
		<xsl:apply-templates select="//dpla:SourceResource[@rdf:about=$uri]">
			<xsl:with-param name="depiction"
				select="
				if (edm:object/@rdf:resource) then
				edm:object/@rdf:resource
				else
				edm:object/edm:WebResource/@rdf:about"/>
			<xsl:with-param name="thumbnail"
				select="
				if (edm:preview/@rdf:resource) then
				edm:preview/@rdf:resource
				else
				edm:preview/edm:WebResource/@rdf:about"/>
			<xsl:with-param name="dataProvider" select="edm:dataProvider/@rdf:resource"/>
		</xsl:apply-templates>
	</xsl:template>
</xsl:stylesheet>
