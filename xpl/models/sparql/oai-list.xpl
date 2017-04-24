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
				<!-- Note: resumptionToken format is {$set}:{$metadataPrefix}:{$offset} -->
				
				<xsl:param name="resumptionToken" select="doc('input:request')/request/parameters/parameter[name = 'resumptionToken']/value"/>
				<xsl:param name="from" select="doc('input:request')/request/parameters/parameter[name = 'from']/value"/>
				<xsl:param name="until" select="doc('input:request')/request/parameters/parameter[name = 'until']/value"/>
				<xsl:param name="set" select="if (string-length($resumptionToken) &gt; 0) then tokenize($resumptionToken, ':')[1] else doc('input:request')/request/parameters/parameter[name = 'set']/value"/>

				<xsl:param name="offset">
					<xsl:choose>
						<xsl:when test="string-length($resumptionToken) &gt; 0">
							<xsl:value-of select="tokenize($resumptionToken, ':')[3]"/>
						</xsl:when>
						<xsl:otherwise>0</xsl:otherwise>
					</xsl:choose>
				</xsl:param>
				
				<xsl:variable name="filter">
					<!--FILTER (?mod >= xsd:dateTime("2017-02-10T00:00:00Z") && ?mod <= xsd:dateTime("2017-03-11T12:59:59Z"))-->
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
				
				<!-- config variables -->
				<xsl:variable name="limit" select="if ($set = 'primo-test') then '50' else /config/oai-pmh_limit"/>				
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

DESCRIBE * WHERE {
  ?cho a dpla:SourceResource;
		dcterms:isPartOf ?collection
		OPTIONAL {?cho edm:hasType ?type}
		OPTIONAL {?cho dcterms:creator ?creator}
		OPTIONAL {?cho dcterms:contributor ?contributor}
       { SELECT * WHERE {
         ?agg a ore:Aggregation ;
                edm:isShownAt ?cho ;
                prov:generatedAtTime ?mod;
                doap:audience "primo" %FILTER%}         
       }
} ORDER BY DESC(?mod) OFFSET %OFFSET% LIMIT %LIMIT% ]]>
				</xsl:variable>
	
				<xsl:variable name="service" select="concat($sparql_endpoint, '?query=', encode-for-uri(replace(replace(replace($query, '%LIMIT%', $limit), '%OFFSET%', $offset), '%FILTER%', $filter)), '&amp;output=xml')"/>					
				

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
