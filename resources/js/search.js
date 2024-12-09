//New search functions
//Parse out parameters
function getParams(name) {
    var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.search);
    return (results !== null) ? results[1] || 0: false;
}
//Global param variables
var apiUrl = "https://50fnejdk87.execute-api.us-east-1.amazonaws.com/opensearch-api-test";
    if (getParams('size')) {
        var size = getParams('size');
    } else {
        var size = 25;
    }
    if (getParams('from')) {
        var from = getParams('from');
    } else {
        var from = 0;
    }
    if (getParams('letter')) {
        var letter = getParams('letter');
    } else {
        var letter = 'a';
    }

    if (getParams('lang') == 'syr') {
        var lang = '&lang=syr';
    } else if (getParams('lang') == 'ar') {
        var lang = '&lang=ar';
    } else {
        var lang = '';
    }
    
    if (getParams('q')) {
        var q = getParams('q');
    } else {
        var q = '';
    }
    
function getBrowse(series) {
    if (getParams('q')) {
        var q = getParams('q');
    } else {
        var q = series;
    }
    //Browse URL
    var browseURL = apiUrl + '?searchType=letter&letter=' + letter + '&q=' + q + '&from=' + from + '&size=' + size + lang;
    $. get (browseURL, function (data) {
        var totalResults = data.hits.total.value;
        displayBrowseInfo(totalResults);
        displayResults(data);
    }).fail(function (jqXHR, textStatus, errorThrown) {
        console.error('Error fetching search results:', error);
        document.getElementById("search-results").innerHTML = '<p>There was an error retrieving the search results. Please try again later.</p>';
    });
}

function runSearch() {
    //Catch keyword passed via parameters. 
    if(getParams('keyword')) {
        var fullText = getParams('keyword');
    } else if(getParams('q')){
        var fullText = getParams('q');
    }    
    var series = getParams('series');
    if(fullText){ 
        $. get(apiUrl + '?fullText=' + fullText + '&series=' + series, function (data) {
            var totalResults = data.hits.total.value;
            $("#advancedSearch").hide(); 
            displaySearchInfo(data)
            //createPaginationControls(totalResults,size);
            displayResults(data);
        }).fail(function (jqXHR, textStatus, errorThrown) {
            console.error('Error fetching search results:', error);
            document.getElementById("search-results").innerHTML = '<p>There was an error retrieving the search results. Please try again later.</p>';
        });
    } 
}
//run search from search page
$('.search').submit(function (e) {
    // on change of state
    e.preventDefault(e);
    var formData = $(this).serializeArray().filter(function (item) {
                return item.value !== "";
    });
    $.get(apiUrl, formData, function (data) {
        var totalResults = data.hits.total.value;
       $("#advancedSearch").hide(); 
       displaySearchInfo(totalResults);
       //createPaginationControls(totalResults,size);
       displayResults(data);
    }).fail(function (jqXHR, textStatus, errorThrown) {
        console.error('Error fetching search results:', error);
        document.getElementById("search-results").innerHTML = '<p>There was an error retrieving the search results. Please try again later.</p>';
    });
});

//Deperciated 
function createPaginationControls(totalResults, pageSize) {
    const pages = Math.ceil(totalResults / pageSize);
    if(totalResults > pageSize) {
       $('#pagination').bootpag({
        total: pages, // total pages
        page: 1, // default page
        maxVisible: 5, // visible pagination
        leaps: true // next/prev leaps through maxVisible
        }).on("page", function (event, num) {
            var browseURL = apiUrl + '?searchType=letter&letter=' + letter + '&q=' + q + '&from=' + num * pageSize + '&size=' + size;
            $. get(browseURL, function (data) {
                createPaginationControls(data);
                displayResults(data);
            }).fail(function (jqXHR, textStatus, errorThrown) {
                console.error('Error fetching search results:', error);
                document.getElementById("search-results").innerHTML = '<p>There was an error retrieving the search results. Please try again later.</p>';
            });
            $(this).bootpag({
                total: 10, maxVisible: 10
            });
        }); 
    }
}

