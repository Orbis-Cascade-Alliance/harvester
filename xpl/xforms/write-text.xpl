<?xml version="1.0" encoding="UTF-8"?>
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline"
	xmlns:oxf="http://www.orbeon.com/oxf/processors">
	
	<p:param type="input" name="configuration"/>
	<p:param type="input" name="doc"/>	
	<p:param type="output" name="data"/>
	
	<p:processor name="oxf:text-converter">
		<p:input name="config">
			<config>
				<method>text</method>								
				<encoding>utf-8</encoding>
			</config>
		</p:input>
		<p:input name="data" href="#doc"/>
		<p:output name="data" id="converted"/>
		<p:output name="data" ref="data"/>		
	</p:processor>
	
	<p:processor name="oxf:file-serializer">
		<p:input name="config" href="#configuration"/>
		<p:input name="data" href="#converted"/>		
	</p:processor>
</p:pipeline>

