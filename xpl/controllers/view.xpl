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

	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="#request"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:output indent="yes"/>
				<xsl:template match="/">
					<output>
						<xsl:value-of select="/request/parameters/parameter[name='output']/value"/>
					</output>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="output"/>
	</p:processor>
	
	<p:choose href="#output">
		<p:when test="/output = 'html'">
			<p:processor name="oxf:pipeline">
				<p:input name="data" href="#data"/>
				<p:input name="request" href="#request"/>
				<p:input name="config" href="../views/serializations/rdf/html.xpl"/>
				<p:output name="data" id="model"/>
			</p:processor>
			
			<p:processor name="oxf:html-converter">
				<p:input name="data" href="#model"/>
				<p:input name="config">
					<config>
						<version>5.0</version>
						<indent>true</indent>
						<content-type>text/html</content-type>
						<encoding>utf-8</encoding>
						<indent-amount>4</indent-amount>
					</config>
				</p:input>
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:when>
		<p:when test="/output = 'ajax'">
			<p:processor name="oxf:pipeline">
				<p:input name="data" href="#data"/>
				<p:input name="request" href="#request"/>
				<p:input name="config" href="../views/serializations/rdf/html.xpl"/>
				<p:output name="data" id="model"/>
			</p:processor>
			
			<p:processor name="oxf:html-converter">
				<p:input name="data" href="#model"/>
				<p:input name="config">
					<config>
						<content-type>text/plain</content-type>
						<encoding>utf-8</encoding>
					</config>
				</p:input>
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:when>
		<p:otherwise>
			<p:processor name="oxf:identity">
				<p:input name="data" href="#data"/>
				<p:output name="data" id="model"/>
			</p:processor>
			
			<p:processor name="oxf:xml-serializer">
				<p:input name="data" href="#model"/>
				<p:input name="config">
					<config>
						<content-type>application/rdf+xml</content-type>
						<indent>true</indent>
					</config>
				</p:input>
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:otherwise>
	</p:choose>
</p:pipeline>