function displayBrowseInfo(totalResults) {
    const searchPagination = document.getElementById("searchPagination");
          searchPagination.innerHTML = ''; // Clear previous result
    var pageCount =  totalResults / size;
    if(totalResults > size) {
        for(var i = 0 ; i<pageCount;i++){   
           $("#searchPagination").append('<li><a href="#" class="browsePage" data-page-num="'+(i+1)+'">'+(i+1)+'</a></li> ');
         }    
     };
}

function displaySearchInfo(totalResults) {
   const resultsInfo = document.getElementById("search-info");
          resultsInfo.innerHTML = ''; // Clear previous results
    const searchPagination = document.getElementById("searchPagination");
          searchPagination.innerHTML = ''; // Clear previous result      
    resultsInfo.innerHTML = `
            <h3 class="hit-count paging">${totalResults} Search results </h3>
            <p class="col-md-offset-1 hit-count note small">
                        You may wish to expand your search by using wildcard characters to increase results.
            </p>
        `;
        
    var pageCount =  totalResults / size;
    if(totalResults > size) {
        for(var i = 0 ; i<pageCount;i++){   
           $("#searchPagination").append('<li><a href="#" class="searchPage" data-page-num="'+(i+1)+'">'+(i+1)+'</a></li> ');
         }        
     };
}

$(document).on('click', '.browsePage', function(e) {
    // on change of state
    e.preventDefault(e);
    var browseParams = window.location.search;
    var page = $(this).data("page-num");
    var from = page * size;
    $.get(apiUrl + window.location.search + '&from=' + from, function (data) {
        var totalResults = data.hits.total.value;
        displayBrowseInfo(totalResults);
        displayResults(data);
    }).fail(function (jqXHR, textStatus, errorThrown) {
        console.error('Error fetching search results:', error);
        document.getElementById("search-results").innerHTML = '<p>There was an error retrieving the search results. Please try again later.</p>';
    });
});

$(document).on('click', '.searchPage', function(e) {
    // on change of state
    e.preventDefault(e);
    var formData = $('#advancedSearch').serializeArray().filter(function (item) {
                return item.value !== "";
    });
    var page = $(this).data("page-num");
    var from = page * size;
    $.get(apiUrl + '?from=' + from, formData, function (data) {
        var totalResults = data.hits.total.value;
       $("#advancedSearch").hide(); 
       displaySearchInfo(totalResults);
       //createPaginationControls(totalResults,size);
       displayResults(data);
    }).fail(function (jqXHR, textStatus, errorThrown) {
        console.error('Error fetching search results:', error);
        document.getElementById("search-results").innerHTML = '<p>There was an error retrieving the search results. Please try again later.</p>';
    });
});

//display openSearch results
function displayResults(data) {
    const resultsContainer = document.getElementById("search-results");
          resultsContainer.innerHTML = ''; // Clear previous results
    
    if (data.hits && data.hits.hits.length > 0) {
        data.hits.hits.forEach(hit => {
            const resultItem = document.createElement("div");
            resultItem.classList.add("result-item");
            resultItem.style.marginBottom = "15px"; // Add spacing between items
            
            // Extract the title, prologue, and idno fields from the response
            const title = hit._source.title || 'No Title';
            const type = hit._source.type || '';
            if(hit._source.placeName){
                var placeName = hit._source.placeName || '';
                var names = placeName.join(", ")
                var nameString = names ? ` <br/>Names: ${names} `: '';
            }else if(hit._source.persName){
                var persName = hit._source.persName || '';
                var names = persName.join(", ")
                var nameString = names ? ` <br/>Names: ${names} `: '';
            } else {
                nameString = '';
            }
            const abstract = hit._source.abstract || '';
            const abstractString = abstract ? ` ${abstract} <br/>`: '';
            const typeString = type ? ` (${type}) `: '';
            const prologue = hit._source.prologue || ' ';
            const idno = hit._source.idno || ''; // Fallback if no idno
            // Construct the URL using the idno field
            const url = idno ? `${idno}`: '#';
            
            // Populate the result item with the link and details
            resultItem.innerHTML = `
                <a href="${url}" target="_blank" style="text-decoration: none; color: #007bff;">
                    <span class="tei-title title-analytic">${title}</span> ${typeString}
                </a>
                ${nameString}
                <br/>URI: 
                <a href="${url}" target="_blank" style="text-decoration: none; color: #007bff;">
                    <span class="tei-title title-analytic">${url}</span>
                </a>
              `;
            
            resultsContainer.appendChild(resultItem);
        });
    } else {
        resultsContainer.innerHTML = '<p>No results found.</p>';
    }
}

