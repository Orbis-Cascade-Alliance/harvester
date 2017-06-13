<?xml version="1.0" encoding="UTF-8"?>
<!--
 Changes:

    09/23/15    KEF     The count was only tallying the first page for Willamette,
                        which has a complicated set-up with a proxy to their
                        CDM server.  It looks like the code in the recurse
                        template was using an overly-restrictive namespace 
                        mapping.  I changed it to the same mapping that is
                        used in the initial page count and all is now well.
-->
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xforms="http://www.w3.org/2002/xforms"
	xmlns:xxforms="http://orbeon.org/oxf/xml/xforms" xmlns:res="http://www.w3.org/2005/sparql-results#">

	<p:param type="input" name="data"/>
	<p:param type="output" name="data"/>

	<p:processor name="oxf:request">
		<p:input name="config">
			<config>
				<include>/request</include>
			</config>
		</p:input>
		<p:output name="data" id="request"/>
	</p:processor>

	<!-- Step 1: evaluate whether this set has already been connected to Primo or DPLA -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="request" href="#request"/>
		<p:input name="data" href="../../config.xml"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:param name="set" select="doc('input:request')/request/parameters/parameter[name='set']/value"/>
				<xsl:variable name="sparql_endpoint" select="/config/sparql/query"/>

				<!-- derive OAI-PMH service and setSpec -->
				<xsl:variable name="service" select="substring-before($set, '?')"/>
				<xsl:variable name="setSpec" select="tokenize(substring-after($set, '?'), '&amp;')[contains(., 'set=')]"/>

				<!-- SPARQL query to see if there's an ore:Aggregation belonging to this set that has been designated for Primo or DPLA -->
				<xsl:variable name="query"><![CDATA[PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dcmitype:	<http://purl.org/dc/dcmitype/>
PREFIX prov:	<http://www.w3.org/ns/prov#>
PREFIX doap:	<http://usefulinc.com/ns/doap#>

ASK {
  ?set a dcmitype:Collection FILTER (regex(str(?set), '%SETSPEC%') && strStarts(str(?set), '%SERVICE%'))
  ?agg prov:wasDerivedFrom ?set ;
         doap:audience ?target FILTER (?target = 'primo' || ?target = 'dpla')
}]]></xsl:variable>

				<xsl:template match="/">
					<config>
						<url>
							<xsl:value-of
								select="concat($sparql_endpoint, '?query=', encode-for-uri(replace(replace($query, '%SETSPEC%', $setSpec), '%SERVICE%', $service)), '&amp;output=xml')"
							/>
						</url>
						<content-type>application/xml</content-type>
						<encoding>utf-8</encoding>
					</config>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="ask-generator-config"/>
	</p:processor>

	<p:processor name="oxf:url-generator">
		<p:input name="config" href="#ask-generator-config"/>
		<p:output name="data" id="sparql-response"/>
	</p:processor>

	<!-- evaluate the SPARQL response -->
	<p:choose href="#sparql-response">
		<p:when test="//res:boolean = true()">
			<!-- if the response is true that the set is designated for Primo or DPLA, then result in an error -->
			<p:processor name="oxf:xslt">
				<p:input name="data" href="#request"/>
				<p:input name="config">
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
						exclude-result-prefixes="#all">
						<xsl:param name="set" select="/request/parameters/parameter[name='set']/value"/>

						<xsl:template match="/">
							<set>
								<url>
									<xsl:value-of select="$set"/>
								</url>
								<error type="use-harvester">This set has been published with a doap:audience of 'primo' and/or 'dpla' already. Please resubmit through
									the Harvester backend.</error>
							</set>
						</xsl:template>
					</xsl:stylesheet>
				</p:input>
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:when>
		<p:otherwise>
			<!-- otherwise proceed with the check workflow -->
			<p:processor name="oxf:unsafe-xslt">
				<p:input name="data" href="#request"/>
				<p:input name="config">
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
						<xsl:output indent="yes"/>
						<xsl:param name="set" select="/request/parameters/parameter[name='set']/value"/>

						<xsl:template match="/">
							<config>
								<url>
									<xsl:value-of select="$set"/>
								</url>
								<mode>xml</mode>
								<content-type>application/xml</content-type>
								<header>
									<name>User-Agent</name>
									<value>XForms/harvester.orbiscascade.org</value>
								</header>
								<encoding>utf-8</encoding>
							</config>
						</xsl:template>
					</xsl:stylesheet>
				</p:input>
				<p:output name="data" id="url-generator-config"/>
			</p:processor>

			<!-- get OAI-PMH feed -->
			<p:processor name="oxf:url-generator">
				<p:input name="config" href="#url-generator-config"/>
				<p:output name="data" id="url-data"/>
			</p:processor>

			<!-- validate for well-formedness of XML response -->
			<p:processor name="oxf:exception-catcher">
				<p:input name="data" href="#url-data"/>
				<p:output name="data" id="url-data-checked"/>
			</p:processor>

			<p:choose href="#url-data-checked">
				<p:when test="/exceptions">
					<!-- Extract the message -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="#url-data-checked"/>
						<p:input name="request" href="#request"/>
						<p:input name="config">
							<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
								exclude-result-prefixes="#all">
								<xsl:param name="set" select="doc('input:request')/request/parameters/parameter[name='set']/value"/>

								<xsl:template match="/">
									<set>
										<url>
											<xsl:value-of select="$set"/>
										</url>
										<error type="http">
											<xsl:value-of select="/exceptions/exception/message"/>
										</error>
									</set>
								</xsl:template>
							</xsl:stylesheet>
						</p:input>
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:when>
				<p:when test="/*[not(namespace-uri() = 'http://www.openarchives.org/OAI/2.0/')]">
					<!-- Extract the message -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="#url-data-checked"/>
						<p:input name="request" href="#request"/>
						<p:input name="config">
							<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
								exclude-result-prefixes="#all">
								<xsl:param name="set" select="doc('input:request')/request/parameters/parameter[name='set']/value"/>

								<xsl:template match="/">
									<set>
										<url>
											<xsl:value-of select="$set"/>
										</url>
										<error type="other">The response is XML, but not OAI-PMH.</error>
									</set>
								</xsl:template>
							</xsl:stylesheet>
						</p:input>
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:when>
				<p:when test="//*[local-name()='error'][namespace-uri()='http://www.openarchives.org/OAI/2.0/']">
					<p:processor name="oxf:xslt">
						<p:input name="data" href="#url-data-checked"/>
						<p:input name="request" href="#request"/>
						<p:input name="config">
							<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:oai="http://www.openarchives.org/OAI/2.0/"
								xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all">
								<xsl:param name="set" select="doc('input:request')/request/parameters/parameter[name='set']/value"/>

								<xsl:template match="/">
									<set>
										<url>
											<xsl:value-of select="$set"/>
										</url>
										<error type="oai-pmh">
											<xsl:value-of select="//oai:error"/>
										</error>
									</set>
								</xsl:template>
							</xsl:stylesheet>
						</p:input>
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:when>
				<p:otherwise>
					<!-- Just return the document -->
					<p:processor name="oxf:identity">
						<p:input name="data" href="#url-data-checked"/>
						<p:output name="data" id="oai-pmh"/>
					</p:processor>

					<!-- count objects in the OAI-PMH feed that have an associated ARK -->
					<p:processor name="oxf:unsafe-xslt">
						<p:input name="data" href="#oai-pmh"/>
						<p:input name="request" href="#request"/>
						<p:input name="config">
							<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
								xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/"
								xmlns:oai="http://www.openarchives.org/OAI/2.0/" exclude-result-prefixes="#all">

								<!-- allow the specification of an ARK to count specific instances, otherwise find the count of any CHO with an associated ARK URI -->
								<xsl:param name="set" select="doc('input:request')/request/parameters/parameter[name='set']/value"/>
								<xsl:param name="ark"
									select="if (string(doc('input:request')/request/parameters/parameter[name='ark']/value)) then doc('input:request')/request/parameters/parameter[name='ark']/value else 'ark:/'"/>

								<xsl:template match="/">
									<xsl:variable name="count">
										<xsl:choose>
											<xsl:when test="descendant::oai:resumptionToken">
												<xsl:call-template name="recurse">
													<xsl:with-param name="token" select="descendant::oai:resumptionToken"/>
													<xsl:with-param name="count"
														select="count(descendant::oai:metadata[descendant::dc:relation[contains(., $ark)]])"/>
													<xsl:with-param name="set" select="descendant::oai:request"/>
												</xsl:call-template>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="count(descendant::oai:metadata[descendant::dc:relation[contains(., $ark)]])"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:variable>

									<set>
										<url>
											<xsl:value-of select="$set"/>
										</url>
										<count>
											<xsl:value-of select="$count"/>
										</count>
									</set>
								</xsl:template>

								<xsl:template name="recurse">
									<xsl:param name="token"/>
									<xsl:param name="count"/>
									<xsl:param name="set"/>

									<xsl:variable name="oai" as="node()*">
										<xsl:copy-of select="document(concat($set, '?verb=ListRecords&amp;resumptionToken=', $token))"/>
									</xsl:variable>

									<xsl:choose>
										<xsl:when test="$oai/descendant::oai:resumptionToken">
											<xsl:call-template name="recurse">
												<xsl:with-param name="token" select="$oai/descendant::oai:resumptionToken"/>
												<xsl:with-param name="count"
													select="$count + count($oai/descendant::oai:metadata/*[dc:relation[contains(., $ark)]])"/>
												<xsl:with-param name="set" select="$set"/>
											</xsl:call-template>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="$count + count($oai/descendant::oai:metadata/*[dc:relation[contains(., $ark)]])"/>
										</xsl:otherwise>
									</xsl:choose>

								</xsl:template>
							</xsl:stylesheet>
						</p:input>
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:otherwise>
			</p:choose>
		</p:otherwise>
	</p:choose>
</p:pipeline>
