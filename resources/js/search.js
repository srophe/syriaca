const state = {
    from: 0,
    size: 25,
    lang: '',
    query: '',
    series: '',
    totalResults: 0,
    currentPage: 1,
    letter: 'a',
    searchType: '',
    fullText: '',
    placeName: '',
    attestations: '',
    attestationRangeStart: '',
    attestationRangeEnd: '',
    eventRangeStart: '',
    eventRangeEnd: '',
    stateRangeStart: '',
    stateRangeEnd: '',
    type: [],
    gender: '',
    persName: '',
    state: '',
    stateType: '',
    birthRangeStart: '',
    birthRangeEnd: '',
    deathRangeStart: '',
    deathRangeEnd: '',
    floruitRangeStart: '',
    floruitRangeEnd: '',
    title: '',
    author: '',
    idno: '',
    BHO: '',
    BHS: '',
    CPG: '',
    prologue: '',
    abstract: '',
    incipit: '',
    explicit: '',
    cbssPubDateStart: '',
    cbssPubDateEnd: '',
    publisher: '',
    pubPlace: '',
    cbssSubject: '',
    keyword: '',
};

// Base API URL
const apiUrl = "https://50fnejdk87.execute-api.us-east-1.amazonaws.com/opensearch-api-test";

// Fetch results and update UI
function fetchAndRenderAdvancedSearchResults() {
    //built from url params
    const queryParams = new URLSearchParams(buildQueryParams());

    fetch(`${apiUrl}?${queryParams.toString()}`, { method: 'GET' })
        .then(response => response.json())
        .then(data => {
            state.totalResults = data.hits.total.value;
            displayResultsInfo(state.totalResults);
            if (state.series === 'Comprehensive Bibliography on Syriac Studies'){displayCBSSAuthorResults(data);}
            else {displayResults(data);}
            if (state.totalResults > state.size) {
                renderPagination(state.totalResults, state.size, state.currentPage, changePage);
            }
        })
        .catch(error => {
            handleError('search-results', 'Error fetching search results.');
            console.error(error);
        });
}

// Update state and fetch results for a specific page
function changePage(page) {
    state.currentPage = page;
    state.from = (page - 1) * state.size;
    if(state.searchType === 'browse' || state.query === 'cbssAuthor' || state.searchType === 'letter' || state.searchType === 'cbssSubject'){
        console.log("change page search type: " + state.searchType);
        getPaginatedBrowse();
    } else {
        fetchAndRenderAdvancedSearchResults();
    }
}


// Render pagination buttons
function renderPagination(totalResults, resultsPerPage, currentPage, onPageChange) {
    const totalPages = Math.ceil(totalResults / resultsPerPage);
    const paginationContainer = document.getElementById('searchPagination');
    paginationContainer.innerHTML = '';
    const maxPageNumbers = 5; // Maximum number of page numbers to display

    // Calculate the start and end page range dynamically
    let startPage = Math.max(1, currentPage - Math.floor(maxPageNumbers / 2));
    let endPage = Math.min(totalPages, startPage + maxPageNumbers - 1);

    // Adjust the startPage if we are near the last pages and need to show exactly `maxPageNumbers`
    if (endPage - startPage + 1 < maxPageNumbers) {
        startPage = Math.max(1, endPage - maxPageNumbers + 1);
    }


    // Add page number buttons
    for (let page = startPage; page <= endPage; page++) {
        const pageButton = createPaginationButton(page, () => onPageChange(page));
        if (page === currentPage) {
            pageButton.classList.add('active'); // Highlight the current page
        }
        paginationContainer.appendChild(pageButton);
}


}

// Create a pagination button
function createPaginationButton(text, onClick) {
    const button = document.createElement('button');
    //btn btn-default
    button.classList.add('btn');
    button.classList.add('btn-default');
    button.textContent = text;
    button.onclick = onClick;
    return button;
}

