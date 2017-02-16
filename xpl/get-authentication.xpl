<!--
    Copyright (C) 2007 Orbeon, Inc.

    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.

    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors">

	<p:param name="dump" type="input"/>
	<p:param name="data" type="output"/>

	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="../config.xml"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:template match="/">
					<config>
						<role>harvester-admin</role>
						<xsl:for-each select="distinct-values(//repository)">
							<role><xsl:value-of select="."/></role>
						</xsl:for-each>
					</config>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="request-security-config"/>
	</p:processor>

	<p:processor xmlns:xforms="http://www.w3.org/2002/xforms" name="oxf:request-security">
		<p:input name="config" href="#request-security-config"/>
		<p:output name="data" ref="data"/>
	</p:processor>

</p:config>
