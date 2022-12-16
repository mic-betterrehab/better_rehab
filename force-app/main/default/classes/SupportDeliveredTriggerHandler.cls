public with sharing class SupportDeliveredTriggerHandler implements ITrigger
{
    Map<Id,List<enrtcr__Support_Delivered__c>> sdsForClientMap = new Map<Id,List<enrtcr__Support_Delivered__c>>();
    Set<Contact> consToUpdate = new Set<Contact>();
    ByPass_Code__c byPass = ByPass_Code__c.getInstance();

    public void bulkBefore()
    {
    }

    public void bulkAfter()
    {
        Set<Id> clientIds = new Set<Id>();
        if(!Trigger.isDelete)
        {
            getClientIds(Trigger.new,clientIds);
        }
        else
        {
            getClientIds(Trigger.old,clientIds);
        }

        List<enrtcr__Support_Delivered__c> sdList = new List<enrtcr__Support_Delivered__c>();
        Id oldClientId = null;
        for (enrtcr__Support_Delivered__c sd : [SELECT id, Name, enrtcr__Total__c,enrtcr__Client__c
                                                    FROM enrtcr__Support_Delivered__c
                                                WHERE enrtcr__Support_Contract__r.enrtcr__Funding_Management__c = 'NDIA'
                                                    AND enrtcr__Client__c IN :clientIds ORDER BY enrtcr__Client__c])
        {
            if(oldClientId != sd.enrtcr__Client__c)
            {
                if(oldClientId != null)
                {
                    sdsForClientMap.put(oldClientId,sdList);
                }
                sdList = new List<enrtcr__Support_Delivered__c>();
                sdList.add(sd);
                oldClientId = sd.enrtcr__Client__c;
            }
            else
            {
                sdList.add(sd);
            }

        }
        if(sdList.size()> 0)
        {
            sdsForClientMap.put(oldClientId, sdList);
        }
    }

    public void beforeInsert(SObject so)
    {
        enrtcr__Support_Delivered__c sd = (enrtcr__Support_Delivered__c) so;

        if(sd.enrtcr__Worker__c == null && !byPass.ByPass_SupportDelivered__c)
        {
            sd.enrtcr__Worker__c = UserInfo.getUserId();
        }
    }

    public void beforeUpdate(SObject oldSo, SObject so)
    {
    }

    public void beforeDelete(SObject so)
    {
    }

    public void afterInsert(SObject so)
    {
        enrtcr__Support_Delivered__c sd = (enrtcr__Support_Delivered__c) so;
        updateDeliveredTotal(sd,false);
    }

    public void afterUpdate(SObject oldSo, SObject so)
    {
        enrtcr__Support_Delivered__c sd = (enrtcr__Support_Delivered__c) so;
        updateDeliveredTotal(sd,false);
    }

    public void afterDelete(SObject so)
    {
        enrtcr__Support_Delivered__c sd = (enrtcr__Support_Delivered__c) so;
        updateDeliveredTotal(sd, True);
    }

    public void andFinally()
    {
        system.debug('consToUpdate: ' + consToUpdate);
        if(consToUpdate.size() > 0 && !byPass.ByPass_SupportDelivered__c)
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

    private void getClientIds(List<enrtcr__Support_Delivered__c> sdList, Set<Id> clientIds)
    {
        for (enrtcr__Support_Delivered__c sd : sdList)
        {
            if (sd.enrtcr__Client__c != null)
            {
                clientIds.add(sd.enrtcr__Client__c);
            }
        }
    }

    private void updateDeliveredTotal(enrtcr__Support_Delivered__c sd, Boolean isDelete)
    {
        Decimal total = 0.0;

        if(sdsForClientMap.containsKey(sd.enrtcr__Client__c))
        {
            List<enrtcr__Support_Delivered__c> clientSDList = sdsForClientMap.get(sd.enrtcr__Client__c);
            for(enrtcr__Support_Delivered__c oldSDs : clientSDList)
            {
                if(sd.Id != oldSDs.Id)
                {
                    total += oldSDs.enrtcr__Total__c;
                }
            }
        }
        if(!isDelete)
        {
            total += sd.enrtcr__Total__c;
        }

        Contact con = new Contact(Id=sd.enrtcr__Client__c,Funding_Management_NDIA_Delivered__c=total);
        consToUpdate.add(con);
    }
}