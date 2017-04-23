<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai="http://www.openarchives.org/OAI/2.0/"
	exclude-result-prefixes="#all" version="2.0">
	<xsl:include href="../../templates.xsl"/>

	<!-- request params -->
	<xsl:param name="pipeline" select="tokenize(doc('input:request')/request/request-uri, '/')[last()]"/>
	<xsl:param name="output" select="doc('input:request')/request/parameters/parameter[name = 'output']/value"/>
	<xsl:param name="model" select="doc('input:request')/request/parameters/parameter[name = 'model']/value"/>

	<xsl:variable name="display_path">
		<xsl:choose>
			<xsl:when test="$pipeline = 'results'"/>
			<xsl:otherwise>../</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="$output = 'ajax'">
				<div class="container-fluid">
					<xsl:apply-templates select="descendant::oai_dc:dc"/>
				</div>
			</xsl:when>
			<xsl:otherwise>
				<html lang="en">
					<head>
						<title>
							<xsl:text>Orbis Cascade Harvester: </xsl:text>
							<xsl:value-of select="//dc:title"/>
						</title>
						<meta name="viewport" content="width=device-width, initial-scale=1"/>
						<!-- bootstrap -->
						<script type="text/javascript" src="http://code.jquery.com/jquery-latest.min.js"/>
						<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"/>
						<script src="http://netdna.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"/>
						<link rel="stylesheet" href="{$display_path}ui/css/style.css"/>
						<link rel="stylesheet" href="http://cdn.leafletjs.com/leaflet/v0.7.7/leaflet.css"/>
						<script src="http://cdn.leafletjs.com/leaflet/v0.7.7/leaflet.js"/>
						<script type="text/javascript" src="{$display_path}ui/javascript/display_functions.js"/>
					</head>
					<body>
						<xsl:call-template name="header"/>
						<xsl:call-template name="body"/>
						<xsl:call-template name="footer"/>
					</body>
				</html>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="body">
		<div class="container-fluid content">
			<xsl:apply-templates select="descendant::oai_dc:dc"/>
		</div>
	</xsl:template>

	<xsl:template match="oai_dc:dc">
		<div class="row">
			<div class="col-md-12">
				<h3>
					<a href="{dc:identifier}" target="_blank">
						<xsl:value-of select="dc:title"/>
					</a>
				</h3>
				<dl class="dl-horizontal">
					<xsl:apply-templates/>
				</dl>
			</div>
		</div>		
	</xsl:template>

	<xsl:template match="*">
		<dt>
			<xsl:value-of select="name()"/>
		</dt>
		<dd>
			<xsl:apply-templates/>
		</dd>
	</xsl:template>

</xsl:stylesheet>
