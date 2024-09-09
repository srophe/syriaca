xquery version "3.1";        
(:~  
 : Builds HTML search forms and HTMl search results Srophe Collections and sub-collections   
 :) 
module namespace search="http://srophe.org/srophe/search";

(:eXist templating module:)
import module namespace templates="http://exist-db.org/xquery/html-templating";

(: Import KWIC module:)
import module namespace kwic="http://exist-db.org/xquery/kwic";

(: Import Srophe application modules. :)
import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";
import module namespace data="http://srophe.org/srophe/data" at "../lib/data.xqm";
import module namespace global="http://srophe.org/srophe/global" at "../lib/global.xqm";
import module namespace sf="http://srophe.org/srophe/facets" at "../lib/facets.xql";
import module namespace page="http://srophe.org/srophe/page" at "../lib/paging.xqm";
import module namespace slider = "http://srophe.org/srophe/slider" at "../lib/date-slider.xqm";
import module namespace tei2html="http://srophe.org/srophe/tei2html" at "../content-negotiation/tei2html.xqm";

(: Syriaca.org search modules :)
import module namespace bhses="http://srophe.org/srophe/bhses" at "bhse-search.xqm";
import module namespace bibls="http://srophe.org/srophe/bibls" at "bibl-search.xqm";
import module namespace ms="http://srophe.org/srophe/ms" at "ms-search.xqm";
import module namespace nhsls="http://srophe.org/srophe/nhsls" at "nhsl-search.xqm";
import module namespace persons="http://srophe.org/srophe/persons" at "persons-search.xqm";
import module namespace places="http://srophe.org/srophe/places" at "places-search.xqm";
import module namespace spears="http://srophe.org/srophe/spears" at "spear-search.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
(:declare namespace facet="http://expath.org/ns/facet";:)

(: Variables:)
declare variable $search:start {
    if(request:get-parameter('start', 1)[1] castable as xs:integer) then 
        xs:integer(request:get-parameter('start', 1)[1]) 
    else 1};
declare variable $search:perpage {
    if(request:get-parameter('perpage', 25)[1] castable as xs:integer) then 
        xs:integer(request:get-parameter('perpage', 25)[1]) 
    else 25};

(:~
 : Builds search result, saves to model("hits") for use in HTML display
:)

declare function search:build-query($collection as xs:string?){
    (:if($collection = ('johnofephesusPersons','johnofephesusPlaces')) then ()
    else:) if($collection = ('sbd','q','authors','saints','persons','johnofephesusPersons')) then persons:query-string($collection)
    else if($collection ='spear') then spears:query-string()
    else if($collection = ('places','johnofephesusPersons')) then places:query-string()
    else if($collection = ('bhse','nhsl','bible')) then bhses:query-string($collection)
    else if($collection = 'bibl') then bibls:query-string()
    else if($collection = 'manuscripts') then ms:query-string()
    else ()
};

(:~
 : Search results stored in map for use by other HTML display functions 
:)
declare %templates:wrap function search:search-data($node as node(), $model as map(*), $collection as xs:string*, $sort-element as xs:string*){
    let $queryExpr := search:build-query($collection)
    let $hits := data:search($collection, $queryExpr, $sort-element[1])
    return
        map {
                "hits" :
                    if(exists(request:get-parameter-names())) then $hits 
                    else if(ends-with(request:get-url(), 'search.html')) then ()
                    else $hits
        } 
};