// Display search results
function displayResults(data) {
    //Add series selector here for JoE display? 
    
    //Set displat for selected menu item
    const items = document.querySelectorAll('.ui-menu-item');
    //On initial load add badge to first letter if no other letter is selected. 
    // Check if any item has the 'selected' class
    const anyItemSelected = Array.from(items).some(item => 
      item.classList.contains('badge')
    );
  
    // If no item is selected, add the class to the first one
    if (!anyItemSelected && items.length > 0) {
      items[0].classList.add('badge');
    }
    
    //Add class badge to selected letter
    items.forEach(item => {
      item.addEventListener('click', () => {
        // Remove 'selected' class from all items
        items.forEach(el => el.classList.remove('badge'));

        // Add 'selected' class to the clicked item
        item.classList.add('badge');
      });
      
    });

    
    const resultsContainer = document.getElementById("search-results");
    resultsContainer.innerHTML = ''; // Clear previous results
    if(document.getElementById("toggleSearchForm")){
        const toggleButton = document.getElementById("toggleSearchForm");
        const searchFormContainer = document.getElementById("advancedSearch");
        
        // Show the toggle button
        toggleButton.style.display = "inline-block";

        // Hide the advanced search form
        searchFormContainer.style.display = "none";

        // Update the button text
        toggleButton.textContent = "Show Search";
    }

    if (data.hits && data.hits.hits.length > 0) {
        data.hits.hits.forEach(hit => {
            const resultItem = document.createElement("div");
            resultItem.classList.add("result-item");
            resultItem.style.marginBottom = "15px"; // Add spacing between items
            
            // Extract the title, prologue, and idno fields from the response
            const title = hit._source.title || 'No Title';
            const syriacTitle = hit._source.titleSyriac || 'No Syriac Title';
            const arabicTitle = hit._source.titleArabic || 'No Arabic Title';
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
            if(hit._source.placeName){
                var typeString = type ? ` (${type}) `: '';
            }else if(hit._source.persName){
                var typeString = type ? ` (${type}) `: '';
            } else {
                typeString = '';
            }
            const abstract = hit._source.abstract || '';
            const abstractString = abstract ? ` ${abstract} <br/>`: '';
            const prologue = hit._source.prologue || ' ';
            const idno = hit._source.idno || ''; // Fallback if no idno
            const coordinates = hit._source.coordinates || ''; // Fallback if no idno
            // Construct the URL using the idno field
            //const url = idno ? `${idno}`: '#';

             //URL if JoE
           if(state.series = 'Prosopography to John of Ephesus’s Ecclesiastical History'){
                var idnoString = idno.replace('\/person\/', '\/johnofephesus\/persons\/');
                var url = idnoString ? `${idnoString}`: '#';
            }else if(state.series = 'Gazetteer to John of Ephesus’s Ecclesiastical History'){
                var idnoString = idno.replace('\/place\/', '\/johnofephesus\/places\/');
                var url = idnoString ? `${idnoString}`: '#';
            } else {
                 var url = idno ? `${idno}`: '#';
            }
           
            
            // Populate the result item with the link and details
            if(state.lang === 'syr'){
                resultItem.innerHTML = `
                <a href="${url}" target="_blank" style="text-decoration: none; color: #007bff;">
                    <span class="tei-title title-analytic">${syriacTitle}</span> ${typeString}
                </a>
                ${nameString}
                <br/>URI: 
                <a href="${url}" target="_blank" style="text-decoration: none; color: #007bff;">
                    <span class="tei-title title-analytic">${url}</span>
                </a>
                `;
            }
            if(state.lang === 'ar'){
                resultItem.innerHTML = `
                <a href="${url}" target="_blank" style="text-decoration: none; color: #007bff;">
                    <span class="tei-title title-analytic">${arabicTitle}</span> ${typeString}
                </a>
                ${nameString}
                <br/>URI: 
                <a href="${url}" target="_blank" style="text-decoration: none; color: #007bff;">
                    <span class="tei-title title-analytic">${url}</span>
                </a>
                `;
            } else (
                resultItem.innerHTML = `
                <a href="${url}" target="_blank" style="text-decoration: none; color: #007bff;">
                    <span class="tei-title title-analytic">${title}</span> ${typeString}
                </a>
                ${nameString}
                <br/>URI: 
                <a href="${url}" target="_blank" style="text-decoration: none; color: #007bff;">
                    <span class="tei-title title-analytic">${url}</span>
                </a>
                `);

            resultsContainer.appendChild(resultItem);
        });
    } else {
    resultsContainer.innerHTML = '<p>No results found.</p>';
    }
}

// Reusable error handler
function handleError(containerId, message) {
    const container = document.getElementById(containerId);
    container.innerHTML = ''; // Clear previous message
    container.innerHTML = `<p>${message}</p>`;
}

