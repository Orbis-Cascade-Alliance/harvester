<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:res="http://www.w3.org/2005/sparql-results#" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:saxon="http://saxon.sf.net/"
	version="2.0">
	<xsl:include href="../templates.xsl"/>

	<xsl:param name="ark" select="doc('input:request')/request/parameters/parameter[name='ark']/value"/>

	<xsl:variable name="display_path">../</xsl:variable>
	<xsl:variable name="repositoryLabel" select="descendant::res:binding[@name='repository'][1]/res:literal"/>
	<xsl:variable name="repositoryUri" select="descendant::res:binding[@name='repo_uri'][1]/res:uri"/>	

	<xsl:template match="/">
		<xsl:apply-templates select="descendant::res:sparql"/>
	</xsl:template>

	<xsl:template match="res:sparql">
		<html lang="en">
			<head>
				<title>NWDA Harvester: Cultural Heritage Objects</title>
				<meta name="viewport" content="width=device-width, initial-scale=1"/>
				<!-- bootstrap -->
				<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"/>
				<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css"/>
				<script src="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"/>
				<!-- fancybox -->
				<link rel="stylesheet" href="{$display_path}ui/css/jquery.fancybox.css?v=2.1.5" type="text/css" media="screen"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/jquery.fancybox.pack.js?v=2.1.5"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/get_functions.js"/>
				<!-- local styling -->
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
					<xsl:choose>
						<xsl:when test="count(descendant::res:result) = 0">
							<p>There are no objects associated with this ARK.</p>
						</xsl:when>
						<xsl:otherwise>
							<!-- use the ark URI to get the EAD/XML in response with the xsl document() function, apply template on archdesc/did -->
							<xsl:apply-templates select="document(concat('oxf:', '/apps/harvester/NTE2pc35.xml'))//*[local-name()='archdesc']/*[local-name()='did']"/>
							<h3>Associated Cultural Heritage Objects</h3>
							<xsl:apply-templates select="descendant::res:result"/>
						</xsl:otherwise>
					</xsl:choose>
				</div>
			</div>
		</div>
	</xsl:template>

	<!-- styling for an individual result -->
	<xsl:template match="res:result">
		<div class="col-lg-2 col-md-3 col-sm-6">
			<div class="cho-container text-center">
				<xsl:choose>
					<xsl:when test="res:binding[@name='thumbnail'] and res:binding[@name='depiction']">
						<a href="{res:binding[@name='depiction']}" class="thumbImage" title="{res:binding[@name='title']/res:literal}">
							<img src="{res:binding[@name='thumbnail']/res:uri}" alt="thumbnail" class="cho-thumb"/>
						</a>
						<br/>
					</xsl:when>
					<xsl:when test="res:binding[@name='thumbnail'] and not(res:binding[@name='depiction'])">
						<img src="{res:binding[@name='thumbnail']/res:uri}" alt="thumbnail" class="cho-thumb"/>
						<br/>
					</xsl:when>
				</xsl:choose>
				<a href="{res:binding[@name='cho']/res:uri}" target="_blank" title="{res:binding[@name='title']/res:literal}">
					<xsl:value-of select="if (string-length(res:binding[@name='title']/res:literal) &gt; 50) then concat(substring(res:binding[@name='title']/res:literal, 1, 50), '...') else
						res:binding[@name='title']/res:literal"/>
				</a>
			</div>
		</div>
	</xsl:template>

	<!-- templates for processing the archdesc/did in the EAD file into the collection overview metadata -->
	<xsl:template match="did">
		<h2>Overview of Collection</h2>
		<h3>
			<a href="{$ark}">
				<xsl:value-of select="unittitle"/>
			</a>
		</h3>
		<dl class="dl-horizontal">
			<dt>Creator:</dt>
			<dd>
				<xsl:value-of select="origination"/>
			</dd>
			<xsl:if test="unitdate">
				<dt>Dates:</dt>
				<dd>
					<xsl:value-of select="unitdate"/>
				</dd>
			</xsl:if>
			<xsl:if test="physdesc/extent">
				<dt>Quantity:</dt>
				<dd>
					<xsl:value-of select="physdesc/extent"/>
				</dd>
			</xsl:if>
			<xsl:if test="unitid">
				<dt>Collection Number:</dt>
				<dd>
					<xsl:value-of select="unitid"/>
				</dd>
			</xsl:if>
			<xsl:if test="abstract">
				<dt>Summary:</dt>
				<dd>
					<xsl:value-of select="abstract"/>
				</dd>
			</xsl:if>
			<dt>Repository:</dt>
			<dd>
				<a href="{$repositoryUri}">
					<xsl:value-of select="$repositoryLabel"/>
				</a>
			</dd>
			<xsl:if test="langmaterial">
				<dt>Languages:</dt>
				<dd>
					<xsl:value-of select="langmaterial"/>
				</dd>
			</xsl:if>
			<xsl:if test="sponsor">
				<dt>Sponsor:</dt>
				<dd>
					<xsl:value-of select="sponsor"/>
				</dd>
			</xsl:if>
		</dl>
	</xsl:template>

</xsl:stylesheet>
