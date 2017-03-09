<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:arch="http://purl.org/archival/vocab/arch#" xmlns:edm="http://www.europeana.eu/schemas/edm/"
	xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:vcard="http://www.w3.org/2006/vcard/ns#"
	xmlns:prov="http://www.w3.org/ns/prov#" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:dcmitype="http://purl.org/dc/dcmitype/"
	xmlns:nwda="https://github.com/Orbis-Cascade-Alliance/nwda-editor#" xmlns:ore="http://www.openarchives.org/ore/terms/" xmlns:dpla="http://dp.la/terms/"
	xmlns:foaf="http://xmlns.com/foaf/0.1/" exclude-result-prefixes="#all" version="2.0">
	<xsl:include href="../../templates.xsl"/>
	<xsl:variable name="display_path">../</xsl:variable>

	<!-- request params -->
	<xsl:param name="output" select="doc('input:request')/request/parameters/parameter[name = 'output']/value"/>

	<xsl:variable name="namespaces" as="item()*">
		<namespaces>
			<namespace prefix="dc" uri="http://purl.org/dc/elements/1.1/"/>
			<namespace prefix="dcmitype" uri="http://purl.org/dc/dcmitype/"/>
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
		<xsl:choose>
			<xsl:when test="$output = 'ajax'">
				<div class="container-fluid">
					<xsl:apply-templates select="descendant::ore:Aggregation"/>
				</div>
			</xsl:when>
			<xsl:otherwise>
				<html lang="en">
					<head>
						<title>Archives West Harvester: <xsl:value-of
								select="
									if (count(//dcterms:title) &gt; 1) then
										'Test'
									else
										//dcterms:title"/></title>
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
			<xsl:apply-templates select="descendant::dcmitype:Collection" mode="render"/>
			<xsl:apply-templates select="descendant::ore:Aggregation"/>
		</div>
	</xsl:template>

	<xsl:template match="ore:Aggregation">
		<div class="row">

			<xsl:choose>
				<xsl:when test="string($output)">
					<xsl:variable name="cho_uri" select="edm:aggregatedCHO/@rdf:resource"/>
					<xsl:variable name="reference" select="edm:object/@rdf:resource"/>
					<xsl:variable name="thumbnail" select="edm:preview/@rdf:resource"/>

					<xsl:apply-templates select="parent::node()/dpla:SourceResource[@rdf:about = $cho_uri]">
						<xsl:with-param name="reference" select="$reference"/>
						<xsl:with-param name="thumbnail" select="$thumbnail"/>
						<xsl:with-param name="hasCoords" select="false()" as="xs:boolean"/>
					</xsl:apply-templates>

					<!-- self -->
					<xsl:apply-templates select="self::node()" mode="render"/>

					<!-- images -->
					<xsl:apply-templates
						select="parent::node()/edm:WebResource[@rdf:about = $thumbnail] | parent::node()/edm:WebResource[@rdf:about = $reference]" mode="render"
					/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="hasCoords" as="xs:boolean">
						<xsl:choose>
							<xsl:when test="descendant::geo:lat and descendant::geo:long">true</xsl:when>
							<xsl:otherwise>false</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>

					<xsl:apply-templates select="descendant::dpla:SourceResource">
						<xsl:with-param name="reference" select="edm:object/@rdf:resource"/>
						<xsl:with-param name="hasCoords" select="$hasCoords"/>
					</xsl:apply-templates>

					<xsl:if test="$hasCoords = true()">
						<div class="hidden">
							<span id="lat">
								<xsl:value-of select="descendant::geo:lat"/>
							</span>
							<span id="long">
								<xsl:value-of select="descendant::geo:long"/>
							</span>
						</div>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>

		</div>
	</xsl:template>

	<xsl:template match="edm:WebResource | ore:Aggregation | dcmitype:Collection" mode="render">
		<xsl:variable name="uri" select="@rdf:about"/>

		<div class="col-md-12">
			<h2>
				<xsl:variable name="propertyUri" select="nwda:linkProperty(name())"/>
				<a href="{$propertyUri}" title="{$propertyUri}">
					<xsl:value-of select="name()"/>
				</a>
			</h2>
			<h4>
				<a href="{@rdf:about}">
					<xsl:value-of select="@rdf:about"/>
				</a>
			</h4>
			<dl class="dl-horizontal">
				<xsl:apply-templates>
					<xsl:sort select="local-name()"/>
				</xsl:apply-templates>
			</dl>

			<xsl:if test="self::edm:WebResource and position() = last()">
				<hr/>
			</xsl:if>
		</div>
	</xsl:template>

	<xsl:template match="dpla:SourceResource">
		<xsl:param name="thumbnail"/>
		<xsl:param name="reference"/>
		<xsl:param name="hasCoords" as="xs:boolean"/>
		<div class="col-md-12">
			<h1>
				<xsl:choose>
					<xsl:when test="string($output)">
						<xsl:variable name="propertyUri" select="nwda:linkProperty(name())"/>
						<a href="{$propertyUri}" title="{$propertyUri}">
							<xsl:value-of select="name()"/>
						</a>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="dcterms:title"/>
					</xsl:otherwise>
				</xsl:choose>
			</h1>
			<h4>
				<a href="{@rdf:about}">
					<xsl:value-of select="@rdf:about"/>
				</a>
			</h4>
		</div>
		<xsl:choose>
			<xsl:when test="string($output)">
				<div class="col-md-6">
					<dl class="dl-horizontal">
						<xsl:apply-templates>
							<xsl:sort select="local-name()"/>
						</xsl:apply-templates>
					</dl>
				</div>
				<div class="col-md-6">
					<xsl:if test="string($reference)">
						<img src="{$reference}" alt="Reference image URL not dereferenceable" title="Thumbnail" style="max-width:100%"/>
					</xsl:if>
					<xsl:if test="string($thumbnail)">
						<img src="{$thumbnail}" alt="Thumbnail image URL not dereferenceable" title="Reference" style="max-width:100%"/>
					</xsl:if>
				</div>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="$hasCoords = true()">
						<div class="col-md-12">
							<dl class="dl-horizontal">
								<xsl:apply-templates select="*[not(name() = 'dcterms:title')]">
									<xsl:sort select="local-name()"/>
								</xsl:apply-templates>
							</dl>
						</div>
						<div class="col-md-6">
							<xsl:if test="string($reference)">
								<img src="{$reference}" alt="Reference image URL not dereferenceable" style="max-width:100%"/>
							</xsl:if>
						</div>
						<div class="col-md-6">
							<div id="map"/>
						</div>
					</xsl:when>
					<xsl:otherwise>
						<div class="col-md-6">
							<dl class="dl-horizontal">
								<xsl:apply-templates select="*[not(name() = 'dcterms:title')]">
									<xsl:sort select="local-name()"/>
								</xsl:apply-templates>
							</dl>
						</div>
						<div class="col-md-6">
							<img src="{$reference}" alt="image" style="max-width:100%"/>
						</div>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="*">
		<xsl:variable name="propertyUri" select="nwda:linkProperty(name())"/>

		<dt>
			<a href="{$propertyUri}" title="{$propertyUri}">
				<xsl:value-of select="name()"/>
			</a>
		</dt>
		<dd>
			<xsl:choose>
				<xsl:when test="@rdf:resource">
					<a href="{@rdf:resource}">
						<xsl:value-of select="@rdf:resource"/>
					</a>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose>
		</dd>
	</xsl:template>

	<xsl:template match="edm:TimeSpan | edm:Place">
		<xsl:variable name="propertyUri" select="nwda:linkProperty(name())"/>
		<div>
			<h4>
				<a href="{$propertyUri}" title="{$propertyUri}">
					<xsl:value-of select="name()"/>
				</a>
			</h4>
			<dl class="dl-horizontal">
				<xsl:apply-templates/>
			</dl>
		</div>
	</xsl:template>

	<xsl:function name="nwda:linkProperty">
		<xsl:param name="property"/>
		<xsl:variable name="prefix" select="substring-before($property, ':')"/>
		<xsl:value-of select="concat($namespaces//namespace[@prefix = $prefix]/@uri, substring-after($property, ':'))"/>
	</xsl:function>

</xsl:stylesheet>
