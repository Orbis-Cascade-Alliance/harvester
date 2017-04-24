<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">

	<xsl:template name="header">
		<!-- Static navbar -->
		<div class="navbar navbar-default navbar-static-top" role="navigation">
			<div class="container-fluid">
				<div class="navbar-header">
					<button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
						<span class="sr-only">Toggle navigation</span>
						<span class="icon-bar"/>
						<span class="icon-bar"/>
						<span class="icon-bar"/>
					</button>
					<a class="navbar-brand logo-nav" href="{$display_path}./">
						<xsl:value-of select="//config/title"/>
					</a>
				</div>
				<div class="navbar-collapse collapse">
					<ul class="nav navbar-nav">
						<li>
							<a href="{$display_path}sparql">SPARQL</a>
						</li>
						<li>
							<a href="{$display_path}documentation">Documentation</a>
						</li>
					</ul>
					<!--<div class="col-sm-3 col-md-3 pull-right">
						<form class="navbar-form" role="search" action="{$display_path}id/" method="get">
							<div class="input-group">
								<input type="text" class="form-control" placeholder="Search" name="q" id="srch-term"/>
								<div class="input-group-btn">
									<button class="btn btn-default" type="submit">
										<i class="glyphicon glyphicon-search"/>
									</button>
								</div>
							</div>
						</form>
					</div>-->
				</div>
				<!--/.nav-collapse -->
			</div>
		</div>
	</xsl:template>

	<xsl:template name="footer">
		<div class="container-fluid">
			<div class="row">
				<div class="col-md-12">
					<footer>
						<div class="footer-left-col"> © 2017 Orbis Cascade Alliance <br/> 2288 Oakmont Way Eugene, OR 97401 </div>
						<div class="footer-right-col"> (541) 246-2470 <br/>
							<a href="mailto:info@orbiscascade.org">info@orbiscascade.org</a>
						</div>
						
						<nav>
							<ul>
								<li>
									<a href="https://www.orbiscascade.org/programs">Programs</a>
								</li>
								<li>
									<a href="https://www.orbiscascade.org/teams">Teams</a>
								</li>
								<li>
									<a href="https://www.orbiscascade.org/docs">Documentation</a>
								</li>
								<li>
									<a href="https://www.orbiscascade.org/shared-ils">Shared ILS</a>
								</li>
								<li>
									<a href="https://www.orbiscascade.org/about">About</a>
								</li>
								<li>
									<a href="https://www.orbiscascade.org/contact">Contact</a>
								</li>
							</ul>
						</nav>
					</footer>
				</div>
			</div>
		</div>		
	</xsl:template>

</xsl:stylesheet>