function getBrowse(series) {
    state.query = series; // Retain the series in state.query
    state.from = 0; // Reset for the first page
    state.letter = state.letter || 'a'; // Default to 'a' if undefined
    state.searchType = 'letter'; // Set search type to 'browse'
    const params = {
        searchType: 'letter',
        q: state.query, // Retain the query which is the series name in the case of browse
        letter: state.letter,
        from: state.from,
        size: state.size,
        lang: state.lang
    };

    // Remove empty or undefined parameters
    const filteredBrowseParams = Object.fromEntries(
        Object.entries(params).filter(([key, value]) => value !== '' && value !== undefined)
    );

    // Create URLSearchParams with filtered parameters
    const queryParams = new URLSearchParams(filteredBrowseParams);

    fetch(`${apiUrl}?${queryParams.toString()}`, { method: 'GET' })
        .then(response => response.json())
        .then(data => {
            state.totalResults = data.hits.total.value;
            displayResultsInfo(state.totalResults);
            displayResults(data);
        })
        .catch(error => {
            handleError('search-results', 'Error fetching browse results.');
            console.error(error);
        });
}
function getPaginatedBrowse() {

    const params = {
        searchType: state.searchType,
        q: state.query, // Retain the query which is the series name in the case of browse
        letter: state.letter,
        from: state.from,
        size: state.size,
        lang: state.lang,
        series: state.series,
        subject: state.subject
    };

    // Remove empty or undefined parameters
    const filteredBrowseParams = Object.fromEntries(
        Object.entries(params).filter(([key, value]) => value !== '' && value !== undefined)
    );

    // Create URLSearchParams with filtered parameters
    const queryParams = new URLSearchParams(filteredBrowseParams);

    fetch(`${apiUrl}?${queryParams.toString()}`, { method: 'GET' })
        .then(response => response.json())
        .then(data => {
            state.totalResults = data.hits.total.value;
            displayResultsInfo(state.totalResults);
            if(state.query === 'cbssAuthor' || state.series === 'Comprehensive Bibliography on Syriac Studies'){ displayCBSSAuthorResults(data); }
            else if(state.query === 'cbssSubject'){ 
                console.log("cbssSubject q with no series designated");
                displayCBSSDocumentResults(data); 
            }
            else{displayResults(data);}
        })
        .catch(error => {
            handleError('search-results', 'Error fetching browse results.');
            console.error(error);
        });
}
function displayResultsInfo(totalResults) {
    const browseInfoContainer = document.getElementById('search-info');
    
    // Clear previous browse info and pagination
    browseInfoContainer.innerHTML = '';

    // Display total results count
    browseInfoContainer.innerHTML = `
        <br/>
        <p>Total Results: ${totalResults}</p>
    `;
    const paginationContainer = document.getElementById('searchPagination');
    paginationContainer.innerHTML = '';
    if (totalResults > state.size) {
        renderPagination(totalResults, state.size, state.currentPage, changePage);
    }

}
function initializeStateFromURL() {
    const urlParams = new URLSearchParams(window.location.search);
    state.lang = urlParams.get('lang') || 'en'; // Default to English if no language is set
    state.keyword = urlParams.get('keyword') || ''; // Default to empty query if not set
    state.series = urlParams.get('series') || ''; // Default to empty query if not set
    state.searchType = urlParams.get('searchType') || ''; // Retrieve searchType from the URL

    state.query = urlParams.get('q') || ''; // Retrieve query from the URL
    if(state.keyword){
        fetchAndRenderAdvancedSearchResults();
    }
}

