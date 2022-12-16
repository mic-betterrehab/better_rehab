({
    closeModal: function(component, event, helper) {
        const parent = component.get("v.parent");
        parent.closeModals();
    },
    clickCreate: function(component, event, helper) {
        helper.removeAttributesFromObj(component);
        let calendarCreateCmp = component.find("calendarCreateCmp");
        calendarCreateCmp.createOrBookFromMCC(event.getSource().get("v.value"));
    },
    clickReset: function(component, event, helper) {
        let calendarCreateCmp = component.find("calendarCreateCmp");
        calendarCreateCmp.clickResetHandle();
    },
    handleSiteChange: function(component, event, helper) {
        if (component.get('v.eventLocation') == 'Site') {
            const site = JSON.parse(JSON.stringify(component.get('v.site')));
            component.set("v.newEvent.Address", site.enrtcr__Business_Address_1__c);
        }
    },
})