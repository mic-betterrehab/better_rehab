({
    setLoading: function (component, state) {
        component.set('v.isLoading', state);
    },
    removeAttributesFromObj: function(component) {
        let workers = component.get('v.workers');

        workers.forEach(object => {
            delete object['id'];
            delete object['title'];
        });

        component.set('v.workers', workers);
    },
    showMyToast: function(mode, type, title, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: mode,
            title: title,
            message: message,
            type: type
        });
        toastEvent.fire();
    },
})