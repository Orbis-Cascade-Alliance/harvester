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
	
	<!-- generate repository input model for SPARQL aggregation -->
	<!-- config for file serializer to write RDF/XML to disk -->
	<p:processor name="oxf:unsafe-xslt">		
		<p:input name="data" href="#request"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:template match="/">
					<repository>
						<xsl:value-of select="/request/parameters/parameter[name='repository']/value"/>
					</repository>			
				</xsl:template>
			</xsl:stylesheet>
		</p:input>		
		<p:output name="data" id="repository"/>
	</p:processor>
	
	<!-- get the SPARQL response model -->
	<p:processor name="oxf:pipeline">
		<p:input name="data" href="#repository"/>
		<p:input name="config" href="../models/sparql/rdf.xpl"/>
		<p:output name="data" id="rdfxml"/>
	</p:processor>
	
	<!-- config for file serializer to write RDF/XML to disk -->
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
						<content-type>application/xml</content-type>
						<make-directories>false</make-directories>
						<append>false</append>
					</config>			
				</xsl:template>
			</xsl:stylesheet>
		</p:input>		
		<p:output name="data" id="file-serializer-config"/>
	</p:processor>
	
	<!-- rdfxml has to be converted back into application/xml -->
	<p:processor name="oxf:xml-converter">
		<p:input name="config">
			<config>
				<method>xml</method>
				<content-type>application/xml</content-type>
				<indent-amount>4</indent-amount>
				<encoding>utf-8</encoding>
				<indent>true</indent>
			</config>
		</p:input>
		<p:input name="data" href="#rdfxml"/>
		<p:output name="data" id="converted"/>				
	</p:processor>
	
	<p:processor name="oxf:file-serializer">
		<p:input name="config" href="#file-serializer-config"/>
		<p:input name="data" href="#converted"/>		
	</p:processor>
</p:pipeline>
