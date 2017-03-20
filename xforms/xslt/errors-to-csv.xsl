<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:numishare="https://github.com/ewg118/numishare" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all"
	version="2.0">
	
	<xsl:template match="/">
		<xsl:text>id,errors&#x0A;</xsl:text>
		<xsl:apply-templates select="//record"/>
	</xsl:template>	
	
	<xsl:template match="record">
		<xsl:value-of select="concat('&#x022;', @id, '&#x022;')"/>
		<xsl:text>,</xsl:text>
		<xsl:value-of select="concat('&#x022;', string-join(error, ';'), '&#x022;')"/>
		<xsl:text>&#x0A;</xsl:text>
	</xsl:template>
</xsl:stylesheet>
