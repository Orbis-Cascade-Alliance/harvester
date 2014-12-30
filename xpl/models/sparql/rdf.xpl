<?xml version="1.0" encoding="UTF-8"?>
<!--
	XPL for aggregating three SPARQL queries to reassamble triples as RDF
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
	
	<!-- generator config for dpla:SourceResource -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="request" href="#request"/>
		<p:input name="data" href="aggregate('content', #data, ../../../config.xml)"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
				<xsl:variable name="repository" select="/content/repository"/>
				<!-- config variables -->
				<xsl:variable name="sparql_endpoint" select="/content/config/sparql/query"/>
				<xsl:variable name="query">
					<![CDATA[PREFIX edm:	<http://www.europeana.eu/schemas/edm/>
SELECT ?s ?p ?o WHERE {
  ?agg edm:dataProvider <http://nwda.orbiscascade.org/contact#%REPOSITORY%> ;
       edm:aggregatedCHO ?s .
  ?s ?p ?o
}]]>
				</xsl:variable>
				
				<xsl:variable name="service">
					<xsl:value-of select="concat($sparql_endpoint, '?query=', encode-for-uri(replace($query, '%REPOSITORY%', $repository)), '&amp;output=xml')"/>					
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
		<p:output name="data" id="SourceResource-url-generator-config"/>
	</p:processor>
	
	<p:processor name="oxf:url-generator">
		<p:input name="config" href="#SourceResource-url-generator-config"/>
		<p:output name="data" id="SourceResource"/>
	</p:processor>
	
	<!-- generator config for ore:Aggregation -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="request" href="#request"/>
		<p:input name="data" href="aggregate('content', #data, ../../../config.xml)"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
				<xsl:variable name="repository" select="/content/repository"/>
				<!-- config variables -->
				<xsl:variable name="sparql_endpoint" select="/content/config/sparql/query"/>
				<xsl:variable name="query">
					<![CDATA[PREFIX edm:	<http://www.europeana.eu/schemas/edm/>
SELECT ?s ?p ?o WHERE {
  ?s edm:dataProvider <http://nwda.orbiscascade.org/contact#%REPOSITORY%> .
  ?s ?p ?o
}]]>
				</xsl:variable>
				
				<xsl:variable name="service">
					<xsl:value-of select="concat($sparql_endpoint, '?query=', encode-for-uri(replace($query, '%REPOSITORY%', $repository)), '&amp;output=xml')"/>					
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
		<p:output name="data" id="Aggregation-url-generator-config"/>
	</p:processor>
	
	<p:processor name="oxf:url-generator">
		<p:input name="config" href="#Aggregation-url-generator-config"/>
		<p:output name="data" id="Aggregation"/>
	</p:processor>
	
	<!-- generator config for edm:WebResource -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="request" href="#request"/>
		<p:input name="data" href="aggregate('content', #data, ../../../config.xml)"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
				<xsl:variable name="repository" select="/content/repository"/>
				<!-- config variables -->
				<xsl:variable name="sparql_endpoint" select="/content/config/sparql/query"/>
				<xsl:variable name="query">
					<![CDATA[PREFIX edm:	<http://www.europeana.eu/schemas/edm/>
SELECT ?s ?p ?o WHERE {
  ?agg edm:dataProvider <http://nwda.orbiscascade.org/contact#%REPOSITORY%> .
  {?agg edm:preview ?s}
  UNION {?agg edm:object ?s}
  ?s ?p ?o
}]]>
				</xsl:variable>
				
				<xsl:variable name="service">
					<xsl:value-of select="concat($sparql_endpoint, '?query=', encode-for-uri(replace($query, '%REPOSITORY%', $repository)), '&amp;output=xml')"/>					
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
		<p:output name="data" id="WebResource-url-generator-config"/>
	</p:processor>
	
	<p:processor name="oxf:url-generator">
		<p:input name="config" href="#WebResource-url-generator-config"/>
		<p:output name="data" id="WebResource"/>
	</p:processor>
	
	<p:processor name="oxf:pipeline">
		<p:input name="data" href="aggregate('content', #SourceResource, #Aggregation, #WebResource)"/>
		<p:input name="config" href="../../views/serializations/sparql/rdf.xpl"/>
		<p:output name="data" ref="data"/>
	</p:processor>
</p:config>
