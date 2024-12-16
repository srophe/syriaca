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
    type: '',
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
    prologue: '',
    abstract: '',
    incipit: '',
    explicit: ''
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
            displayResults(data);
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
    if(state.searchType === 'browse' || state.query === 'cbssAuthor' || state.searchType === 'letter'){
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
    button.textContent = text;
    button.onclick = onClick;
    return button;
}

// Display search results
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
            const abstract = hit._source.abstract || '';
            const abstractString = abstract ? ` ${abstract} <br/>`: '';
            const typeString = type ? ` (${type}) `: '';
            const prologue = hit._source.prologue || ' ';
            const idno = hit._source.idno || ''; // Fallback if no idno
            // Construct the URL using the idno field
            const url = idno ? `${idno}`: '#';
            
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
        lang: state.lang,
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
        series: state.series
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
            if(state.query === 'cbssAuthor'){ displayCBSSAuthorResults(data); }
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
    } else if (state.lang === 'ar') {
        alphabet = arAlphabet;
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


function getCBSSBrowse(browseType = 'cbssAuthor') {
    // Set state for CBSS browse
    state.query = browseType; // Retain the series name in the state
    state.from = 0; // Reset for the first page
    state.letter = state.letter || 'a'; // Default letter if not already set
    state.searchType = 'browse'; // Set search type to 'browse'
    const queryParams = new URLSearchParams({
        searchType: 'browse',
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
            displayResultsInfo(state.totalResults); 
            displayCBSSAuthorResults(data); 
        })
        .catch(error => {
            handleError('search-results', 'Error fetching CBSS browse results.');
            console.error(error);
        });
}

function displayCBSSAuthorResults(data) {
    const resultsContainer = document.getElementById('search-results');
    resultsContainer.innerHTML = data.hits.hits.map(hit => `
            <div class="result-item">
                <div>
                    <strong>Author:</strong> 
                    <a href="${hit._source.idno}" target="_blank">${hit._source.author}</a>
                </div>
                <div>
                    <strong>Title:</strong> 
                    <a href="${hit._source.idno || '#'}" target="_blank">${hit._source.title || ''}</a>
                    <p>${hit._source.type || ''}</p>
                </div>
            </div>
        `).join('');
}
//Advanced Search
// Handle form submission
document.addEventListener('DOMContentLoaded', () => {

    if(document.getElementById('advancedSearch')){
        const advancedSearchForm = document.getElementById('advancedSearch');

        advancedSearchForm.addEventListener('submit', function (e) {
            e.preventDefault(); // Prevent the default form submission behavior (page reload)
    
            updateStateFromForm(this); // Update state with form data
            fetchAndRenderAdvancedSearchResults(); 
        });
    }

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
    state.type = formData.get('type') || '';
    state.series = formData.get('series') || 'The Syriac Gazetteer'; // Default to "The Syriac Gazetteer"
    state.from = 0; // Reset pagination
    state.stateRangeStart = formData.get('stateDatesStart') || '';
    state.stateRangeEnd = formData.get('stateDatesEnd') || '';
    state.gender = formData.get('gender') || '';
    state.persName = formData.get('persName') || '';
    state.state = formData.get('state') || '';
    state.stateType = formData.get('stateType') || '';
    state.startDate = formData.get('start-date') || '';
    state.endDate = formData.get('end-date') || '';
    const dateType = formData.get('date-type') || '';

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
        state.floruitRangeEnd = '';
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
    if(formData.get('idno')){
    state.idno = "http://syriaca.org/work/"+formData.get('idno') || '';}
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
        type: state.type,
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
        author: state.author
    };

    // Filter out empty or undefined parameters
    return Object.fromEntries(Object.entries(params).filter(([key, value]) => value !== '' && value !== undefined));
}