function browseAlphaMenu() {
    const urlParams = new URLSearchParams(window.location.search);
    state.lang = urlParams.get('lang') || 'en'; // Default to English if no language is set
    

    const engAlphabet = 'A B C D E F G H I J K L M N O P Q R S T U V W X Y Z';
    const syrAlphabet = 'ܐ ܒ ܓ ܕ ܗ ܘ ܙ ܚ ܛ ܝ ܟ ܠ ܡ ܢ ܣ ܥ ܦ ܩ ܪ ܫ ܬ';
    const arAlphabet = 'ا ب ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ق ك ل م ن ه و ي';

    // Determine the alphabet based on the selected language
    let alphabet = engAlphabet;
    if (state.lang === 'syr') {
        alphabet = syrAlphabet;
        state.letter = 'ܐ'; // Default to first Syriac letter
    } else if (state.lang === 'ar') {
        alphabet = arAlphabet;
        state.letter = 'ا'; // Default to first Arabic letter
    }

    // Create the menu container
    const menuContainer = document.getElementById('abcMenu');
    menuContainer.innerHTML = ''; // Clear previous menu

    // Set direction for right-to-left languages
    if (state.lang === 'syr' || state.lang === 'ar') {
        menuContainer.setAttribute('dir', 'rtl');
    } else {
        menuContainer.setAttribute('dir', 'ltr');
    }

    // Create alphabet navigation
    alphabet.split(' ').forEach(letter => {
        const menuItem = document.createElement('li');
        menuItem.classList.add('ui-menu-item');
        menuItem.setAttribute('role', 'menuitem');
        //items.forEach(el => el.classList.remove('selected'));
        const menuLink = document.createElement('a');
        menuLink.classList.add('ui-all');
        menuLink.textContent = letter;
        menuLink.href = `?searchType=letter&letter=${letter}&q=${encodeURIComponent(state.query)}&size=${state.size}&lang=${state.lang}`;
        
        // Attach event listener for letter selection
        menuLink.addEventListener('click', (event) => {
            event.preventDefault(); // Prevent page reload
            state.letter = letter; // Update state
            state.from = 0; // Reset pagination
            getBrowse(state.query); // Trigger browse function
        });

        menuItem.appendChild(menuLink);
        menuContainer.appendChild(menuItem);
    });
}
function browseCbssAlphaMenu() {
    const urlParams = new URLSearchParams(window.location.search);
    state.lang = urlParams.get('lang') || 'en'; // Default to English if no language is set
    const alphabets = {
        en: 'A B C D E F G H I J K L M N O P Q R S T U V W X Y Z',
        rus: 'А Б В Г Д Е Ё Ж З И Й К Л М Н О П Р С Т У Ф Х Ц Ч Ш Щ Ъ Ы Ь Э Ю Я',
        gr: 'Α Β Γ Δ Ε Ζ Η Θ Ι Κ Λ Μ Ν Ξ Ο Π Ρ Σ Τ Υ Φ Χ Ψ Ω',
        arm: 'Ա Բ Գ Դ Ե Զ Է Ը Թ Ժ Ի Լ Խ Ծ Կ Հ Ձ Ղ Ճ Մ Յ Ն Շ Ո Չ Պ Ջ Ռ Ս Վ Տ Ր Ց Ու Փ Ք Օ Ֆ',
        he: 'א ב ג ד ה ו ז ח ט י כ ל מ נ ס ע פ צ ק ר ש ת',
        syr: 'ܐ ܒ ܓ ܕ ܗ ܘ ܙ ܚ ܛ ܝ ܟ ܠ ܡ ܢ ܣ ܥ ܦ ܨ ܩ ܪ ܫ ܬ',
        ar: 'ا ب ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ق ك ل م ن ه و ي'
    };

    // Select the appropriate alphabet for the current language
    const alphabet = alphabets[state.lang] || alphabets.en;
    // Set the default letter based on the language-- this is not yet necessary
    if (state.lang === 'syr') {
        state.letter = 'ܐ'; // Default to first Syriac letter
    } else if (state.lang === 'ar') {
        state.letter = 'ا'; // Default to first Arabic letter
    } else if (state.lang === 'he') {
        state.letter = 'א'; // Default to first Hebrew letter
    } else if (state.lang === 'arm') {
        state.letter = 'Ա'; // Default to first Armenian letter
    } else if (state.lang === 'gr') {
        state.letter = 'Α'; // Default to first Greek letter
    } else if (state.lang === 'rus') {
        state.letter = 'А'; // Default to first Russian letter
    } else { state.letter = 'A'; } // Default to first English letter

    // Create the menu container
    const menuContainer = document.getElementById('abcMenu');
    menuContainer.innerHTML = ''; // Clear previous menu

    // Set direction for right-to-left languages
    const rtlLanguages = ['ar', 'syr', 'he'];
    menuContainer.setAttribute('dir', rtlLanguages.includes(state.lang) ? 'rtl' : 'ltr');

    // Create alphabet navigation
    alphabet.split(' ').forEach(letter => {
        const menuItem = document.createElement('li');
        menuItem.classList.add('ui-menu-item');
        menuItem.setAttribute('role', 'menuitem');

        const menuLink = document.createElement('a');
        menuLink.classList.add('ui-all');
        menuLink.textContent = letter;
        menuLink.href = `?searchType=browse&q=${encodeURIComponent(state.query)}&letter=${letter}&size=${state.size}&lang=${state.lang}`;

        // Attach event listener for letter selection
        menuLink.addEventListener('click', (event) => {
            event.preventDefault(); // Prevent page reload
            state.letter = letter; // Update state
            state.from = 0; // Reset pagination
            getCBSSBrowse(); // Trigger the CBSS browse function
        });

        menuItem.appendChild(menuLink);
        menuContainer.appendChild(menuItem);
    });
}


