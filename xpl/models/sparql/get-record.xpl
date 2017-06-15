<?xml version="1.0" encoding="UTF-8"?>
<!--
	XPL handling SPARQL queries from Fuseki	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors">

	<p:param type="input" name="data"/>
	<p:param type="output" name="data"/>

	<p:processor name="oxf:request">
		<p:input name="config">
			<config>
				<include>/request</include>
			</config>
		</p:input>
		<p:output name="data" id="request"/>
	</p:processor>
	
	<!-- generator config for pagination -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="request" href="#request"/>
		<p:input name="data" href="../../../config.xml"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
				<xsl:param name="identifier" select="doc('input:request')/request/parameters/parameter[name='identifier']/value"/>
				<xsl:param name="id" select="if (string($identifier)) then tokenize($identifier, ':')[3] else tokenize(doc('input:request')/request/request-url, '/')[last()]"/>
				
				<!-- config variables -->
				<xsl:variable name="uri" select="concat(config/url, 'record/', $id)"/>
				<xsl:variable name="sparql_endpoint" select="/config/sparql/query"/>
				<xsl:variable name="production_server" select="/config/production_server"/>
				
				
				<xsl:variable name="query">
					<![CDATA[PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dcterms:	<http://purl.org/dc/terms/>
PREFIX dpla:	<http://dp.la/terms/>
PREFIX dcmitype:	<http://purl.org/dc/dcmitype/>
PREFIX edm:	<http://www.europeana.eu/schemas/edm/>
PREFIX foaf:	<http://xmlns.com/foaf/0.1/>
PREFIX ore:	<http://www.openarchives.org/ore/terms/>
PREFIX xsd:	<http://www.w3.org/2001/XMLSchema#>
PREFIX vcard:	<http://www.w3.org/2006/vcard/ns#>
PREFIX arch:	<http://purl.org/archival/vocab/arch#>
PREFIX nwda:	<https://github.com/Orbis-Cascade-Alliance/nwda-editor#>
PREFIX prov:	<http://www.w3.org/ns/prov#>
PREFIX doap:	<http://usefulinc.com/ns/doap#>
PREFIX skos:	<http://www.w3.org/2004/02/skos/core#>

DESCRIBE * WHERE {
  BIND (<URI> as ?agg)
  ?agg a ore:Aggregation ;
                edm:aggregatedCHO ?cho .
                OPTIONAL {?agg edm:object ?reference}
                OPTIONAL {?agg edm:preview ?thumbnail}
  ?cho dcterms:isPartOf ?collection
       OPTIONAL {?cho dcterms:creator ?creator . ?creator a edm:Agent}
       OPTIONAL {?cho dcterms:contributor ?contributor . ?contributor a edm:Agent}
       OPTIONAL {?cho edm:hasType ?type . ?type a skos:Concept}
} LIMIT 1]]>
				</xsl:variable>
				
				<xsl:variable name="service">
					<xsl:value-of select="concat($sparql_endpoint, '?query=', encode-for-uri(replace($query, 'URI', $uri)), '&amp;output=xml')"/>					
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
