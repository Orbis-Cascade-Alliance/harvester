<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:res="http://www.w3.org/2005/sparql-results#" exclude-result-prefixes="#all"
	version="2.0">
	<xsl:include href="../templates.xsl"/>
	<xsl:variable name="display_path">./</xsl:variable>

	<xsl:template match="/">

		<html lang="en">
			<head>
				<title>
					<xsl:value-of select="/config/title"/>
				</title>
				<meta name="viewport" content="width=device-width, initial-scale=1"/>
				<script type="text/javascript" src="http://code.jquery.com/jquery-latest.min.js"/>
				<!-- bootstrap -->
				<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css"/>
				<script type="text/javascript" src="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"/>
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
					<h1>Documentation</h1>
					<p>Most documentation is provided through the Harvester's Github <a href="https://github.com/Orbis-Cascade-Alliance/harvester/wiki">wiki</a>.</p>
					<h2>Web Services</h2>
					<ul>
						<li>
							<a href="https://github.com/Orbis-Cascade-Alliance/harvester/wiki/APIs">APIs</a>
						</li>
						<li>
							<a href="https://github.com/Orbis-Cascade-Alliance/harvester/wiki/Atom-Feed">Atom Feed</a>
						</li>
						<li>
							<a href="https://github.com/Orbis-Cascade-Alliance/harvester/wiki/SPARQL-Endpoint">SPARQL Endpoint</a>
						</li>
					</ul>

					<h2>Data Model</h2>
					<p>The Harvester data model conforms to the <a href="http://dp.la/info/developers/map/">DPLA Metadata Application Profile</a>. Below is an example of four RDF objects for one
						Cultural Heritage Object from Boise State University's contentDM repository.</p>
					<div class="row">
						<div class="col-md-8 col-md-offset-2">
							<pre><![CDATA[<dpla:SourceResource rdf:about="http://digital.boisestate.edu/cdm/ref/collection/roach/id/79">
	<dcterms:title>Boise Fire Department Engine</dcterms:title>
	<dcterms:date rdf:datatype="http://www.w3.org/2001/XMLSchema#gYear">1910</dcterms:date>
	<dcterms:subject>Fire fighters; Fire engines; Horse-drawn vehicles; Horses;</dcterms:subject>
	<dcterms:type>image;</dcterms:type>
	<dcterms:format>image/jpeg</dcterms:format>
	<dcterms:language>eng;</dcterms:language>
	<dcterms:description>Six firefighters ride on a fire engine pulled by three horses. The firefighters are putting on their uniforms as the engine is in motion. Sign on engine reads "B.F.D." The
		phrase "Topping Photo 1910" is handwritten on the photograph.</dcterms:description>
	<dcterms:isPartOf rdf:resource="http://archiveswest.orbiscascade.org/ark:/80444/xv61544"/>
	<dcterms:relation rdf:resource="http://digital.boisestate.edu/oai/oai.php?verb=ListRecords&amp;metadataPrefix=oai_qdc&amp;set=roach"/>
</dpla:SourceResource>
<edm:WebResource rdf:about="http://digital.boisestate.edu/utils/getthumbnail/collection/roach/id/79">
	<edm:rights>placeholder</edm:rights>
</edm:WebResource>
<edm:WebResource rdf:about="http://digital.boisestate.edu/utils/getstream/collection/roach/id/79">
	<edm:rights>placeholder</edm:rights>
</edm:WebResource>
<ore:Aggregation>
	<edm:aggregatedCHO rdf:resource="http://digital.boisestate.edu/cdm/ref/collection/roach/id/79"/>
	<edm:isShownAt rdf:resource="http://digital.boisestate.edu/cdm/ref/collection/roach/id/79"/>
	<edm:dataProvider rdf:resource="http://archiveswest.orbiscascade.org/contact#idbb"/>
	<edm:provider rdf:resource="http://archiveswest.orbiscascade.org/"/>
	<edm:preview rdf:resource="http://digital.boisestate.edu/utils/getthumbnail/collection/roach/id/79"/>
	<edm:object rdf:resource="http://digital.boisestate.edu/utils/getstream/collection/roach/id/79"/>
	<dcterms:modified rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">2014-12-30T22:14:20.112-05:00</dcterms:modified>
</ore:Aggregation>]]></pre>
						</div>
					</div>
					<p>The CHO metadata is stored in the dpla:sourceResource object. Each image URL is designated with the edm:WebSource class, and the ore:Aggregation (which will be given a URI upon
						ingestion into DPLA) points to the CHO URI with edm:aggregatedCHO and edm:isShownAt. The edm:dataProvider is the URI of the repository in the NWDA system. This URI must match
						that in the NWDA repository metadata RDF. The edm:preview contains a link to the thumbnail, and the edm:object is a large-scale image URL. The dcterms:modified is the date of
						ingestion. It is used by the Harvester's front end Atom feed.</p>
					<p>There are two important things to note about the dpla:SourceResource:</p>

					<ul>
						<li>The dcterms:isPartOf links to the finding aid URI.</li>
						<li>The object must contain a dcterms:relation which points to the source OAI-PMH set.</li>
					</ul>
				</div>
			</div>
		</div>
	</xsl:template>
</xsl:stylesheet>