//Build browse menus 
function browseAlphaMenu(){
    var eng = 'A B C D E F G H I J K L M N O P Q R S T U V W X Y Z';
    var syr = 'ܐ ܒ ܓ ܕ ܗ ܘ ܙ ܚ ܛ ܝ ܟ ܠ ܡ ܢ ܣ ܥ ܦ ܩ ܪ ܫ ܬ';
    var ar = 'ا ب ت ث ج ح  خ  د  ذ  ر  ز  س  ش  ص  ض  ط  ظ  ع  غ  ف  ق  ك ل م ن ه  و ي';
    
    if (getParams('lang') == 'syr') {
        var menuArray = syr.split(" ");
    } else if (getParams('lang') == 'ar') {
        var menuArray = ar.split(" ");
    }else {
        var menuArray = eng.split(" ");
    }
    
    var abcMenu = $('#abcMenu');
    
    if(getParams('lang') == 'syr'){
        $('#abcMenu').attr("dir", "rtl");    
    } else if (getParams('lang') == 'ar') {
        $('#abcMenu').attr("dir", "rtl");
    } else {
        $('#abcMenu').attr("dir", "ltr");
    }
    
    $.each(menuArray, function(i)
    {
        var li = $('<li/>')
            .addClass('ui-menu-item')
            .attr('role', 'menuitem')
            .appendTo(abcMenu);
        var aaa = $('<a/>')
            .addClass('ui-all')
            .attr('href', '?searchType=letter&letter='+ menuArray[i] + '&q='+ q +'&size=25' + lang)
            .text(menuArray[i])
            .appendTo(li);
    });
}
//Special CBSS functions

function getCBSSBrowse() {
    //Browse URL
    var browseURL = apiUrl + '?searchType=browse&q=cbssAuthor&from=' + from + '&size=' + size;
    $. get (browseURL, function (data) {
        var totalResults = data.hits.total.value;
        displayCBSSBrowseInfo(totalResults);
        displayCBSSResults(data);
    }).fail(function (jqXHR, textStatus, errorThrown) {
        console.error('Error fetching search results:', error);
        document.getElementById("search-results").innerHTML = '<p>There was an error retrieving the search results. Please try again later.</p>';
    });
}

//display openSearch results
function displayCBSSResults(data) {
    const resultsContainer = document.getElementById("search-results");
          resultsContainer.innerHTML = ''; // Clear previous results
    
    if (data.hits && data.hits.hits.length > 0) {
        data.hits.hits.forEach(hit => {
            const resultItem = document.createElement("div");
            resultItem.classList.add("result-item");
            resultItem.style.marginBottom = "15px"; // Add spacing between items
            
            // Extract the title, prologue, and idno fields from the response
            const title = hit._source.citation || 'No Title';
            const type = hit._source.type || '';
            const typeString = type ? ` (${type}) `: '';
            const prologue = hit._source.prologue || ' ';
            const idno = hit._source.idno || ''; // Fallback if no idno
            // Construct the URL using the idno field
            const url = idno ? `${idno}`: '#';
            
            // Populate the result item with the link and details
            resultItem.innerHTML = `
                ${title}
                <br/>URI: 
                <a href="${url}" target="_blank" style="text-decoration: none; color: #007bff;">
                    <span class="tei-title title-analytic">${url}</span>
                </a>
              `;
            
            resultsContainer.appendChild(resultItem);
        });
    } else {
        resultsContainer.innerHTML = '<p>No results found.</p>';
    }
}


function displayCBSSBrowseInfo(totalResults) {
    const searchPagination = document.getElementById("searchPagination");
          searchPagination.innerHTML = ''; // Clear previous result
    var pageCount =  totalResults / size;
    if(totalResults > size) {
        for(var i = 0 ; i<pageCount;i++){   
           $("#searchPagination").append('<li><a href="#" class="browsePage" data-page-num="'+(i+1)+'">'+(i+1)+'</a></li> ');
         }    
     };
}