function getCBSSBrowse() {
    // Set state for CBSS browse
    initializeStateFromURL();
    state.from = 0; // Reset for the first page
    state.letter = state.letter || 'a'; // Default letter if not already set
    const queryParams = new URLSearchParams({
        searchType: state.searchType,
        q: state.query,
        letter: state.letter,
        from: state.from,
        size: state.size,
        lang: state.lang,
    });

    fetch(`${apiUrl}?${queryParams.toString()}`, { method: 'GET' })
        .then(response => response.json())
        .then(data => {
            state.totalResults = data.hits.total.value;
            // displayResultsInfo(state.totalResults); 
            if(state.query === 'cbssAuthor' ){ displayCBSSAuthorResults(data); }
            if(state.query === 'cbssSubject' ){ displayCBSSSubjectResults(data); }   })
        .catch(error => {
            handleError('search-results', 'Error fetching CBSS browse results.');
            console.error(error);
        });
}
function displayCBSSSubjectResults(data) {
    const resultsContainer = document.getElementById("search-results");
    resultsContainer.innerHTML = ''; // Clear previous results
    console.log("cbsssubjectresults", state.letter);
    // Ensure aggregation data is available
    const subjects = data.aggregations?.unique_subjects?.buckets || [];

    // Filter subjects that start with the designated letter
    const filteredSubjects = subjects.filter(subject => 
        subject.key.toLowerCase().startsWith(state.letter.toLowerCase())
    );
    state.totalResults = filteredSubjects.length;
    displayResultsInfo(state.totalResults); 
    if (state.totalResults > state.size) {
        renderPagination(state.totalResults, state.size, state.currentPage, changePage);
    }
    if (filteredSubjects.length > 0) {
        const list = document.createElement("ul"); // Create a list to display subjects
        list.classList.add("subject-list"); // Add a class for styling

        filteredSubjects.forEach(subject => {
            const listItem = document.createElement("li");
            const link = document.createElement("a");

            link.href = "#"; // Placeholder, will be handled by the click event
            link.textContent = `${subject.key} (${subject.doc_count})`; // Display the subject name and count
            link.style.textDecoration = "none"; // Style the link
            link.style.color = "#007bff";

            // Attach click event to fetch CBSS records for this subject
            link.addEventListener("click", (event) => {
                event.preventDefault(); // Prevent default anchor behavior
                state.subject = subject.key;
                fetchCBSSRecordsBySubject(subject.key); // Fetch records for the clicked subject
            });

            listItem.appendChild(link);
            list.appendChild(listItem);
        });

        resultsContainer.appendChild(list); // Add the list to the results container
    } else {
        resultsContainer.innerHTML = `<p>No subjects found starting with "${state.letter}".</p>`;
    }
}
// Function to fetch CBSS document entries by subject
function fetchCBSSRecordsBySubject(subjectKey) {
    const apiUrl = "https://50fnejdk87.execute-api.us-east-1.amazonaws.com/opensearch-api-test";
    state.searchType = "cbssSubject";     

    // Build query parameters
    const queryParams = new URLSearchParams({
        searchType: "cbssSubject",        
        subject: subjectKey, 
        size: state.size, 
        from: state.from
    });
    
    // Fetch data from the API
    fetch(`${apiUrl}?${queryParams.toString()}`, { method: 'GET' })
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! Status: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            state.totalResults = data.hits.total.value;
            displayResultsInfo(state.totalResults);
            // Display the results
            displayCBSSDocumentResults(data, subjectKey);
        })
        .catch(error => {
            console.error('Error fetching CBSS records:', error);
            handleError('search-results', 'Error fetching CBSS records.');
        });
}

