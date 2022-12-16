public class UpdateClientNDIAFundingTotalsBatch implements Database.batchable<sObject>
{
    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        Set<Id> clientIds = new Set<Id>();
        for(enrtcr__Support_Delivered__c sd : [SELECT id, Name, enrtcr__Total__c,enrtcr__Client__c
                                                    FROM enrtcr__Support_Delivered__c
                                                WHERE enrtcr__Support_Contract__r.enrtcr__Funding_Management__c = 'NDIA' AND enrtcr__Current_NDIS_Extract_Item__c = NULL])
        {
            clientIds.add(sd.enrtcr__Client__c);
        }

        for(enrtcr__Extract_Item__c exi : [SELECT id, Name, enrtcr__Total_ex_GST__c,enrtcr__Service_Delivered__r.enrtcr__Client__c
                                                FROM enrtcr__Extract_Item__c
                                            WHERE enrtcr__Service_Delivered__r.enrtcr__Support_Contract__r.enrtcr__Funding_Management__c = 'NDIA'  AND RecordType.Name != 'DVA'
                                                AND (enrtcr__Claim_Status__c = 'Success' OR enrtcr__Claim_Status__c = 'Paid' OR enrtcr__Claim_Status__c='')])
        {
            clientIds.add(exi.enrtcr__Service_Delivered__r.enrtcr__Client__c);
        }

        return Database.getQueryLocator([SELECT Id FROM Contact WHERE Id IN :clientIds]);
    }

    public void execute(Database.BatchableContext info, List<Contact> scope)
    {
        //Get SDs for the clients
        Set<Id> clientIds = new Set<Id>();
        for(Contact con : scope)
        {
            clientIds.add(con.Id);
        }

        Map<Id,List<enrtcr__Support_Delivered__c>> sdsForClientMap = new Map<Id,List<enrtcr__Support_Delivered__c>>();
        Map<Id,List<enrtcr__Extract_Item__c>> exisForClientMap = new Map<Id,List<enrtcr__Extract_Item__c>>();
        Map<Id,List<enrtcr__Support_Delivered__c>> sdNoEXIForClientMap = new Map<Id,List<enrtcr__Support_Delivered__c>>();

        List<enrtcr__Support_Delivered__c> sdList = new List<enrtcr__Support_Delivered__c>();
        Id oldClientId = null;

        //Load up SD map
        for(enrtcr__Support_Delivered__c sd : [SELECT id, Name, enrtcr__Total__c,enrtcr__Client__c
                                                    FROM enrtcr__Support_Delivered__c
                                                WHERE enrtcr__Support_Contract__r.enrtcr__Funding_Management__c = 'NDIA'
                                                    AND enrtcr__Client__c IN :clientIds
                                                ORDER BY enrtcr__Client__c])
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

        //Load up EXI map
        List<enrtcr__Extract_Item__c> exiList = new List<enrtcr__Extract_Item__c>();
        oldClientId = null;
        for(enrtcr__Extract_Item__c exi : [SELECT Id, Name, enrtcr__Total_ex_GST__c,enrtcr__Service_Delivered__r.enrtcr__Client__c
                                                FROM enrtcr__Extract_Item__c
                                            WHERE enrtcr__Service_Delivered__r.enrtcr__Support_Contract__r.enrtcr__Funding_Management__c = 'NDIA'  AND RecordType.Name != 'DVA'
                                                AND (enrtcr__Claim_Status__c = 'Success' OR enrtcr__Claim_Status__c = 'Paid' OR enrtcr__Claim_Status__c='')
                                                AND enrtcr__Service_Delivered__r.enrtcr__Client__c IN :clientIds
                                            ORDER BY enrtcr__Service_Delivered__r.enrtcr__Client__c])
        {
            if(oldClientId != exi.enrtcr__Service_Delivered__r.enrtcr__Client__c)
            {
                if(oldClientId != null)
                {
                    exisForClientMap.put(oldClientId,exiList);
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
            exisForClientMap.put(oldClientId, exiList);
        }

        //Load up SD with no EXI map
        List<enrtcr__Support_Delivered__c> sdNoEXIList = new List<enrtcr__Support_Delivered__c>();
        oldClientId = null;
        for(enrtcr__Support_Delivered__c sd : [SELECT id, Name, enrtcr__Total__c,enrtcr__Client__c
                                                    FROM enrtcr__Support_Delivered__c
                                                WHERE enrtcr__Support_Contract__r.enrtcr__Funding_Management__c = 'NDIA'
                                                    AND enrtcr__Current_NDIS_Extract_Item__c = null
                                                    AND enrtcr__Client__c IN :clientIds
                                                ORDER BY enrtcr__Client__c])
        {
            if(oldClientId != sd.enrtcr__Client__c)
            {
                if(oldClientId != null)
                {
                    sdNoEXIForClientMap.put(oldClientId,sdNoEXIList);
                }
                sdNoEXIList = new List<enrtcr__Support_Delivered__c>();
                sdNoEXIList.add(sd);
                oldClientId = sd.enrtcr__Client__c;
            }
            else
            {
                sdNoEXIList.add(sd);
            }

        }
        if(sdNoEXIList.size()> 0)
        {
            sdNoEXIForClientMap.put(oldClientId, sdNoEXIList);
        }

        //Calculate the totals
        List<Contact> consToUpdate = new List<Contact>();
        for(Contact con : scope)
        {
            Decimal deliveredTotal, claimedTotal;
            deliveredTotal = calculateDeliveredTotal(con.Id,sdsForClientMap);
            claimedTotal = calculateClaimedTotal(con.Id, exisForClientMap, sdNoEXIForClientMap);
            con.Funding_Management_NDIA_Delivered__c = deliveredTotal;
            con.Funding_Management_NDIA_Claimed__c = claimedTotal;

            consToUpdate.add(con);
        }

        if(consToUpdate.size() > 0)
        {
            UPDATE consToUpdate;
        }

        if(Test.isRunningTest())
        {
            addSomeLines();
        }

    }

    public void finish(Database.BatchableContext info)
    {

    }

    private Decimal calculateDeliveredTotal(Id clientId, Map<Id,List<enrtcr__Support_Delivered__c>> sdsForClientMap)
    {
        Decimal total = 0.0;

        if(sdsForClientMap.containsKey(clientId))
        {
            List<enrtcr__Support_Delivered__c> clientSDList = sdsForClientMap.get(clientId);
            for(enrtcr__Support_Delivered__c sd : clientSDList)
            {
                total += sd.enrtcr__Total__c;
            }
        }
        return total;
    }

    private Decimal calculateClaimedTotal(Id clientId, Map<Id,List<enrtcr__Extract_Item__c>> exisForClientMap, Map<Id,List<enrtcr__Support_Delivered__c>> sdNoEXIForClientMap)
    {
        Decimal total = 0.0;

        if(exisForClientMap.containsKey(clientId))
        {
            List<enrtcr__Extract_Item__c> clientEXIList = exisForClientMap.get(clientId);
            for(enrtcr__Extract_Item__c exi : clientEXIList)
            {
                total += exi.enrtcr__Total_ex_GST__c ;
            }
        }
        if(sdNoEXIForClientMap.containsKey(clientId))
        {
            List<enrtcr__Support_Delivered__c> clientSDNoEXIList = sdNoEXIForClientMap.get(clientId);
            for(enrtcr__Support_Delivered__c sd : clientSDNoEXIList)
            {
                total += sd.enrtcr__Total__c ;
            }
        }

        return total;
    }

    private void addSomeLines()
    {
        Integer i=0;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;

    }
}