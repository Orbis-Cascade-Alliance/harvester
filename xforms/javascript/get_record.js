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
    var rights = ORBEON.xforms.Document.getValue('rights');
    var target = ORBEON.xforms.Document.getValue('target');
    
    var container = id + '_container';
    //call getrecord web service/AJAX if the div is blank
    if (ORBEON.jQuery('.' + container).html().indexOf('<div>') < 0) {
        ORBEON.jQuery.get('../getrecord', {
            sets: service,
            repository: repository,
            rights: rights,
            target: target,
            output: 'ajax'
        },
        function (data) {
            ORBEON.jQuery('.' + container).html(data);
            ORBEON.jQuery('.' + container).removeClass('hidden');
        });
    } else {
        if (ORBEON.jQuery('.' + container).hasClass('hidden')) {
            ORBEON.jQuery('.' + container).removeClass('hidden');
        } else {
            ORBEON.jQuery('.' + container).addClass('hidden');
        }
    }
}