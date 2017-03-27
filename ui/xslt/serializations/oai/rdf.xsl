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

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:oai="http://www.openarchives.org/OAI/2.0/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:dpla="http://dp.la/terms/"
	xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:foaf="http://xmlns.com/foaf/0.1/"
	xmlns:edm="http://www.europeana.eu/schemas/edm/" xmlns:ore="http://www.openarchives.org/ore/terms/" xmlns:atom="http://www.w3.org/2005/Atom"
	xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/" xmlns:prov="http://www.w3.org/ns/prov#" xmlns:doap="http://usefulinc.com/ns/doap#"
	xmlns:gsx="http://schemas.google.com/spreadsheets/2006/extended" xmlns:harvester="https://github.com/Orbis-Cascade-Alliance/harvester"
	xmlns:digest="org.apache.commons.codec.digest.DigestUtils" xmlns:res="http://www.w3.org/2005/sparql-results#"
	exclude-result-prefixes="oai_dc oai xs harvester atom openSearch gsx digest res" version="2.0">
	<xsl:output indent="yes" encoding="UTF-8"/>

	<!-- request parameters -->
	<xsl:param name="mode" select="doc('input:request')/request/parameters/parameter[name = 'mode']/value"/>
	<xsl:param name="output" select="doc('input:request')/request/parameters/parameter[name = 'output']/value"/>
	<xsl:param name="set" select="normalize-space(doc('input:request')/request/parameters/parameter[name = 'sets']/value)"/>
	<xsl:param name="repository" select="doc('input:request')/request/parameters/parameter[name = 'repository']/value"/>
	<xsl:param name="ark" select="doc('input:request')/request/parameters/parameter[name = 'ark']/value"/>
	<xsl:param name="target" select="doc('input:request')/request/parameters/parameter[name = 'target']/value"/>
	<xsl:param name="rightsStatement" select="doc('input:request')/request/parameters/parameter[name = 'rights']/value"/>
	<xsl:param name="rightsText" select="doc('input:request')/request/parameters/parameter[name = 'rightsText']/value"/>
	<xsl:param name="type" select="doc('input:request')/request/parameters/parameter[name = 'type']/value"/>
	<xsl:param name="format" select="doc('input:request')/request/parameters/parameter[name = 'format']/value"/>
	<xsl:param name="genre" select="doc('input:request')/request/parameters/parameter[name = 'genre']/value"/>
	<xsl:param name="language" select="doc('input:request')/request/parameters/parameter[name = 'language']/value"/>

	<!-- config variables -->
	<xsl:param name="url" select="/content/config/url"/>
	<xsl:param name="production_server" select="/content/config/production_server"/>
	<xsl:param name="sparql_endpoint" select="/content/config/vocab_sparql/query"/>
	<xsl:variable name="repo_uri">
		<xsl:choose>
			<xsl:when test="/content/config/codes/repository[@marc=$repository]/@harvester-only='true'">
				<xsl:value-of select="concat('http://harvester.orbiscascade.org/agency/', $repository)"/>
			</xsl:when>
			<xsl:otherwise>				
				<xsl:value-of select="concat($production_server, 'contact#', $repository)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<!-- break down information about the OAI-PMH service -->
	<xsl:variable name="oai_service" select="/content/oai:OAI-PMH/oai:request"/>
	<xsl:variable name="setSpec" select="/content/oai:OAI-PMH/oai:request/@set"/>

	<!-- load controlled vocabulary lists from SPARQL -->
	<xsl:variable name="sparqlQuery-template"><![CDATA[PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dcterms:	<http://purl.org/dc/terms/>
PREFIX dcam:	<http://purl.org/dc/dcam/>
PREFIX edm:	<http://www.europeana.eu/schemas/edm/>
PREFIX xsd:	<http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs:	<http://www.w3.org/2000/01/rdf-schema#>
PREFIX skos:	<http://www.w3.org/2004/02/skos/core#>

SELECT ?label ?uri WHERE {
?s dcterms:source "%REPO%" ;
rdf:type %TYPE%;
skos:exactMatch ?uri ;
rdfs:label ?label
}]]></xsl:variable>

	<xsl:variable name="genre-query" select="replace(replace($sparqlQuery-template, '%REPO%', $repository), '%TYPE%', 'skos:Concept')"/>
	<xsl:variable name="agent-query" select="replace(replace($sparqlQuery-template, '%REPO%', $repository), '%TYPE%', 'edm:Agent')"/>
	<xsl:variable name="place-query" select="replace(replace($sparqlQuery-template, '%REPO%', $repository), '%TYPE%', 'edm:Place')"/>

	<xsl:variable name="genres" as="node()*">
		<types>
			<xsl:copy-of select="document(concat($sparql_endpoint, '?query=', encode-for-uri($genre-query), '&amp;output=xml'))//res:result"/>
		</types>
	</xsl:variable>

	<xsl:variable name="agents" as="node()*">
		<agents>
			<xsl:copy-of select="document(concat($sparql_endpoint, '?query=', encode-for-uri($agent-query), '&amp;output=xml'))//res:result"/>
		</agents>
	</xsl:variable>

	<xsl:variable name="places" as="node()*">
		<places>
			<xsl:copy-of select="document(concat($sparql_endpoint, '?query=', encode-for-uri($place-query), '&amp;output=xml'))//res:result"/>
		</places>
	</xsl:variable>

	<xsl:variable name="languages" as="element()*">
		<languages>
			<xsl:copy-of select="document('oxf:/apps/harvester/xforms/instances/languages.xml')//language"/>
		</languages>
	</xsl:variable>

	<xsl:variable name="dams" select="/content/config/dams//repository[. = $repository][contains($set, @pattern)]/parent::node()/name()"/>

	<xsl:template match="/">
		<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"
			xmlns:ore="http://www.openarchives.org/ore/terms/" xmlns:xsd="http://www.w3.org/2001/XMLSchema#" xmlns:edm="http://www.europeana.eu/schemas/edm/"
			xmlns:dpla="http://dp.la/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:prov="http://www.w3.org/ns/prov#"
			xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
			xmlns:doap="http://usefulinc.com/ns/doap#">

			<!-- generate triples for describing the set, but not for GetRecord -->
			<xsl:if test="not(contains($set, 'GetRecord'))">
				<xsl:variable name="setNode" as="element()*">
					<xsl:copy-of select="document(concat($oai_service, '?verb=ListSets'))//oai:set[oai:setSpec = $setSpec]"/>
				</xsl:variable>

				<dcmitype:Collection rdf:about="{$set}">
					<dcterms:title>
						<xsl:value-of select="$setNode/oai:setName"/>
					</dcterms:title>
					<xsl:if test="$setNode/oai:setDescription">
						<dcterms:description>
							<xsl:value-of select="$setNode/oai:setDescription"/>
						</dcterms:description>
					</xsl:if>
					<dcterms:publisher rdf:resource="{$repo_uri}"/>
				</dcmitype:Collection>
			</xsl:if>

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
				<xsl:if test="descendant::oai:resumptionToken[string-length(normalize-space(.)) &gt; 0]">
					<xsl:call-template name="recurse">
						<xsl:with-param name="token" select="descendant::oai:resumptionToken"/>
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
				<xsl:when test="matches($cho_uri, '\.(jpe?g|tif|pdf)$')"/>
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
				<xsl:analyze-string select="normalize-space(dc:format[contains(., '/')][1])" regex="(^[a-z]+/[^\s]+$)">
					<xsl:matching-substring>
						<xsl:choose>
							<xsl:when test="regex-group(1) = 'image/jpg'">
								<xsl:text>image/jpeg</xsl:text>
							</xsl:when> 
							<xsl:otherwise>
								<xsl:value-of select="regex-group(1)"/>
							</xsl:otherwise>
						</xsl:choose>						
					</xsl:matching-substring>
				</xsl:analyze-string>
			</xsl:if>
		</xsl:variable>

		<dpla:SourceResource rdf:about="{$cho_uri}">
			<dcterms:title>
				<xsl:value-of select="dc:title"/>
			</dcterms:title>

			<!-- apply generic DC templates -->
			<xsl:apply-templates select="dc:date[1] | dc:creator | dc:contributor | dc:rights | dc:subject | dc:format | dc:extent | dc:temporal"/>

			<!-- conditionals for parameters passed from remediation page -->
			<xsl:if test="string($genre)">
				<edm:hasType rdf:resource="{$genre}"/>
			</xsl:if>
			<xsl:if test="string($type)">
				<dcterms:type rdf:resource="{concat('http://purl.org/dc/dcmitype/', $type)}"/>
			</xsl:if>
			<xsl:apply-templates select="dc:type"/>

			<xsl:choose>
				<xsl:when test="string($language)">
					<dcterms:language>
						<xsl:value-of select="$language"/>
					</dcterms:language>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="dc:language"/>
				</xsl:otherwise>
			</xsl:choose>

			<xsl:if test="string($rightsStatement)">
				<dcterms:rights rdf:resource="{concat('http://rightsstatements.org/vocab/', $rightsStatement, '/1.0/')}"/>
			</xsl:if>

			<xsl:if test="string(normalize-space($rightsText))">
				<dcterms:rights>
					<xsl:value-of select="normalize-space($rightsText)"/>
				</dcterms:rights>
			</xsl:if>

			<!-- process spatial fields -->
			<xsl:if test="*[contains(local-name(), '.lat')] and *[contains(local-name(), '.long')]">
				<xsl:call-template name="place">
					<xsl:with-param name="lat" select="*[contains(local-name(), '.lat')][1]"/>
					<xsl:with-param name="long" select="*[contains(local-name(), '.long')][2]"/>
				</xsl:call-template>
			</xsl:if>

			<xsl:apply-templates select="*[local-name() = 'spatial'] | *[local-name() = 'coverage']"/>

			<!-- process descriptions that are not image URLs -->
			<xsl:if test="dc:description[not(matches(., '.jpe?g$'))]">
				<dcterms:description>
					<xsl:for-each select="dc:description[not(matches(., '.jpe?g$'))]">
						<xsl:value-of select="harvester:cleanText(normalize-space(.), local-name())"/>
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
		</xsl:call-template>

		<!-- ore:Aggregation -->
		<ore:Aggregation>
			<xsl:attribute name="rdf:about" select="concat($url, 'record/', digest:md5Hex(normalize-space($cho_uri)))"/>

			<edm:aggregatedCHO rdf:resource="{$cho_uri}"/>
			<edm:isShownAt rdf:resource="{$cho_uri}"/>
			<edm:dataProvider rdf:resource="{$repo_uri}"/>
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
						<xsl:value-of select="harvester:parseDateTime($val)"/>
					</dcterms:date>
				</xsl:if>
			</xsl:when>
			<xsl:when test="contains(., '/')">
				<xsl:variable name="date-tokens" select="tokenize(., '/')"/>

				<!-- only process if there is a definite date range -->
				<xsl:if test="count($date-tokens) = 2">
					<xsl:variable name="begin" select="normalize-space($date-tokens[1])"/>
					<xsl:variable name="end" select="normalize-space($date-tokens[2])"/>

					<!-- only include the date range if both the begin and end dates are castable as xs date types -->
					<xsl:if
						test="($begin castable as xs:date or $begin castable as xs:gYearMonth or $begin castable as xs:gYear) and ($end castable as xs:date or $end castable as xs:gYearMonth or $end castable as xs:gYear)">
						<dcterms:date>
							<edm:TimeSpan>
								<edm:begin>
									<xsl:attribute name="rdf:datatype">
										<xsl:value-of select="harvester:date_dataType($begin)"/>
									</xsl:attribute>
									<xsl:value-of select="harvester:parseDateTime($begin)"/>
								</edm:begin>
								<edm:end>
									<xsl:attribute name="rdf:datatype">
										<xsl:value-of select="harvester:date_dataType($end)"/>
									</xsl:attribute>
									<xsl:value-of select="harvester:parseDateTime($end)"/>
								</edm:end>
							</edm:TimeSpan>
						</dcterms:date>
					</xsl:if>
				</xsl:if>
			</xsl:when>
			<xsl:when test="matches(., '\d{4}\s?-\s?\d{4}')">
				<xsl:variable name="date-tokens" select="tokenize(., '-')"/>

				<!-- only process if there is a definite date range -->
				<xsl:if test="count($date-tokens) = 2">
					<xsl:variable name="begin" select="normalize-space($date-tokens[1])"/>
					<xsl:variable name="end" select="normalize-space($date-tokens[2])"/>

					<!-- only include the date range if both the begin and end dates are castable as xs date types -->
					<xsl:if
						test="($begin castable as xs:date or $begin castable as xs:gYearMonth or $begin castable as xs:gYear) and ($end castable as xs:date or $end castable as xs:gYearMonth or $end castable as xs:gYear)">
						<dcterms:date>
							<edm:TimeSpan>
								<edm:begin>
									<xsl:attribute name="rdf:datatype">
										<xsl:value-of select="harvester:date_dataType($begin)"/>
									</xsl:attribute>
									<xsl:value-of select="harvester:parseDateTime($begin)"/>
								</edm:begin>
								<edm:end>
									<xsl:attribute name="rdf:datatype">
										<xsl:value-of select="harvester:date_dataType($end)"/>
									</xsl:attribute>
									<xsl:value-of select="harvester:parseDateTime($end)"/>
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
					<xsl:value-of select="harvester:parseDateTime(.)"/>
				</dcterms:date>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- parse rights. Always include textual statement if available -->
	<xsl:template match="dc:rights">
		<xsl:choose>
			<xsl:when test="matches(., '^https?://') and not(contains(., ' ')) and not(string($rightsStatement))">
				<dcterms:rights>
					<xsl:attribute name="rdf:resource" select="normalize-space(.)"/>
				</dcterms:rights>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="not(string(normalize-space($rightsText)))">
					<dcterms:rights>
						<xsl:value-of select="harvester:cleanText(normalize-space(.), 'rights')"/>
					</dcterms:rights>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- evaluate languages, ensure they are valid to xs:lanugate -->
	<xsl:template match="dc:language">
		<xsl:for-each select="tokenize(., ';')">
			<xsl:if test="string-length(normalize-space(.)) &gt; 0">
				<xsl:variable name="val" select="lower-case(normalize-space(.))"/>

				<xsl:choose>
					<!-- if 3 characters, assume it is the correct code -->
					<xsl:when test="string-length($val) = 3">
						<xsl:if test="$languages//language[code = $val]">
							<dcterms:language>
								<xsl:value-of select="$val"/>
							</dcterms:language>
						</xsl:if>

					</xsl:when>
					<!-- when it is too characters, look up the 3 letter code -->
					<xsl:when test="string-length($val) = 2">
						<xsl:if test="$languages//language[twoLetter = $val]">
							<dcterms:language>
								<xsl:value-of select="$languages//language[twoLetter = $val]/code"/>
							</dcterms:language>
						</xsl:if>
					</xsl:when>
					<xsl:otherwise>
						<xsl:if test="$languages//language[lower-case(name) = $val]">
							<dcterms:language>
								<xsl:value-of select="$languages//language[lower-case(name) = $val][1]/code"/>
							</dcterms:language>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="*[local-name() = 'coverage'] | *[local-name() = 'spatial']">
		<xsl:variable name="element" select="local-name()"/>
		<xsl:variable name="val" select="normalize-space(.)"/>


		<xsl:choose>
			<xsl:when test="matches($val, '-?\d+\.\d+,\s?-?\d+\.\d+')">
				<xsl:analyze-string select="$val" regex="(-?\d+\.\d+),\s?(-?\d+\.\d+)">
					<xsl:matching-substring>
						<xsl:call-template name="place">
							<xsl:with-param name="lat" select="regex-group(1)"/>
							<xsl:with-param name="long" select="regex-group(2)"/>
						</xsl:call-template>
					</xsl:matching-substring>
				</xsl:analyze-string>
			</xsl:when>
			<xsl:when test="$val castable as xs:decimal">
				<!-- if this element is a decimal and a following sibling is also a decimal, this is a lat and the other is a long -->
				<xsl:if test="following-sibling::*[local-name() = $element][normalize-space(text()) castable as xs:decimal]">
					<xsl:choose>
						<xsl:when test="$dams = 'digital-commons'">
							<xsl:call-template name="place">
								<xsl:with-param name="lat" select="$val"/>
								<xsl:with-param name="long"
									select="following-sibling::*[local-name() = $element][normalize-space(text()) castable as xs:decimal][1]"/>
							</xsl:call-template>
						</xsl:when>
					</xsl:choose>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="pieces" select="tokenize($val, ';')"/>

				<xsl:for-each select="$pieces">
					<xsl:variable name="label" select="harvester:cleanText(normalize-space(.), $element)"/>

					<dcterms:spatial>
						<xsl:choose>
							<xsl:when test="$places//res:result[res:binding[@name = 'label']/res:literal = $label]">
								<xsl:attribute name="rdf:resource"
									select="$places//res:result[res:binding[@name = 'label']/res:literal = $label]/res:binding[@name = 'uri']/res:uri"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$label"/>
							</xsl:otherwise>
						</xsl:choose>
					</dcterms:spatial>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- geographic -->
	<xsl:template name="place">
		<xsl:param name="lat"/>
		<xsl:param name="long"/>

		<dcterms:spatial>
			<edm:Place>
				<geo:lat>
					<xsl:value-of select="$lat"/>
				</geo:lat>
				<geo:long>
					<xsl:value-of select="$long"/>
				</geo:long>
			</edm:Place>
		</dcterms:spatial>
	</xsl:template>

	<!-- normalize to DCMI types -->
	<xsl:template match="dc:type">
		<xsl:for-each select="tokenize(., ';')">
			<xsl:variable name="val" select="lower-case(normalize-space(.))"/>

			<xsl:if test="string-length($val) &gt; 0">
				<xsl:variable name="typeURI">
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

				<xsl:choose>
					<xsl:when test="string($typeURI)">
						<!-- only display types when they aren't provided by the remediation -->
						<xsl:if test="not(string($type))">
							<dcterms:type rdf:resource="{$typeURI}"/>
						</xsl:if>
					</xsl:when>
					<xsl:otherwise>
						<!-- only display genres when they aren't provided by the remediation -->
						<xsl:if test="not(string($genre))">
							<edm:hasType>
								<xsl:variable name="norm" select="normalize-space(.)"/>

								<xsl:choose>
									<xsl:when test="$genres//res:result[res:binding[@name = 'label']/res:literal = $norm]">
										<xsl:attribute name="rdf:resource"
											select="$genres//res:result[res:binding[@name = 'label']/res:literal = $norm]/res:binding[@name = 'uri']/res:uri"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="harvester:cleanText(normalize-space(.), 'type')"/>
									</xsl:otherwise>
								</xsl:choose>
							</edm:hasType>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
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
				<xsl:variable name="val" select="harvester:cleanText(normalize-space(.), $property)"/>
				<!-- conditionals for ignoring or processing specific properties differently -->
				<xsl:choose>
					<xsl:when test="$property = 'creator' or $property = 'contributor'">
						<xsl:if test="not(contains(lower-case($val), 'unknown'))">
							<xsl:element name="dcterms:{$property}" namespace="http://purl.org/dc/terms/">
								<xsl:choose>
									<xsl:when test="$agents//res:result[res:binding[@name = 'label']/res:literal = $val]">
										<xsl:attribute name="rdf:resource"
											select="$agents//res:result[res:binding[@name = 'label']/res:literal = $val]/res:binding[@name = 'uri']/res:uri"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$val"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:element>
						</xsl:if>
					</xsl:when>
					<!-- ignore format for now -->
					<xsl:when test="$property = 'format'">
						<!-- ignore mime types in the CHO -->
						<xsl:if test="not(matches(., '^[a-z]+/[^\s]+$'))">
							<!-- convert to extent -->
							<xsl:choose>
								<xsl:when test="matches(., '\d+\s?[x|X]\s?\d+')">
									<!-- pattern for dimensions -->
									<dcterms:extent>
										<xsl:value-of select="."/>
									</dcterms:extent>
								</xsl:when>
								<xsl:when test="contains(., 'second') or contains(., 'minute')">
									<!-- audio/video -->
									<dcterms:extent>
										<xsl:value-of select="."/>
									</dcterms:extent>
								</xsl:when>
							</xsl:choose>
						</xsl:if>
					</xsl:when>
					<xsl:otherwise>
						<xsl:element name="dcterms:{$property}" namespace="http://purl.org/dc/terms/">
							<!-- normalization -->
							<xsl:choose>
								<xsl:when test="$property = 'subject'">
									<xsl:variable name="label" select="$val"/>

									<!--<xsl:choose>
										<xsl:when test="$subjects//atom:entry[gsx:label = $label]">
											<xsl:attribute name="rdf:resource" select="$subjects//atom:entry[gsx:label = $label]/gsx:uri"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="$val"/>
										</xsl:otherwise>
									</xsl:choose>-->
									<xsl:value-of select="$val"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$val"/>
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

		<!-- process by default DAMS -->
		<xsl:choose>
			<xsl:when test="$dams = 'contentdm-default'">
				<edm:WebResource rdf:about="{replace($cho_uri, 'cdm/ref', 'utils/getthumbnail')}">
					<dcterms:format>image/jpeg</dcterms:format>
				</edm:WebResource>
				<edm:WebResource rdf:about="{replace($cho_uri, 'cdm/ref', 'utils/getstream')}">
					<xsl:choose>
						<xsl:when test="string($format)">
							<dcterms:format>
								<xsl:value-of select="$format"/>
							</dcterms:format>
						</xsl:when>
						<xsl:otherwise>
							<xsl:if test="string-length($content-type) &gt; 0">
								<dcterms:format>
									<xsl:value-of select="$content-type"/>
								</dcterms:format>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
				</edm:WebResource>
			</xsl:when>
			<xsl:when test="$dams = 'oregondigital'">
				<xsl:variable name="filename" select="substring-after(tokenize($cho_uri, '/')[last()], ':')"/>

				<edm:WebResource rdf:about="http://oregondigital.org/thumbnails/oregondigital-{$filename}.jpg">
					<dcterms:format>image/jpeg</dcterms:format>
				</edm:WebResource>
				<edm:WebResource rdf:about="http://oregondigital.org/downloads/oregondigital:{$filename}">
					<xsl:if test="$content-type = 'image/tiff'">
						<dcterms:format>image/jpeg</dcterms:format>
					</xsl:if>
				</edm:WebResource>
			</xsl:when>
			<xsl:when test="$dams = 'digital-commons'">
				<xsl:if test="dc:description[matches(., '.jpg$')]">
					<edm:WebResource rdf:about="{dc:description[matches(., '.jpg$')]}">
						<dcterms:format>image/jpeg</dcterms:format>
					</edm:WebResource>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$dams = 'dspace'">
				<!-- dspace does not include links to files -->
			</xsl:when>
			<xsl:when test="$dams = 'omeka'">
				<xsl:if test="dc:identifier[contains(., 'files/original')]">
					<edm:WebResource rdf:about="{dc:identifier[contains(., 'files/original')]}">
						<xsl:if test="string-length($content-type) &gt; 0">
							<dcterms:format>
								<xsl:value-of select="$content-type"/>
							</dcterms:format>
						</xsl:if>
					</edm:WebResource>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<!-- individual repository logic -->
				<xsl:choose>
					<xsl:when test="$repository = 'orphs'">
						<xsl:if test="dc:identifier[matches(., '.jpg$')]">
							<edm:WebResource rdf:about="{dc:identifier[matches(., '.jpg$')]}">
								<dcterms:format>image/jpeg</dcterms:format>
							</edm:WebResource>
						</xsl:if>
					</xsl:when>
					<!-- Willamette - contentDM but with different CHO URI style -->
					<xsl:when test="$repository = 'orsaw'">
						<edm:WebResource rdf:about="{replace($cho_uri, 'cview/archives.html#!doc:page:(.*)/(.*)', 'utils/getthumbnail/collection/$1/id/$2')}">
							<dcterms:format>image/jpeg</dcterms:format>
						</edm:WebResource>
						<edm:WebResource rdf:about="{replace($cho_uri, 'cview/archives.html#!doc:page:(.*)/(.*)', 'utils/getstream/collection/$1/id/$2')}">
							<xsl:choose>
								<xsl:when test="string($format)">
									<dcterms:format>
										<xsl:value-of select="$format"/>
									</dcterms:format>
								</xsl:when>
								<xsl:otherwise>
									<xsl:if test="string-length($content-type) &gt; 0">
										<dcterms:format>
											<xsl:value-of select="$content-type"/>
										</dcterms:format>
									</xsl:if>
								</xsl:otherwise>
							</xsl:choose>
						</edm:WebResource>
					</xsl:when>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- views -->
	<xsl:template name="views">
		<xsl:param name="cho_uri"/>

		<xsl:choose>
			<xsl:when test="$dams = 'contentdm-default'">
				<edm:preview rdf:resource="{replace($cho_uri, 'cdm/ref', 'utils/getthumbnail')}"/>
				<edm:object rdf:resource="{replace($cho_uri, 'cdm/ref', 'utils/getstream')}"/>
			</xsl:when>
			<xsl:when test="$dams = 'digital-commons'">
				<xsl:if test="dc:description[matches(., '.jpg$')]">
					<edm:preview rdf:resource="{dc:description[matches(., '.jpg$')]}"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$dams = 'dspace'">
				<!-- dspace does not include links to files -->
			</xsl:when>
			<xsl:when test="$dams = 'omeka'">
				<xsl:if test="dc:identifier[contains(., 'files/original')]">
					<edm:object rdf:resource="{dc:identifier[contains(., 'files/original')]}"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$dams = 'oregondigital'">
				<xsl:variable name="filename" select="substring-after(tokenize($cho_uri, '/')[last()], ':')"/>

				<edm:preview rdf:resource="http://oregondigital.org/thumbnails/oregondigital-{$filename}.jpg"/>
				<edm:object rdf:resource="http://oregondigital.org/downloads/oregondigital:{$filename}"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
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
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="recurse">
		<xsl:param name="token"/>

		<xsl:variable name="oai" as="node()*">
			<xsl:copy-of select="document(concat($oai_service, '?verb=ListRecords&amp;resumptionToken=', encode-for-uri($token)))"/>
		</xsl:variable>

		<xsl:apply-templates select="$oai/descendant::oai:record[not(oai:header/@status = 'deleted')]"/>

		<xsl:if test="$oai/descendant::oai:resumptionToken[string-length(normalize-space(.)) &gt; 0]">
			<xsl:call-template name="recurse">
				<xsl:with-param name="token" select="$oai/descendant::oai:resumptionToken"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<!-- FUNCTIONS -->
	<xsl:function name="harvester:cleanText">
		<xsl:param name="val"/>
		<xsl:param name="element"/>

		<xsl:variable name="html-stripped" select="replace(replace($val, '&lt;[^&gt;]+&gt;', ' '), '\\s+', ' ')"/>

		<xsl:choose>
			<xsl:when test="$element = 'subject' or $element = 'creator' or $element = 'contributor' or $element = 'spatial' or $element = 'coverage'">
				<!-- do not strip trailing period from these elements -->
				<xsl:value-of select="$html-stripped"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<!-- strip trailing period -->
					<xsl:when test="substring($html-stripped, string-length($html-stripped), 1) = '.'">
						<xsl:value-of select="substring($html-stripped, 1, string-length($html-stripped) - 1)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$html-stripped"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:function>

	<xsl:function name="harvester:date_dataType">
		<xsl:param name="val"/>

		<xsl:choose>
			<!-- replace dateTime with the xs:date when not January 1: otherwise this is only a year -->
			<xsl:when test="$val castable as xs:dateTime">
				<xsl:variable name="date" select="substring($val, 1, 10)"/>

				<xsl:choose>
					<xsl:when test="substring($date, 6) = '01-01' and $dams = 'digital-commons'">http://www.w3.org/2001/XMLSchema#gYear</xsl:when>
					<xsl:otherwise>http://www.w3.org/2001/XMLSchema#date</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$val castable as xs:date">http://www.w3.org/2001/XMLSchema#date</xsl:when>
			<xsl:when test="$val castable as xs:gYearMonth">http://www.w3.org/2001/XMLSchema#gYearMonth</xsl:when>
			<xsl:when test="$val castable as xs:gYear">http://www.w3.org/2001/XMLSchema#gYear</xsl:when>
		</xsl:choose>
	</xsl:function>

	<xsl:function name="harvester:parseDateTime">
		<xsl:param name="val"/>

		<xsl:choose>
			<xsl:when test="$val castable as xs:dateTime">
				<xsl:variable name="date" select="substring($val, 1, 10)"/>

				<xsl:choose>
					<xsl:when test="substring($date, 6) = '01-01' and $dams = 'digital-commons'">
						<xsl:value-of select="substring($date, 1, 4)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$date"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$val"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

</xsl:stylesheet>
