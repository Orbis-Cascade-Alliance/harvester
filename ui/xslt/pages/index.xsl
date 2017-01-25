<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:res="http://www.w3.org/2005/sparql-results#" exclude-result-prefixes="#all"
	version="2.0">
	<xsl:include href="../templates.xsl"/>
	<xsl:variable name="display_path">./</xsl:variable>

	<xsl:template match="/">
		
		<html lang="en">
			<head>
				<title>
					<xsl:value-of select="/content/config/title"/>
				</title>
				<meta name="viewport" content="width=device-width, initial-scale=1"/>
				<script type="text/javascript" src="http://code.jquery.com/jquery-latest.min.js"/>
				<!-- bootstrap -->
				<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"/>
				<script type="text/javascript" src="http://netdna.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"/>
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
				<div class="col-md-9">
					<h1>
						<xsl:value-of select="/content/config/title"/>
					</h1>
					<p>Placeholder for project description.</p>
					<h2>Partners</h2>
					<p>
						<a href="{/content/config/repository_rdf}"><span class="glyphicon glyphicon-download-alt"/>Download Orbis Cascade repository RDF/XML</a>
					</p>
					<table class="table table-striped">
						<thead>
							<tr>
								<th style="width:80%">Repository</th>
								<th style="width:20%" class="text-center">Count</th>								
							</tr>
						</thead>
						<tbody>
							<!-- only display the repositories with at least 1 CHO -->
							<xsl:apply-templates select="descendant::res:result[res:binding[@name='count']/res:literal &gt; 0]"/>
						</tbody>
					</table>
				</div>
				<div class="col-md-3">
					<div class="highlight">
						<h3>Export</h3>
						<p>Data dumps in the DPLA Metadata Application Profile (RDF) are available in three serializations.</p>
						<table class="table-dl">
							<tr>
								<td>
									<img src="{$display_path}ui/images/rdf-large.gif"/>
								</td>
								<td>
									<strong>Linked Data (VoID): </strong>
									<a href="void.jsonld">JSON-LD</a>, <a href="void.ttl">TTL</a>, <a href="void.rdf">RDF/XML</a>
								</td>
							</tr>
						</table>
					</div>
					<div class="highlight">
						<h3>Updates</h3>
						<p>The Atom feed provides access to recently updated Cultural Heritage Objects in the system.</p>
						<table class="table-dl">
							<tr>
								<td>
									<a href="feed">
										<img src="{$display_path}ui/images/atom-large.png" alt="Atom"/>
									</a>
								</td>
								<td>
									<strong>Atom: </strong>
									<a href="feed">XML</a>
								</td>
							</tr>
							<tr>
								<td>
									<a href="feed">
										<img src="{$display_path}ui/images/oai-pmh.png" alt="OAI-PMH"/>
									</a>
								</td>
								<td>
									<strong>OAI-PMH: </strong>
									<a href="oai-pmh/?verb=Identify">Identify</a><xsl:text>, </xsl:text><a href="oai-pmh/?verb=ListRecords&amp;set=primo&amp;metadataPrefix=oai_dc">ListRecords</a>
								</td>
							</tr>
						</table>
						<p>
							
						</p>
					</div>
				</div>
			</div>
		</div>
	</xsl:template>

	<!-- handle each matching res:result as an individual table row -->
	<xsl:template match="res:result">
		<xsl:variable name="repository" select="substring-after(res:binding[@name='uri']/res:uri, '#')"/>
		
		<tr>
			<td>
				<a href="{res:binding[@name='uri']/res:uri}">
					<xsl:value-of select="res:binding[@name='name']/res:literal"/>
				</a>
			</td>
			<td class="text-center">
				<xsl:value-of select="format-number(res:binding[@name='count']/res:literal, '###,###')"/>
			</td>
		</tr>
	</xsl:template>
	
	
</xsl:stylesheet>
