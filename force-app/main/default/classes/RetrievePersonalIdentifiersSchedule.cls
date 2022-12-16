/**
 * Created by Enrite Solutions on 22/08/2019.
 */

global with sharing class RetrievePersonalIdentifiersSchedule implements Schedulable {
    global void execute(SchedulableContext ctx){
        RetrievePersonalIdentifiersBatch b = new RetrievePersonalIdentifiersBatch();
        Database.executeBatch(b);
    }
}