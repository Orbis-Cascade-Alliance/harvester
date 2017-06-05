<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.openarchives.org/OAI/2.0/"
	xmlns:digest="org.apache.commons.codec.digest.DigestUtils" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:arch="http://purl.org/archival/vocab/arch#" xmlns:edm="http://www.europeana.eu/schemas/edm/" xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:vcard="http://www.w3.org/2006/vcard/ns#" xmlns:prov="http://www.w3.org/ns/prov#"
	xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:nwda="https://github.com/Orbis-Cascade-Alliance/nwda-editor#"
	xmlns:ore="http://www.openarchives.org/ore/terms/" xmlns:dpla="http://dp.la/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/"
	xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:doap="http://usefulinc.com/ns/doap#" xmlns:skos="http://www.w3.org/2004/02/skos/core#"
	exclude-result-prefixes="xs res rdf arch edm dcterms vcard nwda dpla ore digest prov geo dcmitype skos" version="2.0">

	<xsl:template match="dpla:SourceResource">
		<xsl:param name="dataProvider"/>
		<xsl:param name="thumbnail"/>
		<xsl:param name="depiction"/>
		<xsl:param name="format"/>

		<oai_dc:dc>
			<xsl:apply-templates select="*"/>

			<dc:publisher>
				<xsl:choose>
					<xsl:when test="contains($dataProvider, 'archiveswest')">
						<xsl:variable name="code" select="substring-after($dataProvider, '#')"/>

						<xsl:value-of select="//config/codes/repository[@marc = $code]/@exlibris"/>
					</xsl:when>
					<xsl:when test="contains($dataProvider, 'harvester')">
						<xsl:variable name="code" select="tokenize($dataProvider, '/')[last()]"/>

						<xsl:value-of select="//config/codes/repository[@marc = $code]/@exlibris"/>
					</xsl:when>
				</xsl:choose>
			</dc:publisher>

			<dc:identifier>
				<xsl:value-of select="@rdf:about"/>
			</dc:identifier>
			<xsl:if test="string($format)">
				<dc:format>
					<xsl:value-of select="$format"/>
				</dc:format>
			</xsl:if>
			<xsl:if test="string($thumbnail)">
				<dc:relation.hasVersion>
					<xsl:value-of select="$thumbnail"/>
				</dc:relation.hasVersion>
			</xsl:if>
			<xsl:if test="string($depiction)">
				<dc:relation.references>
					<xsl:value-of select="$depiction"/>
				</dc:relation.references>
			</xsl:if>
		</oai_dc:dc>
	</xsl:template>

	<!-- types -->
	<xsl:template match="dcterms:type">
		<dc:type>
			<xsl:value-of select="tokenize(@rdf:resource, '/')[last()]"/>
		</dc:type>
	</xsl:template>

	<xsl:template match="dcterms:creator | dcterms:contributor">
		<xsl:variable name="element" select="local-name()"/>

		<xsl:choose>
			<xsl:when test="child::edm:Agent">
				<xsl:variable name="label" select="child::edm:Agent/skos:prefLabel"/>

				<xsl:element name="dc:{$element}" namespace="http://purl.org/dc/elements/1.1/">
					<xsl:value-of select="$label"/>
				</xsl:element>

				<!-- strip dates from preferred label, if applicable -->
				<xsl:if test="string-length($label) &gt; 0">
					<xsl:call-template name="undated-name">
						<xsl:with-param name="label" select="$label"/>
						<xsl:with-param name="element" select="$element"/>
					</xsl:call-template>
				</xsl:if>
			</xsl:when>
			<xsl:when test="@rdf:resource">
				<xsl:variable name="uri" select="@rdf:resource"/>
				<xsl:choose>
					<xsl:when test="//edm:Agent[@rdf:about = $uri]">
						<xsl:variable name="label" select="//edm:Agent[@rdf:about = $uri]/skos:prefLabel"/>

						<xsl:element name="dc:{$element}" namespace="http://purl.org/dc/elements/1.1/">
							<xsl:value-of select="$label"/>
						</xsl:element>

						<!-- strip dates from preferred label, if applicable -->
						<xsl:if test="string-length($label) &gt; 0">
							<xsl:call-template name="undated-name">
								<xsl:with-param name="label" select="$label"/>
								<xsl:with-param name="element" select="$element"/>
							</xsl:call-template>
						</xsl:if>
					</xsl:when>
					<xsl:otherwise>
						<xsl:element name="dc:{$element}" namespace="http://purl.org/dc/elements/1.1/">
							<xsl:value-of select="@rdf:resource"/>
						</xsl:element>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="label" select="."/>

				<xsl:element name="dc:{$element}" namespace="http://purl.org/dc/elements/1.1/">
					<xsl:value-of select="$label"/>
				</xsl:element>

				<!-- strip dates from preferred label, if applicable -->
				<xsl:if test="string-length($label) &gt; 0">
					<xsl:call-template name="undated-name">
						<xsl:with-param name="label" select="$label"/>
						<xsl:with-param name="element" select="$element"/>
					</xsl:call-template>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="undated-name">
		<xsl:param name="label"/>
		<xsl:param name="element"/>

		<xsl:analyze-string select="$label" regex="(.*),\s\d{{4}}">
			<xsl:matching-substring>
				<xsl:element name="dc:{$element}.undated" namespace="http://purl.org/dc/elements/1.1/">
					<xsl:value-of select="regex-group(1)"/>
				</xsl:element>
			</xsl:matching-substring>
		</xsl:analyze-string>
	</xsl:template>

	<xsl:template match="edm:hasType">
		<dc:genre>
			<xsl:choose>
				<xsl:when test="child::skos:Concept">
					<xsl:value-of select="child::skos:Concept/skos:prefLabel"/>
				</xsl:when>
				<xsl:when test="@rdf:resource">
					<xsl:variable name="uri" select="@rdf:resource"/>
					<xsl:choose>
						<xsl:when test="//skos:Concept[@rdf:about = $uri]">
							<xsl:value-of select="//skos:Concept[@rdf:about = $uri]/skos:prefLabel"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="@rdf:resource"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</dc:genre>
	</xsl:template>

	<!-- parse dates -->
	<xsl:template match="dcterms:date">
		<xsl:choose>
			<xsl:when test="edm:TimeSpan">
				<xsl:apply-templates select="edm:TimeSpan"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="@rdf:datatype">
						<dc:date>
							<xsl:value-of select="."/>
						</dc:date>
						<dc:date.start>
							<xsl:value-of select="nwda:denormalizeDate(., 'from')"/>
						</dc:date.start>
						<dc:date.end>
							<xsl:value-of select="nwda:denormalizeDate(., 'to')"/>
						</dc:date.end>
					</xsl:when>
					<xsl:otherwise>
						<dc:date>
							<xsl:value-of select="."/>
						</dc:date>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="edm:TimeSpan">
		<dc:date>
			<xsl:value-of select="concat(replace(edm:begin, '-', ''), '/', replace(edm:end, '-', ''))"/>
		</dc:date>
		<dc:date.start>
			<xsl:value-of select="nwda:denormalizeDate(edm:begin, 'from')"/>
		</dc:date.start>
		<dc:date.end>
			<xsl:value-of select="nwda:denormalizeDate(edm:end, 'to')"/>
		</dc:date.end>
	</xsl:template>

	<!-- put edm:Place coordinates back together -->
	<xsl:template match="dcterms:spatial[edm:Place]">
		<dc:coverage.spatial.latlong>
			<xsl:apply-templates select="edm:Place"/>
		</dc:coverage.spatial.latlong>
	</xsl:template>

	<xsl:template match="edm:Place">
		<xsl:value-of select="concat(geo:lat, ',', geo:long)"/>
	</xsl:template>

	<xsl:template match="dc:rights[@rdf:resource]">
		<dc:rights.standardized>
			<xsl:value-of select="@rdf:resource"/>
		</dc:rights.standardized>
	</xsl:template>

	<xsl:template match="dcterms:isPartOf">
		<dc:isPartOf>
			<xsl:choose>
				<xsl:when test="@rdf:resource">
					<xsl:variable name="uri" select="@rdf:resource"/>
					<xsl:choose>
						<xsl:when test="//dcmitype:Collection[@rdf:about = $uri]/dcterms:title">
							<xsl:value-of select="//dcmitype:Collection[@rdf:about = $uri]/dcterms:title"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$uri"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="descendant::dcterms:title"/>
				</xsl:otherwise>
			</xsl:choose>
		</dc:isPartOf>
	</xsl:template>

	<xsl:template match="*">
		<xsl:element name="dc:{local-name()}" namespace="http://purl.org/dc/elements/1.1/">
			<xsl:choose>
				<xsl:when test="@rdf:resource">
					<xsl:value-of select="@rdf:resource"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
	</xsl:template>

	<!-- ************ FUNCTIONS *************-->
	<xsl:function name="nwda:denormalizeDate">
		<xsl:param name="date"/>
		<xsl:param name="pos"/>

		<xsl:choose>
			<xsl:when test="$date castable as xs:date">
				<xsl:value-of select="replace($date, '-', '')"/>
			</xsl:when>
			<xsl:when test="$date castable as xs:gYearMonth">
				<xsl:choose>
					<xsl:when test="$pos = 'from'">
						<xsl:value-of select="concat(replace($date, '-', ''), '01')"/>
					</xsl:when>
					<xsl:when test="$pos = 'to'">
						<xsl:variable name="last">
							<xsl:call-template name="last-day-of-month">
								<xsl:with-param name="date" select="$date"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:value-of select="concat(replace($date, '-', ''), $last)"/>
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$date castable as xs:gYear">
				<xsl:choose>
					<xsl:when test="$pos = 'from'">
						<xsl:value-of select="concat(replace($date, '-', ''), '0101')"/>
					</xsl:when>
					<xsl:when test="$pos = 'to'">
						<xsl:variable name="last">
							<xsl:call-template name="last-day-of-month">
								<xsl:with-param name="date" select="$date"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:value-of select="concat(replace($date, '-', ''), '1231')"/>
					</xsl:when>
				</xsl:choose>
			</xsl:when>
		</xsl:choose>
	</xsl:function>

	<xsl:template name="last-day-of-month">
		<xsl:param name="date"/>
		<xsl:param name="y" select="xs:integer(substring($date, 1, 4))"/>
		<xsl:param name="m" select="xs:integer(substring($date, 6, 2))"/>
		<xsl:param name="cal" select="'312831303130313130313031'"/>
		<xsl:param name="leap" select="not($y mod 4) and $y mod 100 or not($y mod 400)"/>
		<xsl:param name="month-length" select="substring($cal, 2 * ($m - 1) + 1, 2)"/>
		<xsl:value-of select="$month-length"/>
	</xsl:template>

</xsl:stylesheet>
