<?xml version="1.0" encoding="UTF-8"?>

<!-- 	AUTHOR: Ethan Gruber
	DATE: December 30, 2014
	FUNCTION: This XSLT accepts a data model generated by download.xpl that contains an aggregation of three SPARQL XML responses for generating data dumps for each institution.
		1. The triples of the dpla:SourceResource (CHO)
		2. The ore:Aggregation
		3. The edm:WebResource
	
	There are three template modes for reconstructing RDF/XML out of the SPARQL XML response.
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:ore="http://www.openarchives.org/ore/terms/"
	xmlns:xsd="http://www.w3.org/2001/XMLSchema#" xmlns:edm="http://www.europeana.eu/schemas/edm/" xmlns:dpla="http://dp.la/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/" exclude-result-prefixes="xs
	res" version="2.0">

	<xsl:variable name="namespaces" as="item()*">
		<namespaces>
			<namespace prefix="dc" uri="http://purl.org/dc/elements/1.1/"/>
			<namespace prefix="dcterms" uri="http://purl.org/dc/terms/"/>
			<namespace prefix="dpla" uri="http://dp.la/terms/"/>
			<namespace prefix="edm" uri="http://www.europeana.eu/schemas/edm/"/>
			<namespace prefix="ore" uri="http://www.openarchives.org/ore/terms/"/>
			<namespace prefix="foaf" uri="http://xmlns.com/foaf/0.1/"/>
			<namespace prefix="geo" uri="http://www.w3.org/2003/01/geo/wgs84_pos#"/>
			<namespace prefix="rdf" uri="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
			<namespace prefix="xsd" uri="http://www.w3.org/2001/XMLSchema#"/>
		</namespaces>
	</xsl:variable>

	<xsl:template match="/">
		<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"
			xmlns:ore="http://www.openarchives.org/ore/terms/" xmlns:xsd="http://www.w3.org/2001/XMLSchema#" xmlns:edm="http://www.europeana.eu/schemas/edm/" xmlns:dpla="http://dp.la/terms/"
			xmlns:foaf="http://xmlns.com/foaf/0.1/">			
			
			<!-- dpla:SourceResource -->
			<xsl:apply-templates select="descendant::res:sparql[1]">
				<xsl:with-param name="class">dpla:SourceResource</xsl:with-param>
			</xsl:apply-templates>
			<!-- ore:Aggregation -->
			<xsl:apply-templates select="descendant::res:sparql[2]">
				<xsl:with-param name="class">ore:Aggregation</xsl:with-param>
			</xsl:apply-templates>
			<!-- edm:WebResource -->
			<xsl:apply-templates select="descendant::res:sparql[3]">
				<xsl:with-param name="class">edm:WebResource</xsl:with-param>
			</xsl:apply-templates>
		</rdf:RDF>
	</xsl:template>	
	
	<!-- res:sparql template -->
	<xsl:template match="res:sparql">
		<xsl:param name="class"/>
		<xsl:variable name="results" as="element()*">
			<xsl:copy-of select="res:results"/>
		</xsl:variable>
		
		<xsl:for-each select="distinct-values(descendant::res:binding[@name='s']/res:uri|descendant::res:binding[@name='s']/res:bnode)">
			<xsl:variable name="uri" select="."/>
			<xsl:call-template name="rdf-object">
				<xsl:with-param name="class" select="$class"/>
				<xsl:with-param name="uri" select="$uri"/>
				<xsl:with-param name="results" as="element()">
					<results>
						<xsl:copy-of select="$results/res:result[res:binding[@name='s']/res:uri=$uri]|$results/res:result[res:binding[@name='s']/res:bnode=$uri]"/>
					</results>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
		
	<xsl:template name="rdf-object">
		<xsl:param name="class"/>
		<xsl:param name="uri"/>
		<xsl:param name="results"/>
		
		<xsl:element name="{$class}">
			<!-- do not associate the URI if the class is not ore:Aggregation. ore:Aggregation is a blank node and will be dealt with by DPLA, but insert rdf:nodeID -->
			<xsl:choose>
				<xsl:when test="$class='ore:Aggregation'">
					<xsl:attribute name="rdf:nodeID" select="generate-id($results)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:attribute name="rdf:about" select="$uri"/>
				</xsl:otherwise>
			</xsl:choose>			
			<xsl:apply-templates select="$results/res:result[not(res:binding[@name='p']/res:uri='http://www.w3.org/1999/02/22-rdf-syntax-ns#type')]"/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="res:result">
		<xsl:variable name="property" select="res:binding[@name='p']/res:uri"/>
		<xsl:variable name="element" select="replace($property, $namespaces//namespace[contains($property, @uri)]/@uri, concat($namespaces//namespace[contains($property, @uri)]/@prefix, ':'))"/>
		
		<xsl:element name="{$element}">
			<xsl:choose>
				<xsl:when test="res:binding[@name='o']/res:uri">
					<xsl:attribute name="rdf:resource" select="res:binding[@name='o']/res:uri"/>
				</xsl:when>
				<xsl:when test="res:binding[@name='o']/res:literal">
					<xsl:value-of select="res:binding[@name='o']/res:literal"/>
				</xsl:when>
			</xsl:choose>
		</xsl:element>
	</xsl:template>
	
</xsl:stylesheet>
