({
    closeModal: function(component, event, helper) {
        let parent = component.get('v.parent');
        parent.closeModals();
    },
    updateWillReload: function(component, event, helper) {
        let parent = component.get('v.parent');
        parent.updateWillReload();
    }
})