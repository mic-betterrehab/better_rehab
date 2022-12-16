({
    cancel: function() {
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
    },

    deleteItems: function(component, helper) {
        component.set('v.showSpinner', true);
        var action = component.get('c.deleteAllExtractItemsNotApproved');

        action.setParam('extractId', component.get('v.recordId'));

        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Success",
                    "type": "success",
                    "message": response.getReturnValue()
                });
                resultsToast.fire();
                helper.cancel();
            } else {
                console.log(response);
                component.set('v.showSpinner', true);
            }
        });

        $A.enqueueAction(action);
    }
});