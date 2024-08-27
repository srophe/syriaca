xquery version "3.0";
(:~ 
 : Date slider
 : Add jquery.js, jquery-ui.min.js, jQDateRangeSlider-min.js to page header. 
 : 
 : @dependencies
 :   jQRangeSlider javascript library
 :      https://github.com/ghusse/jQRangeSlider
 :   JQuery
 :       https://jquery.com/
 :   jQuery UI
 :      https://jqueryui.com/
 : 
 : @author Winona Salesky
 : @version 1.0 
 :
 :)

module namespace slider = "http://srophe.org/srophe/slider";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(:
 : Build date filter for date slider. 
 : @param $startDate
 : @param $endDate
 : @param $mode selects which date element to use for filter. Current modes are 'inscription' and 'bibl'
:)
declare function slider:date-filter($mode) {
let $startDate := 
               if(request:get-parameter('startDate', '') != '') then
                    request:get-parameter('startDate', '')
                else()   
let $endDate := 
                if(request:get-parameter('endDate', '') != '') then  
                     request:get-parameter('endDate', '')
                else() 
return   
(:These should have @when, @notBefore, and/or @notAfter attributes with ISO dates:)
    if(not(empty($startDate)) and not(empty($endDate))) then
        if($mode != '') then 
            if($mode = 'origDate') then 
                concat('[descendant::tei:origDate[
                ((@notBefore gt "', $startDate,'" and @notBefore lt "', $endDate,'") and
                (@notAfter gt "', $startDate,'" and @notAfter lt "', $endDate,'")) or 
                (@when gt "', $startDate,'" and @when lt "', $endDate,'")
                ]]')
            else if($mode = 'imprint') then 
                concat('[descendant::tei:imprint/tei:date[((. gt "', $startDate,'" and . lt "', $endDate,'"))]]')
            else 
                concat('[descendant::',$mode,'[
                (@from gt "', $startDate,'" and @from lt "', $endDate,'") and
                (@to gt "', $startDate,'" and @to lt "', $endDate,'")
                ]]')
        else
           concat('[descendant::tei:state[@type="existence"][
            (@from gt "', $startDate,'" and @from lt "', $endDate,'") and
            (@to gt "', $startDate,'" and @to lt "', $endDate,'")
            ]]')
    else ()
};

(:
 : Date slider functions
:)
(:~
 : Check dates for proper formatting, conver negative dates to JavaScript format
 : @param $dates accepts xs:gYear (YYYY) or xs:date (YYYY-MM-DD)
:)
declare function slider:expand-dates($date){
let $year := 
        if(matches($date, '^\-')) then 
            if(matches($date, '\d{4}-\d{4}')) then substring-before($date,'-') 
            else if(matches($date, '^\-\d{6}')) then $date
            else replace($date,'^-','-00')
        else $date
return       
    if($year castable as xs:date) then 
         $year
    else if($year castable as xs:gYear) then  
        concat($year, '-01-01')
    else if(matches($year,'^0000')) then  '0001-01-01'
    else ()
};

