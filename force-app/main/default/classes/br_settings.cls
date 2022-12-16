public with sharing class br_settings {
    
    public Setting__c settings {get; set;}
    public Map<String, Object> mappedSettings {get;set;}
    public Map<String,Object> newKeyValues {get;set;}
    public String newKeyName {get;set;}
    
    public br_settings(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()) stdController.addFields(new List<String>{'Name', 'Settings__c'});
        this.settings = (Setting__c)stdController.getRecord();
        this.mappedSettings = JSONtoMap(settings.Settings__c);
        
        initialiseNewValues();
        
    }
    
    private void initialiseNewValues() {
        this.newKeyValues = new Map<String, Object>();
    }
    
    private Map<String, Object> JSONtoMap(String jsonString) {
        return (Map<String, Object>) JSON.deserializeUntyped(jsonString);
    }
    
    private String maptoJSON(Map<String, Object> myMap) {
        return JSON.serialize(myMap);
    }
    
    public void addKeyToMap() {
        newKeyValues.put(newKeyName, 'newValue');
    }
    
    public PageReference submit() {
       	
        mappedSettings.putAll(newKeyValues);
        settings.Settings__c = mapToJSON(mappedSettings);
        
        try {
            update settings;
           
            PageReference refresh = new PageReference('/' + settings.Id );
            refresh.setRedirect(true);
            return refresh;
        } catch (DmlException e) {
            
            PageReference doNothing = new PageReference('/BR_Settings');
            return doNothing;
        }
    }
    
    
}