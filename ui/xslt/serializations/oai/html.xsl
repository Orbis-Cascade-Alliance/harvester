<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai="http://www.openarchives.org/OAI/2.0/"
	exclude-result-prefixes="#all" version="2.0">
	<xsl:include href="../../templates.xsl"/>

	<!-- request params -->
	<xsl:param name="pipeline" select="tokenize(doc('input:request')/request/request-uri, '/')[last()]"/>
	<xsl:param name="output" select="doc('input:request')/request/parameters/parameter[name = 'output']/value"/>
	<xsl:param name="model" select="doc('input:request')/request/parameters/parameter[name = 'model']/value"/>
	<xsl:param name="set" select="doc('input:request')/request/parameters/parameter[name = 'set']/value"/>
	<xsl:param name="pageParam" select="doc('input:request')/request/parameters/parameter[name = 'page']/value"/>
	<xsl:param name="page" as="xs:integer">
		<xsl:choose>
			<xsl:when test="$pageParam castable as xs:integer">
				<xsl:value-of select="$pageParam"/>
			</xsl:when>
			<xsl:otherwise>1</xsl:otherwise>
		</xsl:choose>
	</xsl:param>

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
		<div class="container-fluid content"><!-- apply-templates on numFound, if available -->
			<!--<xsl:apply-templates select="//res:binding[@name = 'numFound']"/>-->
			<xsl:apply-templates select="descendant::oai_dc:dc"/>
			<!-- apply-templates on numFound, if available -->
			<!--<xsl:apply-templates select="//res:binding[@name = 'numFound']"/>-->
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
			<xsl:choose>
				<xsl:when test="matches(., '^https?://')">
					<a href=".">
						<xsl:apply-templates/>
					</a>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose>			
		</dd>
	</xsl:template>
	
	<!-- pagination -->
	<xsl:template match="res:binding[@name = 'numFound']">
		<xsl:variable name="limit" select="100"/>
		<xsl:variable name="numFound" select="res:literal" as="xs:integer"/>
		
		<div class="row paging">
			<div class="col-md-6">
				<xsl:text>Displaying records </xsl:text>
				<strong>
					<xsl:value-of select="(($page - 1) * 100) + 1"/>
				</strong>
				<xsl:text> to </xsl:text>
				<strong>
					<xsl:value-of select="
						if ($numFound &gt; $page * 100) then
						$page * 100
						else
						$numFound"/>
				</strong>
				<xsl:text> of </xsl:text>
				<strong>
					<xsl:value-of select="$numFound"/>
				</strong>
				<xsl:text> total results.</xsl:text>
			</div>
			<div class="col-md-6">
				<div class="btn-toolbar" role="toolbar">
					<div class="btn-group pull-right">
						<!-- back -->
						<xsl:choose>
							<xsl:when test="not($page) or $page = 1">
								<a class="btn btn-default disabled" title="Previous">
									<span class="glyphicon glyphicon-backward"/>
								</a>
							</xsl:when>
							<xsl:when test="$page &gt; 1">
								<a class="btn btn-default" title="Previous" href="results?set={encode-for-uri($set)}&amp;page={$page - 1}">
									<span class="glyphicon glyphicon-backward"/>
								</a>
							</xsl:when>
						</xsl:choose>
						<button class="btn btn-default">
							<span>
								<xsl:value-of select="$page"/>
							</span>
						</button>
						<!-- forward -->
						<xsl:choose>
							<xsl:when test="($numFound &gt; $page * 100)">
								<a class="btn btn-default" title="Next" href="results?set={encode-for-uri($set)}&amp;page={$page + 1}">
									<span class="glyphicon glyphicon-forward"/>
								</a>
							</xsl:when>
							<xsl:otherwise>
								<a class="btn btn-default disabled" title="Next">
									<span class="glyphicon glyphicon-forward"/>
								</a>
							</xsl:otherwise>
						</xsl:choose>
					</div>
				</div>
			</div>
		</div>
	</xsl:template>
	

</xsl:stylesheet>
