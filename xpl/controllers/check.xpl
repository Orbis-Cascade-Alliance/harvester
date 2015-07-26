<?xml version="1.0" encoding="UTF-8"?>
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xxforms="http://orbeon.org/oxf/xml/xforms">

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

	<!-- set up iteration of sets -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="#request"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:output indent="yes"/>
				<xsl:template match="/">
					<sets>
						<xsl:for-each select="tokenize(/request/parameters/parameter[name='sets']/value, '\|')">
							<set>
								<xsl:value-of select="."/>
							</set>
						</xsl:for-each>
					</sets>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="sets"/>
	</p:processor>

	<p:for-each href="#sets" select="//set" id="response" root="response">
		<!-- generate the controls to include the repository ID and ARK URI -->
		<p:processor name="oxf:unsafe-xslt">
			<p:input name="request" href="#request"/>
			<p:input name="data" href="current()"/>
			<p:input name="config">
				<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
					<xsl:output indent="yes"/>
					<xsl:param name="ark" select="doc('input:request')/request/parameters/parameter[name='ark']/value"/>

					<xsl:template match="/">
						<controls>
							<ark>
								<xsl:value-of select="$ark"/>
							</ark>
							<set>
								<xsl:value-of select="/set"/>
							</set>
						</controls>
					</xsl:template>
				</xsl:stylesheet>
			</p:input>
			<p:output name="data" id="controls"/>
		</p:processor>

		<!-- generate URL Generator config -->
		<p:processor name="oxf:unsafe-xslt">
			<p:input name="data" href="current()"/>
			<p:input name="config">
				<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
					<xsl:output indent="yes"/>
					<xsl:template match="/">
						<config>
							<url>
								<xsl:value-of select="/set"/>
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
					<p:input name="controls" href="#controls"/>
					<p:input name="config">
						<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all">
							<xsl:template match="/">
								<set>
									<url>
										<xsl:value-of select="doc('input:controls')/controls/set"/>
									</url>
									<error type="http">
										<xsl:value-of select="/exceptions/exception/message"/>
									</error>
								</set>
							</xsl:template>
						</xsl:stylesheet>
					</p:input>
					<p:output name="data" ref="response"/>
				</p:processor>
			</p:when>
			<p:when test="/*[not(namespace-uri() = 'http://www.openarchives.org/OAI/2.0/')]">
				<!-- Extract the message -->
				<p:processor name="oxf:xslt">
					<p:input name="data" href="#url-data-checked"/>
					<p:input name="controls" href="#controls"/>
					<p:input name="config">
						<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all">
							<xsl:template match="/">
								<set>
									<url>
										<xsl:value-of select="doc('input:controls')/controls/set"/>
									</url>
									<error type="other">The response is XML, but not OAI-PMH.</error>
								</set>
							</xsl:template>
						</xsl:stylesheet>
					</p:input>
					<p:output name="data" ref="response"/>
				</p:processor>
			</p:when>
			<p:when test="//*[local-name()='error'][namespace-uri()='http://www.openarchives.org/OAI/2.0/']">
				<p:processor name="oxf:xslt">
					<p:input name="data" href="#url-data-checked"/>
					<p:input name="controls" href="#controls"/>
					<p:input name="config">
						<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:oai="http://www.openarchives.org/OAI/2.0/" xmlns:xs="http://www.w3.org/2001/XMLSchema"
							exclude-result-prefixes="#all">
							<xsl:template match="/">
								<set>
									<url>
										<xsl:value-of select="doc('input:controls')/controls/set"/>
									</url>
									<error type="oai-pmh">
										<xsl:value-of select="//oai:error"/>
									</error>
								</set>
							</xsl:template>
						</xsl:stylesheet>
					</p:input>
					<p:output name="data" ref="response"/>
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
					<p:input name="controls" href="#controls"/>
					<p:input name="config">
						<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
							xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai="http://www.openarchives.org/OAI/2.0/"
							exclude-result-prefixes="#all">

							<!-- allow the specification of an ARK to count specific instances, otherwise find the count of any CHO with an associated ARK URI -->
							<xsl:param name="ark" select="if (string(doc('input:controls')/controls/ark)) then doc('input:controls')/controls/ark else 'ark:/'"/>

							<xsl:template match="/">
								<xsl:variable name="count">
									<xsl:choose>
										<xsl:when test="descendant::oai:resumptionToken">
											<xsl:call-template name="recurse">
												<xsl:with-param name="token" select="descendant::oai:resumptionToken"/>
												<xsl:with-param name="count" select="count(descendant::oai:metadata[descendant::dc:relation[contains(., $ark)]])"/>
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
										<xsl:value-of select="doc('input:controls')/controls/set"/>
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
											<xsl:with-param name="count" select="$count + count($oai/descendant::oai_dc:dc[dc:relation[contains(., $ark)]])"/>
											<xsl:with-param name="set" select="$set"/>
										</xsl:call-template>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$count + count($oai/descendant::oai_dc:dc[dc:relation[contains(., $ark)]])"/>
									</xsl:otherwise>
								</xsl:choose>

							</xsl:template>
						</xsl:stylesheet>
					</p:input>
					<p:output name="data" ref="response"/>
				</p:processor>
			</p:otherwise>
		</p:choose>
	</p:for-each>

	<p:processor name="oxf:identity">
		<p:input name="data" href="#response"/>
		<p:output name="data" ref="data"/>
	</p:processor>
</p:pipeline>
