<?xml version="1.0" encoding="UTF-8"?>
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors">

	<p:param type="input" name="data"/>
	<p:param type="input" name="controls"/>
	<p:param type="output" name="data"/>

	<p:processor name="oxf:request">
		<p:input name="config">
			<config>
				<include>/request</include>
			</config>
		</p:input>
		<p:output name="data" id="request"/>
	</p:processor>

	<!-- set up iteration of sets -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="#request"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:output indent="yes"/>
				<xsl:template match="/">
					<xsl:copy-of select="/request"/>
					<!--<sets>
						<xsl:for-each select="tokenize(/request/parameters/parameter[name='sets']/value, '\|')">
							<set>
								<xsl:value-of select="."/>
							</set>
						</xsl:for-each>
					</sets>-->
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<!--<p:output name="data" id="sets"/>-->
		<p:output name="data" ref="data"/>
		
	</p:processor>
	
	<!--<p:for-each href="#sets" select="//set" id="controls-model" root="new">
		<p:processor name="oxf:unsafe-xslt">
			<p:input name="request" href="#request"/>
			<p:input name="data" href="current()"/>
			<p:input name="config">
				<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
					<xsl:output indent="yes"/>
					
					<xsl:param name="ark" select="doc('input:request')/request/parameters/parameter[name='ark']/value"/>
					
					<xsl:template match="/">
						<controls>
							<ark>
								<xsl:value-of select="$ark"/>
							</ark>
							<id><xsl:value-of select="//feed[starts-with(., url)]/id"/></id>
						</controls>
					</xsl:template>
				</xsl:stylesheet>
			</p:input>
			<p:output name="data" ref="controls-model"/>
			<!-\-<p:output name="data" ref="data"/>-\->
		</p:processor>
	</p:for-each>
	
	<p:processor name="oxf:identity">
		<p:input name="data" href="#controls-model"/>
		<p:output name="data" ref="data"/>
	</p:processor>-->
</p:pipeline>
