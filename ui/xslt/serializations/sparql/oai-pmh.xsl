<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.openarchives.org/OAI/2.0/"
	xmlns:digest="org.apache.commons.codec.digest.DigestUtils" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:arch="http://purl.org/archival/vocab/arch#" xmlns:edm="http://www.europeana.eu/schemas/edm/" xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:vcard="http://www.w3.org/2006/vcard/ns#" xmlns:prov="http://www.w3.org/ns/prov#"
	xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:nwda="https://github.com/Orbis-Cascade-Alliance/nwda-editor#"
	xmlns:ore="http://www.openarchives.org/ore/terms/" xmlns:dpla="http://dp.la/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/"
	exclude-result-prefixes="xs res rdf arch edm dcterms vcard nwda dpla ore digest prov geo" version="2.0">

	<xsl:variable name="url" select="//config/url"/>
	<xsl:variable name="publisher" select="//config/publisher"/>
	<xsl:variable name="publisher_email" select="//config/publisher_email"/>
	<xsl:variable name="publisher_code" select="//config/publisher_code"/>
	<xsl:variable name="repositoryIdentifier" select="substring-before(substring-after($url, 'http://'), '/')"/>

	<!-- request params -->
	<xsl:param name="verb" select="doc('input:request')/request/parameters/parameter[name = 'verb']/value"/>
	<xsl:param name="metadataPrefix" select="doc('input:request')/request/parameters/parameter[name = 'metadataPrefix']/value"/>
	<xsl:param name="set" select="doc('input:request')/request/parameters/parameter[name = 'set']/value"/>
	<xsl:param name="identifier" select="doc('input:request')/request/parameters/parameter[name = 'identifier']/value"/>
	<xsl:param name="from" select="doc('input:request')/request/parameters/parameter[name = 'from']/value"/>
	<xsl:param name="until" select="doc('input:request')/request/parameters/parameter[name = 'until']/value"/>
	<xsl:param name="resumptionToken" select="doc('input:request')/request/parameters/parameter[name = 'resumptionToken']/value"/>

	<!-- pagination -->
	<xsl:variable name="limit" select="//config/oai-pmh_limit" as="xs:integer"/>
	<xsl:variable name="count" select="//count" as="xs:integer"/>
	<xsl:variable name="offset">
		<xsl:choose>
			<xsl:when test="$resumptionToken castable as xs:integer and $resumptionToken &gt; 0">
				<xsl:value-of select="$resumptionToken"/>
			</xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<xsl:variable name="resumptionToken-valid" as="xs:boolean">
		<xsl:choose>
			<xsl:when test="string($resumptionToken)">
				<xsl:choose>
					<xsl:when test="$resumptionToken castable as xs:integer and xs:integer($resumptionToken) &gt; 0">true</xsl:when>
					<xsl:otherwise>false</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<!-- construct OAI-PMH response -->
	<xsl:template match="/">
		<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
			xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/
			http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
			<responseDate>
				<xsl:value-of select="concat(substring-before(string(current-dateTime()), '.'), 'Z')"/>
			</responseDate>
			<request verb="{$verb}">
				<xsl:if test="string($metadataPrefix)">
					<xsl:attribute name="metadataPrefix" select="$metadataPrefix"/>
				</xsl:if>
				<xsl:if test="string($set)">
					<xsl:attribute name="set" select="$set"/>
				</xsl:if>
				<xsl:if test="string($identifier)">
					<xsl:attribute name="identifier" select="$identifier"/>
				</xsl:if>
				<xsl:value-of select="concat($url, 'oai-pmh/')"/>
			</request>

			<!-- conditional to validate and respond, based on the $verb -->
			<xsl:choose>
				<xsl:when test="$verb = 'Identify'">
					<Identify>
						<repositoryName>
							<xsl:value-of select="$publisher"/>
						</repositoryName>
						<baseURL>
							<xsl:value-of select="concat($url, 'oai-pmh/')"/>
						</baseURL>
						<protocolVersion>2.0</protocolVersion>
						<adminEmail>
							<xsl:value-of select="$publisher_email"/>
						</adminEmail>
						<earliestDatestamp>
							<xsl:value-of select="descendant::res:binding[@name = 'mod']/res:literal"/>
						</earliestDatestamp>
						<deletedRecord>no</deletedRecord>
						<granularity>YYYY-MM-DD</granularity>
						<description>
							<oai-identifier>
								<scheme>oai</scheme>
								<repositoryIdentifier>
									<xsl:value-of select="$repositoryIdentifier"/>
								</repositoryIdentifier>
								<delimiter>:</delimiter>
								<sampleIdentifier>
									<xsl:value-of select="descendant::res:binding[@name = 'uri']/res:uri"/>
								</sampleIdentifier>
							</oai-identifier>
						</description>
					</Identify>
				</xsl:when>
				<xsl:when test="$verb = 'ListSets'">
					<ListSets>
						<set>
							<setSpec>primo</setSpec>
							<setName>Primo Harvest</setName>
							<setDescription>
								<oai_dc:dc>
									<dc:title>All cultural heritage objects in <xsl:value-of select="$publisher"/> designated for harvesting into
										Primo</dc:title>
									<dc:creator>
										<xsl:value-of select="$publisher"/>
									</dc:creator>
								</oai_dc:dc>
							</setDescription>
						</set>
					</ListSets>
				</xsl:when>
				<xsl:when test="$verb = 'ListMetadataFormats'">
					<ListMetadataFormats>
						<metadataFormat>
							<metadataPrefix>oai_dc</metadataPrefix>
							<schema>http://www.openarchives.org/OAI/2.0/oai_dc.xsd</schema>
							<metadataNamespace>http://www.openarchives.org/OAI/2.0/oai_dc/</metadataNamespace>
						</metadataFormat>
					</ListMetadataFormats>
				</xsl:when>
				<xsl:when test="$verb = 'ListRecords' or $verb = 'ListIdentifiers'">
					<xsl:choose>
						<xsl:when test="string($metadataPrefix)">
							<xsl:choose>
								<xsl:when test="$metadataPrefix = 'oai_dc'">
									<xsl:choose>
										<xsl:when test="count(descendant::dpla:SourceResource) = 0">
											<error code="noRecordsMatch">No matching records in date range</error>
										</xsl:when>
										<xsl:otherwise>
											<xsl:element name="{$verb}" namespace="http://www.openarchives.org/OAI/2.0/">
												<xsl:apply-templates select="descendant::ore:Aggregation">
													<xsl:with-param name="verb" select="$verb"/>
												</xsl:apply-templates>

												<xsl:call-template name="resumptionToken"/>
											</xsl:element>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:otherwise>
									<error code="cannotDisseminateFormat">Cannot disseminate format.</error>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>
							<error code="badArgument">No metadata prefix</error>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="$verb = 'GetRecord'">
					<xsl:choose>
						<xsl:when test="$identifier">
							<xsl:variable name="identifier-valid" select="iri-to-uri($identifier) castable as xs:anyURI" as="xs:boolean"/>
							<xsl:variable name="character-pass" as="xs:boolean">
								<xsl:choose>
									<xsl:when test="$identifier-valid = true()">
										<xsl:choose>
											<xsl:when
												test="contains($identifier, '!') or contains($identifier, '&#x022;') or contains($identifier, '#') or contains($identifier, '[') or contains($identifier, ']') or contains($identifier, '(') or contains($identifier, ')') or contains($identifier, '{') or contains($identifier, '}')"
												>false</xsl:when>
											<xsl:otherwise>true</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:otherwise>false</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:choose>
								<xsl:when test="string($metadataPrefix) and $character-pass = true()">
									<xsl:choose>
										<xsl:when test="$metadataPrefix = 'oai_dc'">
											<GetRecord>
												<xsl:apply-templates select="descendant::ore:Aggregation">
													<xsl:with-param name="verb" select="$verb"/>
												</xsl:apply-templates>
											</GetRecord>
										</xsl:when>
										<xsl:otherwise>
											<error code="cannotDisseminateFormat">Cannot disseminate format.</error>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:otherwise>
									<error code="badArgument">Bad OAI Argument</error>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>
							<error code="badArgument">Bad OAI Argument: No identifier</error>
						</xsl:otherwise>
					</xsl:choose>

				</xsl:when>
				<xsl:otherwise>
					<error code="badVerb">Illegal OAI verb</error>
				</xsl:otherwise>
			</xsl:choose>
		</OAI-PMH>
	</xsl:template>

	<!-- generate resumptionToken from the $limit defined in the config and the $offset, an integer value for SPARQL that stands as a resumptionToken -->
	<xsl:template name="resumptionToken">
		<xsl:if test="$offset &lt; $count">
			<resumptionToken completeListSize="{$count}" cursor="{$offset}">
				<xsl:value-of select="$offset + $limit"/>
			</resumptionToken>
		</xsl:if>
	</xsl:template>

	<!-- *************** TEMPLATES FOR PROCESSING RDF BACK INTO OAI-PMH METADATA **************** -->
	<xsl:template match="ore:Aggregation">
		<header>
			<identifier>
				<xsl:value-of select="descendant::dpla:SourceResource/@rdf:about"/>
			</identifier>
			<datestamp>
				<xsl:value-of select="dcterms:modified"/>
			</datestamp>
			<setSpec>primo</setSpec>
		</header>
	</xsl:template>

	<xsl:template match="ore:Aggregation">
		<xsl:param name="verb"/>

		<record>
			<header>
				<identifier>
					<xsl:choose>
						<xsl:when test="$verb = 'GetIdentifiers'">
							<xsl:value-of select="edm:object/@rdf:resource"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:variable name="uri" select="string(descendant::dpla:SourceResource/@rdf:about)"/>
							<xsl:if test="string(normalize-space($uri))">
								<xsl:value-of select="concat('oai:', $repositoryIdentifier, ':', digest:md5Hex(normalize-space($uri)))"/>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>

				</identifier>
				<datestamp>
					<xsl:value-of select="substring(prov:generatedAtTime, 1, 10)"/>
				</datestamp>
				<setSpec>primo</setSpec>
			</header>

			<xsl:if test="$verb = 'GetRecord' or $verb = 'ListRecords'">
				<metadata>
					<xsl:apply-templates select="descendant::dpla:SourceResource">
						<xsl:with-param name="depiction" select="edm:object/@rdf:resource"/>
						<xsl:with-param name="thumbnail" select="edm:preview/@rdf:resource"/>
						<xsl:with-param name="publisher" select="edm:dataProvider/@rdf:resource"/>
					</xsl:apply-templates>
				</metadata>
			</xsl:if>
		</record>
	</xsl:template>

	<xsl:template match="dpla:SourceResource">
		<xsl:param name="publisher"/>
		<xsl:param name="thumbnail"/>
		<xsl:param name="depiction"/>

		<oai_dc:dc>
			<xsl:apply-templates select="*"/>
			<dc:publisher>
				<xsl:value-of select="$publisher"/>
			</dc:publisher>
			<dc:identifier>
				<xsl:value-of select="@rdf:about"/>
			</dc:identifier>

			<xsl:if test="string($thumbnail)">
				<foaf:thumbnail>
					<xsl:value-of select="$thumbnail"/>
				</foaf:thumbnail>
			</xsl:if>
			<xsl:if test="string($depiction)">
				<foaf:depiction>
					<xsl:value-of select="$depiction"/>
				</foaf:depiction>
			</xsl:if>
		</oai_dc:dc>
	</xsl:template>

	<xsl:template match="dcterms:coverage[edm:Place]">
		<dc:coverage>
			<xsl:apply-templates select="edm:Place"/>
		</dc:coverage>
	</xsl:template>

	<xsl:template match="edm:Place">
		<xsl:value-of select="concat(geo:lat, ',', geo:long)"/>
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

</xsl:stylesheet>
