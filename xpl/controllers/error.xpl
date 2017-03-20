<?xml version="1.0" encoding="UTF-8"?>
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors">

	<p:param type="input" name="data"/>

	<p:processor name="oxf:request">
		<p:input name="config">
			<config>
				<include>/request</include>
			</config>
		</p:input>
		<p:output name="data" id="request"/>
	</p:processor>

	<!-- generate HTML fragment to be returned -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="#data"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:output indent="yes"/>
				<xsl:template match="/">
					<xsl:variable name="status-code" select="/*/@status-code"/>
					<xml xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" content-type="text/html">
						<![CDATA[<html>
		<head>
			<title>]]><xsl:value-of select="if (string($status-code)) then $status-code else '500'"/><![CDATA[</title>
		</head>
		<body>
			<h1>]]><xsl:value-of select="if (string($status-code)) then $status-code else '500'"/><![CDATA[</h1>
			<p>]]><xsl:value-of select="message"/><![CDATA[</p>
		</body>
</html>]]>
					</xml>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="html"/>
	</p:processor>

	<!-- generate config for http-serializer -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="#data"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:output indent="yes"/>
				<xsl:template match="/">
					<xsl:variable name="status-code" select="/*/@status-code"/>
					<config>
						<status-code>
							<xsl:value-of select="if (string($status-code)) then $status-code else '500'"/>
						</status-code>
						<content-type>text/html</content-type>
					</config>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="header"/>
	</p:processor>

	<p:processor name="oxf:http-serializer">
		<p:input name="data" href="#html"/>
		<p:input name="config" href="#header"/>
	</p:processor>
</p:pipeline>
