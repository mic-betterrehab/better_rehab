({
	getEvent : function(component) {
        return new Promise(function (resolve, reject) {
            const id = component.get('v.recordId');
        
        	var action = component.get('c.getEvent');
            
            action.setParams({
                eventId : id
            });
             
            action.setCallback(this, function(response) {
                var state = response.getState();
                
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    resolve(result)
                } else {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                    reject();
                }
            });
            $A.enqueueAction(action);
        })
	},
    
    createERsAura : function (component, buttonId) {
        console.log('create before helper')
        return new Promise(function (resolve, reject) {
        	const event = component.get('v.eventRecord');
            console.log(event);
            const action = component.get('c.createERs');
            
            action.setParams({
                ids : component.get('v.toAdd'),
                eventId : event.Id,
                action : buttonId
            });
            
            action.setCallback(this, function(res) {
                var state = res.getState();
                console.log(state)
                if (state === 'SUCCESS') {
                    console.log(res)
                	resolve(res.getReturnValue());
            	} else {
              		reject();
        		}
            })
            $A.enqueueAction(action);
        })
    },
    
    updateER : function (component, status, buttonId) {
		return new Promise(function (resolve, reject) {
            const record = component.get('v.selectedRow');
                    
            const action = component.get('c.handleERchange');

            action.setParams({
                action : 'update',
                ERid : record.id,
                newStatus : status,
                saveType : buttonId
            });
            
            action.setCallback(this, function(res)  {
                var state = res.getState();

                if (state === 'SUCCESS') {
                    resolve(state);
                } else {
                    reject(state);
                }
            });
            
            $A.enqueueAction(action);
        })
    },
    
    updateEventAura : function (component, status) {
        return new Promise(function (resolve, reject) {
            const action = component.get('c.updateEvent');
                
            action.setParams({
                eventId : component.get('v.recordId'),
                status : status
            });
            
            action.setCallback(this, function(res)  {
                var state = res.getState();
                console.log(state);
                if (state === 'SUCCESS') {
                    resolve(state);
                } else {
                    reject(state);
                }
            });
            
            $A.enqueueAction(action);
        })
    },
})