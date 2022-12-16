({
    onInit: function(component, event, helper) {
        const selectEvent = component.getEvent("eventChange");
        selectEvent.fire();
        component.set('v.isLoading', false);
        console.log(component.get('v.isLoading'));
    },
    closeModal: function(component, event, helper) {
        const parent = component.get("v.parent");
        parent.closeModals();
    },
    reload: function(component, event, helper) {
        const parent = component.get("v.parent");
        parent.reloadAfterCreateEvent();
    }
})