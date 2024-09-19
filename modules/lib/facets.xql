xquery version "3.1";

(:
 : Srophe application facets module. 
 :  1) Creates lucene index definitions based on facet-def.xml files living in the Srophe application.
 :  2) Creates xquery filters for passing facets to search/browse functions within the Srophe application. 
 :  3) Creates facet display for search/browse HTML pages in Srophe application
 :
 : Uses the following eXist-db specific functions:
 :      util:eval 
 :      request:get-parameter
 :      request:get-parameter-names()
 : 
 : Facet definition files based on the EXpath specs. 
 : @see http://expath.org/spec/facet
 :
 : @author Winona Salesky
 : @version .05    
:)

module namespace sf = "http://srophe.org/srophe/facets";
import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";
import module namespace slider = "http://srophe.org/srophe/slider" at "date-slider.xqm";
declare namespace srophe="https://srophe.app";
declare namespace facet="http://expath.org/ns/facet";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $sf:QUERY_OPTIONS := map {
    "leading-wildcard": "yes",
    "filter-rewrite": "yes"
};

declare variable $sf:sortFieldsConfig := $config:get-config//*:sortFields/*:fields;

(: Add sort fields to browse and search options. Used for sorting, add sort fields and functions, add sort function:)
declare variable $sf:sortFields :=  let $fields := 
                                        if($sf:sortFieldsConfig != '') then
                                            for $f in $sf:sortFieldsConfig
                                            return $f 
                                        else ("title", "idno", "author","titleSyriac","titleArabic")
                                    return map { "fields": $fields };

declare function sf:words-to-camel-case
  ( $arg as xs:string? )  as xs:string {

     string-join((tokenize($arg,'\s+')[1],
       for $word in tokenize($arg,'\s+')[position() > 1]
       return sf:capitalize-first($word))
      ,'')
 };
 
 declare function sf:capitalize-first
  ( $arg as xs:string? )  as xs:string? {

   concat(upper-case(substring($arg,1,1)),
             substring($arg,2))
 };
