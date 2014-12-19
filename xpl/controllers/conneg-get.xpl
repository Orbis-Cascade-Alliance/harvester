<?xml version="1.0" encoding="UTF-8"?>
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors">

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
				<xsl:param name="output" select="/request/parameters/parameter[name='format']/value"/>
				<xsl:variable name="content-type">
					<xsl:choose>
						<xsl:when test="string($output)">
							<xsl:choose>
								<xsl:when test="$output='json' or $output='xml'">
									<xsl:value-of select="$output"/>
								</xsl:when>
								<xsl:otherwise>html</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:when test="string(//header[name[.='accept']]/value)">
							<xsl:variable name="content-type" select="//header[name[.='accept']]/value"/>
							<xsl:choose>
								<xsl:when test="$content-type='application/sparql-results+json' or $content-type='application/json'">json</xsl:when>
								<xsl:when test="$content-type='application/sparql-results+xml' or $content-type='application/xml'">xml</xsl:when>
								<xsl:when test="contains($content-type, 'text/html') or $content-type='*/*'">html</xsl:when>
								<xsl:otherwise>error</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>html</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				
				<xsl:template match="/">
					<content-type>
						<xsl:value-of select="$content-type"/>
					</content-type>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="conneg-config"/>
	</p:processor>
	
	<!-- generator config for URL generator -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="request" href="#request"/>
		<p:input name="data" href="../../config.xml"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
				<!-- url params -->				
				<xsl:param name="ark" select="doc('input:request')/request/parameters/parameter[name='ark']/value"/>
				<xsl:param name="output" select="doc('input:request')/request/parameters/parameter[name='format']/value"/>
				
				<xsl:variable name="query">
					<![CDATA[PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dcterms:	<http://purl.org/dc/terms/>
PREFIX dpla:	<http://dp.la/terms/>
PREFIX edm:	<http://www.europeana.eu/schemas/edm/>
PREFIX foaf:	<http://xmlns.com/foaf/0.1/>
PREFIX ore:	<http://www.openarchives.org/ore/terms/>
PREFIX xsd:	<http://www.w3.org/2001/XMLSchema>
SELECT ?cho ?title ?repo_uri ?repository ?description ?date ?thumbnail ?depiction WHERE {
  ?cho dcterms:isPartOf <URI> ;
        dcterms:title ?title 
  OPTIONAL {?cho dcterms:description ?description}
  OPTIONAL {?cho dcterms:date ?date}
  ?agg edm:aggregatedCHO ?cho ;
     edm:dataProvider ?repo_uri .
   OPTIONAL {?agg edm:preview ?thumbnail}
   OPTIONAL {?agg edm:object ?depiction}
   ?repo_uri foaf:name ?repository
}]]>
				</xsl:variable>
				
				<xsl:variable name="output-normalized">
					<xsl:choose>
						<xsl:when test="string($output)">
							<xsl:choose>
								<xsl:when test="$output='json'">
									<xsl:value-of select="$output"/>
								</xsl:when>
								<xsl:otherwise>xml</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:when test="string(doc('input:request')/request//header[name[.='accept']]/value)">
							<xsl:variable name="content-type" select="doc('input:request')/request//header[name[.='accept']]/value"/>
							<xsl:choose>
								<xsl:when test="$content-type='application/sparql-results+json'">json</xsl:when>
								<xsl:otherwise>xml</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>xml</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				
				<!-- config variables -->
				<xsl:variable name="sparql_endpoint" select="/config/sparql/query"/>
				
				<xsl:variable name="service">
					<xsl:value-of select="concat($sparql_endpoint, '?query=', encode-for-uri(replace($query, 'URI', concat('http://nwda.orbiscascade.org/', $ark))), '&amp;output=', $output-normalized)"/>
				</xsl:variable>
				
				<xsl:template match="/">
					<config>
						<url>
							<xsl:value-of select="$service"/>
						</url>
						<content-type>
							<xsl:choose>
								<xsl:when test="$output-normalized='json'">application/sparql-results+json</xsl:when>
								<xsl:otherwise>application/sparql-results+xml</xsl:otherwise>
							</xsl:choose>
						</content-type>
						<xsl:if test="$output-normalized='json'">
							<mode>text</mode>
						</xsl:if>
						<encoding>utf-8</encoding>
					</config>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="url-generator-config"/>
	</p:processor>
	
	<!-- get the data from fuseki -->
	<p:processor name="oxf:url-generator">
		<p:input name="config" href="#url-generator-config"/>
		<p:output name="data" id="url-data"/>
	</p:processor>
	
	<p:processor name="oxf:exception-catcher">
		<p:input name="data" href="#url-data"/>
		<p:output name="data" id="url-data-checked"/>
	</p:processor>
	
	<!-- Check whether we had an exception -->
	<p:choose href="#url-data-checked">
		<p:when test="//*/@status-code != '200'">
			<p:processor name="oxf:pipeline">
				<p:input name="data" href="#url-data"/>
				<p:input name="config" href="error.xpl"/>		
				<p:output name="data" ref="data"/>
			</p:processor>			
		</p:when>
		<p:otherwise>
			<!-- Just return the document -->
			<p:processor name="oxf:identity">
				<p:input name="data" href="#url-data-checked"/>
				<p:output name="data" id="model"/>
			</p:processor>
			
			<p:choose href="#conneg-config">
				<p:when test="content-type='xml'">
					<p:processor name="oxf:xml-converter">
						<p:input name="data" href="#model"/>
						<p:input name="config">
							<config>
								<content-type>application/sparql-results+xml</content-type>
								<encoding>utf-8</encoding>
								<version>1.0</version>
								<indent>true</indent>
								<indent-amount>4</indent-amount>
							</config>
						</p:input>
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:when>
				<p:when test="content-type='json'">
					<p:processor name="oxf:text-converter">
						<p:input name="data" href="#model"/>
						<p:input name="config">
							<config>
								<content-type>application/sparql-results+json</content-type>
								<encoding>utf-8</encoding>
							</config>
						</p:input>
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:when>				
				<p:when test="content-type='html'">
					<p:processor name="oxf:pipeline">
						<p:input name="request" href="#request"/>
						<p:input name="data" href="#model"/>
						<p:input name="config" href="../views/apis/get.xpl"/>		
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:when>
				<p:otherwise>
					<p:processor name="oxf:pipeline">
						<p:input name="data" href="#data"/>
						<p:input name="config" href="406-not-acceptable.xpl"/>		
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:otherwise>
			</p:choose>
		</p:otherwise>
	</p:choose> 
</p:pipeline>
