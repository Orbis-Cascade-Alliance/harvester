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
		<p:input name="data" href="#data"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
				<xsl:param name="resumptionToken" select="doc('input:request')/request/parameters/parameter[name = 'resumptionToken']/value"/>
				<xsl:param name="offset">
					<xsl:choose>
						<xsl:when test="$resumptionToken castable as xs:integer and $resumptionToken &gt; 0">
							<xsl:value-of select="$resumptionToken"/>
						</xsl:when>
						<xsl:otherwise>0</xsl:otherwise>
					</xsl:choose>
				</xsl:param>
				
				<!-- config variables -->
				<xsl:variable name="limit" select="/config/oai-pmh_limit"/>				
				<xsl:variable name="sparql_endpoint" select="/config/sparql/query"/>

				<xsl:variable name="query"><![CDATA[PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dcterms:	<http://purl.org/dc/terms/>
PREFIX dpla:	<http://dp.la/terms/>
PREFIX edm:	<http://www.europeana.eu/schemas/edm/>
PREFIX foaf:	<http://xmlns.com/foaf/0.1/>
PREFIX ore:	<http://www.openarchives.org/ore/terms/>
PREFIX xsd:	<http://www.w3.org/2001/XMLSchema>
PREFIX vcard:	<http://www.w3.org/2006/vcard/ns#>
PREFIX arch:	<http://purl.org/archival/vocab/arch#>
PREFIX nwda:	<https://github.com/Orbis-Cascade-Alliance/nwda-editor#>

DESCRIBE * WHERE {
  ?cho a dpla:SourceResource
       { SELECT * WHERE {
         ?agg a ore:Aggregation ;
                edm:isShownAt ?cho ;
                dcterms:modified ?mod
       }         
         }
} ORDER BY DESC(?mod) OFFSET %OFFSET% LIMIT %LIMIT% ]]>
				</xsl:variable>

				<xsl:variable name="service" select="concat($sparql_endpoint, '?query=', encode-for-uri(replace(replace($query, '%LIMIT%', $limit), '%OFFSET%', $offset)), '&amp;output=xml')"/>					
				

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
