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
				<xsl:param name="from" select="doc('input:request')/request/parameters/parameter[name = 'from']/value"/>
				<xsl:param name="until" select="doc('input:request')/request/parameters/parameter[name = 'until']/value"/>
				<xsl:variable name="sparql_endpoint" select="/config/sparql/query"/>

				<xsl:variable name="filter">
					<xsl:choose>
						<xsl:when test="$from castable as xs:date and not(string($until))">
							<xsl:value-of select="concat('FILTER (?mod &gt;= xsd:dateTime(&#x022;', $from, 'T00:00:00Z&#x022;))')"/>
						</xsl:when>
						<xsl:when test="not(string($from)) and $until castable as xs:date">
							<xsl:value-of select="concat('FILTER (?mod &lt;= xsd:dateTime(&#x022;', $until, 'T12:59:59Z&#x022;))')"/>
						</xsl:when>
						<xsl:when test="$from castable as xs:date and $until castable as xs:date">
							<xsl:value-of select="concat('FILTER (?mod &gt;= xsd:dateTime(&#x022;', $from, 'T00:00:00Z&#x022;) &amp;&amp; ?mod &lt;= xsd:dateTime(&#x022;', $until, 'T12:59:59Z&#x022;))')"/>
						</xsl:when>						
					</xsl:choose>
				</xsl:variable>

				<xsl:variable name="query"><![CDATA[PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX ore:	<http://www.openarchives.org/ore/terms/>
PREFIX doap:	<http://usefulinc.com/ns/doap#>
PREFIX xsd:	<http://www.w3.org/2001/XMLSchema#>
PREFIX prov:	<http://www.w3.org/ns/prov#>

SELECT (count(?agg) as ?count) WHERE {
  ?agg a ore:Aggregation ;
    prov:generatedAtTime ?mod;
  	doap:audience "primo" %FILTER%
}]]></xsl:variable>

				<xsl:variable name="service" select="concat($sparql_endpoint, '?query=', encode-for-uri(replace($query, '%FILTER%', $filter)), '&amp;output=xml')"/>

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

	<!-- simply the sparql response into a count element -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="#sparql-response"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
				xmlns:res="http://www.w3.org/2005/sparql-results#">

				<xsl:template match="/">
					<count>
						<xsl:value-of select="descendant::res:binding[@name='count']/res:literal"/>
					</count>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" ref="data"/>
	</p:processor>

</p:config>
