<?xml version="1.0" encoding="UTF-8"?>
<!--
 Changes:

    08/20/15    KEF     Don't use a <dc:identifier> URL beginning with 
                        "http://kagi" as the cho_uri.  This is a hack to keep
                        WSU's audio server URLs from being picked.  Would be
                        better to generalize to filtering out all URLs without
                        "cdm/ref" in them for ContentDM users, but that would be
                        a lot of code that I'm not ready to introduce.
    09/16/15    KEF     Added custom code for Willamette, which uses a proxy of
                        sorts in front of their contentDM system, such that the
                        public URL for the object isn't standard and needs custom
                        image URLs.
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
	xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:oai="http://www.openarchives.org/OAI/2.0/"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:dpla="http://dp.la/terms/" xmlns:skos="http://www.w3.org/2004/02/skos/core#"
	xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:edm="http://www.europeana.eu/schemas/edm/"
	xmlns:ore="http://www.openarchives.org/ore/terms/" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/"
	xmlns:prov="http://www.w3.org/ns/prov#" xmlns:doap="http://usefulinc.com/ns/doap#" xmlns:gsx="http://schemas.google.com/spreadsheets/2006/extended"
	xmlns:harvester="https://github.com/Orbis-Cascade-Alliance/harvester" xmlns:digest="org.apache.commons.codec.digest.DigestUtils"
	exclude-result-prefixes="oai_dc oai xs harvester atom openSearch gsx digest" version="2.0">
	<xsl:output indent="yes" encoding="UTF-8"/>

	<!-- request parameters -->
	<xsl:param name="mode" select="doc('input:request')/request/parameters/parameter[name = 'mode']/value"/>
	<xsl:param name="repository" select="/content/controls/repository"/>
	<xsl:param name="set" select="/content/controls/set"/>
	<xsl:param name="ark" select="/content/controls/ark"/>
	<xsl:param name="target" select="/content/controls/target"/>
	<xsl:param name="url" select="/content/config/url"/>
	<xsl:param name="production_server" select="/content/config/production_server"/>

	<!-- load Google Sheets Atom feeds into variables for normalization -->
	<xsl:variable name="places" as="element()*">
		<xsl:copy-of select="document(/content/config/sheets/places)/*"/>
	</xsl:variable>

	<xsl:variable name="subjects" as="element()*">
		<xsl:copy-of select="document(/content/config/sheets/subjects)/*"/>
	</xsl:variable>

	<xsl:template match="/">
		<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"
			xmlns:ore="http://www.openarchives.org/ore/terms/" xmlns:xsd="http://www.w3.org/2001/XMLSchema#" xmlns:edm="http://www.europeana.eu/schemas/edm/"
			xmlns:dpla="http://dp.la/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:prov="http://www.w3.org/ns/prov#" xmlns:skos="http://www.w3.org/2004/02/skos/core#"
			xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:doap="http://usefulinc.com/ns/doap#">
			<!-- either process only those objects with a matching $ark when the process is instantiated by the finding aid upload, or process all objects for bulk uploading -->

			<xsl:choose>
				<xsl:when test="$mode = 'test'">
					<xsl:apply-templates select="descendant::oai:record[not(oai:header/@status = 'deleted')][position() &lt;= 10]"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="descendant::oai:record[not(oai:header/@status = 'deleted')]"/>
				</xsl:otherwise>
			</xsl:choose>

			<xsl:if test="not($mode = 'test')">
				<xsl:if test="descendant::oai:resumptionToken">
					<xsl:call-template name="recurse">
						<xsl:with-param name="token" select="descendant::oai:resumptionToken"/>
						<xsl:with-param name="set" select="descendant::oai:request"/>
					</xsl:call-template>
				</xsl:if>
			</xsl:if>
		</rdf:RDF>
	</xsl:template>

	<xsl:template match="oai:record">
		<xsl:choose>
			<xsl:when test="string($ark)">
				<xsl:apply-templates select="oai:metadata/*[dc:relation[contains(., $ark)]][dc:identifier[matches(., 'https?://')]]"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="oai:metadata/*[dc:identifier[matches(., 'https?://')]]"/>
			</xsl:otherwise>
		</xsl:choose>

		<xsl:if test="not($mode = 'test') and not($mode = 'form')">
			<xsl:if test="descendant::oai:resumptionToken">
				<xsl:call-template name="recurse">
					<xsl:with-param name="token" select="descendant::oai:resumptionToken"/>
					<xsl:with-param name="set" select="descendant::oai:request"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:if>
	</xsl:template>

	<xsl:template match="oai:metadata/*">
		<xsl:variable name="URLs" select="dc:identifier[matches(normalize-space(.), 'https?://')]"/>
		<xsl:variable name="metadata" as="element()*">
			<xsl:copy-of select="self::node()"/>
		</xsl:variable>

		<!-- process $cho_uri, as there might be more than one that matches a URI pattern -->
		<xsl:for-each select="$URLs">
			<xsl:variable name="cho_uri" select="normalize-space(.)"/>

			<!-- conditional for isolating appropriate CHO URI -->
			<xsl:choose>
				<!-- ignore kaga -->
				<xsl:when test="matches($cho_uri, 'https?://kaga')"/>
				<!-- ignore jpg files -->
				<xsl:when test="matches($cho_uri, '.jpe?g$')"/>
				<xsl:otherwise>
					<xsl:apply-templates select="$metadata" mode="process-metadata">
						<xsl:with-param name="cho_uri" select="$cho_uri"/>
					</xsl:apply-templates>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="*" mode="process-metadata">
		<xsl:param name="cho_uri"/>

		<!-- parse ARK -->
		<xsl:variable name="ark">
			<xsl:if test="dc:relation[matches(., 'ark:/')]">
				<xsl:analyze-string select="dc:relation[matches(., 'ark:/')][1]" regex=".*(ark:/[0-9]{{5}}/[A-Za-z0-9]+)">
					<xsl:matching-substring>
						<xsl:value-of select="regex-group(1)"/>
					</xsl:matching-substring>
				</xsl:analyze-string>
			</xsl:if>
		</xsl:variable>
		<!-- parse content type -->
		<xsl:variable name="content-type">
			<xsl:if test="dc:format[contains(., '/')][1]">
				<xsl:analyze-string select="dc:format[contains(., '/')][1]" regex="([^\s]+/[^\s]+)">
					<xsl:matching-substring>
						<xsl:value-of select="regex-group(1)"/>
					</xsl:matching-substring>
				</xsl:analyze-string>
			</xsl:if>
		</xsl:variable>

		<!-- parse rights statement from dc:rights -->
		<xsl:variable name="rights">
			<xsl:if test="dc:rights[starts-with(normalize-space(.), 'http://rightsstatements.org')]">
				<xsl:value-of select="dc:rights[starts-with(normalize-space(.), 'http://rightsstatements.org')]"/>
			</xsl:if>
		</xsl:variable>

		<dpla:SourceResource rdf:about="{$cho_uri}">
			<dcterms:title>
				<xsl:value-of select="dc:title"/>
			</dcterms:title>

			<!-- apply generic DC templates -->
			<xsl:apply-templates
				select="dc:date[1] | dc:type | dc:creator | dc:language | dc:contributor | dc:rights | dc:format | dc:subject | dc:extent | dc:temporal | dc:publisher"/>

			<!-- handle coverage and spatial for coordinates vs. text -->
			<xsl:choose>
				<!-- handle spatial/coverage with lat and long encoded directly -->
				<xsl:when test="count(*[local-name() = 'spatial']) = 2">
					<xsl:if test="*[local-name() = 'spatial'][1] castable as xs:decimal and *[local-name() = 'spatial'][2] castable as xs:decimal">
						<xsl:call-template name="place">
							<xsl:with-param name="lat" select="*[local-name() = 'spatial'][1]"/>
							<xsl:with-param name="long" select="*[local-name() = 'spatial'][2]"/>
						</xsl:call-template>
					</xsl:if>
				</xsl:when>
				<xsl:when test="count(*[local-name() = 'coverage']) = 2">
					<xsl:if test="*[local-name() = 'coverage'][1] castable as xs:decimal and *[local-name() = 'coverage'][2] castable as xs:decimal">
						<xsl:call-template name="place">
							<xsl:with-param name="lat" select="*[local-name() = 'coverage'][1]"/>
							<xsl:with-param name="long" select="*[local-name() = 'coverage'][2]"/>
						</xsl:call-template>
					</xsl:if>
				</xsl:when>
				<!-- handle .lat and .long qualified DC -->
				<xsl:when test="*[contains(local-name(), '.lat')] and *[contains(local-name(), '.long')]">
					<xsl:call-template name="place">
						<xsl:with-param name="lat" select="*[contains(local-name(), '.lat')][1]"/>
						<xsl:with-param name="long" select="*[contains(local-name(), '.long')][2]"/>
					</xsl:call-template>
				</xsl:when>
				<!-- handle spatial/coverage with lat,long value -->
				<xsl:when test="matches(*[local-name() = 'coverage'], '-?\d+\.\d+,-?\d+\.\d+')">
					<xsl:variable name="coords" select="*[local-name() = 'coverage'][matches(., '-?\d+\.\d+,-?\d+\.\d+')]"/>
					<xsl:analyze-string select="$coords" regex="(-?\d+\.\d+),(-?\d+\.\d+)">
						<xsl:matching-substring>
							<xsl:call-template name="place">
								<xsl:with-param name="lat" select="regex-group(1)"/>
								<xsl:with-param name="long" select="regex-group(2)"/>
							</xsl:call-template>
						</xsl:matching-substring>
					</xsl:analyze-string>
				</xsl:when>
				<xsl:when test="matches(*[local-name() = 'spatial'], '-?\d+\.\d+,-?\d+\.\d+')">
					<xsl:variable name="coords" select="*[local-name() = 'spatial'][matches(., '-?\d+\.\d+,-?\d+\.\d+')]"/>
					<xsl:analyze-string select="$coords" regex="(-?\d+\.\d+),(-?\d+\.\d+)">
						<xsl:matching-substring>
							<xsl:call-template name="place">
								<xsl:with-param name="lat" select="regex-group(1)"/>
								<xsl:with-param name="long" select="regex-group(2)"/>
							</xsl:call-template>
						</xsl:matching-substring>
					</xsl:analyze-string>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="*[local-name() = 'spatial'] | *[local-name() = 'coverage']"/>
				</xsl:otherwise>
			</xsl:choose>

			<xsl:if test="dc:description">
				<dcterms:description>
					<xsl:for-each select="dc:description[not(matches(., '.jpe?g$'))]">
						<xsl:value-of select="normalize-space(.)"/>
						<xsl:if test="not(position() = last())">
							<xsl:text> </xsl:text>
						</xsl:if>
					</xsl:for-each>
				</dcterms:description>
			</xsl:if>

			<xsl:if test="string($ark)">
				<dcterms:relation rdf:resource="{concat($production_server, $ark)}"/>
			</xsl:if>
			<dcterms:isPartOf rdf:resource="{$set}"/>
		</dpla:SourceResource>

		<!-- handle images: edm:WebResource -->
		<xsl:call-template name="resources">
			<xsl:with-param name="cho_uri" select="$cho_uri"/>
			<xsl:with-param name="content-type" select="$content-type"/>
			<xsl:with-param name="rights" select="$rights"/>
		</xsl:call-template>

		<!-- ore:Aggregation -->
		<ore:Aggregation>
			<xsl:attribute name="rdf:about" select="concat($url, 'record/', digest:md5Hex(normalize-space($cho_uri)))"/>

			<edm:aggregatedCHO rdf:resource="{$cho_uri}"/>
			<edm:isShownAt rdf:resource="{$cho_uri}"/>
			<edm:dataProvider rdf:resource="{$production_server}contact#{$repository}"/>
			<edm:provider rdf:resource="{$production_server}"/>
			<xsl:call-template name="views">
				<xsl:with-param name="cho_uri" select="$cho_uri"/>
			</xsl:call-template>
			<xsl:choose>
				<xsl:when test="$target = 'dpla'">
					<doap:audience>dpla</doap:audience>
				</xsl:when>
				<xsl:when test="$target = 'primo'">
					<doap:audience>primo</doap:audience>
				</xsl:when>
				<xsl:otherwise>
					<doap:audience>dpla</doap:audience>
					<doap:audience>primo</doap:audience>
				</xsl:otherwise>
			</xsl:choose>
			<prov:wasDerivedFrom rdf:resource="{$set}"/>
			<prov:generatedAtTime rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
				<xsl:value-of select="current-dateTime()"/>
			</prov:generatedAtTime>
		</ore:Aggregation>
	</xsl:template>

	<!-- ******
		SPECIFIC DUBLIC CORE ELEMENT TEMPLATES MUST COME BEFORE THE GENERIC DC:* TEMPLATE
		 ******-->
	<!-- RDF date/date range parsing -->
	<xsl:template match="dc:date">
		<xsl:choose>
			<xsl:when test="contains(., ';')">
				<!-- only accept first year value when they are joined by semicolons -->
				<xsl:variable name="val" select="normalize-space(tokenize(., ';')[1])"/>

				<xsl:if test="string-length($val) &gt; 0">
					<dcterms:date>
						<xsl:if test="string(harvester:date_dataType($val))">
							<xsl:attribute name="rdf:datatype">
								<xsl:value-of select="harvester:date_dataType($val)"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:value-of select="$val"/>
					</dcterms:date>
				</xsl:if>
			</xsl:when>
			<xsl:when test="contains(., '/')">
				<xsl:variable name="date-tokens" select="tokenize(., '/')"/>

				<!-- only process if there is a definite date range -->
				<xsl:if test="count($date-tokens) = 2">
					<xsl:variable name="begin" select="$date-tokens[1]"/>
					<xsl:variable name="end" select="$date-tokens[2]"/>

					<!-- only include the date range if both the begin and end dates are castable as xs date types -->
					<xsl:if
						test="($begin castable as xs:date or $begin castable as xs:gYearMonth or $begin castable as xs:gYear) and ($end castable as xs:date or $end castable as xs:gYearMonth or $end castable as xs:gYear)">
						<dcterms:date>
							<edm:TimeSpan>
								<edm:begin>
									<xsl:attribute name="rdf:datatype">
										<xsl:value-of select="harvester:date_dataType($begin)"/>
									</xsl:attribute>
								</edm:begin>
								<edm:end>
									<xsl:attribute name="rdf:datatype">
										<xsl:value-of select="harvester:date_dataType($end)"/>
									</xsl:attribute>
								</edm:end>
							</edm:TimeSpan>
						</dcterms:date>
					</xsl:if>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<dcterms:date>
					<xsl:if test="string(harvester:date_dataType(.))">
						<xsl:attribute name="rdf:datatype">
							<xsl:value-of select="harvester:date_dataType(.)"/>
						</xsl:attribute>
					</xsl:if>
					<xsl:value-of select="."/>
				</dcterms:date>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- only include rights if they are a URI -->
	<xsl:template match="dc:rights">
		<xsl:for-each select="tokenize(., ';')">
			<xsl:if test="starts-with(normalize-space(.), 'http://rightsstatements.org')">
				<dcterms:rights rdf:resource="{normalize-space(.)}"/>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<!-- evaluate languages, ensure they are valid to xs:lanugate -->
	<xsl:template match="dc:language">
		<xsl:for-each select="tokenize(., ';')">
			<xsl:if test="string-length(normalize-space(.)) &gt; 0">
				<dcterms:language>
					<xsl:value-of select="lower-case(normalize-space(.))"/>
				</dcterms:language>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<!-- geographic -->
	<xsl:template name="place">
		<xsl:param name="lat"/>
		<xsl:param name="long"/>

		<dcterms:coverage>
			<edm:Place>
				<geo:lat>
					<xsl:value-of select="$lat"/>
				</geo:lat>
				<geo:long>
					<xsl:value-of select="$long"/>
				</geo:long>
			</edm:Place>
		</dcterms:coverage>

	</xsl:template>

	<!-- normalize to DCMI types -->
	<xsl:template match="dc:type">
		<xsl:for-each select="tokenize(., ';')">
			<xsl:variable name="val" select="lower-case(normalize-space(.))"/>

			<xsl:if test="string-length($val) &gt; 0">
				<xsl:variable name="type">
					<xsl:choose>
						<xsl:when test="$val = 'collection'">http://purl.org/dc/dcmitype/Collection</xsl:when>
						<xsl:when test="$val = 'dataset'">http://purl.org/dc/dcmitype/Dataset</xsl:when>
						<xsl:when test="$val = 'event'">http://purl.org/dc/dcmitype/Event</xsl:when>
						<xsl:when test="$val = 'image'">http://purl.org/dc/dcmitype/Image</xsl:when>
						<xsl:when test="$val = 'interactiveresource'">http://purl.org/dc/dcmitype/InteractiveResource</xsl:when>
						<xsl:when test="$val = 'movingimage'">http://purl.org/dc/dcmitype/MovingImage</xsl:when>
						<xsl:when test="$val = 'physicalobject'">http://purl.org/dc/dcmitype/PhysicalObject</xsl:when>
						<xsl:when test="$val = 'service'">>http://purl.org/dc/dcmitype/Service</xsl:when>
						<xsl:when test="$val = 'software'">http://purl.org/dc/dcmitype/Software</xsl:when>
						<xsl:when test="$val = 'sound'">http://purl.org/dc/dcmitype/Sound</xsl:when>
						<xsl:when test="$val = 'stillimage'">http://purl.org/dc/dcmitype/StillImage</xsl:when>
						<xsl:when test="$val = 'text'">http://purl.org/dc/dcmitype/Text</xsl:when>
					</xsl:choose>
				</xsl:variable>

				<xsl:if test="string($type)">
					<dcterms:type rdf:resource="{$type}"/>
				</xsl:if>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<!-- ******
		GENERIC DC:* HANDLING
		 ******-->

	<xsl:template match="dc:*">
		<!-- handle multiple terms joined by semicolons -->
		<xsl:variable name="property" select="local-name()"/>
		<xsl:for-each select="tokenize(normalize-space(.), ';')">
			<!-- ignore 0 length strings -->
			<xsl:if test="string-length(normalize-space(.)) &gt; 0">
				<!-- conditionals for ignoring or processing specific properties differently -->
				<xsl:choose>
					<xsl:when test="$property = 'format'">
						<!-- suppress content types -->
						<xsl:if test="not(contains(., '/'))">
							<xsl:element name="dcterms:{$property}" namespace="http://purl.org/dc/terms/">
								<xsl:value-of select="normalize-space(.)"/>
							</xsl:element>
							<xsl:element name="edm:hasType" namespace="http://www.europeana.eu/schemas/edm/">placeholder for AAT URI</xsl:element>
						</xsl:if>
					</xsl:when>
					<xsl:otherwise>
						<xsl:element name="dcterms:{$property}" namespace="http://purl.org/dc/terms/">
							<!-- normalization -->
							<xsl:choose>
								<xsl:when test="$property = 'subject'">
									<xsl:variable name="label" select="normalize-space(.)"/>

									<xsl:choose>
										<xsl:when test="$subjects//atom:entry[gsx:label = $label]">
											<xsl:attribute name="rdf:resource" select="$subjects//atom:entry[gsx:label = $label]/gsx:uri"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="normalize-space(.)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:when test="$property = 'spatial' or $property = 'coverage'">
									<xsl:variable name="label" select="normalize-space(.)"/>

									<xsl:choose>
										<xsl:when test="$places//atom:entry[gsx:label = $label]">
											<xsl:attribute name="rdf:resource" select="$places//atom:entry[gsx:label = $label]/gsx:uri"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="normalize-space(.)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="normalize-space(.)"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:element>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<!-- edm:WebResource -->
	<xsl:template name="resources">
		<xsl:param name="cho_uri"/>
		<xsl:param name="content-type"/>
		<xsl:param name="rights"/>

		<xsl:choose>
			<!-- contentDM institutions -->
			<xsl:when test="$repository = 'waps' or $repository = 'idbb' or $repository = 'US-ula' or $repository = 'US-uuml' or $repository = 'wauar' or $repository = 'wabewwuh'">
				<!-- get thumbnail -->
				<edm:WebResource rdf:about="{replace($cho_uri, 'cdm/ref', 'utils/getthumbnail')}">
					<xsl:if test="string-length($content-type) &gt; 0">
						<dcterms:format>
							<xsl:value-of select="$content-type"/>
						</dcterms:format>
					</xsl:if>
					<xsl:if test="string($rights)">
						<edm:rights rdf:resource="{$rights}"/>
					</xsl:if>
				</edm:WebResource>
				<edm:WebResource rdf:about="{replace($cho_uri, 'cdm/ref', 'utils/getstream')}">
					<xsl:if test="string-length($content-type) &gt; 0">
						<dcterms:format>
							<xsl:value-of select="$content-type"/>
						</dcterms:format>
					</xsl:if>
					<xsl:if test="string($rights)">
						<edm:rights rdf:resource="{$rights}"/>
					</xsl:if>
				</edm:WebResource>
			</xsl:when>
			<!-- University of Montana -->
			<xsl:when test="$repository = 'mtu'">
				<xsl:if test="dc:description[matches(., '.jpg$')]">
					<edm:WebResource rdf:about="{dc:description[matches(., '.jpg$')]}">
						<xsl:if test="string-length($content-type) &gt; 0">
							<dcterms:format>
								<xsl:value-of select="$content-type"/>
							</dcterms:format>
						</xsl:if>
						<xsl:if test="string($rights)">
							<edm:rights rdf:resource="{$rights}"/>
						</xsl:if>
					</edm:WebResource>
				</xsl:if>
			</xsl:when>
			<!-- Omeka -->
			<xsl:when test="$repository = 'orphs'">
				<xsl:if test="dc:identifier[matches(., '.jpg$')]">
					<edm:WebResource rdf:about="{dc:identifier[matches(., '.jpg$')]}">
						<xsl:if test="string-length($content-type) &gt; 0">
							<dcterms:format>
								<xsl:value-of select="$content-type"/>
							</dcterms:format>
						</xsl:if>
						<xsl:if test="string($rights)">
							<edm:rights rdf:resource="{$rights}"/>
						</xsl:if>
					</edm:WebResource>
				</xsl:if>
			</xsl:when>
			<!-- Willamette - contentDM but with different CHO URI style -->
			<xsl:when test="$repository = 'orsaw'">
				<!-- get thumbnail -->
				<edm:WebResource rdf:about="{replace($cho_uri, 'cview/archives.html#!doc:page:(.*)/(.*)', 'utils/getthumbnail/collection/$1/id/$2')}">
					<xsl:if test="string-length($content-type) &gt; 0">
						<dcterms:format>
							<xsl:value-of select="$content-type"/>
						</dcterms:format>
					</xsl:if>
					<xsl:if test="string($rights)">
						<edm:rights rdf:resource="{$rights}"/>
					</xsl:if>
				</edm:WebResource>
				<edm:WebResource rdf:about="{replace($cho_uri, 'cview/archives.html#!doc:page:(.*)/(.*)', 'utils/getstream/collection/$1/id/$2')}">
					<xsl:if test="string-length($content-type) &gt; 0">
						<dcterms:format>
							<xsl:value-of select="$content-type"/>
						</dcterms:format>
					</xsl:if>
					<xsl:if test="string($rights)">
						<edm:rights rdf:resource="{$rights}"/>
					</xsl:if>
				</edm:WebResource>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- views -->
	<xsl:template name="views">
		<xsl:param name="cho_uri"/>
		<xsl:choose>
			<!-- contentDM institutions -->
			<xsl:when
				test="$repository = 'waps' or $repository = 'idbb' or $repository = 'US-ula' or $repository = 'US-uuml' or $repository = 'wauar' or $repository = 'wabewwuh' or $repository = 'xxx'">
				<!-- get thumbnail -->
				<edm:preview rdf:resource="{replace($cho_uri, 'cdm/ref', 'utils/getthumbnail')}"/>
				<edm:object rdf:resource="{replace($cho_uri, 'cdm/ref', 'utils/getstream')}"/>
			</xsl:when>
			<!-- University of Montana -->
			<xsl:when test="$repository = 'mtu'">
				<xsl:if test="dc:description[contains(., '.jpg')]">
					<edm:preview rdf:resource="{dc:description[contains(., '.jpg')]}"/>
				</xsl:if>
			</xsl:when>
			<!-- Omeka -->
			<xsl:when test="$repository = 'orphs'">
				<xsl:if test="dc:identifier[matches(., '.jpg$')]">
					<edm:preview rdf:resource="{dc:identifier[matches(., '.jpg$')]}"/>
				</xsl:if>
			</xsl:when>
			<!-- Willamette - contentDM but with different CHO URI style -->
			<xsl:when test="$repository = 'orsaw'">
				<!-- get thumbnail -->
				<edm:preview rdf:resource="{replace($cho_uri, 'cview/archives.html#!doc:page:(.*)/(.*)', 'utils/getthumbnail/collection/$1/id/$2')}"/>
				<edm:object rdf:resource="{replace($cho_uri, 'cview/archives.html#!doc:page:(.*)/(.*)', 'utils/getstream/collection/$1/id/$2')}"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="recurse">
		<xsl:param name="token"/>
		<xsl:param name="set"/>

		<xsl:variable name="oai" as="node()*">
			<xsl:copy-of select="document(concat($set, '?verb=ListRecords&amp;resumptionToken=', $token))"/>
		</xsl:variable>

		<xsl:choose>
			<xsl:when test="string($ark)">
				<xsl:apply-templates select="$oai/descendant::oai:metadata/*[dc:relation[contains(., $ark)]]"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="$oai/descendant::oai:metadata/*[dc:relation[contains(., 'ark:/')]]"/>
			</xsl:otherwise>
		</xsl:choose>

		<xsl:if test="$oai/descendant::oai:resumptionToken">
			<xsl:call-template name="recurse">
				<xsl:with-param name="token" select="$oai/descendant::oai:resumptionToken"/>
				<xsl:with-param name="set" select="$set"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<!-- FUNCTIONS -->
	<xsl:function name="harvester:date_dataType">
		<xsl:param name="val"/>

		<xsl:choose>
			<xsl:when test="$val castable as xs:dateTime">http://www.w3.org/2001/XMLSchema#dateTime</xsl:when>
			<xsl:when test="$val castable as xs:date">http://www.w3.org/2001/XMLSchema#date</xsl:when>
			<xsl:when test="$val castable as xs:gYearMonth">http://www.w3.org/2001/XMLSchema#gYearMonth</xsl:when>
			<xsl:when test="$val castable as xs:gYear">http://www.w3.org/2001/XMLSchema#gYear</xsl:when>
		</xsl:choose>
	</xsl:function>

</xsl:stylesheet>
