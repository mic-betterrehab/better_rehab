({
	doInit : function(component, event, helper) {
		var action = component.get("c.getCERs");
     	var recordId = component.get("v.recordId");
        action.setParams({
            eventId :  recordId  
        });
         
     	action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log(result)
                
                const clients = [];
                result.forEach(cer => clients.push({
                    'Id' : cer.lookupId,
                    'Name' : cer.name
                }));
                
                console.log(clients);
                component.set('v.data', result);
                component.set('v.excludedClients', clients);
                
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
    
    //need to retrieve the button Id that was passed in here
	createCERsAura: function (component, event, helper) {
        
        console.log('create before controller')
        
        return new Promise(function (resolve, reject) {
            //need to pass the button Id to createCERsAura in helper
            helper.createCERsAura(component, component.get('v.buttonId')).then(res=> resolve(res)).catch(err => reject(err));
        })
    },
                                                                 
    cancelCER: function (component, event, helper) {
        console.log('CER cancelling controller pre promise');
        return new Promise(function (resolve, reject) {
            helper.updateCER(component, 'Cancelled', component.get('v.buttonId')).then(res=> {console.log('CER cancelling controller post promise'); resolve(res);}).catch(err => reject(err));
        })
    },
    
    deleteCERAura: function (component, event, helper) {
        console.log('parent controller')
        return new Promise(function (resolve, reject) {
            helper.updateCER(component, 'Deleted', component.get('v.buttonId')).then(res=> {console.log('CER cancelling controller post promise'); resolve(res);}).catch(err => reject(err));
        })
    },
                                                                 
    bookCER : function (component, event, helper) {        
        console.log('button Id in parent in bookCER');
        console.log(component.get('v.buttonId'));
        
        return new Promise(function (resolve, reject) {
            helper.updateCER(component, 'Booked', component.get('v.buttonId')).then(res=> resolve(res)).catch(err => reject(err));
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
    
	//this is a component event, to pass a value of button Id from child (table pagination) to parent (ClientEventRelations)
    //this event is only called if we click Save/Save One/Save All when adding CER or ER
    handlePaginationEvent : function (component, event, helper) {
        console.log("handlePaginationEvent");
        
        var valueFromChild = event.getParam("message");
        console.log('valueFromClashChild: ' + valueFromChild);
        component.set('v.buttonId', valueFromChild);
    },   
})