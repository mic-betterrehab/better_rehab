({
	doInit : function(component, event, helper) {
		var action = component.get("c.getERs");
     	var recordId = component.get("v.recordId");
        
        action.setParams({
            eventId :  recordId  
        });
         
     	action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log(result)
                
                const workers = [];
                result.forEach(er => workers.push({
                    'Id' : er.lookupId,
                    'Name' : er.name
                }));
                
                
                component.set('v.data', result);
                component.set('v.excludedClients', workers);
                
                helper.getEvent(component).then(res => {
                    component.set('v.eventRecord', res);
                    component.set('v.isLoaded', true);
                }).catch(err => {
                    console.log(err);
                });
            } else if (state === "INCOMPLETE") {
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
	},
      
    createERsAura: function (component, event, helper) {
        console.log('create before controller');
        console.log('button Id in parent in createERsAura');
        console.log(component.get('v.buttonId'));
        
        return new Promise(function (resolve, reject) {
            helper.createERsAura(component, component.get('v.buttonId')).then(res=> resolve(res)).catch(err => reject(err));
        })
    },
    
    cancelER: function (component, event, helper) {
        return new Promise(function (resolve, reject) {
            helper.updateER(component, 'Cancelled', component.get('v.buttonId')).then(res=> resolve(res)).catch(err => reject(err));
        })
    },
                                                                 
    bookER : function (component, event, helper) {
        return new Promise(function (resolve, reject) {
            helper.updateER(component, 'Booked', component.get('v.buttonId')).then(res=> resolve(res)).catch(err => reject(err));
        })
       
    },
                    
    deleteERAura: function (component, event, helper) {
        console.log('inside deleteERAura');
        return new Promise(function (resolve, reject) {
            helper.updateER(component, 'Deleted', component.get('v.buttonId')).then(res=> resolve(res)).catch(err => reject(err));
        })
    },
    
    bookEvent : function (component, event, helper) {
        return new Promise(function (resolve, reject) {
        	helper.updateEventAura(component, 'Booked').then(res => resolve(res)).catch(err => reject(err)); 
       	})
    },
    
    cancelEvent : function (component, event, helper) {
        return new Promise(function (resolve, reject) {
            helper.updateEventAura(component, 'Cancelled').then(res => resolve(res)).catch(err => reject(err)); 
        })
    },
                                                       
    //this is a component event, to pass a value of button Id from child (table pagination) to parent (WorkerEventRelations)
    //this event is only called if we click Save/Save One/Save All when adding CER or ER
    handlePaginationEvent : function (component, event, helper) {
        console.log("handlePaginationEvent");
        
        var valueFromChild = event.getParam("message");
        console.log('valueFromPaginationChild: ' + valueFromChild);
        component.set('v.buttonId', valueFromChild);
    },   
})