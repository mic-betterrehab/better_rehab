({
    doInit: function (component, event, helper) {
        console.log('Inside doInit in TablePagination');
        helper.setupDataTable(component);
        const data = component.get('v.allData');
        helper.preparePagination(component, data);
        
        var parentRecord = component.get('v.parentRecord');
    },
 
    onNext: function(component, event, helper) {        
        let pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber + 1);
        helper.setPageDataAsPerPagination(component);
    },
     
    onPrev: function(component, event, helper) {        
        let pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber - 1);
        helper.setPageDataAsPerPagination(component);
    },
     
    onFirst: function(component, event, helper) {        
        component.set("v.currentPageNumber", 1);
        helper.setPageDataAsPerPagination(component);
    },
     
    onLast: function(component, event, helper) {        
        component.set("v.currentPageNumber", component.get("v.totalPages"));
        helper.setPageDataAsPerPagination(component);
    },
 
    onPageSizeChange: function(component, event, helper) {        
        helper.preparePagination(component, component.get('v.filteredData'));
    },
 
    onChangeSearchPhrase : function (component, event, helper) {
        if ($A.util.isEmpty(component.get("v.searchPhrase"))) {
            let allData = component.get("v.allData");
            component.set("v.filteredData", allData);
            helper.preparePagination(component, allData);
        }
    },
 
    handleSearch : function (component, event, helper) {
        helper.searchRecordsBySearchPhrase(component);
    },
    
    openModal : function(component, event, helper) {
        component.set("v.isOpenModal", true);
    },
    
    closeModal : function(component, event, helper) {
        component.set("v.isOpenModal", false);
        component.set("v.recurringModal", false);
    },
    
    submitAdditions : function (component, event, helper) {
        
    	const inLookup = component.get('v.contacts');
    	const allData = component.get('v.allData');
        const contactsToAdd = inLookup.filter(l => !allData.map(d=>d.lookupId).includes(l.Id));
       	console.log(inLookup);
        
        const relationIds = [];
        contactsToAdd.forEach(c => relationIds.push(c.Id));
        
        var parent = component.get('v.parent');
        var parentRecord = component.get('v.parentRecord');
        
        parent.set('v.toAdd', relationIds);
        
        const ev = event.getSource();
        const buttonId = ev.getLocalId();
        
        console.log('buttonId in submitAdditions: ' + buttonId);
        
        //fire the event to pass buttonId
        var compEvent = component.getEvent("paginationComponentEvent");
        compEvent.setParams({"message" : buttonId });
        compEvent.fire();
        
        parent.createRelations().then(res => {
           
    		component.set('v.allData', res);
    		helper.preparePagination(component, res);
    		component.set("v.isOpenModal", false);
    		
        }).catch(err => {
            console.log(err);
        });
        
    },
            
    handleEventRecurringRowAction: function(component,event, helper){
        console.log('Inside handleEventRecurringRowAction');
        
        var action = event.getParam('action');
        var row = event.getParam('row');
        
        var parent = component.get('v.parent');
        parent.set('v.selectedRow', row);
        
        console.log('action.name: ' + action.name); //book
        component.set('v.actionRow', action.name);
        
        console.log('v.actionRow: ' + component.get('v.actionRow')); //this is the action of the user - book
        console.log(parent.get('v.selectedRow')); //this is the detail of the CER
        
        
        if(component.get('v.parentRecord').isRecurrence__c){
           component.set('v.recurringModal', true); 
        } else {
            var buttonId = 'saveOne';
            helper.handleRowAction(component, buttonId);
        }
                
    },
    
    handleRecurringSaveAction : function(component, event, helper){
        console.log('Inside handleRecurringSaveAction');
        
        const ev = event.getSource();
        const buttonId = ev.getLocalId(); 
        
        console.log(buttonId);
        
       	helper.handleRowAction(component, buttonId);         
    },
})