xquery version "3.1";
(:~
 : XQuery Zotero integration
 : Queries Zotero API : https://api.zotero.org
 : Checks for updates since last modified version using Zotero Last-Modified-Version header
 : Converts Zotero records to Syriaca.org TEI using zotero2tei.xqm
 : Adds new records to directory.
 :
 : To be done: 
 :      Submit to Perseids
:)

import module namespace http="http://expath.org/ns/http-client";
import module namespace zotero2tei="http://syriaca.org/zotero2tei" at "zotero2tei.xqm";
import module namespace console="http://exist-db.org/xquery/console";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare variable $zotero-api := 'https://api.zotero.org';

(: Access zotero-api configuration file :) 
declare variable $zotero-config := doc('zotero-config.xml');
(: Zotero group id :)
declare variable $groupid := $zotero-config//groupid/text();
(: Zotero last modified version, to check for updates. :)
declare variable $last-modified-version := $zotero-config//last-modified-version/text();
(: Directory bibl data is stored in :)
declare variable $data-dir := $zotero-config//data-dir/text();
(: Local URI pattern for bibl records :)
declare variable $base-uri := $zotero-config//base-uri/text();
(: Format defaults to tei :)
declare variable $format := if($zotero-config//format/text() != '') then $zotero-config//format/text() else 'tei';

(:~
 : Convert records to Syriaca.org compliant TEI records, using zotero2tei.xqm
 : Save records to the database. 
 : @param $record 
 : @param $index-number
 : @param $format
:)
declare function local:process-records($record as item()?, $format as xs:string?){
    let $idNumber :=  tokenize($record?key,'/')[last()]                   
    let $file-name := concat($idNumber,'.xml')
    let $new-record := zotero2tei:build-new-record($record, $idNumber, $format)
    return 
        if($idNumber != '') then 
            try {xmldb:store($data-dir, xmldb:encode-uri($file-name), $new-record)} catch *{
                <response status="fail">
                    <message>Failed to add resource {$file-name}: {concat($err:code, ": ", $err:description), console:log(concat($err:code, ": ", $err:description))}</message>
                </response>
            } 
        else ()  
};

(:~
 : Get and process Zotero data. 
:)
declare function local:get-zotero(){
    <div>{
        for $r in uri-collection('/db/apps/syriaca-data/cbss/data')
        let $doc := json-doc($r)
        for $rec in $doc?*
        where not(exists($rec?data?parentItem))
        return local:process-records($rec,'json')
    }</div>
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xmldb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

(:~
 : Check action parameter, if empty, return contents of config.xml
 : If $action is not empty, check for specified collection, create if it does not exist. 
 : Run Zotero request. 
:)
if(request:get-parameter('action', '') = 'update') then
    if(xmldb:collection-available($data-dir)) then
        local:get-zotero()
    else (local:mkcol("/db/apps", replace($data-dir,'/db/apps','')),local:get-zotero())
else if(request:get-parameter('action', '') = 'initiate') then 
    if(request:get-parameter('start', '') != '' and xmldb:collection-available($data-dir)) then 
        local:get-zotero()
    else if((request:get-parameter('start', '') = '0' or  request:get-parameter('start', '') = '1') and xmldb:collection-available($data-dir)) then 
        local:get-zotero()        
    else if(xmldb:collection-available($data-dir)) then
        (xmldb:remove($data-dir),local:mkcol("/db/apps", replace($data-dir,'/db/apps','')),local:get-zotero())
    else (local:mkcol("/db/apps", replace($data-dir,'/db/apps','')),local:get-zotero())
else 
    <div xmlns="http://www.w3.org/1999/xhtml">
        <p><label>Group ID : </label> {$groupid}</p>
        <p><label>Last Modified Version (Zotero): </label> {$last-modified-version}</p>
        <p><label>Data Directory : </label> {$data-dir}</p>    
    </div>