xquery version "3.1";
(:~  
 : Basic data interactions, returns raw data for use in other modules  
 : Used by browse, search, and view records.  
 :
 : @see config.xqm for global variables
 : @see lib/paging.xqm for sort options
 : @see lib/relationships.xqm for building and visualizing relatiobships 
 :)
 

import module namespace config="http://srophe.org/srophe/config" at "config.xqm";
import module namespace cntneg="http://srophe.org/srophe/cntneg" at "content-negotiation/content-negotiation.xqm";
import module namespace relations="http://srophe.org/srophe/relationships" at "lib/relationships.xqm";
import module namespace data="http://srophe.org/srophe/data" at "lib/data.xqm";
import module namespace maps="http://srophe.org/srophe/maps" at "lib/maps.xqm";
import module namespace search="http://srophe.org/srophe/search" at "search/search.xqm";

declare namespace http="http://expath.org/ns/http-client";
declare namespace tei="http://www.tei-c.org/ns/1.0";

let $collection :=  request:get-parameter("collection", ())
let $id :=  request:get-parameter("id", ())
let $ids :=  request:get-parameter("ids", ())
let $currentID :=  request:get-parameter("currentID", ())
let $relationshipType :=  request:get-parameter("relationshipType", ())
let $relationship :=  request:get-parameter("relationship", ())
let $label :=  request:get-parameter("label", ())
let $format :=  request:get-parameter("format", ())
let $collection-path := 
            if(config:collection-vars($collection)/@data-root != '') then concat('/',config:collection-vars($collection)/@data-root)
            else if($collection != '') then concat('/',$collection)
            else ()
let $data := 
            if(request:get-parameter("getRSS", ()) != '') then 
                let $feed := 
                    http:send-request(
                        <http:request href="{xs:anyURI(request:get-parameter("getRSS", ()))}" method="get">
                            <http:header name="Connection" value="close"/>
                        </http:request>)[2]
                    for $item in subsequence($feed//*:item, 1, 4)
                    return 
                        <div>
                           <h4>{$item/*:title/text()}</h4>
                            <p class="small">{$item/*:pubDate/text()}</p>
                            <p class="small moreInfo"><a href="{$item/*:link/text()}" class="btn btn-default btn-rounded btn-light btn-sm text-center">Read More</a></p>
                        </div>
            else if($ids != '') then
                collection($config:data-root)//tei:idno[@type='URI'][. = tokenize($ids,' ')]
             else if($collection != '') then
                  collection($config:data-root || $collection-path)
             else collection($config:data-root)
let $request-format := if($format != '') then $format else 'xml'
let $queryString := request:get-query-string()
return 
    if($relationship != '') then
        if($relationship = 'internal') then 
            (response:set-header("Content-Type", "text/html; charset=utf-8"),
            relations:get-related($data, request:get-parameter("relID", ())))
        else if($relationship = 'external' and $currentID != '') then 
            (response:set-header("Content-Type", "text/html; charset=utf-8"),
            relations:display-external-relatiobships($currentID, $relationshipType, $label))
        else if($relationship = 'map') then
            if($data/ancestor::tei:TEI/descendant::tei:geo) then 
                (response:set-header("Content-Type", "text/html; charset=utf-8"),
                maps:build-dynamic-map($data/ancestor::tei:TEI,count($data/ancestor::tei:TEI/descendant::tei:geo), $currentID))
            else ()
        else if($ids != '') then 
            (response:set-header("Content-Type", "text/html; charset=utf-8"),
            relations:get-related($data, request:get-parameter("relID", ())))
        else <message>Missing</message>
    else if(request:get-parameter("queryType", ())  = 'search') then
        let $queryExpr := search:build-query($collection)
        return  
        (response:set-header("Content-Type", "text/html; charset=utf-8"), 
        relations:display-records(data:search($collection, $queryExpr, ()),$queryString))
    else 
        (response:set-header("Content-Type", "text/html; charset=utf-8"), $data)
