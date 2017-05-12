<?xml version="1.0" encoding="UTF-8"?>
<!--
	XPL handling SPARQL query for the OAI-PMH ListRecords and ListIdentifiers verbs. 
	There are two queries: one for total count of CHOs and the other for getting CHOs in chunks of 100 (DESCRIBE)
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
				<xsl:param name="set">
					<xsl:if test="string(doc('input:request')/request/parameters/parameter[name = 'set']/value)">
						<xsl:value-of select="concat('; dcterms:isPartOf &lt;', doc('input:request')/request/parameters/parameter[name = 'set']/value, '&gt;')"/>
					</xsl:if>
				</xsl:param>				
				<!-- config variables -->
				<xsl:variable name="sparql_endpoint" select="/config/sparql/query"/>
				<xsl:variable name="query">
					<![CDATA[ PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dpla:	<http://dp.la/terms/>
PREFIX dcterms:	<http://purl.org/dc/terms/>

SELECT (count(?s) as ?numFound) WHERE {
?s a dpla:SourceResource %SET%
}]]>
				</xsl:variable>
				
				<xsl:variable name="service">
					<xsl:value-of select="concat($sparql_endpoint, '?query=', encode-for-uri(replace($query, '%SET%', $set)), '&amp;output=xml')"/>					
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
		<p:output name="data" id="numFound-config"/>
	</p:processor>
	
	<p:processor name="oxf:url-generator">
		<p:input name="config" href="#numFound-config"/>
		<p:output name="data" id="numFound"/>
	</p:processor>

	<!-- generator config for pagination -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="request" href="#request"/>
		<p:input name="data" href="../../../config.xml"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
				<!-- request params -->				
				<xsl:param name="page" select="doc('input:request')/request/parameters/parameter[name = 'page']/value"/>
				<xsl:param name="set">
					<xsl:if test="string(doc('input:request')/request/parameters/parameter[name = 'set']/value)">
						<xsl:value-of select="concat('; dcterms:isPartOf &lt;', doc('input:request')/request/parameters/parameter[name = 'set']/value, '&gt;')"/>
					</xsl:if>
				</xsl:param>

				<xsl:variable name="limit" select="/config/oai-pmh_limit"/>
				<xsl:variable name="offset">
					<xsl:choose>
						<xsl:when test="string-length($page) &gt; 0 and $page castable as xs:integer and number($page) > 0">
							<xsl:value-of select="($page - 1) * $limit"/>
						</xsl:when>
						<xsl:otherwise>0</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				
				<!-- config variables -->
								
				<xsl:variable name="sparql_endpoint" select="/config/sparql/query"/>

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
                prov:generatedAtTime ?mod.
                OPTIONAL {?agg edm:object ?reference}
                OPTIONAL {?agg edm:preview ?thumbnail}
  ?cho a dpla:SourceResource %SET%
       OPTIONAL {?cho dcterms:creator ?creator . ?creator a edm:Agent}
       OPTIONAL {?cho dcterms:contributor ?contributor . ?contributor a edm:Agent}
       OPTIONAL {?cho edm:hasType ?type . ?type a skos:Concept}
} ORDER BY DESC(?mod) OFFSET %OFFSET% LIMIT %LIMIT% ]]>
				</xsl:variable>
	
				<xsl:variable name="service" select="concat($sparql_endpoint, '?query=', encode-for-uri(replace(replace(replace($query, '%LIMIT%', $limit), '%OFFSET%', $offset), '%SET%', $set)), '&amp;output=xml')"/>					
				

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
		<p:output name="data" id="sparql-results"/>
		<p:output name="data" ref="data"/>
	</p:processor>
	
	<!--<p:processor name="oxf:identity">		
		<p:input name="data" href="aggregate('content', #numFound, #sparql-results)"/>
		<p:output name="data" ref="data"/>
	</p:processor>-->

</p:config>
