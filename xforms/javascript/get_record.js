/************************************
GET OAI-PMH RECORD IN VALIDATION INTERFACE
Written by Ethan Gruber, gruber@numismatics.org
Library: jQuery
Description: This calls the getrecord pipeline to show/hide the AJAX response of a GetRecord
 ************************************/

function expand() {
    var id = ORBEON.xforms.Document.getValue('id');
    var service = ORBEON.xforms.Document.getValue('oai-service');
    var repository = ORBEON.xforms.Document.getValue('repository');
    var genre = ORBEON.xforms.Document.getValue('genre');
    var format = ORBEON.xforms.Document.getValue('format');
    var language = ORBEON.xforms.Document.getValue('language');
    var rights = ORBEON.xforms.Document.getValue('rights');
    var rightsText = ORBEON.xforms.Document.getValue('rightsText');
    var target = ORBEON.xforms.Document.getValue('target');
    var type = ORBEON.xforms.Document.getValue('type');
    
    
    var container = id + '_container';
    
     //always call GetRecord when triangle is expanded
     if (ORBEON.jQuery('.' + container).hasClass('hidden')) {
        ORBEON.jQuery.get('../getrecord', {
        sets: service,
        repository: repository,
        genre: genre,
        format: format,
        language: language,
        rights: rights,
        rightsText: rightsText,
        target: target,
        type: type,
        output: 'ajax'
        }, function (data) {
            ORBEON.jQuery('.' + container).html(data);
            ORBEON.jQuery('.' + container).removeClass('hidden');
            ORBEON.jQuery('.' + id + '-button').children('span').children('a').children('span').removeClass('glyphicon-triangle-bottom');
            ORBEON.jQuery('.' + id + '-button').children('span').children('a').children('span').addClass('glyphicon-triangle-top');
        }).fail(function () {
            alert("Error getting individual record from OAI-PMH service. These records will still harvest from the ListRecords service, but the GetRecord service is broken. Please contact the systems administrator for your repository.");
        });
    } else {
        ORBEON.jQuery('.' + container).addClass('hidden');
        ORBEON.jQuery('.' + id + '-button').children('span').children('a').children('span').removeClass('glyphicon-triangle-top');
        ORBEON.jQuery('.' + id + '-button').children('span').children('a').children('span').addClass('glyphicon-triangle-bottom');
    }
}

//clear contents of a container div so that a new ajax call can be made.
function clear() {
    ORBEON.jQuery('.ajax_container').html('');
    ORBEON.jQuery('.ajax_container').addClass('hidden');
}