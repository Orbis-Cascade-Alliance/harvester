<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
	xmlns:edm="http://www.europeana.eu/schemas/edm/" xmlns:dpla="http://dp.la/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/"
	xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:atom="http://www.w3.org/2005/Atom"
	xmlns:gsx="http://schemas.google.com/spreadsheets/2006/extended" xmlns:harvester="https://github.com/Orbis-Cascade-Alliance/harvester"
	xmlns:gn="http://www.geonames.org/ontology#" exclude-result-prefixes="xs harvester atom gsx" version="2.0">
	<xsl:output indent="yes" encoding="UTF-8"/>

	<xsl:variable name="type" select="doc('input:controls')/type"/>
	<xsl:variable name="wikidata-properties" as="element()*">
		<properties>
			<property id="P213">http://isni.org/</property>
			<property id="P214">http://viaf.org/viaf/</property>
			<property id="P227">http://d-nb.info/gnd/</property>
			<property id="P245">http://vocab.getty.edu/ulan/</property>
			<property id="P268">http://catalogue.bnf.fr/ark:/12148/cb</property>
			<property id="P269">http://www.idref.fr/</property>
			<property id="P646">https://www.freebase.com</property>
		</properties>
	</xsl:variable>

	<xsl:template match="/">
		<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
			xmlns:edm="http://www.europeana.eu/schemas/edm/" xmlns:dpla="http://dp.la/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/"
			xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#">

			<!-- apply templates to each atom entry with a valid URI -->
			<xsl:apply-templates select="descendant::atom:entry[matches(gsx:uri, 'https?://')]"/>
		</rdf:RDF>
	</xsl:template>

	<xsl:template match="atom:entry">
		<xsl:variable name="class">
			<xsl:choose>
				<xsl:when test="$type = 'places'">edm:Place</xsl:when>
				<xsl:when test="$type = 'agents'">edm:Agent</xsl:when>
				<xsl:otherwise>skos:Concept</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="rdf" as="element()*">
			<xsl:choose>
				<xsl:when test="contains(gsx:uri, 'geonames.org')">
					<xsl:copy-of select="document(concat(gsx:uri, 'about.rdf'))//gn:Feature"/>
				</xsl:when>
				<xsl:otherwise>
					<rdf:RDF/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:element name="{$class}">
			<xsl:attribute name="rdf:about" select="gsx:uri"/>
			<skos:prefLabel xml:lang="en">
				<xsl:value-of select="gsx:label"/>
			</skos:prefLabel>

			<!-- parse wikipedia column, if applicable -->
			<xsl:if test="contains(gsx:wikipedia, 'en.wikipedia.org')">
				<xsl:call-template name="wikidata">
					<xsl:with-param name="title" select="tokenize(gsx:wikipedia, '/')[last()]"/>
				</xsl:call-template>
			</xsl:if>

			<!-- insert additional information from Geonames RDF -->
			<xsl:if test="contains(gsx:uri, 'geonames.org')">
				<xsl:if test="$rdf/geo:lat and $rdf/geo:long">
					<geo:lat rdf:datatype="http://www.w3.org/2001/XMLSchema#decimal">
						<xsl:value-of select="$rdf/geo:lat"/>
					</geo:lat>
					<geo:long rdf:datatype="http://www.w3.org/2001/XMLSchema#decimal">
						<xsl:value-of select="$rdf/geo:long"/>
					</geo:long>
				</xsl:if>
				<xsl:apply-templates select="$rdf/gn:parentFeature"/>				
				<!-- extract matching terms by parsing English wikipedia articles for Wikidata properties (if there isn't a value in the wikipedia column -->
				<xsl:if test="not(gsx:wikipedia[contains(., 'en.wikipedia.org')])">
					<xsl:apply-templates select="$rdf/gn:wikipediaArticle[contains(@rdf:resource, 'en.wikipedia.org')]"/>
				</xsl:if>				
			</xsl:if>
		</xsl:element>
	</xsl:template>


	<!-- geonames templates -->
	<xsl:template match="gn:wikipediaArticle">
		<xsl:variable name="title" select="tokenize(@rdf:resource, '/')[last()]"/>
		<xsl:call-template name="wikidata">
			<xsl:with-param name="title" select="$title"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="gn:parentFeature">
		<skos:broader rdf:resource="{@rdf:resource}"/>
		<gn:parentFeature rdf:resource="{@rdf:resource}"/>
	</xsl:template>

	<!-- process wikidata -->
	<xsl:template name="wikidata">
		<xsl:param name="title"/>

		<xsl:variable name="service"
			select="concat('https://www.wikidata.org/w/api.php?action=wbgetentities&amp;titles=', $title, '&amp;sites=enwiki&amp;format=xml')"/>
		<xsl:variable name="wikidata" as="element()*">
			<xsl:copy-of select="document($service)/*"/>
		</xsl:variable>

		<!-- add the Wikidata URI -->
		<skos:exactMatch rdf:resource="{concat('https://www.wikidata.org/entity/', $wikidata//entity/@id)}"/>
		<!-- process properties to insert other skos:exactMatch URIs -->
		<xsl:apply-templates
			select="$wikidata//entity/claims/property[@id = 'P214' or @id = 'P227' or @id = 'P213' or @id = 'P268' or @id = 'P269' or @id = 'P646' or @id = 'P245']"
		/>
	</xsl:template>

	<xsl:template match="property">
		<xsl:variable name="property" select="@id"/>
		<xsl:variable name="id" select="replace(descendant::mainsnak[1]/datavalue/@value, ' ', '')"/>
		<xsl:variable name="uri" select="concat($wikidata-properties//property[@id = $property], $id)"/>

		<skos:exactMatch rdf:resource="{$uri}"/>
	</xsl:template>

</xsl:stylesheet>