// Function to display CBSS document results
function displayCBSSDocumentResults(data, subjectKey) {
    const resultsContainer = document.getElementById("search-results");
    resultsContainer.innerHTML = ''; // Clear previous results

    // Add a subject heading
    const subjectHeading = document.createElement("h3");
    subjectHeading.textContent = `Subject: ${subjectKey}`;
    resultsContainer.appendChild(subjectHeading);

    if (data.hits && data.hits.hits.length > 0) {
        
        // Extract and sort the results by author name
        const sortedHits = data.hits.hits.sort((a, b) => {
            const authorA = Array.isArray(a._source.author)
                ? a._source.author.join(", ")
                : a._source.author || "No Author";
            const authorB = Array.isArray(b._source.author)
                ? b._source.author.join(", ")
                : b._source.author || "No Author";

            // Convert to lowercase for case-insensitive comparison
            return authorA.toLowerCase().localeCompare(authorB.toLowerCase());
        });

        // Render the sorted results
        sortedHits.forEach(hit => {
            const resultItem = document.createElement("div");
            resultItem.classList.add("result-item");
            resultItem.style.marginBottom = "15px"; // Add spacing between items

            // Extract relevant fields from the hit source
            const subject = hit._source.subject || 'No Subject';
            const citation = hit._source.citation || 'No Citation';
            const idno = hit._source.idno || '#';

            // Create clickable URI
            const uri = idno !== '#' ? `<a href="${idno}" target="_blank">${idno}</a>` : '';

            // Populate the result item with details
            resultItem.innerHTML = `
                <div>
                    <strong>${citation}</strong>
                    <br/>
                    <p>Subjects: ${subject}</p>
                    <p>URI: ${uri}</p>
                </div>
            `;

            resultsContainer.appendChild(resultItem);
        });
    } else {
        resultsContainer.innerHTML = '<p>No records found for the selected subject.</p>';
    }
}

//Winona's styling implementation
function displayCBSSAuthorResults(data) {
    const resultsContainer = document.getElementById("search-results");
          resultsContainer.innerHTML = ''; // Clear previous results
    
    //Add selected badge here? 
    const items = document.querySelectorAll('.ui-menu-item');
    //On initial load add badge to first letter if no other letter is selected. 
    // Check if any item has the 'selected' class
    const anyItemSelected = Array.from(items).some(item => 
      item.classList.contains('badge')
    );
  
    // If no item is selected, add the class to the first one
    if (!anyItemSelected && items.length > 0) {
      items[0].classList.add('badge');
    }
    
    //Add class badge to selected letter
    items.forEach(item => {
      item.addEventListener('click', () => {
        // Remove 'selected' class from all items
        items.forEach(el => el.classList.remove('badge'));

        // Add 'selected' class to the clicked item
        item.classList.add('badge');
      });
      
    });
    
    if (data.hits && data.hits.hits.length > 0) {
        data.hits.hits.forEach(hit => {
            const resultItem = document.createElement("div");
            const bdiElement = document.createElement("bdi");
            resultItem.classList.add("result-item");
            resultItem.style.marginBottom = "15px"; // Add spacing between items
            //divElement.appendChild(bdiElement); 
            
            // Extract the title, prologue, and idno fields from the response
            const title = hit._source.citation || hit._source.title + ' Missing Citation';
            const type = hit._source.type || '';
            const typeString = type ? ` (${type}) `: '';
            const prologue = hit._source.prologue || ' ';
            const idno = hit._source.idno || ''; // Fallback if no idno
            // Construct the URL using the idno field
            const url = idno ? `${idno}`: '#';
            
            // Populate the result item with the link and details
            bdiElement.innerHTML = `
                ${title}
                <br/>URI: 
                <a href="${url}" target="_blank" style="text-decoration: none; color: #007bff;">
                    <span class="tei-title title-analytic">${url}</span>
                </a>
              `;
            resultItem.appendChild(bdiElement);
            resultsContainer.appendChild(resultItem);
        });
    } else {
        resultsContainer.innerHTML = '<p>No results found.</p>';
    }
}
//Advanced Search
// Handle form submission
document.addEventListener('DOMContentLoaded', () => {
    initializeStateFromURL();
    if(document.getElementById('advancedSearch')){
        const advancedSearchForm = document.getElementById('advancedSearch');

        advancedSearchForm.addEventListener('submit', function (e) {
            e.preventDefault(); // Prevent the default form submission behavior (page reload)
    
            updateStateFromForm(this); // Update state with form data
            fetchAndRenderAdvancedSearchResults(); 
        });
    }
    // currently not needed: url params are used to initialize state
    // if(document.getElementById('site_search_form')){
    //     const searchForm = document.getElementById('site_search_form');

    //     searchForm.addEventListener('submit', function (e) {
    //         e.preventDefault(); // Prevent the default form submission behavior (page reload)
    
    //         updateStateFromForm(this); // Update state with form data
    //         fetchAndRenderAdvancedSearchResults(); 
    //     });
    // }

});
//Not needed?
function runSearch() {
    state.currentPage = 1;
    state.from = 0;
}

