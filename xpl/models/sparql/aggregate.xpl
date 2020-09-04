<?xml version="1.0" encoding="UTF-8"?>
<!--
	Author: Ethan Gruber
	Date: September 2020
	Function: this reads download "filename" for a page number and extension for initiating a DESCRIBE query
	that powers the DPLA harvesting as VoID data dumps. The number of objects per page is stored in the config.xml file.
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
				<xsl:param name="doc" select="tokenize(doc('input:request')/request/request-url, '/')[last()]"/>
				<xsl:variable name="page" select="xs:integer(substring-before($doc, '.'))"/>
				<xsl:variable name="ext" select="substring-after($doc, '.')"/>
				<xsl:variable name="output">
					<xsl:choose>
						<xsl:when test="$ext = 'rdf'">xml</xsl:when>
						<xsl:when test="$ext = 'ttl'">text</xsl:when>
						<xsl:when test="$ext = 'jsonld'">json</xsl:when>
					</xsl:choose>
				</xsl:variable>
				
				<!-- config variables -->
				<xsl:variable name="sparql_endpoint" select="/config/sparql/query"/>	
				<xsl:variable name="limit" select="xs:integer(/config/dpla_limit)"/>
				<xsl:variable name="offset" select="($page - 1) * $limit" as="xs:integer"/>				
				
				<!-- SPARQL query template -->
				<xsl:variable name="query"><![CDATA[PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
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
  ?agg a ore:Aggregation ;
                edm:aggregatedCHO ?cho ;
                prov:generatedAtTime ?mod ;
                doap:audience "dpla" .
                OPTIONAL {?agg edm:object ?reference}
                OPTIONAL {?agg edm:preview ?thumbnail}
  ?cho dcterms:isPartOf ?collection
       OPTIONAL {?cho dcterms:creator ?creator . ?creator a edm:Agent}
       OPTIONAL {?cho dcterms:contributor ?contributor . ?contributor a edm:Agent}
       OPTIONAL {?cho edm:hasType ?type . ?type a skos:Concept}
} ORDER BY DESC(?mod) LIMIT %LIMIT% OFFSET %OFFSET%]]></xsl:variable>
				
				<xsl:variable name="service" select="concat($sparql_endpoint, '?query=', encode-for-uri(replace(replace($query, '%OFFSET%', string($offset)), '%LIMIT%', string($limit))), '&amp;output=', $output)"/>
				
				<xsl:template match="/">
					<config>
						<url>
							<xsl:value-of select="$service"/>
						</url>
						<content-type>
							<xsl:choose>
								<xsl:when test="$output = 'xml'">application/rdf+xml</xsl:when>
								<xsl:when test="$output = 'json'">application/json</xsl:when>
								<xsl:when test="$output = 'text'">text/turtle</xsl:when>
							</xsl:choose>
						</content-type>
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
