<?xml version="1.0" encoding="UTF-8"?>
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xforms="http://www.w3.org/2002/xforms"
	xmlns:xxforms="http://orbeon.org/oxf/xml/xforms">

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

	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="#request"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:param name="set" select="normalize-space(/request/parameters/parameter[name='sets']/value)"/>
				
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
		<p:output name="data" id="oai-pmh"/>
	</p:processor>

	<!-- execute XSLT transformation from OAI to RDF/XML -->
	<p:processor name="oxf:pipeline">
		<p:input name="data" href="#oai-pmh"/>
		<p:input name="request" href="#request"/>
		<p:input name="config" href="../views/serializations/oai/rdf.xpl"/>
		<p:output name="data" ref="data"/>
	</p:processor>
</p:pipeline>
