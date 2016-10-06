<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:skos="http://www.w3.org/2004/02/skos/core#" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:dcterms="http://purl.org/dc/terms/" xmlns:void="http://rdfs.org/ns/void#"
	exclude-result-prefixes="xs res" version="2.0">
	
	<!-- read extension from request header -->
	<xsl:variable name="ext" select="substring-after(tokenize(doc('input:request')/request/request-url, '/')[last()], '.')"/>

	<!-- math variables -->
	<xsl:variable name="numFound"
		select="xs:integer(descendant::res:binding[@name = 'count']/res:literal)"/>
	<xsl:variable name="limit" select="xs:integer(/content/config/dpla_limit)"/>

	<xsl:template match="/">
		<xsl:apply-templates select="//config"/>
	</xsl:template>
	
	<xsl:template match="config">
		<xsl:variable name="url" select="url"/>
		
		<rdf:RDF>
			<void:Dataset rdf:about="{$url}">
				<dcterms:title>
					<xsl:value-of select="title"/>
				</dcterms:title>
				<dcterms:description>
					<xsl:value-of select="description"/>
				</dcterms:description>
				<dcterms:publisher>
					<xsl:value-of select="publisher"/>
				</dcterms:publisher>
				<!--<dcterms:license rdf:resource="{template/license}"/>-->
				
				<xsl:if test="number($numFound) &gt; 0">
					<xsl:variable name="floor" select="xs:integer(ceiling($numFound div $limit))"/>
					
					<xsl:for-each select="1 to $floor">
						<void:dataDump rdf:resource="{$url}download/{position()}.{$ext}"/>
					</xsl:for-each>
				</xsl:if>			
			</void:Dataset>
		</rdf:RDF>
		
	</xsl:template>

</xsl:stylesheet>
