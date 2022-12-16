({
    onblur : function(component,event,helper){
        // on mouse leave clear the listOfSeachRecords & hide the search result component
        component.set("v.listOfSearchRecords", null );
        component.set("v.SearchKeyWord", '');
        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
    },
    onfocus : function(component,event,helper){
        // show the spinner,show child search result component and call helper function
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        component.set("v.listOfSearchRecords", null );
        var forOpen = component.find("searchRes");
        $A.util.addClass(forOpen, 'slds-is-open');
        $A.util.removeClass(forOpen, 'slds-is-close');
        // Get Default 5 Records order by createdDate DESC
        var getInputkeyWord = '';
        helper.searchHelper(component,event,getInputkeyWord);
    },

    keyPressController : function(component, event, helper) {
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        // get the search Input keyword
        var getInputkeyWord = component.get("v.SearchKeyWord");
        console.log(getInputkeyWord)
        // check if getInputKeyWord size id more then 0 then open the lookup result List and
        // call the helper
        // else close the lookup result List part.
        if(getInputkeyWord.length > 0){
            console.log('1')
            var forOpen = component.find("searchRes");
            $A.util.addClass(forOpen, 'slds-is-open');
            $A.util.removeClass(forOpen, 'slds-is-close');
            helper.searchHelper(component,event,getInputkeyWord);
        }
        else{
            console.log('2')
            component.set("v.listOfSearchRecords", null );
            var forclose = component.find("searchRes");
            $A.util.addClass(forclose, 'slds-is-close');
            $A.util.removeClass(forclose, 'slds-is-open');
        }
    },

    // function for clear the Record Selection
    clear :function(component,event,heplper){
        const allowClear = component.get('v.allowClear');
        var selectedPillId = event.getSource().get("v.name");

        var parentComponent = component.get('v.parent');
        // Pass searched clinicians from selected list
        if (component.get('v.isFromMCC')) {
            parentComponent.multiLookupFilter({}, selectedPillId);
        } else {
            if (component.get('v.label') == 'Workers') {
                parentComponent.setContactsHolder([], selectedPillId, true);
            } else {
                parentComponent.setContactsHolder([], selectedPillId, false);
            }
        }

        if (!allowClear) {
            var parent = component.get('v.parent');

            if (!parent) return;

            const rentData = parent.get('v.allData');
            const found = rentData.find(e => e.lookupId === selectedPillId);

            if (found) return;
        }

        var AllPillsList = component.get("v.lstSelectedRecords");

        for(var i = 0; i < AllPillsList.length; i++){
            if(AllPillsList[i].Id == selectedPillId){
                AllPillsList.splice(i, 1);
                component.set("v.lstSelectedRecords", AllPillsList);
            }
        }

        component.set("v.SearchKeyWord",null);
        component.set("v.listOfSearchRecords", null );
    },
    clearFilter: function(component, event, helper) {
        component.set("v.lstSelectedRecords", []);
    },
    // This function call when the end User Select any record from the result list.
    handleComponentEvent : function(component, event, helper) {
        component.set("v.SearchKeyWord",null);
        // get the selected object record from the COMPONENT event
        var listSelectedItems =  component.get("v.lstSelectedRecords");
        var selectedAccountGetFromEvent = event.getParam("recordByEvent");
        listSelectedItems.push(selectedAccountGetFromEvent);
        component.set("v.lstSelectedRecords" , listSelectedItems);

        var forclose = component.find("lookup-pill");
        $A.util.addClass(forclose, 'slds-show');
        $A.util.removeClass(forclose, 'slds-hide');

        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');

        var parentComponent = component.get('v.parent');
        // Pass searched clinicians from selected list
        if (component.get('v.isFromMCC')) {
            parentComponent.multiLookupFilter(component.get("v.lstSelectedRecords"), '');
        } else {
            if (component.get('v.label') == 'Workers') {
                parentComponent.setContactsHolder(component.get("v.lstSelectedRecords"), '', true);
            } else {
                parentComponent.setContactsHolder(component.get("v.lstSelectedRecords"), '', false);
            }
        }
    },

    handleRefresh : function(component, event, helper) {
        console.log('refreshing')
        var listSelectedItems =  component.get("v.lstSelectedRecords");
        component.set("v.lstSelectedRecords" , listSelectedItems);
        var forclose = component.find("lookup-pill");
        $A.util.addClass(forclose, 'slds-show');
        $A.util.removeClass(forclose, 'slds-hide');

        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
    },
})