// Helper function to get form data and update state
function updateStateFromForm(form) {
    const formData = new FormData(form);

    // Map form inputs to state variables
    state.fullText = formData.get('fullText') || '';
    state.placeName = formData.get('placeName') || '';
    state.attestations = formData.get('attestations') || '';
    state.attestationRangeStart = formData.get('attestationRangeStart') || '';
    state.attestationRangeEnd = formData.get('attestationRangeEnd') || '';
    state.eventRangeStart = formData.get('eventDatesStart') || '';
    state.eventRangeEnd = formData.get('eventDatesEnd') || '';
    state.type = formData.getAll('type'); // Get all selected type values, necessary for cbss advanced search only
    state.series = formData.get('series') || ''; 
    state.from = 0; // Reset pagination
    state.stateRangeStart = formData.get('stateDatesStart') || '';
    state.stateRangeEnd = formData.get('stateDatesEnd') || '';
    state.gender = formData.get('gender') || '';
    state.persName = formData.get('persName') || '';
    state.state = formData.get('state') 
    ? formData.get('state').charAt(0).toUpperCase() + formData.get('state').slice(1).toLowerCase() 
    : ''; //need to capitalize the first letter of the state for Martyrs, all states in data are capitalized
    state.stateType = formData.get('stateType') || '';
    state.startDate = formData.get('start-date') || '';
    state.endDate = formData.get('end-date') || '';
    const dateType = formData.get('date-type') || '';
    state.bookLimit = formData.get('bookLimit') || '';
    state.cbssSubject = formData.get('keywordSearch') || '';
    state.cbssPubDateEnd = formData.get('cbssPubDateEnd') || '';
    state.cbssPubDateStart = formData.get('cbssPubDateStart') || '';
    state.publisher = formData.get('publisher') || '';
    state.pubPlace = formData.get('pubPlace') || '';
    state.keyword = formData.get('keyword') || '';



    if (dateType === 'birth') {
        state.birthRangeStart = formData.get('start-date') || '';
        state.birthRangeEnd = formData.get('end-date') || '';
        state.deathRangeStart = '';
        state.deathRangeEnd = '';
        state.floruitRangeStart = '';
        state.floruitRangeEnd = '';
    }
    if (dateType === 'death') {     
        state.deathRangeStart = formData.get('start-date') || '';
        state.deathRangeEnd = formData.get('end-date') || '';
        state.floruitRangeStart = '';
        state.floruitRangeEnd = '';
        state.birthRangeStart = '';
        state.birthRangeEnd = '';
    }
    if (dateType === 'floruit') {   
        state.floruitRangeStart = formData.get('start-date') || '';
        state.floruitRangeEnd = formData.get('end-date') || '';
        state.deathRangeStart = '';
        state.deathRangeEnd = '';
        state.birthRangeStart = '';
        state.birthRangeEnd = '';
    }
    state.prologue = formData.get('prologue') || '';
    state.incipit = formData.get('incipit') || '';
    state.explicit = formData.get('explicit') || '';
    state.title = formData.get('title') || '';
    state.author = formData.get('author') || '';

    if(formData.get('idnoText')){
        if(formData.get('idnoType') === 'BHO'){
            state.BHO = formData.get('idnoText') || '';
        }else if(formData.get('idnoType') === 'BHS'){
            state.BHS = formData.get('idnoText') || '';
        } else if(formData.get('idnoType') === 'CPG'){
            state.CPG = formData.get('idnoText') || '';
        } else {
        //This requires a change to the dynamic search query processing to handle multiple idno type searches that are not inclusive of each other, using default instead
            state.BHO = formData.get('idnoText') || '';
            state.BHS = formData.get('idnoText') || '';
            state.CPG = formData.get('idnoText') || '';
        }
    }
}

