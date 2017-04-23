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
	<xsl:include href="oai-pmh-templates.xsl"/>

	<xsl:variable name="url" select="//config/url"/>
	<xsl:variable name="publisher" select="//config/publisher"/>
	<xsl:variable name="publisher_email" select="//config/publisher_email"/>
	<xsl:variable name="publisher_code" select="//config/publisher_code"/>
	<xsl:variable name="repositoryIdentifier" select="substring-before(substring-after($url, 'http://'), '/')"/>

	<!-- Note: resumptionToken format is {$set}:{$metadataPrefix}:{$offset} -->

	<!-- request params -->
	<xsl:param name="resumptionToken" select="doc('input:request')/request/parameters/parameter[name = 'resumptionToken']/value"/>
	<xsl:param name="verb" select="doc('input:request')/request/parameters/parameter[name = 'verb']/value"/>
	<xsl:param name="metadataPrefix"
		select="
			if (string-length($resumptionToken) &gt; 0) then
				tokenize($resumptionToken, ':')[2]
			else
				doc('input:request')/request/parameters/parameter[name = 'metadataPrefix']/value"/>
	<xsl:param name="set"
		select="
			if (string-length($resumptionToken) &gt; 0) then
				tokenize($resumptionToken, ':')[1]
			else
				doc('input:request')/request/parameters/parameter[name = 'set']/value"/>
	<xsl:param name="identifier" select="doc('input:request')/request/parameters/parameter[name = 'identifier']/value"/>
	<xsl:param name="from" select="doc('input:request')/request/parameters/parameter[name = 'from']/value"/>
	<xsl:param name="until" select="doc('input:request')/request/parameters/parameter[name = 'until']/value"/>

	<!-- pagination -->
	<xsl:variable name="limit" select="//config/oai-pmh_limit" as="xs:integer"/>
	<xsl:variable name="count" select="//count" as="xs:integer"/>
	<xsl:variable name="offset">
		<xsl:choose>
			<xsl:when test="string-length($resumptionToken) &gt; 0">
				<xsl:value-of select="tokenize($resumptionToken, ':')[3]"/>
			</xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<xsl:variable name="resumptionToken-valid" as="xs:boolean">
		<xsl:choose>
			<xsl:when test="string($resumptionToken)">
				<xsl:choose>
					<xsl:when test="matches($resumptionToken, '[a-z]+:oai_dc:\d+')">true</xsl:when>
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
				<xsl:if test="string($resumptionToken)">
					<xsl:attribute name="resumptionToken" select="$resumptionToken"/>
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
							<xsl:value-of select="substring-before(descendant::res:binding[@name = 'mod']/res:literal, 'T')"/>
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
									<dc:description>All cultural heritage objects in <xsl:value-of select="$publisher"/> designated for harvesting into
										Primo</dc:description>
									<dc:creator>
										<xsl:value-of select="$publisher"/>
									</dc:creator>
								</oai_dc:dc>
							</setDescription>
						</set>
						<set>
							<setSpec>primo-test</setSpec>
							<setName>Primo Test Harvest</setName>
							<setDescription>
								<oai_dc:dc>
									<dc:description>Primo test set with 50 objects.</dc:description>
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

												<!-- suppress resumption token from test set -->
												<xsl:if test="not($set = 'primo-test')">
													<xsl:call-template name="resumptionToken"/>
												</xsl:if>
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
					<GetRecord>
						<xsl:apply-templates select="descendant::ore:Aggregation">
							<xsl:with-param name="verb" select="$verb"/>
						</xsl:apply-templates>
					</GetRecord>
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
			<xsl:variable name="next" select="$offset + $limit"/>
			<resumptionToken completeListSize="{$count}" cursor="{$offset}">
				<xsl:value-of select="concat($set, ':oai_dc:', $next)"/>
			</resumptionToken>
		</xsl:if>
	</xsl:template>

	<!-- *************** TEMPLATES FOR PROCESSING RDF BACK INTO OAI-PMH METADATA **************** -->
	<xsl:template match="ore:Aggregation">
		<xsl:param name="verb"/>

		<record>
			<header>
				<identifier>
					<xsl:choose>
						<xsl:when test="$verb = 'GetIdentifiers'">
							<xsl:variable name="uri" select="string(edm:object/@rdf:resource)"/>
							<xsl:if test="string(normalize-space($uri))">
								<xsl:value-of select="concat('oai:', $repositoryIdentifier, ':', digest:md5Hex(normalize-space($uri)))"/>
							</xsl:if>
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
				<xsl:for-each select="doap:audience[. = 'primo']">
					<setSpec>
						<xsl:value-of select="."/>
					</setSpec>
				</xsl:for-each>
			</header>

			<xsl:if test="$verb = 'GetRecord' or $verb = 'ListRecords'">
				<metadata>
					<xsl:apply-templates select="descendant::dpla:SourceResource">
						<xsl:with-param name="depiction"
							select="
								if (edm:object/@rdf:resource) then
									edm:object/@rdf:resource
								else
									edm:object/edm:WebResource/@rdf:about"/>
						<xsl:with-param name="thumbnail"
							select="
								if (edm:preview/@rdf:resource) then
									edm:preview/@rdf:resource
								else
									edm:preview/edm:WebResource/@rdf:about"/>
						<xsl:with-param name="dataProvider" select="edm:dataProvider/@rdf:resource"/>
					</xsl:apply-templates>
				</metadata>
			</xsl:if>
		</record>
	</xsl:template>
</xsl:stylesheet>
