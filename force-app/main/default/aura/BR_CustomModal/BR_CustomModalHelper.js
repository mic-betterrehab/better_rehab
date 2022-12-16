({
	generateModalContent : function(component) {
        var self = this;
        
        //set the title
        this.setTitle;
        
        //set the body
        if(component.get('v.recurrence')){
            component.set('v.body', 'This event is part of a series. Would you like to book this one occurrence or this and the following occurrences in the series?');
        } else {
            component.set('v.body', 'Are you sure you want to book in this event?');
        }
        
        //set the footer
        let buttonList = component.get('v.buttonOptions');
         
        if(component.get('v.recurrence')){
            let one = {label: 'Book One', variant: 'neutral', class: "success-text", value: 'Book One'};
            buttonList.push(one);
            
            let all = {label: 'Book All', variant: 'success', value: 'Book All'};
            buttonList.push(all);
        } else {
            let one = {label: 'Book', variant: 'success', value: 'Book One'};
            buttonList.push(one); 
        }
        
        component.set('v.buttonOptions', buttonList);
	},
    
    setTitle : function(component){
        let title = '';
        
        switch(component.get('v.modalType')){
            case 'Book':
                title = 'Book Event(s)?';
                break;
            case 'Delete':
                title = 'Are you sure you want to cancel?';
                break;
            default:
                title = 'No title here';
        }
        
        component.set('v.title', title);
    },
    
    setBody : function(component){
        let modalType = component.get('v.modalType');
        let recurring = component.get('v.recurrence');
        let body = '';
        
        switch(true){
            case (modalType === 'Book' && recurring === true):
                body = 'This event is part of a series. Would you like to book this one occurrence or this and the following occurrences in the series?';
                break;
            case (modalType === 'Book' && recurring === false):
                body = 'Are you sure you want to book in this event?';
                break;
            /*case (modalType === 'Delete' && recurring === true):
                body = '?????????';
                break;
                //if event type is pch, create the additional reasons
                //if event type is not pch, body = 'xxx'*/
            default:
                body = 'No body here';
        }
        
        //for delete, we got if delete recurrence (pch), delete non recurrence (pch), delete recurrence (non pch), delete non recurrence (non pch)
        
        component.set('v.body', body);

    },
    
    setFooter : function(component){
        
    },
})