(:~ 
 : Build indexes for fields and facets as specified in facet-def.xml and search-config.xml files
 : Note: Hold off on fields until boost has been added. See: https://github.com/eXist-db/exist/issues/3403
:)
declare function sf:build-index(){
<collection xmlns="http://exist-db.org/collection-config/1.0">
    <index xmlns="http://exist-db.org/collection-config/1.0" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:srophe="https://srophe.app">
        <lucene diacritics="no">
            <module uri="http://srophe.org/srophe/facets" prefix="sf" at="xmldb:exist:///{$config:app-root}/modules/lib/facets.xql"/>
            <text qname="tei:TEI">
            {
            let $facets :=     
                for $f in collection($config:app-root)//facet:facet-definition
                let $path := document-uri(root($f))
                group by $facet-grp := $f/@name
                return 
                    if($f[1]/facet:group-by/@function != '') then 
                       (<facet dimension="{sf:words-to-camel-case($facet-grp)}" expression="sf:facet(., {concat("'",$path[1],"'")}, {concat("'",$facet-grp,"'")})"/>(:,
                        <field name="facet-{sf:words-to-camel-case($facet-grp)}" expression="sf:facet(descendant-or-self::tei:body, {concat("'",$path[1],"'")}, {concat("'",$facet-grp,"'")})"/>:))
                    else if($f[1]/facet:range) then
                       (<facet dimension="{sf:words-to-camel-case($facet-grp)}" expression="sf:facet(., {concat("'",$path[1],"'")}, {concat("'",$facet-grp,"'")})"/>(:,
                       <field name="facet-{sf:words-to-camel-case($facet-grp)}" expression="sf:facet(descendant-or-self::tei:body, {concat("'",$path[1],"'")}, {concat("'",$facet-grp,"'")})"/>:))
                    else 
                        (<facet dimension="{sf:words-to-camel-case($facet-grp)}" expression="{replace($f[1]/facet:group-by/facet:sub-path/text(),"&#34;","'")}"/>(:,
                        <field name="facet-{sf:words-to-camel-case($facet-grp)}" expression="{replace($f[1]/facet:group-by/facet:sub-path/text(),"&#34;","'")}"/>:))
            return 
                $facets
            }
            {
                if($sf:sortFieldsConfig != '') then 
                    for $f in $sf:sortFieldsConfig
                    return 
                    element field {
                            attribute { "name" } {$f/text()},
                            attribute { "expression" } {
                                if($f/@xpath[. != '']) then
                                    if(starts-with($f/@xpath,'tei:TEI')) then concat('ancestor-or-self::',$f/@xpath) else string($f/@xpath)
                                else concat("sf:field(descendant-or-self::tei:body,'",$f/text(),"')")
                            }
                           }
                else 
                   (<field name="title" expression="sf:field(.,'title')"/>,
                    <field name="idno" expression="sf:field(.,'idno')"/>,
                    <field name="titleSyriac" expression="sf:field(., 'titleSyriac')"/>,
                    <field name="titleArabic" expression="sf:field(., 'titleArabic')"/>,
                    <field name="author" expression="sf:field(., 'author')"/>,
                    <field name="cbssLangFilter" expression="sf:field(., 'cbssLangFilter')"/>)
            }
            </text>
            <text qname="tei:fileDesc"/>
            <text qname="tei:biblStruct"/>
            <!--<text qname="tei:div"/>-->
            <text qname="tei:author" boost="5.0"/>
            <text qname="tei:persName" boost="5.0"/>
            <text qname="tei:placeName" boost="5.0"/>
            <text qname="tei:title" boost="10.5"/>
            <text qname="tei:location"/>
            <text qname="tei:desc" boost="2.0"/>
            <!--<text qname="tei:event"/> -->
            <text qname="tei:note"/>
            <text qname="tei:pubPlace"/>
            <text qname="tei:publisher"/>
            
            <!--<text qname="tei:term"/>-->
        </lucene> 
        <range>
            <create qname="@syriaca-computed-start" type="xs:date"/>
            <create qname="@syriaca-computed-end" type="xs:date"/>
            <create qname="@type" type="xs:string"/>
            <create qname="@ana" type="xs:string"/>
            <create qname="@syriaca-tags" type="xs:string"/>
            <create qname="@srophe:tags" type="xs:string"/>
            <create qname="@when" type="xs:string"/>
            <create qname="@target" type="xs:string"/>
            <create qname="@who" type="xs:string"/>
            <create qname="@ref" type="xs:string"/>
            <create qname="@uri" type="xs:string"/>
            <create qname="@where" type="xs:string"/>
            <create qname="@active" type="xs:string"/>
            <create qname="@passive" type="xs:string"/>
            <create qname="@mutual" type="xs:string"/>
            <create qname="@name" type="xs:string"/>
            <create qname="@xml:lang" type="xs:string"/>
            <create qname="@level" type="xs:string"/>
            <create qname="@status" type="xs:string"/>
            <create qname="tei:idno" type="xs:string"/>
            <!--
            <create qname="tei:title" type="xs:string"/>
            -->
            <create qname="tei:geo" type="xs:string"/>
            <create qname="tei:relation" type="xs:string"/>
            <create qname="tei:persName" type="xs:string"/>
            <create qname="tei:placeName" type="xs:string"/>
            <!--
            <create qname="tei:author" type="xs:string"/>
            -->
        </range>
    </index>
</collection>
};

(:~ 
 : Update collection.xconf file for data application, can be called by post install script, or index.xql
 : Save collection to correct application subdirectory in /db/system/config
 : Trigger a re-index.
 : 
 : @note reindex does not seem to work... investigate 
 :)
declare function sf:update-index(){
    let $updateXconf := 
      try {
            let $configPath := concat('/db/system/config',replace($config:data-root,'/data',''))
            return xmldb:store($configPath, 'collection.xconf', sf:build-index())
        } catch * {('error: ',concat($err:code, ": ", $err:description))}
    return 
        if(starts-with($updateXconf,'error:')) then
            $updateXconf
        else xmldb:reindex($config:data-root)
};

(: Build facet path based on facet definition file. Used by collection.xconf to build facets at index time. 
 : @param $path - path to facet definition file, if empty assume root.
 : @param $name - name of facet in facet definition file. 
:)
declare function sf:facet($element as item()*, $path as xs:string, $name as xs:string){
    let $facet-definition :=  
        if(doc-available($path)) then
            doc($path)//facet:facet-definition[@name=$name]
        else () 
    let $xpath := $facet-definition/facet:group-by/facet:sub-path/text()    
    return 
        if(not(empty($facet-definition))) then  
           if($facet-definition/facet:group-by/@function != '') then 
             try { 
                   util:eval(concat('sf:facet-',string($facet-definition/facet:group-by/@function),'($element,$facet-definition, $name)'))
                } catch * {concat($err:code, ": ", $err:description)}
            else if($facet-definition/facet:range) then try { 
                   sf:facet-range($element,$facet-definition, $name)
                } catch * {concat($err:code, ": ", $err:description)}
            else util:eval(concat('$element/',$xpath))
        else ()
};

(: For sort fields, or fields not defined in search-config.xml :)
declare function sf:field($element as item()*, $name as xs:string){
    try { 
        util:eval(concat('sf:field-',$name,'($element,$name)'))
    } catch * {concat($err:code, ": ", $err:description)}
};



(:~ 
 : Build fields path based on search-config.xml file. Used by collection.xconf to build facets at index time. 
 : @param $path - path to facet definition file, if empty assume root.
 : @param $name - name of facet in facet definition file. 
 : 
 : @note not currently implemented
:)
declare function sf:field($element as item()*, $path as xs:string, $name as xs:string){
    let $field-definition :=  
        if(doc-available($path)) then
            doc($path)//*:field[@name=$name]
        else () 
    let $xpath := $field-definition/*:expression/text()    
    return 
        if(not(empty($field-definition))) then  
            if($field-definition/@function != '') then 
                try { 
                    util:eval(concat('sf:field-',string($field-definition/@function),'($element,$field-definition, $name)'))
                } catch * {concat($err:code, ": ", $err:description)}
            else util:eval(concat('$element/',$xpath)) 
        else ()  
};

(:~ 
 : Create HTML display for facets
 : Use facet-definition files for labels and sort options
:)
declare function sf:display($result as item()*, $facet-definition as item()*) {
    let $facet-definitions := 
        if($facet-definition/self::facet:facet-definition) then 'definition' 
        else $facet-definition/facet:facets/facet:facet-definition
    for $facet in $facet-definitions
    let $name := string($facet/@name)
    let $count := if(request:get-parameter(concat('all-',$name), '') = 'on' ) then () else string($facet/facet:max-values/@show)
    let $f := ft:facets($result, $name, ())
    let $sortedFacets :=  
                        for $key at $p in map:keys($f)
                        let $value := map:get($f, $key)
                        order by $key ascending
                        return 
                            <facet label="{$key}" value="{$value}"/>
    let $total := count($sortedFacets)                            
    return 
        if($facet/@display="slider") then ()
        else if (map:size($f) > 0) then
            <span class="facet-grp">
                <span class="facet-title">{string($facet/@label)}</span>
                <span class="facet-list">
                {(
                    for $facet at $n in subsequence($sortedFacets,1,5)
                    let $label := string($facet/@label)
                    let $count := string($facet/@value)
                    let $param-name := concat('facet-',$name)
                    let $facet-param := concat($param-name,'=',encode-for-uri($label))
                    let $active := if(request:get-parameter($param-name, '') = $label) then 'active' else ()
                    let $url-params := 
                                    if($active) then replace(replace(replace(request:get-query-string(),encode-for-uri($label),''),concat($param-name,'='),''),'&amp;&amp;','&amp;')
                                    else if(request:get-parameter('start', '')) then '&amp;start=1'
                                    else if(request:get-query-string() != '') then concat($facet-param,'&amp;',request:get-query-string())
                                    else $facet-param
                    return 
                        <a href="?{$url-params}" class="facet-label btn btn-default {$active}" num="{$n}">
                                    {if($active) then (<span class="glyphicon glyphicon-remove facet-remove"></span>)else ()}
                                    {$label} <span class="count"> ({$count})</span> </a>,
                                    
                    <div id="view{$name}" class="collapse">
                        {
                        for $facet at $n in subsequence($sortedFacets,6,$total)
                        let $label := string($facet/@label)
                        let $count := string($facet/@value)
                        let $param-name := concat('facet-',$name)
                        let $facet-param := concat($param-name,'=',encode-for-uri($label))
                        let $active := if(request:get-parameter($param-name, '') = $label) then 'active' else ()
                        let $url-params := 
                                        if($active) then replace(replace(replace(request:get-query-string(),encode-for-uri($label),''),concat($param-name,'='),''),'&amp;&amp;','&amp;')
                                        else if(request:get-parameter('start', '')) then '&amp;start=1'
                                        else if(request:get-query-string() != '') then concat($facet-param,'&amp;',request:get-query-string())
                                        else $facet-param
                        return 
                            <a href="?{$url-params}" class="facet-label btn btn-default {$active}" num="{$n}">
                                        {if($active) then (<span class="glyphicon glyphicon-remove facet-remove"></span>)else ()}
                                        {$label} <span class="count"> ({$count})</span> </a>
                        }
                    </div>,
                    if($total gt 5) then 
                    <a href="#" data-toggle="collapse" data-target="#view{$name}" class="facet-label btn btn-info viewMore">View All</a>
                    else (),
                    <br/>
                    )}
                </span>
            </span>
        else () 
};

(:sf:displayKeywords:)
declare function sf:displayKeywords($result as item()*, $facet-definition as item()*, $sort-option as xs:string*) {
    let $facet-definitions := 
        if($facet-definition/self::facet:facet-definition) then 'definition' 
        else $facet-definition/facet:facets/facet:facet-definition[@name='cbssKeywords']
    for $facet in $facet-definitions
    let $name := string($facet/@name)
    let $count := if(request:get-parameter(concat('all-',$name), '') = 'on' ) then () else string($facet/facet:max-values/@show)
    let $f := ft:facets($result, $name, ())
    let $sortedFacets :=  
                        for $key at $p in map:keys($f)
                        let $value := map:get($f, $key)
                        order by $key ascending
                        return 
                            <facet label="{$key}" value="{$value}"/>
    let $sort := if($sort-option != '') then $sort-option else 'A'                            
    let $total := count($sortedFacets)                            
    return 
        <span class="facet-list">
                {(
                    for $facet at $n in $sortedFacets[matches(@label,concat('^[',$sort,lower-case($sort),']'))]
                    let $label := string($facet/@label)
                    let $count := string($facet/@value)
                    let $param-name := concat('facet-',$name)
                    let $facet-param := concat($param-name,'=',encode-for-uri($label))
                    let $active := if(request:get-parameter($param-name, '') = $label) then 'active' else ()
                    let $url-params := 
                                    if($active) then replace(replace(replace(request:get-query-string(),encode-for-uri($label),''),concat($param-name,'='),''),'&amp;&amp;','&amp;')
                                    else if(request:get-parameter('start', '')) then '&amp;start=1'
                                    else if(request:get-query-string() != '') then concat($facet-param,'&amp;',request:get-query-string())
                                    else $facet-param
                    
                    return 
                        <a href="search.html?{$url-params}" class="facet-label {$active}" num="{$n}">
                                    {if($active) then (<span class="glyphicon glyphicon-remove facet-remove"></span>)else ()}
                                    {$label} <span class="count"> ({$count})</span> </a>
                    )}
                </span>
};
(:~ 
 : Add generic sort option to facets 
 : @depreciated 
:)
declare function sf:sort($facets as map(*)?) {
    array {
        if (exists($facets)) then
            for $key in map:keys($facets)
            let $value := map:get($facets, $key)
            order by $key ascending
            return
                map { $key: $value }
        else
            ()
    }
};


(:~ 
 : Add sort option to facets based on facet definition 
 : Options are
 :    sort by value (ascending/descending), 
 :    sort by result count (ascending/descending) 
 :    sort on range order attribute (ascending/descending) . 
 : Range facets sort on order attribute. Example: 
 :    <range type="xs:year">
 :           <bucket lt="0001-01-01" name="BC dates" order="1"/>
 :           <bucket gt="0001-01-01" lt="0100-01-01" name="1-100" order="2"/>
 :   </range>        
:)
declare function sf:sort($facets as map(*)?, $facet-definition) {
if($facet-definition/facet:order-by/text() = 'value') then
    if($facet-definition/facet:order-by[@direction='descending']) then
        array {
            if (exists($facets)) then
                for $key in map:keys($facets)
                let $value := map:get($facets, $key)
                order by $key descending
                return
                    map { $key: $value }
            else
                ()
        }
    else 
        array {
            if (exists($facets)) then
                for $key in map:keys($facets)
                let $value := map:get($facets, $key)
                order by $key ascending
                return
                    map { $key: $value }
            else
                ()
        }
else
if($facet-definition/facet:range) then
    if($facet-definition/facet:order-by[@direction='descending']) then
        array {
            if (exists($facets)) then
                for $key in map:keys($facets)
                let $value := map:get($facets, $key)
                let $order := string($facet-definition/facet:range/facet:bucket[@name = $key]/@order)
                let $order := if($order castable as xs:integer) then xs:integer($order) else 0
                order by $order descending
                return
                    map { $key: $value }
            else
                ()
        }
    else 
        array {
            if (exists($facets)) then
                for $key in map:keys($facets)
                let $value := map:get($facets, $key)
                let $order := string($facet-definition/facet:range/facet:bucket[@name = $key]/@order)
                let $order := if($order castable as xs:integer) then xs:integer($order) else 0
                order by $order ascending
                return
                    map { $key: $value }
            else
                ()
        }
else if($facet-definition/facet:order-by[@direction='descending']) then
    array {
        if(exists($facets)) then
            for $key in map:keys($facets)
            let $value := map:get($facets, $key)
            order by $value descending
            return
                map { $key: $value }
        else
            ()
    }
else 
 array {
        if(exists($facets)) then
            for $key in map:keys($facets)
            let $value := map:get($facets, $key)
            order by $value ascending
            return
                map { $key: $value }
        else
            ()
    }
};
(:~
 : Build map for search query
 : Used by search functions to add facet query to search/browse queries. 
 :)
declare function sf:facet-query() {
    map:merge((
        $sf:QUERY_OPTIONS,
        $sf:sortFields,
        map {
            "facets":
                map:merge((
                    for $param in request:get-parameter-names()[starts-with(., 'facet-')]
                    let $dimension := substring-after($param, 'facet-')
                    return
                        map {
                            $dimension: request:get-parameter($param, ())
                        }
                ))
        }
    ))
};

declare function sf:facets() {
        map {
            "facets":
                map:merge((
                    for $param in request:get-parameter-names()[starts-with(., 'facet-')]
                    let $dimension := substring-after($param, 'facet-')
                    return
                        map {
                            $dimension: request:get-parameter($param, ())
                        }
                ))
        }
};



(:~
 : Adds type casting when type is specified facet:facet:group-by/@type
 : @param $value of xpath
 : @param $type value of type attribute
:)
declare function sf:type($value as item()*, $type as xs:string?) as item()*{
    if($type != '') then  
        if($type = 'xs:string') then xs:string($value)
        else if($type = 'xs:string') then xs:string($value)
        else if($type = 'xs:decimal') then xs:decimal($value)
        else if($type = 'xs:integer') then xs:integer($value)
        else if($type = 'xs:long') then xs:long($value)
        else if($type = 'xs:int') then xs:int($value)
        else if($type = 'xs:short') then xs:short($value)
        else if($type = 'xs:byte') then xs:byte($value)
        else if($type = 'xs:float') then xs:float($value)
        else if($type = 'xs:double') then xs:double($value)
        else if($type = 'xs:dateTime') then xs:dateTime($value)
        else if($type = 'xs:date') then xs:date($value)
        else if($type = 'xs:gYearMonth') then xs:gYearMonth($value)        
        else if($type = 'xs:gYear') then xs:gYear($value)
        else if($type = 'xs:gMonthDay') then xs:gMonthDay($value)
        else if($type = 'xs:gMonth') then xs:gMonth($value)        
        else if($type = 'xs:gDay') then xs:gDay($value)
        else if($type = 'xs:duration') then xs:duration($value)        
        else if($type = 'xs:anyURI') then xs:anyURI($value)
        else if($type = 'xs:Name') then xs:Name($value)
        else $value
    else $value
};

(:~
 : Used to lookup controlled values in the supplied odd file. See sf:facet-persNameLang() for an example
:)
declare function sf:odd2text($element as xs:string?, $label as xs:string?) as xs:string* {
    let $odd-path := $config:get-config//repo:odd/text()
    let $odd-file := 
                    if($odd-path != '') then
                        if(starts-with($odd-path,'http')) then 
                            hc:send-request(<hc:request href="{xs:anyURI($odd-path)}" method="get"/>)[2]
                        else doc($config:app-root || $odd-path)
                    else ()
    return 
        if($odd-path != '') then
            let $odd := $odd-file
            return 
                try {
                    if($odd/descendant::*[@ident = $element][1]/descendant::tei:valItem[@ident=$label][1]/tei:gloss[1]/text()) then 
                        $odd/descendant::*[@ident = $element][1]/descendant::tei:valItem[@ident=$label][1]/tei:gloss[1]/text()
                    else if($odd/descendant::tei:valItem[@ident=$label][1]/tei:gloss[1]/text()) then 
                        $odd/descendant::tei:valItem[@ident=$label][1]/tei:gloss[1]/text()
                    else ()    
                } catch * {
                    <error>Caught error {$err:code}: {$err:description}</error>
                }  
         else ()
};

(:~ 
 : Syriaca.org strip non sort characters for sorting 
 :)
declare function sf:build-sort-string($titlestring as xs:string?) as xs:string* {
    replace(normalize-space($titlestring),'^\s+|^[‘|ʻ|ʿ|ʾ]|^[tT]he\s+[^\p{L}]+|^[dD]e\s+|^[dD]e-|^[oO]n\s+[aA]\s+|^[oO]n\s+|^[aA]l-|^[aA]n\s|^[aA]\s+|^\d*\W|^[^\p{L}]','')
};

(:~ 
 : Syriaca.org strip non sort characters for sorting 
 :)
declare function sf:build-sort-string-arabic($titlestring as xs:string?) as xs:string* {
    replace(
    replace(
      replace(
        replace(
          replace($titlestring,'^\s+',''), (:remove leading spaces. :)
            '[ً-ٖ]',''), (:remove vowels and diacritics :)
                '(^|\s)(ال|أل|ٱل)',''), (: remove all definite articles :)
                    'آ|إ|أ|ٱ','ا'), (: normalize letter alif :)
                        '^(ابن|إبن|بن)','') (:remove all forms of (ابن) with leading space :)
};

(: Custom search fields, some generic facets provided here, including for handling ranges, and arrays :)

(:~
 : Group by array is used for facets with multiple items in an attribute, common in TEI attributes.  
 :)
declare function sf:facet-group-by-array($element as item()*, $facet-definition as item(), $name as xs:string){
    let $xpath := $facet-definition/facet:group-by/facet:sub-path/text()    
    return tokenize(util:eval(concat('$element/',$xpath)),' ') 
};

(:~
 : Range facets 
 : Example range facet: 
    <range type="xs:year">
        <bucket lt="0001" name="BC dates" order="22"/>
        <bucket gt="1600-01-01" lt="1700-01-01" name="1600-1700" order="5"/>
        <bucket gt="1700-01-01" lt="1800-01-01" name="1700-1800" order="4"/>
        <bucket gt="1800-01-01" lt="1900-01-01" name="1800-1900" order="3"/>
        <bucket gt="1900-01-01" lt="2000-01-01" name="1900-2000" order="2"/>
        <bucket gt="2000-01-01" name="2000 +" order="1"/>
    </range>
:)
declare function sf:facet-range($element as item()*, $facet-definition as item(), $name as xs:string){
    let $range := $facet-definition/facet:range 
    for $r in $range/facet:bucket
    let $path := if($r/@lt and $r/@lt != '' and $r/@gt and $r/@gt != '') then
                    concat('$element/',$facet-definition/descendant::facet:sub-path/text(),'[. >= "', sf:type($r/@gt, $range/@type),'" and . <= "',sf:type($r/@lt, $range/@type),'"]')
                 else if($r/@lt and $r/@lt != '' and (not($r/@gt) or $r/@gt ='')) then 
                    concat('$element/',$facet-definition/descendant::facet:sub-path/text(),'[. <= "',sf:type($r/@lt, $range/@type),'"]')
                 else if($r/@gt and $r/@gt != '' and (not($r/@lt) or $r/@lt ='')) then 
                    concat('$element/',$facet-definition/descendant::facet:sub-path/text(),'[. >= "', sf:type($r/@gt, $range/@type),'"]')
                 else if($r/@eq) then
                    concat('$element/',$facet-definition/descendant::facet:sub-path/text(),'[', $r/@eq ,']')
                 else ()
    let $f := util:eval($path)
    return if($f) then $r/@name else()
};

(:~
 : TEI Title field, specific to Srophe applications 
 :)
declare function sf:field-title($element as item()*, $name as xs:string){
    if($element/descendant-or-self::*[contains(@syriaca-tags,'#syriaca-headword')][contains(@xml:lang,'en')][not(empty(node()))]) then 
        let $en := $element/descendant-or-self::*[contains(@syriaca-tags,'#syriaca-headword')][contains(@xml:lang,'en')][not(empty(node()))][1]
        let $syr := string-join($element/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1],' ')
        return sf:build-sort-string(concat($en, if($syr != '') then  concat(' - ', $syr) else ()))
    else if($element/descendant-or-self::*[contains(@srophe:tags,'#headword')][contains(@xml:lang,'en')][not(empty(node()))]) then
        let $en := $element/descendant-or-self::*[contains(@srophe:tags,'#headword')][contains(@xml:lang,'en')][not(empty(node()))][1]
        let $syr := string-join($element/descendant::*[contains(@srophe:tags,'#headword')][matches(@xml:lang,'^syr')][1],' ')
        return sf:build-sort-string(concat($en, if($syr != '') then  concat(' - ', $syr) else ()))
    else if($element/descendant-or-self::*[contains(@srophe:tags,'#syriaca-headword')][contains(@xml:lang,'en')][not(empty(node()))]) then
        let $en := $element/descendant-or-self::*[contains(@srophe:tags,'#syriaca-headword')][contains(@xml:lang,'en')][not(empty(node()))][1]
        let $syr := string-join($element/descendant::*[contains(@srophe:tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1],' ')
        return sf:build-sort-string(concat($en, if($syr != '') then  concat(' - ', $syr) else ()))       
    else if($element/ancestor-or-self::tei:TEI/descendant::tei:biblStruct) then 
        for $title in $element/ancestor-or-self::tei:TEI/descendant::tei:biblStruct/descendant::tei:title
        return sf:build-sort-string($title)         
    else sf:build-sort-string($element/ancestor-or-self::tei:TEI/descendant::tei:titleStmt/tei:title[1])
};

(:~
 : TEI idno field, specific to Srophe applications 
 :)
declare function sf:field-idno($element as item()*, $name as xs:string){
    replace($element/descendant::tei:publicationStmt/tei:idno[@type="URI"][1],'/tei','')
};

(:~
 : TEI Title field - Syriac, specific to Srophe applications 
 :)
declare function sf:field-titleSyriac($element as item()*, $name as xs:string){
    if($element/descendant-or-self::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^syr')]) then 
        let $syr := string-join($element/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][not(empty(node()))][1],' ')
        return $syr
    else if($element/descendant-or-self::*[contains(@srophe:tags,'#headword')][matches(@xml:lang,'^syr')]) then
        let $syr := string-join($element/descendant::*[contains(@srophe:tags,'#headword')][matches(@xml:lang,'^syr')][not(empty(node()))][1],' ')
        return $syr
    else if($element/descendant-or-self::*[contains(@srophe:tags,'#syriaca-headword')][matches(@xml:lang,'^syr')]) then
        let $syr := string-join($element/descendant::*[contains(@srophe:tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][not(empty(node()))][1],' ')
        return $syr    
    else ()
};

(:~
 : TEI Title field - Arabic, specific to Srophe applications 
 :)
declare function sf:field-titleArabic($element as item()*, $name as xs:string){
    if($element/descendant-or-self::*[contains(@syriaca-tags,'#syriaca-headword')][@xml:lang = 'ar']) then 
        for $title in $element/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][@xml:lang = 'ar']
        let $ar := string-join($title/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][@xml:lang = 'ar'][not(empty(node()))],' ')
        return sf:build-sort-string-arabic($ar)
    else if($element/descendant-or-self::*[contains(@srophe:tags,'#headword')][@xml:lang = 'ar']) then
        for $title in $element/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][@xml:lang = 'ar']
        let $ar := string-join($element/descendant::*[contains(@srophe:tags,'#headword')][@xml:lang = 'ar'][not(empty(node()))],' ')
        return sf:build-sort-string-arabic($ar)
    else if($element/descendant::tei:person/tei:persName[@xml:lang = 'ar']) then 
        for $title in $element/descendant::tei:person/tei:persName[@xml:lang = 'ar']
        return sf:build-sort-string-arabic($title) 
    else if($element/descendant::tei:place/tei:placeName[@xml:lang = 'ar']) then 
        for $title in $element/descendant::tei:place/tei:placeName[@xml:lang = 'ar']
        return sf:build-sort-string-arabic($title)
    else if($element/descendant::tei:bibl/tei:title[@xml:lang = 'ar']) then 
        for $title in $element/descendant::tei:bibl/tei:title[@xml:lang = 'ar']
        return sf:build-sort-string-arabic($title)
    else if($element/descendant::tei:teiHeader/tei:title[@xml:lang = 'ar']) then 
        for $title in $element/descendant::tei:teiHeader/tei:title[@xml:lang = 'ar']
        return sf:build-sort-string-arabic($title)           
    else ()
};

(:~
 : TEI Title field - French, specific to Srophe applications 
 :)
declare function sf:field-titleFrench($element as item()*, $name as xs:string){
    if($element/descendant-or-self::*[contains(@syriaca-tags,'#syriaca-headword')][@xml:lang = 'fr']) then 
        for $title in $element/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][@xml:lang = 'fr']
        let $ar := string-join($title/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][@xml:lang = 'fr'][not(empty(node()))],' ')
        return sf:build-sort-string($ar)
    else if($element/descendant-or-self::*[contains(@srophe:tags,'#headword')][@xml:lang = 'fr']) then
        for $title in $element/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][@xml:lang = 'fr']
        let $ar := string-join($element/descendant::*[contains(@srophe:tags,'#headword')][@xml:lang = 'fr'][not(empty(node()))],' ')
        return sf:build-sort-string($ar)
    else if($element/descendant::tei:person/tei:persName[@xml:lang = 'fr']) then 
        for $title in $element/descendant::tei:person/tei:persName[@xml:lang = 'fr'][1]
        return sf:build-sort-string($title) 
    else if($element/descendant::tei:place/tei:placeName[@xml:lang = 'fr']) then 
        for $title in $element/descendant::tei:place/tei:placeName[@xml:lang = 'fr'][1]
        return sf:build-sort-string($title)        
    else ()
};

(:~
 : TEI Title field - French, specific to Srophe applications 
 :)
declare function sf:field-titleTransliteration($element as item()*, $name as xs:string){
    if($element/descendant-or-self::*[contains(@syriaca-tags,'#syriaca-headword')][@xml:lang = 'en-x-gedsh']) then 
        for $title in $element/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][@xml:lang = 'en-x-gedsh']
        let $ar := string-join($title/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][@xml:lang = 'en-x-gedsh'][not(empty(node()))],' ')
        return sf:build-sort-string($ar)
    else if($element/descendant-or-self::*[contains(@srophe:tags,'#headword')][@xml:lang = 'en-x-gedsh']) then
        for $title in $element/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][@xml:lang = 'en-x-gedsh']
        let $ar := string-join($element/descendant::*[contains(@srophe:tags,'#headword')][@xml:lang = 'en-x-gedsh'][not(empty(node()))],' ')
        return sf:build-sort-string($ar)
    else if($element/descendant::tei:person/tei:persName[@xml:lang = 'en-x-gedsh']) then 
        for $title in $element/descendant::tei:person/tei:persName[@xml:lang = 'en-x-gedsh']
        return sf:build-sort-string($title) 
    else if($element/descendant::tei:place/tei:placeName[@xml:lang = 'en-x-gedsh']) then 
        for $title in $element/descendant::tei:place/tei:placeName[@xml:lang = 'en-x-gedsh']
        return sf:build-sort-string($title)
    else ()
};


(: Title Facet :)
declare function sf:facet-title($element as item()*, $facet-definition as item(), $name as xs:string){
    if($element/descendant::tei:biblStruct) then 
        $element/descendant::tei:biblStruct/descendant::tei:title
    else $element/descendant::tei:titleStmt/tei:title
};

(: Author field :)
declare function sf:field-author($element as item()*, $name as xs:string){
    if($element/descendant::tei:biblStruct) then 
        if($element/descendant::tei:biblStruct/descendant-or-self::tei:author[1]/tei:surname) then
            concat($element/descendant::tei:biblStruct/descendant-or-self::tei:author[1]/tei:surname, ',',  
                $element/descendant::tei:biblStruct/descendant-or-self::tei:author[1]/tei:forename)
        else if($element/descendant::tei:biblStruct/descendant-or-self::tei:editor[1]/tei:surname) then 
               concat($element/descendant::tei:biblStruct/descendant-or-self::tei:editor[1]/tei:surname, ',',  
                $element/descendant::tei:biblStruct/descendant-or-self::tei:author[1]/tei:forename)
        else  $element/descendant::tei:biblStruct/descendant::tei:author
    else $element/descendant::tei:titleStmt/descendant::tei:author
};

(:~
 : TEI author facet, specific to Srophe applications 
 :)
declare function sf:facet-authors($element as item()*, $facet-definition as item(), $name as xs:string){
    if($element/descendant::tei:biblStruct) then 
        $element/descendant::tei:biblStruct/descendant::tei:author | $element/descendant::tei:biblStruct/descendant::tei:editor
    else $element/descendant::tei:titleStmt/descendant::tei:author
};
 
(:~
 : Syriaca.org special field for place and person types 
 :)
declare function sf:facet-type($element as item()*, $facet-definition as item(), $name as xs:string){
    if($element/descendant-or-self::tei:place/@type) then
        lower-case($element/descendant-or-self::tei:place/@type)    
    else if($element/descendant-or-self::tei:person/@ana) then
        tokenize(lower-case(replace($element/descendant-or-self::tei:person/@ana,'#syriaca-','')),' ')
    else ()
};

declare function sf:facet-cbssPubType($element as item()*, $facet-definition as item(), $name as xs:string){
    let $value := $element/descendant::tei:biblStruct/@type
    return 
        if($value = 'book') then 'Book'
        else if($value = 'journalArticle') then 'Journal Article'
        else if($value = 'bookSection') then 'Book Section'
        else if($value = 'thesis') then 'Thesis'
        else $value
};

(: CBSS publication date field :)
declare function sf:field-cbssPublicationDate($element as item()*, $name as xs:string){
    $element/descendant::tei:imprint/tei:date
};

(: CBSS publication place field :)
declare function sf:field-cbssPubPlace($element as item()*, $name as xs:string){
    $element/descendant::tei:imprint/tei:pubPlace
};

(: CBSS publication place field :)
declare function sf:field-cbssLangFilter($element as item()*, $name as xs:string){
let $a := 
    if($element/descendant::tei:biblStruct) then 
        if($element/descendant::tei:biblStruct/descendant::tei:author/tei:surname) then
            $element/descendant::tei:biblStruct/descendant::tei:author/tei:surname
        else if($element/descendant::tei:biblStruct/descendant::tei:editor/tei:surname) then 
               $element/descendant::tei:biblStruct/descendant::tei:editor/tei:surname
        else $element/descendant::tei:biblStruct/descendant::tei:author
    else $element/descendant::tei:titleStmt/descendant::tei:author
for $as in $a
let $author := replace($as,'[^\w+]','')
return 
    if(matches($author,'\p{IsBasicLatin}')) then 'English'
    else if(matches($author,'\p{IsGreekandCoptic}')) then 'Greek'
    else if(matches($author,"\p{IsCyrillic}")) then 'Cyrillic'
    else if(matches($author,"\p{IsArabic}")) then 'Arabic'
    else if(matches($author,"\p{IsHebrew}")) then 'Hebrew'
    else if(matches($author,"\p{IsSyriac}")) then 'Syriac'
    else if(matches($author,'\p{IsArmenian}')) then 'Armenian'
    else if(matches($author,'\p{IsLatinExtended-A}')) then 'English'
    else if(matches($author,'\p{IsLatinExtended-B}')) then 'English'
    else if(matches($author,'\p{IsLatinExtendedAdditional}')) then 'English'
    else 'English'  
};

(: CBSS publication place field :)
declare function sf:facet-cbssKeywords($element as item()*, $facet-definition as item(), $name as xs:string){
    for $f in $element/descendant::tei:relation[@ref="dc:subject"]
    return 
        normalize-space(string-join($f/descendant::text(),' '))
};


(:
declare function facet:collection($results as item()*, $facet-definition as element(facet:facet-definition)?){
    let $path := concat('$results/',$facet-definition/facet:group-by/facet:sub-path/text()) 
    let $sort := $facet-definition/facet:order-by
    let $d := tokenize(string-join(util:eval($path),' '),' ')
    let $facets := 
        for $f in $d
        group by $facet-grp := tokenize($f,' ')
        order by 
            if($sort/text() = 'value') then $f[1]
            else count($f)
            descending
        let $label := facet:controlled-labels($results[1], $facet-grp)
        where starts-with($label,'collection')
        return facet:key(replace($label,'collection',''), $facet-grp, count($f), $facet-definition) 
    let $count := count($facets)           
    return facet:list-keys($facets, $count, $facet-definition)
};
:)
(:
declare function facet:taxonomy($results as item()*, $facet-definition as element(facet:facet-definition)?){
    let $path := concat('$results/',$facet-definition/facet:group-by/facet:sub-path/text()) 
    let $sort := $facet-definition/facet:order-by
    let $taxonomies := $results//tei:taxonomy
    let $d := util:eval($path)
    let $facets := 
        for $cat in tokenize(string-join($d,' '),' ')
        let $catRef := substring-after($cat,'#')
        let $taxRef := replace($catRef,'\d*','')
        group by $taxGrp := $taxRef
        let $taxonomy := $taxonomies[@xml:id = $taxGrp][1]
        let $taxLabel := $taxonomy/tei:bibl/text()
        where $taxLabel != ''
        order by 
            if (matches($taxLabel,'^Full Text','i')) then (0) else (1), $taxLabel
        return 
            <div class="subfacet">
                <h5>{$taxLabel}</h5>
                {
                let $facets := 
                    for $f in $cat
                    group by $catGrp := $f
                    let $label := $taxonomy/tei:category[@xml:id = substring-after($catGrp,'#')][1]/tei:catDesc/text() 
                    order by $label
                    return facet:key($label, $catGrp, count($f), $facet-definition)
                let $count := count($facets)
                let $max := if(xs:integer($facet-definition/facet:max-values)) then xs:integer($facet-definition/facet:max-values) else 10
                let $show := if(xs:integer($facet-definition/facet:max-values/@show)) then xs:integer($facet-definition/facet:max-values/@show) else 5
                return 
                    <div>
                        <div class="facet-list show">{
                            for $key at $l in subsequence($facets,1,$show)
                            return $key}
                         </div>
                        {if($count gt ($show - 1)) then 
                            (<div class="facet-list collapse" id="{concat('show',$taxGrp)}">{
                                for $key at $l in subsequence($facets,$show + 1,$max)
                                where $count gt 0
                                return $key
                            }</div>,
                            <a class="facet-label togglelink" 
                            data-toggle="collapse" data-target="#{concat('show',$taxGrp)}" href="#{concat('show',$taxGrp)}" 
                            data-text-swap="Less"> More &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>)
                        else()}
                    </div>
                }
            </div>       
    let $count := count($facets)           
    return facet:list-keys($facets, $count, $facet-definition)
};
:)

(:~
 : Syriaca.org specific group-by function for correctly labeling attributes with arrays.
 : Used for TEI relationships where multiple URIs may be coded in a single element or attribute
:)
(:
declare function facet:group-by-array-poetess($results as item()*, $facet-definition as element(facet:facet-definition)?){
    let $path := concat('$results/',$facet-definition/facet:group-by/facet:sub-path/text()) 
    let $sort := $facet-definition/facet:order-by
    let $d := tokenize(string-join(util:eval($path),' '),' ')
    let $facets := 
        for $f in $d
        group by $facet-grp := tokenize($f,' ')
        order by 
            if($sort/text() = 'value') then $f[1]
            else count($f)
            descending
        let $label := facet:controlled-labels($results, $facet-grp)
        where $label != ''
        return facet:key($label, $facet-grp, count($f), $facet-definition) 
    let $count := count($facets)           
    return facet:list-keys($facets, $count, $facet-definition)
};
:)