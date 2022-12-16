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
    
    //need to use button Id in this helper and createCERs method
    createCERsAura : function (component, buttonId) {
        
        console.log('create before helper')
        return new Promise(function (resolve, reject) {
        	const event = component.get('v.eventRecord');
            console.log(event);
            const action = component.get('c.createCERs');
            
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
    
    updateCER : function (component, status, buttonId) {
        console.log('CER helper pre promise');
		return new Promise(function (resolve, reject) {
            const record = component.get('v.selectedRow');
                    
            const action = component.get('c.handleCERchange');

            action.setParams({
                action : 'update',
                CERid : record.id,
                newStatus : status,
                saveType : buttonId
            });
            
            action.setCallback(this, function(res)  {
                var state = res.getState();
				console.log('CER helper setCallback');
                if (state === 'SUCCESS') {
                    resolve(state);
                } else {
                    reject(state);
                }
            });
            
            $A.enqueueAction(action);
        })
    },
    
    setLoading : function (component, state) {
        component.set('v.isLoading', state);
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
    }
})