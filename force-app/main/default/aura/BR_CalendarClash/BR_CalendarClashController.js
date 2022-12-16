({
    //call this in parent component, with the init function (immediately upon calling when v.clickCreateClicked is set to true)
    doInitRun : function(component, event, helper) {
        if (!component.get('v.isParentMCC')) {
            helper.clashHandler(component).then((result) => {
                if (result.length !== 0) {
                    component.set("v.clashingWorkerClientNames", result);
                    component.set('v.calendarClashModalVisible', true);
                } else {
                    helper.insertEventFromParent(component);
                }
            }).catch(err => {
                console.log(err);
                helper.showMyToast('dismissible', 'error', 'An error occurred. Please refresh the page and try again.', err);
            })
        }
    },
    continueCreateEvent : function(component, event, helper){
        helper.insertEventFromParent(component);

        //close the modal
        component.set('v.calendarClashModalVisible', false);
    },

    closeModal : function(component, event, helper) {
        component.set('v.calendarClashModalVisible', false);

        var compEvent = component.getEvent("clashComponentEvent");
        compEvent.setParams({"message" : false });
        compEvent.fire();
    },
    handleClash : function(component, event, helper) {
        let params = event.getParam('arguments');

        if (params) {
            component.set('v.clashingWorkerClientNames', params.clashingWorkerClientNames);
            component.set('v.calendarClashModalVisible', params.calendarClashModalVisible);
        }
    }
})