({
    setupDataTable: function (component) {
        component.set('v.columns', [
            {label: 'Id', fieldName: 'id', type: 'text', sortable: false},
            {label: 'Name', fieldName: 'contactLink',  type: 'url', wrapText: true, typeAttributes : {label : { fieldName : 'name'} , tooltip : 'View this contact'}},
            {label: 'Status', fieldName: 'status',  type: 'text', wrapText: true},
            { type : 'action', typeAttributes : { rowActions : [
                { label : 'Book', name : 'book'},
                { label : 'Cancel', name : 'delete'}
            ], menuAlignment : 'right'}}
        ]);
    },
 
    callAction: function (component) {
        component.set("v.isLoading", true);
        return new Promise(
            $A.getCallback((resolve, reject) => {
                const action = component.get("c.getImageRecords");
                action.setCallback(this, response => {
                    component.set("v.isLoading", false);
                    const state = response.getState();
                    if (state === "SUCCESS") {
                        return resolve(response.getReturnValue());
                    } else if (state === "ERROR") {
                        return reject(response.getError());
                    }
                    return null;
                });
                $A.enqueueAction(action);
            })
        );
    },
 
    preparePagination: function (component, imagesRecords) {
        let countTotalPage = Math.ceil(imagesRecords.length/component.get("v.pageSize"));
        let totalPage = countTotalPage > 0 ? countTotalPage : 1;
        component.set("v.totalPages", totalPage);
        component.set("v.currentPageNumber", 1);
        this.setPageDataAsPerPagination(component);
    },
 
    setPageDataAsPerPagination: function(component) {
        let data = [];
        let pageNumber = component.get("v.currentPageNumber");
        let pageSize = component.get("v.pageSize");
        let filteredData = component.get('v.filteredData');
        let x = (pageNumber - 1) * pageSize;
        for (; x < (pageNumber) * pageSize; x++){
            if (filteredData[x]) {
                data.push(filteredData[x]);
            }
        }
        component.set("v.tableData", data);
    },
 
    searchRecordsBySearchPhrase : function (component) {
        let searchPhrase = component.get("v.searchPhrase");
        if (!$A.util.isEmpty(searchPhrase)) {
            let allData = component.get("v.allData");
            let filteredData = allData.filter(record => record.name.includes(searchPhrase));
            component.set("v.filteredData", filteredData);
            this.preparePagination(component, filteredData);
        }
    },
    
    setLoading : function (component, state) {
        component.set('v.isLoading', state);
    },
    
    handleRowAction: function (component, buttonId) {
        console.log('Inside handleRowAction');
        console.log('v.actionRow: ' + component.get('v.actionRow'));
        var self = this;     
        
        var parent = component.get('v.parent'); 
        var row = parent.get('v.selectedRow');
        console.log('row: ');
        console.log(row);
        
        var rows = component.get('v.allData');
        var rowIndex = rows.indexOf(row);
        var lookupContacts = component.get('v.contacts');
        var contactsIndex = lookupContacts.findIndex(e => e.Id === row.lookupId);
        console.log(rows);
        console.log(lookupContacts);
        
        //fire the event to pass buttonId
        var compEvent = component.getEvent("paginationComponentEvent");
        compEvent.setParams({"message" : buttonId });
        compEvent.fire();
        
        if (component.get('v.actionRow') === 'delete') {
			
            // Can't delete/cancel an already cancelled Relation
            if (row.status === 'Cancelled') return;
            
            const eventRecord = parent.get('v.eventRecord')
            
            if ((eventRecord.Event_Type__c === 'Initial Appointment' || eventRecord.Event_Type__c === 'Therapy Session') && row.status === 'Booked') {
                // CANCEL Relation
                console.log('cancelling')
                parent.cancelRelation().then((res) => {
                    console.log('Hello inside cancelRelation now');
                    row.status = 'Cancelled';
                    rows[rowIndex] = row;
                    component.set('v.recurringModal', false);
                    component.set('v.allData', rows);
                    self.preparePagination(component, rows);
                }).catch(err => {
                    console.log(err);
                    return;
                });   
            } else {
                // DELETE Relation
                parent.deleteRelation().then(res => {
                    console.log('Hello inside deleteRelation now');
                    component.set('v.recurringModal', false);
                    rows.splice(rowIndex, 1);
                    lookupContacts.splice(contactsIndex, 1);
                    component.set('v.allData', rows);
                    component.set('v.contacts', lookupContacts);
                    self.preparePagination(component, rows);
                }).catch(err => {
                    console.log(err);
                    return;
                });
                }
        } else if (component.get('v.actionRow') === 'book') {
            if (row.status === 'Booked') return;
            //BOOK Relation    
            parent.bookRelation().then(res => {
                console.log('Hello inside bookRelation now');
                row.status = 'Booked';
                rows[rowIndex] = row;
                component.set('v.recurringModal', false);
                component.set('v.allData', rows);
                self.preparePagination(component, rows);
            }).catch(err => {
                console.log(err);
                return;
            })
        }
        
    	parent.set('v.toDelete', {});
    }
        
})