<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
	<xsl:include href="../templates.xsl"/>
	<xsl:variable name="display_path">./</xsl:variable>

	<xsl:template match="/">

		<html lang="en">
			<head>
				<title>
					<xsl:value-of select="/config/title"/>: Test Set</title>
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
								<select name="repository" class="form-control" id="repository" style="width:10em">
									<xsl:for-each select="distinct-values(/config/dams//repository)">
										<xsl:sort/>
										<option value="{.}">
											<xsl:value-of select="."/>
										</option>
									</xsl:for-each>
								</select>
								<!--<input type="text" class="form-control" id="repository" name="repository" style="width:25em"/>-->
							</div>
						</div>
						<div class="form-group">
							<label for="rights" class="col-sm-2 control-label">Rights</label>
							<div class="col-sm-10">
								<select id="rights" name="rights" class="form-control" style="width:10em">
									<option value="">Select Rights Statement (Optional)</option>
									<option value="InC">In Copyright</option>
									<option value="InC-OW-EU">In Copyright - EU orphan work</option>
									<option value="InC-EDU">In Copyright - Educational use permitted</option>
									<option value="InC-NC">In Copyright - Non-commercial use permitted</option>
									<option value="InC-RUU">In Copyright - Rights-holder(s) unlocatable or unidentifiable</option>
									<option value="NoC-CR">No Copyright - Contractual restrictions</option>
									<option value="NoC-NC">No Copyright - Non-commercial use only</option>
									<option value="NoC-OKLR">No Copyright - Other known legal restrictions</option>
									<option value="NoC-US">No Copyright - United States</option>
									<option value="CNE">Copyright not evaluated</option>
									<option value="UND">Copyright undetermined</option>
									<option value="NKC">No known copyright</option>
								</select>
							</div>
						</div>
						<div class="form-group">
							<label for="output" class="col-sm-2 control-label">Output</label>
							<div class="col-sm-10">
								<select id="output" name="output" class="form-control" style="width:10em">
									<option value="html" selected="selected">HTML</option>
									<option value="rdf">RDF</option>
								</select>
							</div>
						</div>
						<input type="hidden" name="target" value="both"/>
						<input type="hidden" name="mode" value="test"/>
						<input type="submit" value="Submit"/>
					</form>
					<br/>
				</div>
			</div>
		</div>
	</xsl:template>
</xsl:stylesheet>
