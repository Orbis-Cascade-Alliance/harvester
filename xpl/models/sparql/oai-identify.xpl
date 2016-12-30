<?xml version="1.0" encoding="UTF-8"?>
<!--
	XPL handling SPARQL query for the OAI-PMH identify verb
	A SPARQL query is executed to gather an example identifier (URI) of the earliest ingested record
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors">

	<p:param type="input" name="data"/>
	<p:param type="output" name="data"/>

	<!-- generator config for pagination -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="#data"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
				<xsl:variable name="sparql_endpoint" select="/config/sparql/query"/>

				<xsl:variable name="query"><![CDATA[PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dcterms:	<http://purl.org/dc/terms/>
PREFIX edm:	<http://www.europeana.eu/schemas/edm/>
PREFIX ore:	<http://www.openarchives.org/ore/terms/>
PREFIX prov:	<http://www.w3.org/ns/prov#>
SELECT * WHERE {
  ?aggregation a ore:Aggregation ;
       prov:generatedAtTime ?mod ;
       edm:isShownAt ?uri
} ORDER BY ASC(?mod) LIMIT 1]]>
				</xsl:variable>

				<xsl:variable name="service">
					<xsl:value-of select="concat($sparql_endpoint, '?query=', encode-for-uri($query), '&amp;output=xml')"/>
				</xsl:variable>

				<xsl:template match="/">
					<config>
						<url>
							<xsl:value-of select="$service"/>
						</url>
						<content-type>application/xml</content-type>
						<encoding>utf-8</encoding>
					</config>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="url-generator-config"/>
	</p:processor>

	<p:processor name="oxf:url-generator">
		<p:input name="config" href="#url-generator-config"/>
		<p:output name="data" ref="data"/>
	</p:processor>

</p:config>
