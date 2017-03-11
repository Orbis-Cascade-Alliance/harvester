<?xml version="1.0" encoding="UTF-8"?>
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

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
	
	<!-- read the HTTP request parameters to construct the appropriate OAI-PMH response -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="#request"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:output indent="yes"/>
				<xsl:param name="verb" select="/request/parameters/parameter[name='verb']/value"/>				
				
				<xsl:template match="/">
					<verb>
						<xsl:value-of select="$verb"/>
					</verb>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="verb"/>
	</p:processor>
	
	<p:choose href="#verb">
		<!-- execute SPARQL query to get some basic information about a record to Identify OAI-PMH endpoint -->
		<p:when test="verb='Identify'">
			<p:processor name="oxf:pipeline">
				<p:input name="data" href="../../config.xml"/>
				<p:input name="config" href="../models/sparql/oai-identify.xpl"/>
				<p:output name="data" id="identify"/>
			</p:processor>
			
			<p:processor name="oxf:unsafe-xslt">
				<p:input name="data" href="aggregate('content', ../../config.xml, #identify)"/>
				<p:input name="request" href="#request"/>
				<p:input name="config" href="../../ui/xslt/serializations/sparql/oai-pmh.xsl"/>
				<p:output name="data" id="model"/>
			</p:processor>			
		</p:when>
		<p:when test="verb='GetRecord'">
			<p:processor name="oxf:unsafe-xslt">
				<p:input name="data" href="#request"/>
				<p:input name="config">
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">		
						<xsl:param name="metadataPrefix" select="/request/parameters/parameter[name = 'metadataPrefix']/value"/>
						<xsl:param name="identifier" select="/request/parameters/parameter[name='identifier']/value"/>		
						
						<xsl:template match="/">
							<valid>
								<xsl:choose>
									<xsl:when test="not($metadataPrefix = 'oai_dc')">
										<error code="cannotDisseminateFormat" xmlns="http://www.openarchives.org/OAI/2.0/">Cannot disseminate format.</error>
									</xsl:when>
									<xsl:when test="not(string($identifier))">
										<error code="badArgument" xmlns="http://www.openarchives.org/OAI/2.0/">Bad OAI Argument: No identifier</error>
									</xsl:when>
									<xsl:otherwise>true</xsl:otherwise>
								</xsl:choose>
							</valid>
						</xsl:template>
					</xsl:stylesheet>
				</p:input>
				<p:output name="data" id="valid"/>
			</p:processor>
			
			<p:choose href="#valid">
				<p:when test="valid != 'true'">
					<p:processor name="oxf:unsafe-xslt">
						<p:input name="data" href="aggregate('content', #valid, ../../config.xml)"/>
						<p:input name="request" href="#request"/>
						<p:input name="config">
							<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="#all">
								<xsl:variable name="url" select="//config/url"/>								
								<xsl:param name="verb" select="doc('input:request')/request/parameters/parameter[name = 'verb']/value"/>
								
								<xsl:template match="/">
									<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
										xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
										xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/
										http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
										<responseDate>
											<xsl:value-of select="concat(substring-before(string(current-dateTime()), '.'), 'Z')"/>
										</responseDate>
										<request verb="{$verb}">
											<xsl:value-of select="concat($url, 'oai-pmh/')"/>
										</request>
										<xsl:copy-of select="//*:error"/>
									</OAI-PMH>
								</xsl:template>
							</xsl:stylesheet>
						</p:input>
						<p:output name="data" id="model"/>
					</p:processor>
				</p:when>
				<p:otherwise>	
					
					<!-- execute SPARQL query for DESCRIBING a single record -->
					<p:processor name="oxf:pipeline">
						<p:input name="data" href="../../config.xml"/>
						<p:input name="config" href="../models/sparql/get-record.xpl"/>
						<p:output name="data" id="record"/>
					</p:processor>
					
					<p:processor name="oxf:unsafe-xslt">
						<p:input name="request" href="#request"/>
						<p:input name="data" href="aggregate('content', ../../config.xml, #record)"/>				
						<p:input name="config" href="../../ui/xslt/serializations/sparql/oai-pmh.xsl"/>
						<p:output name="data" id="model"/>
					</p:processor>	
				</p:otherwise>
			</p:choose>
		</p:when>
		<p:when test="verb='ListIdentifiers' or verb='ListRecords'">
			<!-- evaluate for errors -->
			<p:processor name="oxf:unsafe-xslt">
				<p:input name="data" href="#request"/>
				<p:input name="config">
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">						
						<xsl:param name="resumptionToken" select="/request/parameters/parameter[name='resumptionToken']/value"/>
						<xsl:param name="set" select="if (string-length($resumptionToken) &gt; 0) then tokenize($resumptionToken, ':')[1] else /request/parameters/parameter[name = 'set']/value"/>
						<xsl:param name="from" select="/request/parameters/parameter[name='from']/value"/>
						<xsl:param name="until" select="/request/parameters/parameter[name='until']/value"/>				
						
						<xsl:template match="/">
							<valid>
								<xsl:choose>
									<xsl:when test="not($set = 'primo') and not($set='primo-test')">
										<error code="badArgument" xmlns="http://www.openarchives.org/OAI/2.0/">Invalid Set</error>
									</xsl:when>
									<xsl:when test="string($resumptionToken) and not(tokenize($resumptionToken, ':')[3] castable as xs:integer)">
										<error code="badResumptionToken" xmlns="http://www.openarchives.org/OAI/2.0/">Invalid resumptionToken</error>
									</xsl:when>									
									<xsl:when test="string($from) and not($from castable as xs:date)">
										<error code="badArgument" xmlns="http://www.openarchives.org/OAI/2.0/">From argument invalid</error>
									</xsl:when>
									<xsl:when test="string($until) and not($until castable as xs:date)">
										<error code="badArgument" xmlns="http://www.openarchives.org/OAI/2.0/">To argument invalid</error>
									</xsl:when>
									<xsl:when test="(string($from) and string($until)) and xs:date($from) &gt; xs:date($until)">
										<error code="badArgument">From argument more recent than to argument</error>
									</xsl:when>
									<xsl:otherwise>true</xsl:otherwise>
								</xsl:choose>
							</valid>
						</xsl:template>
					</xsl:stylesheet>
				</p:input>
				<p:output name="data" id="valid"/>
			</p:processor>
			
			<p:choose href="#valid">
				<p:when test="valid != 'true'">
					<p:processor name="oxf:unsafe-xslt">
						<p:input name="data" href="aggregate('content', #valid, ../../config.xml)"/>
						<p:input name="request" href="#request"/>
						<p:input name="config">
							<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="#all">
								<xsl:variable name="url" select="//config/url"/>								
								<xsl:param name="verb" select="doc('input:request')/request/parameters/parameter[name = 'verb']/value"/>
								
								<xsl:template match="/">
									<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
										xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
										xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/
										http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
										<responseDate>
											<xsl:value-of select="concat(substring-before(string(current-dateTime()), '.'), 'Z')"/>
										</responseDate>
										<request verb="{$verb}">
											<xsl:value-of select="concat($url, 'oai-pmh/')"/>
										</request>
										<xsl:copy-of select="//*:error"/>
									</OAI-PMH>
								</xsl:template>
							</xsl:stylesheet>
						</p:input>
						<p:output name="data" id="model"/>
					</p:processor>
				</p:when>
				<p:otherwise>
					<!-- get count of dpla:SourceResources in order to formulate resumption tokens -->
					<p:processor name="oxf:pipeline">
						<p:input name="data" href="../../config.xml"/>
						<p:input name="config" href="../models/sparql/oai-count.xpl"/>
						<p:output name="data" id="count"/>
					</p:processor>					
					
					<!-- execute SPARQL query for list of dpla:SourceResources -->
					<p:processor name="oxf:pipeline">
						<p:input name="data" href="../../config.xml"/>
						<p:input name="config" href="../models/sparql/oai-list.xpl"/>
						<p:output name="data" id="list"/>
					</p:processor>
					
					<p:processor name="oxf:unsafe-xslt">
						<p:input name="request" href="#request"/>
						<p:input name="data" href="aggregate('content', ../../config.xml, #count, #list)"/>				
						<p:input name="config" href="../../ui/xslt/serializations/sparql/oai-pmh.xsl"/>
						<p:output name="data" id="model"/>
					</p:processor>	
				</p:otherwise>
			</p:choose>
		</p:when>
		<p:otherwise>
			<p:processor name="oxf:unsafe-xslt">
				<p:input name="data" href="../../config.xml"/>
				<p:input name="request" href="#request"/>
				<p:input name="config" href="../../ui/xslt/serializations/sparql/oai-pmh.xsl"/>
				<p:output name="data" id="model"/>
			</p:processor>
		</p:otherwise>
	</p:choose>
	 
	 <!-- serialize the resulting XML document -->
	<p:processor name="oxf:xml-serializer">
		<p:input name="data" href="#model"/>
		<p:input name="config">
			<config>
				<content-type>application/xml</content-type>
				<indent>true</indent>
			</config>
		</p:input>
		<p:output name="data" ref="data"/>
	</p:processor>
	 
</p:pipeline>
