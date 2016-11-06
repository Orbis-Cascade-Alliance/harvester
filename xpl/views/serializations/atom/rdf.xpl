<?xml version="1.0" encoding="UTF-8"?>
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors">

	<p:param type="input" name="data"/>
	<p:param type="input" name="controls"/>
	<p:param type="output" name="data"/>
	
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="controls" href="#controls"/>
		<p:input name="data" href="#data"/>
		<p:input name="config" href="../../../../ui/xslt/serializations/atom/rdf.xsl"/>
		<p:output name="data" ref="data"/>
	</p:processor>
</p:pipeline>
