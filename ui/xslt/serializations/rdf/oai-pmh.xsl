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

	<xsl:template match="/">
		<root>
			<xsl:apply-templates select="descendant::ore:Aggregation"/>
		</root>
	</xsl:template>

	<xsl:template match="ore:Aggregation">
		<xsl:choose>
			<xsl:when test="descendant::dpla:SourceResource">
				<xsl:apply-templates select="descendant::dpla:SourceResource">
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
					<xsl:with-param name="format">
						<xsl:variable name="object_uri" select="edm:object/@rdf:resource"/>
						
						<xsl:choose>
							<xsl:when test="string($object_uri)">
								<xsl:value-of select="//edm:WebResource[@rdf:about = $object_uri]/dcterms:format"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="edm:object/edm:WebResource/dcterms:format"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:with-param>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="edm:aggregatedCHO/@rdf:resource">
				<xsl:variable name="uri" select="edm:aggregatedCHO/@rdf:resource"/>
				
				<xsl:apply-templates select="//dpla:SourceResource[@rdf:about = $uri]">
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
					<xsl:with-param name="format">
						<xsl:variable name="object_uri" select="edm:object/@rdf:resource"/>
						
						<xsl:choose>
							<xsl:when test="string($object_uri)">
								<xsl:value-of select="//edm:WebResource[@rdf:about = $object_uri]/dcterms:format"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="edm:object/edm:WebResource/dcterms:format"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:with-param>
				</xsl:apply-templates>
			</xsl:when>
		</xsl:choose>

		
	</xsl:template>
</xsl:stylesheet>