(:~ 
 : Builds results output
:)
declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*), $collection as xs:string?, $kwic as xs:string?, $sort-options as xs:string*, $search-string as xs:string?) {
    let $hits := $model("hits")
    let $count := count($hits)
    let $facet-config := global:facet-definition-file($collection)
    let $facetsDisplay := sf:display($model("hits"),$facet-config)
    let $dateSlider := slider:browse-date-slider($hits, 'imprint')
    return 
        if(request:get-parameter-names() = '' or empty(request:get-parameter-names())) then () 
           (: search:search-form($node, $model, $collection):) 
        else if($count = 0  and exists(request:get-parameter-names())) then ()
        (:
            <div>
                {page:pages($hits, $collection, $search:start, $search:perpage,$search-string, $sort-options)}
                {search:search-form($node, $model, $collection)}
                <br/>
            </div>
            :)
        else if(not(empty($facetsDisplay)) or not(empty($dateSlider)) ) then 
            <div>
                {if($collection = 'bibl') then () else page:pages($hits, $collection, $search:start, $search:perpage,$search-string, $sort-options)}
                <div class="row" id="search-results" xmlns="http://www.w3.org/1999/xhtml">
                    <div class="col-md-8 col-md-push-4">
                        <div class="indent" id="search-results" xmlns="http://www.w3.org/1999/xhtml">{
                                let $hits := $model("hits")
                                for $hit at $p in subsequence($hits, $search:start, $search:perpage)
                                let $id := replace($hit/descendant::tei:idno[1],'/tei','')
                                let $kwic := if($kwic = ('true','yes','true()','kwic')) then kwic:expand($hit) else () 
                                return 
                                 <div class="row record" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
                                     <div class="col-md-1" style="margin-right:-1em; padding-top:.25em;">        
                                         <span class="badge" style="margin-right:1em;">{$search:start + $p - 1}</span>
                                     </div>
                                     <div class="col-md-11" style="margin-right:-1em; padding-top:.25em;">
                                         {tei2html:summary-view($hit, '', $id)}
                                         {
                                            if($kwic//exist:match) then 
                                               tei2html:output-kwic($kwic, $id)
                                            else ()
                                         }
                                     </div>
                                 </div>   
                        }</div>
                    </div>
                    <div class="col-md-4 col-md-pull-8">{
                     let $hits := $model("hits")
                     let $facet-config := global:facet-definition-file($collection)
                     return 
                        ($dateSlider,
                         if(not(empty($facetsDisplay))) then 
                             $facetsDisplay
                         else ())  
                    }</div>
                </div>
                {page:pages($hits, $collection, $search:start, $search:perpage,'no', $sort-options)}
            </div>
        else 
         <div class="indent" id="search-results" xmlns="http://www.w3.org/1999/xhtml">
         {
                 let $hits := $model("hits")
                 for $hit at $p in subsequence($hits, $search:start, $search:perpage)
                 let $id := 
                    if($collection = 'johnofephesusPersons') then 
                        $hit/descendant::tei:body/descendant::tei:idno[contains(.,'/johnofephesus/persons/')]
                    else if($collection = 'johnofephesusPlaces') then 
                        $hit/descendant::tei:body/descendant::tei:idno[contains(.,'/johnofephesus/places/')]     
                    else replace($hit/descendant::tei:publicationStmt/tei:idno[1],'/tei','')
                 let $kwic := if($kwic = ('true','yes','true()','kwic')) then kwic:expand($hit) else () 
                 return 
                  <div class="row record" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
                      <div class="col-md-1" style="margin-right:-1em; padding-top:.25em;">        
                          <span class="badge" style="margin-right:1em;">{$search:start + $p - 1}</span>
                      </div>
                      <div class="col-md-11" style="margin-right:-1em; padding-top:.25em;">
                          {tei2html:summary-view($hit, '', $id)}
                          {
                             if($kwic//exist:match) then 
                                tei2html:output-kwic($kwic, $id)
                             else ()
                          }
                      </div>
                  </div>   
         }
         </div>
};

(:~
 : Build advanced search form using either search-config.xml or the default form search:default-search-form()
 : @param $collection. Optional parameter to limit search by collection. 
 : @note Collections are defined in repo-config.xml
 : @note Additional Search forms can be developed to replace the default search form.
 : @depreciated: do a manual HTML build, add xquery keyboard options 
:)
declare function search:search-form($node as node(), $model as map(*), $collection as xs:string?){
if(exists(request:get-parameter-names()) and count($model("hits")) gt 0) then ()
else 
    let $search-config := 
        if($collection != '') then concat($config:app-root, '/', string(config:collection-vars($collection)/@app-root),'/','search-config.xml')
        else concat($config:app-root, '/','search-config.xml')
    return 
        if($collection = ('persons','sbd','authors','q','saints')) then <div>{persons:search-form($collection)}</div>
        else if($collection ='spear') then <div>{spears:search-form()}</div>
        else if($collection ='manuscripts') then <div>{ms:search-form()}</div>
        else if($collection = ('bhse','nhsl')) then <div>{bhses:search-form($collection)}</div>
        else if($collection ='bibl') then <div>{bibls:search-form()}</div>
        else if($collection ='places') then <div>{places:search-form()}</div>
        else if($collection ='johnofephesusPersons') then <div>{persons:johnofephesusPersons-form()}</div>
        else if($collection ='johnofephesusPlaces') then <div>{places:johnofephesusPlaces-form()}</div>
        else if(doc-available($search-config)) then 
            search:build-form($search-config)             
        else search:default-search-form()
};

(:~
 : Builds a simple advanced search from the search-config.xml. 
 : search-config.xml provides a simple mechinisim for creating custom inputs and XPaths, 
 : For more complicated advanced search options, especially those that require multiple XPath combinations
 : we recommend you add your own customizations to search.xqm
 : @param $search-config a values to use for the default search form and for the XPath search filters.
 : @depreciated: do a manual HTML build, add xquery keyboard options 
:)
declare function search:build-form($search-config) {
    let $config := doc($search-config)
    return 
        <form method="get" class="form-horizontal indent" role="form">
            <h1 class="search-header">{if($config//label != '') then $config//label else 'Search'}</h1>
            {if($config//desc != '') then 
                <p class="indent info">{$config//desc}</p>
            else() 
            }
            <div class="well well-small search-box">
                <div class="row">
                    <div class="col-md-10">{
                        for $input in $config//input
                        let $name := string($input/@name)
                        let $id := concat('s',$name)
                        return 
                            <div class="form-group">
                                <label for="{$name}" class="col-sm-2 col-md-3  control-label">{string($input/@label)}: 
                                {if($input/@title != '') then 
                                    <span class="glyphicon glyphicon-question-sign text-info moreInfo" aria-hidden="true" data-toggle="tooltip" title="{string($input/@title)}"></span>
                                else ()}
                                </label>
                                <div class="col-sm-10 col-md-9 ">
                                    <div class="input-group">
                                        <input type="text" 
                                        id="{$id}" 
                                        name="{$name}" 
                                        data-toggle="tooltip" 
                                        data-placement="left" class="form-control keyboard"/>
                                        {($input/@title,$input/@placeholder)}
                                        {
                                            if($input/@keyboard='yes') then 
                                                <span class="input-group-btn">{global:keyboard-select-menu($id)}</span>
                                             else ()
                                         }
                                    </div> 
                                </div>
                            </div>}
                    </div>
                </div> 
            </div>
            <div class="pull-right">
                <button type="submit" class="btn btn-info">Search</button>&#160;
                <button type="reset" class="btn btn-warning">Clear</button>
            </div>
            <br class="clearfix"/><br/>
        </form> 
};

(:~
 : Simple default search form to us if not search-config.xml file is present. Can be customized. 
:)
declare function search:default-search-form() {
    <form method="get" class="form-horizontal indent" role="form">
        <h1 class="search-header">Search</h1>
        <div class="well well-small search-box">
            <div class="row">
                <div class="col-md-10">
                    <!-- Keyword -->
                    <div class="form-group">
                        <label for="q" class="col-sm-2 col-md-3  control-label">Keyword: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="keyword" name="keyword" class="form-control keyboard"/>
                                <div class="input-group-btn">
                                {global:keyboard-select-menu('keyword')}
                                </div>
                            </div> 
                        </div>
                    </div>
                    <!-- Title-->
                    <div class="form-group">
                        <label for="title" class="col-sm-2 col-md-3  control-label">Title: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="title" name="title" class="form-control keyboard"/>
                                <div class="input-group-btn">
                                {global:keyboard-select-menu('title')}
                                </div>
                            </div>   
                        </div>
                    </div>
                   <!-- Place Name-->
                    <div class="form-group">
                        <label for="placeName" class="col-sm-2 col-md-3  control-label">Place Name: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="placeName" name="placeName" class="form-control keyboard"/>
                                <div class="input-group-btn">
                                {global:keyboard-select-menu('placeName')}
                                </div>
                            </div>   
                        </div>
                    </div>
                    <!-- Place Name-->
                    <div class="form-group">
                        <label for="persName" class="col-sm-2 col-md-3  control-label">Person Name: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="persName" name="persName" class="form-control keyboard"/>
                                <div class="input-group-btn">
                                {global:keyboard-select-menu('persName')}
                                </div>
                            </div>   
                        </div>
                    </div>
                <!-- end col  -->
                </div>
                <!-- end row  -->
            </div>    
            <div class="pull-right">
                <button type="submit" class="btn btn-info">Search</button>&#160;
                <button type="reset" class="btn">Clear</button>
            </div>
            <br class="clearfix"/><br/>
        </div>
    </form>
};