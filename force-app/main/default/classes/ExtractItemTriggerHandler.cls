public with sharing class ExtractItemTriggerHandler implements ITrigger
{
    Map<Id,List<enrtcr__Extract_Item__c>> paidEXIForClientMap = new Map<Id,List<enrtcr__Extract_Item__c>>();
    Map<Id,enrtcr__Support_Delivered__c> sdMap = new Map<Id, enrtcr__Support_Delivered__c>();
    Set<Contact> consToUpdate = new Set<Contact>();
    ByPass_Code__c byPass = ByPass_Code__c.getInstance();

    public void bulkBefore()
    {
    }

    public void bulkAfter()
    {
        Set<Id> sdIds = new Set<Id>();
        Set<Id> clientIds = new Set<Id>();

        if(!Trigger.isDelete)
        {
            getServiceDeliveredIds(Trigger.new,sdIds);
        }
        else
        {
            getServiceDeliveredIds(Trigger.old,sdIds);
        }

//        for (SObject so : Trigger.new)
//        {
//            enrtcr__Extract_Item__c exi = (enrtcr__Extract_Item__c ) so;
//            system.debug('client: ' + exi.enrtcr__Service_Delivered__r.enrtcr__Client__c);
//            if (exi.enrtcr__Service_Delivered__c != null)
//            {
//                sdIds.add(exi.enrtcr__Service_Delivered__c);
//            }
//        }

        sdMap = new Map<Id, enrtcr__Support_Delivered__c>([SELECT Id, enrtcr__Client__c FROM enrtcr__Support_Delivered__c WHERE Id IN :sdIds]);
        for(enrtcr__Support_Delivered__c sd : sdMap.values())
        {
            if(sd.enrtcr__Client__c != null)
            {
                clientIds.add(sd.enrtcr__Client__c);
            }
        }

        List<enrtcr__Extract_Item__c> exiList = new List<enrtcr__Extract_Item__c>();
        Id oldClientId = null;
        for (enrtcr__Extract_Item__c exi : [SELECT id, Name, enrtcr__Total_ex_GST__c,enrtcr__Service_Delivered__r.enrtcr__Client__c
                                                FROM enrtcr__Extract_Item__c
                                            WHERE enrtcr__Service_Delivered__r.enrtcr__Support_Contract__r.enrtcr__Funding_Management__c = 'NDIA'
                                                AND (enrtcr__Claim_Status__c = 'Success' OR enrtcr__Claim_Status__c = 'Paid' OR enrtcr__Claim_Status__c='')
                                                AND enrtcr__Service_Delivered__r.enrtcr__Client__c IN :clientIds
                                            ORDER BY enrtcr__Service_Delivered__r.enrtcr__Client__c])
        {
            if(oldClientId != exi.enrtcr__Service_Delivered__r.enrtcr__Client__c)
            {
                if(oldClientId != null)
                {
                    paidEXIForClientMap.put(oldClientId,exiList);
                }
                exiList = new List<enrtcr__Extract_Item__c>();
                exiList.add(exi);
                oldClientId = exi.enrtcr__Service_Delivered__r.enrtcr__Client__c;
            }
            else
            {
                exiList.add(exi);
            }

        }
        if(exiList.size()> 0)
        {
            paidEXIForClientMap.put(oldClientId, exiList);
        }
    }

    public void beforeInsert(SObject so)
    {
    }

    public void beforeUpdate(SObject oldSo, SObject so)
    {
    }

    public void beforeDelete(SObject so)
    {
    }

    public void afterInsert(SObject so)
    {
        enrtcr__Extract_Item__c exi = (enrtcr__Extract_Item__c) so;
        updateClaimedTotal(exi,false);
    }

    public void afterUpdate(SObject oldSo, SObject so)
    {
        enrtcr__Extract_Item__c exi = (enrtcr__Extract_Item__c) so;
        updateClaimedTotal(exi,false);
    }

    public void afterDelete(SObject so)
    {
        enrtcr__Extract_Item__c exi = (enrtcr__Extract_Item__c) so;
        updateClaimedTotal(exi, True);
    }

    public void andFinally()
    {
        if(consToUpdate.size() > 0 && !byPass.ByPass_ExtractItem__c)
        {
            //List<Contact> consToUpdateList = new List<Contact> (consToUpdate);

            Map<Id,Contact> conMap = new Map<Id, Contact>();
            for(Contact con : consToUpdate)
            {
                conMap.put(con.Id,con);
            }
            List<Contact> consToUpdateList = new List<Contact> ();
            consToUpdateList = conMap.values();
            
            UPDATE consToUpdateList;
        }
    }

    private void getServiceDeliveredIds(List<enrtcr__Extract_Item__c> exiList, Set<Id> servDeliveredIds)
    {
        for (enrtcr__Extract_Item__c exi : exiList)
        {
            if (exi.enrtcr__Service_Delivered__c != null)
            {
                servDeliveredIds.add(exi.enrtcr__Service_Delivered__c);
            }
        }
    }

    private void updateClaimedTotal(enrtcr__Extract_Item__c exi, Boolean isDelete)
    {
        Decimal total = 0.0;

        if(sdMap.containsKey(exi.enrtcr__Service_Delivered__c))
        {
            Id clientId = sdMap.get(exi.enrtcr__Service_Delivered__c).enrtcr__Client__c;

            if(paidEXIForClientMap.containsKey(clientId))
            {
                List<enrtcr__Extract_Item__c> clientSDList = paidEXIForClientMap.get(clientId);
                for(enrtcr__Extract_Item__c oldEXIs : clientSDList)
                {
                    if(exi.Id != oldEXIs.Id && oldEXIs.enrtcr__Total_ex_GST__c!= null)
                    {
                        total += oldEXIs.enrtcr__Total_ex_GST__c ;
                    }
                }
            }
            if(!isDelete && (exi.enrtcr__Claim_Status__c =='Paid' || exi.enrtcr__Claim_Status__c=='Success') && exi.enrtcr__Total_ex_GST__c!= null)
            {
                total += exi.enrtcr__Total_ex_GST__c ;
            }

            Contact con = new Contact(Id=clientId,Funding_Management_NDIA_Claimed__c=total);
            consToUpdate.add(con);

        }

    }
}