<?xml version="1.0" encoding="UTF-8"?>
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:res="http://www.w3.org/2005/sparql-results#">

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
	
	<!-- read request header for content-type -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="#request"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:output indent="yes"/>
				<xsl:param name="uri" select="/request/parameters/parameter[name='uri']/value"/>
				
				
				<xsl:template match="/">
					<uri>
						<xsl:choose>
							<xsl:when test="matches($uri, '^https?://')">
								<xsl:value-of select="$uri"/>
							</xsl:when>
							<xsl:otherwise>error</xsl:otherwise>
						</xsl:choose>
					</uri>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="uri-config"/>
	</p:processor>
	
	<p:choose href="#uri-config">
		<p:when test="uri='error'">
			<!-- if there is an error, then create an appropriate HTTP response -->
			<p:processor name="oxf:pipeline">
				<p:input name="data" href="#uri-config"/>
				<p:input name="config" href="400-bad-request.xpl"/>		
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:when>
		<p:otherwise>
			<!-- otherwise execute the SPARQL query and generate a 303 -->
			<p:processor name="oxf:unsafe-xslt">
				<p:input name="uri" href="#uri-config"/>
				<p:input name="data" href="../../config.xml"/>
				<p:input name="config">
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
						<xsl:param name="uri" select="doc('input:uri')/uri"/>
						<!-- config variables -->
						<xsl:variable name="sparql_endpoint" select="/config/sparql/query"/>
						<xsl:variable name="query">
							<![CDATA[PREFIX edm:	<http://www.europeana.eu/schemas/edm/>
SELECT ?agg WHERE {
  ?agg edm:aggregatedCHO <URI>
}]]>
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
				<p:output name="data" id="sparqlResponse"/>
			</p:processor>
			
			<!-- check to see if there is indeed an ore:Aggregation URI -->
			<p:choose href="#sparqlResponse">
				<p:when test="count(//res:result) = 1">
					<p:processor name="oxf:pipeline">
						<p:input name="data" href="#sparqlResponse"/>
						<p:input name="config" href="303-redirect.xpl"/>		
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:when>
				<p:otherwise>
					<p:processor name="oxf:pipeline">
						<p:input name="data" href="#uri-config"/>
						<p:input name="config" href="400-bad-request.xpl"/>		
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:otherwise>
			</p:choose>
		</p:otherwise>
	</p:choose>
</p:pipeline>
