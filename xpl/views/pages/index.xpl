<?xml version="1.0" encoding="UTF-8"?>

<!-- this this the XPL for the index view. It aggrecates the config.xml, the SPARQL response model (for listing repositories with CHOs), and the directory reader for generating links for data dumps -->

<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors">

	<p:param type="input" name="data"/>
	<p:param type="output" name="data"/>

	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="aggregate('content', #data, ../../../config.xml)"/>		
		<p:input name="config" href="../../../ui/xslt/pages/index.xsl"/>
		<p:output name="data" ref="data"/>
	</p:processor>
</p:config>