(:~
 : Build Javascript Date Slider. 
 : @param $hits node containing all hits from search/browse pages
 : @param $mode selects which date element to use for filter. Current modes are 'inscription' and 'bibl'
:)
declare function slider:browse-date-slider($hits, $mode as xs:string?){                  
let $startDate := request:get-parameter('startDate', '')
let $endDate := request:get-parameter('endDate', '')
(: Dates in current results set :)  
let $d := 
        if($mode = 'origDate') then 
            for $dates in $hits/descendant::tei:origDate/@notBefore | 
            $hits/descendant::tei:origDate/@notAfter |
            $hits/descendant::tei:origDate/@when
            let $date := slider:expand-dates($dates)
            order by $date 
            return 
                if($date castable as xs:date) then
                    xs:date($date)
                else () 
        else if($mode = 'imprint') then 
            for $dates in $hits/descendant::tei:imprint/tei:date
            let $date := slider:expand-dates($dates)
            order by $date 
            return 
                if($date castable as xs:date) then
                    xs:date($date)
                else () 
        else 
            for $dates in $hits/descendant::tei:state[@type="existence"]/@to | 
            $hits/descendant::tei:state[@type="existence"]/@from
            order by xs:date(slider:expand-dates($dates)) 
            return $dates    
let $min := if($startDate) then 
                slider:expand-dates($startDate) 
            else $d[1]
let $max := 
            if($endDate) then slider:expand-dates($endDate) 
            else $d[last()]        
let $minPadding := $min[1] - xs:yearMonthDuration('P10Y')
let $maxPadding := $max[last()] + xs:yearMonthDuration('P10Y')
let $cleanParams :=
        string-join(
        for $pramName in request:get-parameter-names()
        return 
            if($pramName = ('start','perpage','sort-element','sort','endDate','startDate')) then ()
            else 
                for $param in request:get-parameter($pramName, '')
                where $param != ''
                return ($pramName || '=' || $param)
                ,'&amp;')
                
let $sortParams := 
        if(request:get-parameter('sort-element', '') != '') then 
            ('sort-element'|| '=' || request:get-parameter('sort-element', '')[1])
        else()
let $param-string := 
        if($cleanParams != '' and $sortParams != '') then 
            ('&amp;' || $cleanParams || '&amp;' || $sortParams)
        else if($cleanParams != '') then 
            ('&amp;' || $cleanParams)
        else if($sortParams != '') then 
            ('&amp;' || $sortParams)
        else ()
return 
if(not(empty($min)) and not(empty($max))) then
    <div>
            <!-- Date Slider -->
        <link rel="stylesheet" type="text/css" href="$nav-base/resources/dateSlider/css/slider.css"/>
        <link rel="stylesheet" type="text/css" href="$nav-base/resources/dateSlider/css/slider-classic-min.css"/>
        <script src="$nav-base/resources/dateSlider/js/jQDateRangeSlider-min.js"/>
        <h4 class="slider">Date range</h4>
        <div class="sliderContainer">
        <div id="slider"/>
        {if($startDate != '') then
                (<br/>,<a href="?start=1{$param-string}" class="btn btn-warning btn-sm" role="button"><i class="glyphicon glyphicon-remove-circle"></i> Reset Dates</a>,<br/>)
        else()}
        <script type="text/javascript">
        <![CDATA[
            var minPadding = "]]>{$minPadding}<![CDATA["
            var maxPadding = "]]>{$maxPadding}<![CDATA["
            var minValue = "]]>{$min}<![CDATA["
            var maxValue = "]]>{$max}<![CDATA["
            $("#slider").dateRangeSlider({  
                            bounds: {
                                    min:  new Date(minPadding),
                                   	max:  new Date(maxPadding)
                                   	},
                            defaultValues: {min: new Date(minValue), max: new Date(maxValue)},
                            //values: {min: new Date(minValue), max: new Date(maxValue)},
    		        		formatter:function(val){
    		        		     var year = val.getFullYear();
    		        		     return year;
    		        		}
                });
                
                $("#slider").bind("userValuesChanged", function(e, data){
                    var url = window.location.href.split('?')[0];
                    var minDate = data.values.min.toISOString().split('T')[0]
                    var maxDate = data.values.max.toISOString().split('T')[0]
                    console.log(url + "?startDate=" + minDate + "&endDate=" + maxDate + "]]> {$param-string} <![CDATA[");
                    window.location.href = url + "?startDate=" + minDate + "&endDate=" + maxDate + "]]> {$param-string} <![CDATA[" ;
                    //$('#browse-results').load(window.location.href + "?startDate=" + data.values.min.toISOString() + "&endDate=" + data.values.max.toISOString() + " #browse-results");
                });
            ]]>
        </script>     
        </div>
    </div>
else ()
};
 