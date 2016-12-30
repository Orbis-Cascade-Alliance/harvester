<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:arch="http://purl.org/archival/vocab/arch#" xmlns:edm="http://www.europeana.eu/schemas/edm/"
	xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:vcard="http://www.w3.org/2006/vcard/ns#"
	xmlns:prov="http://www.w3.org/ns/prov#" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
	xmlns:nwda="https://github.com/Orbis-Cascade-Alliance/nwda-editor#" xmlns:ore="http://www.openarchives.org/ore/terms/" xmlns:dpla="http://dp.la/terms/"
	xmlns:foaf="http://xmlns.com/foaf/0.1/" exclude-result-prefixes="#all" version="2.0">
	<xsl:include href="../../templates.xsl"/>
	<xsl:variable name="display_path"/>

	<xsl:variable name="namespaces" as="item()*">
		<namespaces>
			<namespace prefix="dc" uri="http://purl.org/dc/elements/1.1/"/>
			<namespace prefix="dcterms" uri="http://purl.org/dc/terms/"/>
			<namespace prefix="dpla" uri="http://dp.la/terms/"/>
			<namespace prefix="edm" uri="http://www.europeana.eu/schemas/edm/"/>
			<namespace prefix="ore" uri="http://www.openarchives.org/ore/terms/"/>
			<namespace prefix="foaf" uri="http://xmlns.com/foaf/0.1/"/>
			<namespace prefix="geo" uri="http://www.w3.org/2003/01/geo/wgs84_pos#"/>
			<namespace prefix="prov" uri="http://www.w3.org/ns/prov#"/>
			<namespace prefix="rdf" uri="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
			<namespace prefix="xsd" uri="http://www.w3.org/2001/XMLSchema#"/>
		</namespaces>
	</xsl:variable>

	<xsl:template match="/">
		<html lang="en">
			<head>
				<title>Archives West Harvester: <xsl:value-of select="//dcterms:title"/></title>
				<meta name="viewport" content="width=device-width, initial-scale=1"/>
				<!-- bootstrap -->
				<script type="text/javascript" src="http://code.jquery.com/jquery-latest.min.js"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/result_functions.js"/>
				<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css"/>
				<script src="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"/>
				<link rel="stylesheet" href="{$display_path}ui/css/style.css"/>
			</head>
			<body>
				<xsl:call-template name="header"/>
				<xsl:call-template name="body"/>
				<xsl:call-template name="footer"/>
			</body>
		</html>
	</xsl:template>

	<xsl:template name="body">
		<div class="container-fluid content">
			<div class="row">
				<div class="col-md-12">
					<xsl:apply-templates select="descendant::ore:Aggregation"/>

				</div>
			</div>
		</div>
	</xsl:template>

	<xsl:template match="ore:Aggregation">
		<xsl:apply-templates select="descendant::dpla:SourceResource">
			<xsl:with-param name="reference" select="edm:object/@rdf:resource"/>
		</xsl:apply-templates>

	</xsl:template>

	<xsl:template match="dpla:SourceResource">
		<xsl:param name="reference"/>

		<h1>
			<xsl:value-of select="dcterms:title"/>
		</h1>
		<div class="col-md-6">
			<dl class="dl-horizontal"><xsl:apply-templates select="*[not(name() = 'dcterms:title')]"/></dl>
		</div>
		<div class="col-md-6">
			<img src="{$reference}" alt="image" style="max-width:100%"/>
		</div>
	</xsl:template>

	<xsl:template match="*">
		<dt>
			<xsl:value-of select="name()"/>
		</dt>
		<dd>
			<xsl:choose>
				<xsl:when test="@rdf:resource">
					<a href="{@rdf:resource}">
						<xsl:value-of select="@rdf:resource"/>
					</a>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</dd>
	</xsl:template>

</xsl:stylesheet>
