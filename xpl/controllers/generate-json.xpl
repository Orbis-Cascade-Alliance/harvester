<?xml version="1.0" encoding="UTF-8"?>
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xxforms="http://orbeon.org/oxf/xml/xforms">

	<p:param type="input" name="data"/>	
	
	<p:processor name="oxf:request">
		<p:input name="config">
			<config>
				<include>/request</include>
			</config>
		</p:input>
		<p:output name="data" id="request"/>
	</p:processor>	
	
	<!-- URL Generator config for loading the RDF/XML file -->
	<p:processor name="oxf:unsafe-xslt">		
		<p:input name="data" href="#request"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:output indent="yes"/>
				<xsl:template match="/">
					<xsl:param name="repository" select="/request/parameters/parameter[name='repository']/value"/>
					
					<config>
						<url>
							<xsl:value-of select="concat('oxf:/apps/harvester/download/', $repository, '.rdf')"/>
						</url>						
						<mode>xml</mode>
						<content-type>application/rdf+xml</content-type>
						<encoding>utf-8</encoding>
					</config>			
				</xsl:template>
			</xsl:stylesheet>
		</p:input>		
		<p:output name="data" id="url-generator-config"/>
	</p:processor>
	
	<!-- config for file serializer to write JSON-LD to disk -->
	<p:processor name="oxf:unsafe-xslt">		
		<p:input name="data" href="#request"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:output indent="yes"/>
				<xsl:template match="/">
					<xsl:param name="repository" select="/request/parameters/parameter[name='repository']/value"/>
					
					<config>
						<url>
							<xsl:value-of select="concat('oxf:/apps/harvester/download/', $repository, '.jsonld')"/>
						</url>
						<content-type>text/plain</content-type>
						<make-directories>false</make-directories>
						<append>false</append>
					</config>			
				</xsl:template>
			</xsl:stylesheet>
		</p:input>		
		<p:output name="data" id="file-serializer-config"/>
	</p:processor>
	
	<p:processor name="oxf:url-generator">
		<p:input name="config" href="#url-generator-config"/>
		<p:output name="data" id="xml"/>
	</p:processor>

	<!-- execute XSLT transformation from RDF/XML to JSON-LD -->
	<p:processor name="oxf:pipeline">
		<p:input name="data" href="#xml"/>
		<p:input name="config" href="../views/serializations/rdf/json-ld.xpl"/>
		<p:output name="data" id="json-ld"/>
	</p:processor>
	
	<p:processor name="oxf:file-serializer">
		<p:input name="config" href="#file-serializer-config"/>
		<p:input name="data" href="#json-ld"/>		
	</p:processor>
</p:pipeline>
