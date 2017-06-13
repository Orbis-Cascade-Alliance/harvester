<?xml version="1.0" encoding="UTF-8"?>
<!--
	Author: Ethan Gruber
	Date: October 2016
	Function: query SPARQL for total count of data objects to generate the VoID RDF with paginated data dumps	
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

	<!-- execute SPARQL query to get count of total data objects -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="request" href="#request"/>
		<p:input name="data" href="../../../../config.xml"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
				<!-- config variables -->
				<xsl:variable name="sparql_endpoint" select="/config/sparql/query"/>
				
				<!-- only need to count ore:Aggregations with a doap:audience of 'dpla' -->
				<xsl:variable name="query"><![CDATA[PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX ore:	<http://www.openarchives.org/ore/terms/>
PREFIX doap:	<http://usefulinc.com/ns/doap#>

SELECT (count(?agg) as ?count) WHERE {
  ?agg a ore:Aggregation ;
       doap:audience "dpla" .
}]]></xsl:variable>
				
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
		<p:output name="data" id="sparql-response"/>
	</p:processor>

	<!-- process the result into VoID RDF -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="request" href="#request"/>
		<p:input name="data" href="aggregate('content', #sparql-response, ../../../../config.xml)"/>
		<p:input name="config" href="../../../../ui/xslt/serializations/sparql/void.xsl"/>
		<p:output name="data" id="model"/>
	</p:processor>
	
	<p:processor name="oxf:xml-serializer">
		<p:input name="data" href="#model"/>
		<p:input name="config">
			<config>
				<content-type>application/rdf+xml</content-type>
				<indent>true</indent>
				<indent-amount>4</indent-amount>
			</config>
		</p:input>
		<p:output name="data" ref="data"/>
	</p:processor>
</p:config>
