<?xml version="1.0" encoding="UTF-8"?>

<!-- this this the XPL for the index view. It aggrecates the config.xml, the SPARQL response model (for listing repositories with CHOs), and the directory reader for generating links for data dumps -->

<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors">

	<p:param type="input" name="data"/>
	<p:param type="output" name="data"/>

	<p:processor name="oxf:directory-scanner">
		<p:input name="config">
			<config>
				<base-directory>oxf:/apps/harvester/download</base-directory>
				<include>*.rdf</include>
				<include>*.ttl</include>
				<include>*.jsonld</include>
			</config>
		</p:input>
		<p:output name="data" id="directory-scan"/>
	</p:processor>

	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="#directory-scan"/>
		<p:input name="config">
			<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xsl xs" version="2.0">

				<xsl:template match="/">
					<files>
						<xsl:for-each select="//file">
							<file>
								<xsl:attribute name="size" select="@size"/>
								<xsl:value-of select="@name"/>
							</file>
						</xsl:for-each>
					</files>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="files"/>
	</p:processor>

	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="aggregate('content', #data, #files, ../../../config.xml)"/>		
		<p:input name="config" href="../../../ui/xslt/pages/index.xsl"/>
		<p:output name="data" ref="data"/>
	</p:processor>
</p:config>
