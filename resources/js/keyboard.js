$(document).ready(function () {
    $('[data-toggle="tooltip"]').tooltip({ container: 'body' });

    $('.keyboard').keyboard({
        openOn: null,
        stayOpen: false,
        alwaysOpen: false,
        autoAccept: true,
        usePreview: false,
        initialFocus: true,
        rtl: true,
        layout: 'syriac-phonetic',
        hidden: function(event, keyboard, el) {
            // keyboard.destroy();
        }
    });

    $('.keyboard-select').click(function () {
        var keyboardID = '#' + $(this).data("keyboard-id");
        var kb = $(keyboardID).getkeyboard();
        // Change layout based on link ID
        kb.options.layout = this.id;
        // Open keyboard if layout is different or time from it last closing is < 200 ms
        if (kb.last.layout !== kb.options.layout || (new Date().getTime() - kb.last.eventTime) < 200) {
            kb.reveal();
        }
    });

    // Change fonts
    $('.swap-font').on('click', function () {
        var selectedFont = $(this).data("font-id");
        $('.selectableFont').not('.syr').css('font-family', selectedFont);
        $("*:lang(syr)").css('font-family', selectedFont);
    });
});