// Build the API query based on state
function buildQueryParams() {
    const params = {
        fullText: state.fullText,
        placeName: state.placeName,
        attestations: state.attestations,
        attestationRangeStart: state.attestationRangeStart,
        attestationRangeEnd: state.attestationRangeEnd,
        eventRangeStart: state.eventRangeStart,
        eventRangeEnd: state.eventRangeEnd,
        stateType: state.stateType,
        stateRangeStart: state.stateRangeStart,
        stateRangeEnd: state.stateRangeEnd,
        type: state.type.join(','), // Join array elements with commas for query string
        series: state.series,
        from: state.from,
        size: state.size,
        gender: state.gender,
        persName: state.persName,
        state: state.state,
        birthRangeStart: state.birthRangeStart,
        birthRangeEnd: state.birthRangeEnd,
        deathRangeStart: state.deathRangeStart,
        deathRangeEnd: state.deathRangeEnd,
        floruitRangeStart: state.floruitRangeStart,
        floruitRangeEnd: state.floruitRangeEnd,
        idno: state.idno,
        prologue: state.prologue,
        incipit: state.incipit,
        explicit: state.explicit,
        title: state.title,
        author: state.author,
        cbssPubRangeStart: state.cbssPubDateStart,
        cbssPubRangeEnd: state.cbssPubDateEnd,
        publisher: state.publisher,
        cbssPubPlace: state.pubPlace,
        subject: state.cbssSubject,
        keyword: state.keyword,
        BHO: state.BHO,
        BHS: state.BHS,     
        CPG: state.CPG

    };

    // Filter out empty or undefined parameters
    return Object.fromEntries(Object.entries(params).filter(([key, value]) => value !== '' && value !== undefined));
}
//NavBar
document.querySelector(".navbar-form").addEventListener("submit", (event) => {
    event.preventDefault(); // Prevent the default form submission behavior

    // Reset state variables to ensure a clean slate
    resetState();

    // Get form values
    const form = event.target;
    const formData = new FormData(form);
    // Map form inputs to state variables
    state.keyword = formData.get('q') || formData.get('fullText')||formData.get('keyword')||'';
    state.series = formData.get('series') || ''; // 

    // Call your search function
    fetchAndRenderAdvancedSearchResults();
});


// Helper function to reset the state to its default values
function resetState() {
    state.from = 0;
    state.size = 25;
    state.lang = '';
    state.query = '';
    state.series = '';
    state.totalResults = 0;
    state.currentPage = 1;
    state.letter = 'a';
    state.searchType = '';
    state.fullText = '';
    state.placeName = '';
    state.attestations = '';
    state.attestationRangeStart = '';
    state.attestationRangeEnd = '';
    state.eventRangeStart = '';
    state.eventRangeEnd = '';
    state.stateRangeStart = '';
    state.stateRangeEnd = '';
    state.type = [];
    state.gender = '';
    state.persName = '';
    state.state = '';
    state.stateType = '';
    state.birthRangeStart = '';
    state.birthRangeEnd = '';
    state.deathRangeStart = '';
    state.deathRangeEnd = '';
    state.floruitRangeStart = '';
    state.floruitRangeEnd = '';
    state.title = '';
    state.author = '';
    state.idno = '';
    state.prologue = '';
    state.abstract = '';
    state.incipit = '';
    state.explicit = '';
    state.pubDate = '';
    state.publisher = '';
    state.pubPlace = '';
    state.cbssSubject = '';
    state.keyword = '';
}
document.addEventListener("DOMContentLoaded", function () {
    if (document.getElementById("toggleSearchForm")) {
        const toggleButton = document.getElementById("toggleSearchForm");
            const searchFormContainer = document.getElementById("advancedSearch");

            // Toggle the display of the advanced search form
            toggleButton.addEventListener("click", function () {
                if (searchFormContainer.style.display === "none" || searchFormContainer.style.display === "") {
                    searchFormContainer.style.display = "block";
                    toggleButton.textContent = "Hide Search";
                } else {
                    searchFormContainer.style.display = "none";
                    toggleButton.textContent = "Show Search";
                }
            });
    }
    
});


