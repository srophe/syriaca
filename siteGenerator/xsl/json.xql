xquery version "3.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:
<xsl:param name="applicationPath" select="'/Users/wsalesky/syriaca/syriaca/syriaca'"/>
    <xsl:param name="staticSitePath" select="'/Users/wsalesky/syriaca/syriaca/syriacaStatic'"/>
    <xsl:param name="dataPath" select="'/Users/wsalesky/syriaca/syriaca/syriaca-data-test/data/'"/>
    <xsl:param name="configPath" select="concat($staticSitePath, '/siteGenerator/components/repo-config.xml')"/>
    <xsl:variable name="config">
        <xsl:if test="doc-available(xs:anyURI($configPath))">
            <xsl:sequence select="document(xs:anyURI($configPath))"/>
        </xsl:if>
    </xsl:variable>
:)
declare variable $local:SITE_PATH := '/Users/wsalesky/syriaca/syriaca/syriacaStatic';
declare variable $local:CONFIG_PATH := concat($local:SITE_PATH, '/siteGenerator/components/repo-config.xml');
declare variable $local:CONFIG := doc(xs:anyURI($local:CONFIG_PATH));

declare function local:buildIndex() {

};

<div>{$local:CONFIG}</div>