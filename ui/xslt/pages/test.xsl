<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
	<xsl:include href="../templates.xsl"/>
	<xsl:variable name="display_path">./</xsl:variable>

	<xsl:template match="/">

		<html lang="en">
			<head>
				<title>
					<xsl:value-of select="/content/config/title"/>
				</title>
				<meta name="viewport" content="width=device-width, initial-scale=1"/>
				<script type="text/javascript" src="http://code.jquery.com/jquery-latest.min.js"/>
				<!-- bootstrap -->
				<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"/>
				<script type="text/javascript" src="http://netdna.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"/>
				<link rel="stylesheet" href="{$display_path}ui/css/style.css"/>
			</head>
			<body>
				<xsl:call-template name="header"/>
				<xsl:call-template name="body"/>
				<xsl:call-template name="footer"/>
			</body>
		</html>
	</xsl:template>

	<xsl:template name="body">
		<div class="container-fluid content">
			<div class="row">
				<div class="col-md-12">
					<h2>Harvester Testing</h2>
					<form action="./test/view" method="GET" role="form" class="form-horizontal">
						<div class="form-group">
							<label for="set" class="col-sm-2 control-label">Set URL</label>
							<div class="col-sm-10">
								<input type="text" name="sets" class="form-control" id="set" style="width:25em"/>
							</div>
						</div>
						<div class="form-group">
							<label for="repository" class="col-sm-2 control-label">Agency Code</label>
							<div class="col-sm-10">
								<input type="text" class="form-control" id="repository" name="repository" style="width:25em"/>
							</div>
						</div>
						<div class="form-group">
							<label for="output" class="col-sm-2 control-label">Output</label>
							<div class="col-sm-10">
								<select id="output" name="output">
									<option value="html" selected="selected">HTML</option>
									<option value="rdf">RDF</option>
								</select>
							</div>
						</div>
						<input type="hidden" name="target" value="dpla"/>
						<input type="hidden" name="mode" value="test"/>
						<input type="submit" value="Submit"/>
					</form>
					<br/>
				</div>
			</div>
		</div>
	</xsl:template>
</xsl:stylesheet>
