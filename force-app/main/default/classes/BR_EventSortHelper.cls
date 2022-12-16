global class BR_EventSortHelper implements Comparable {
    
    public Event e;
    
    public BR_EventSortHelper(Event ev){
        e = ev;
    }
    
    //this is to sort based on end date and DESCENDING (latest event at the start)
    global Integer compareTo(Object compareTo){
        // Cast argument to BR_EventSortHelper
        BR_EventSortHelper compareToEvent = (BR_EventSortHelper)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        
        System.debug('In BR_EventSortHelper, currently processing this event: ' + e.Id);
        
        if(e.EndDateTime < compareToEvent.e.EndDateTime){
            returnValue = 1;
        } else if (e.EndDateTime > compareToEvent.e.EndDateTime){
            returnValue = -1;
        } else if ((e.EndDateTime == null) && (compareToEvent.e.EndDateTime != null)){
            // nulls-first implementation
            returnValue = -1;
        } else if ((e.EndDateTime != null) && (compareToEvent.e.EndDateTime == null)){
            // nulls-first implementation
            returnValue = 1;
        }
        
        return returnValue;
    }

}