<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:res="http://www.w3.org/2005/sparql-results#" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:saxon="http://saxon.sf.net/"
	version="2.0">
	<xsl:include href="../templates.xsl"/>
	
	<xsl:variable name="display_path">../</xsl:variable>
	
	<xsl:template match="/">
		<xsl:apply-templates select="descendant::res:sparql"/>
	</xsl:template>
	
	<xsl:template match="res:sparql">
		<html lang="en">
			<head>
				<title>NWDA Harvester: Cultural Heritage Objects</title>
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
						<h1>Cultural Heritage Objects</h1>
						<xsl:choose>
							<xsl:when test="count(descendant::res:result) = 0">
								<p>There are no objects associated with this ARK.</p>
							</xsl:when>
							<xsl:otherwise>
								<xsl:apply-templates select="descendant::res:result"/>
							</xsl:otherwise>
						</xsl:choose>
					</div>
				</div>
			</div>
	</xsl:template>
	
	<xsl:template match="res:result">
		<div class="col-lg-2 col-md-3 col-sm-6">
			<div class="cho-container text-center">
				<xsl:choose>
					<xsl:when test="res:binding[@name='thumbnail']">
						<img src="{res:binding[@name='thumbnail']/res:uri}" alt="thumbnail" class="cho-thumb"/>
						<br/>
					</xsl:when>
				</xsl:choose>
				<a href="{res:binding[@name='cho']/res:uri}" target="_blank">
					<xsl:value-of select="res:binding[@name='title']/res:literal"/>
				</a>
			</div>
			
			
			<!--<xsl:if test="res:binding[@name='description']">
				<br/>
				<div><xsl:copy-of select="saxon:parse(concat('&lt;div&gt;', res:binding[@name='description']/res:literal, '&lt;/div&gt;'))"/></div>
				
			</xsl:if>-->
		</div>
	</xsl:template>
	
</xsl:stylesheet>