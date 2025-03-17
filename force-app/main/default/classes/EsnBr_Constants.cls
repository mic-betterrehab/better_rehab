/**
 * Copyright (c) 2023, Enrite Solutions Australia Pty Ltd
 *
 * All rights reserved. Reproduction, copying, redistribution and use in source and binary forms is strictly prohibited
 * without the express written consent of Enrite Solutions Australia Pty Ltd and is subject to our Master Service
 * Agreement, or other contract terms and conditions, as applicable.
 *
 * Limitation of Liability
 *
 * THIS SOFTWARE IS PROVIDED BY ENRITE SOLUTIONS AUSTRALIA PTY LTD ON AND SUBJECT TO THE PROVISIONS OF ITS MASTER
 * SERVICES AGREEMENT, OR OTHER CONTRACT TERMS AND CONDITIONS, AS APPLICABLE ("TERMS AND CONDITIONS"). UNLESS OTHERWISE
 * PROVIDED BY THE TERMS AND CONDITIONS, THE SOFTWARE IS PROVIDED STRICTLY ON THE CONDITION THAT IT IS ACCEPTED BY THE
 * RECEIVER OF THE SOFTWARE ON ITS OWN ASSESSMENT, EVALUATION AND TESTING OF THE SOFTWARE AND, EXCEPT AS MAY BE
 * MANDATED BY ANY APPLICABLE LAW, ALL WARRANTIES, GUARANTEES OR REPRESENTATIONS IN RELATION TO THE SOFTWARE, INCLUDING
 * FITNESS FOR PURPOSE OR MERCHANTABILITY, ARE EXPRESSLY EXCLUDED AND ALL LIABILITY OF ENRITE SOLUTIONS AUSTRALIA PTY
 * LTD FOR ANY LOSS OR DAMAGE, INCLUDING ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY OR CONSEQUENTIAL LOSSES
 * SUCH AS BUSINESS INTERRUPTION OR LOSS OF PROFIT OR LOSS OF DATA IS EXCLUDED, OR TO THE EXTENT THAT LIABILITY MAY NOT
 * BE EXCLUDED, IS LIMITED TO THE RE-SUPPLY OF THE SOFTWARE.
**/
public with sharing class EsnBr_Constants
{
    public static final String SELECTOR_FORMAT_CONDITION_FIELD_EQUALS_VALUE = '{0} = \'\'{1}\'\'';
    public static final String SELECTOR_FORMAT_CONDITION_FIELD_LESS_THAN_VALUE = '{0} < {1}';
    public static final String SELECTOR_FORMAT_CONDITION_FIELD_LESS_THAN_EQ_VALUE = '{0} <= {1}';
    public static final String SELECTOR_FORMAT_CONDITION_FIELD_GREATER_THAN_VALUE = '{0} > {1}';
    public static final String SELECTOR_FORMAT_CONDITION_FIELD_EQUALS = '{0} = {1}';
    public static final String SELECTOR_FORMAT_CONDITION_FIELD_NOT_EQUALS_STRING = '{0} != \'\'{1}\'\'';
    public static final String SELECTOR_FORMAT_CONDITION_FIELD_NOT_EQUALS = '{0} != {1}';
    public static final String SELECTOR_FORMAT_CONDITION_FIELD_LIKE_VALUE = '{0} LIKE \'\'{1}%\'\'';
    public static final String SELECTOR_FORMAT_CONDITION_FIELD_IN = '{0} IN {1}';
    public static final String SELECTOR_FORMAT_CONDITION_FIELD_NOT_IN = '{0}  NOT IN {1}';
    public static final String SELECTOR_FORMAT_CONDITION_FIELD_DISTANCE = 'DISTANCE({0}, {1}, {2})';
    public static final String SELECTOR_FORMAT_CONDITION_FIELD_GEOLOCATION = 'GEOLOCATION({0}, {1})';
    public static final String SELECTOR_FORMAT_CONDITION_FIELD_UNIT_KM = '\'km\'';
    public static final String SELECTOR_AND_CONDITION = ' AND ';
    public static final String SELECTOR_OR_CONDITION = ' OR ';

    public static final String AMPERSAND = '&';
    public static final String FORWARD_SLASH = '/';
    public static final String QUESTION_MARK = '?';
    public static final String SEMI_COLON = ';';
    public static final String PERIOD = '.';
    public static final String LEFT_BRACKET = '(';
    public static final String RIGHT_BRACKET = ')';
    public static final String COMMA_IN_QUOTES = '\',\'';
    public static final String COMMA = ',';
    public static final String EMPTY_STRING = '';
    public static final String EMPTY_STRING_FORMAT = '\'\'';
    public static final String LIST_SOQL_FORMAT = '(\'\'{0}\'\')';
    public static final String BRACKET_FORMAT = '({0})';
    public static final String NEW_LINE = '\n';
    public static final String COLON = ':';
    public static final String DASH = '-';
    public static final String PERCENT = '%';
    public static final String SPACE = ' ';
    public static final String YES = 'Yes';
    public static final String UNCHANGED = 'Unchanged';
    public static final String ENCODING_UTF8 = 'UTF-8';
    public static final String EQUALS = '=';
    public static final String PARAM_CODE = 'code';
    public static final String PARAM_AUTHORIZATION = 'Authorization';
    public static final String PARAM_BASIC = 'Basic '; // space is intentional
    public static final String PARAM_BEARER = 'Bearer '; // space is intentional
    public static final String PARAM_CONTENT_TYPE_JSON = 'application/json';
    public static final String PARAM_CONTENT_TYPE = 'Content-Type';
    public static final String PARAM_ACCEPT = 'Accept';
    public static final String PARAM_CONTENT_TYPE_FORM_DATA = 'application/x-www-form-urlencoded';
    public static final String PARAM_AUTHORIZATION_CODE = 'authorization_code';
    public static final String PARAM_GRANT_TYPE = 'grant_type';
    public static final String PARAM_REDIRECT_URI = 'redirect_uri';
    public static final Integer STATUS_CODE_GOOD_REQUEST = 200;
    public static final String HTTP_METHOD_GET = 'GET';
    public static final String XERO_NOT_AUTHORISED = 'Salesforce has not been authorised to access Xero. Contact your System Administrator for help';
    public static final String HEADER_XERO_TENANT_ID = 'Xero-tenant-id';
    public static final Integer READ_TIME_OUT = 120000;
    public static final String PARAM_REFRESH_TOKEN = 'refresh_token';
    public static final Integer OK_STATUS_CODE = 200;
    public static final String OK_STATUS = 'OK';
    public static final Integer XERO_ID_LIMIT = 42; // xero has a 1600 WHERE query character limit, so we just fit as many as we can into it so we can get about 42 Ids in
    public static final String STRING_TOO_LARGE = 'The received response is too large. Please see attached response.txt file for the JSON response.';
    public static final String XERO_INVOICE_STATUS_AUTHORISED = 'AUTHORISED';
    public static final String XERO_INVOICE_PARAM_PAGE = 'page';
    public static final String XERO_INVOICE_PARAM_STATUS = 'Statuses';
    public static final String XERO_INVOICE_PARAM_SUMMARISE = 'SummarizeErrors';
    public static final String XERO_INVOICE_PARAM_CONTACT_IDS = 'ContactIDs';
    public static final String RESPONSE_FILE_NAME = 'response.txt';
    public static final String REQUEST_FILE_NAME = 'request.txt';
    public static final String RESPONSE_FILE_TYPE = 'text/plain';
    public static final Integer XERO_RETRIEVE_INVOICE_CALCULATIONS_DELAY = 1; //todo metadata
    public static final String LOG_TYPE_ERROR = 'Error';
    public static final String LOG_TYPE_INFO = 'Info';
    public static final String LOG_SOURCE_XERO = 'Xero';
    public static final String LOG_ERROR_CONTACT_FAILED_FORMAT = 'Contact Id: {0} failed to update with the following error(s): {1}';
    public static final String DATABASE_ERROR_FORMAT = 'Status Code: "{0}", Error: "{1}"';
    public static final String XERO_INVOICE_TYPE_ACCREC = 'ACCREC';
    public static final String REGEX_DATE_FORMAT_STRING = 'YYYY-MM-dd';
    public static final String INVOICE_LINE_ITEM_TYPE = 'EXEMPTOUTPUT';
    public static final String INVOICE_LINE_ITEM_TYPE_TAX = 'OUTPUT';
    public static final String INVOICE_DESCRIPTION_FORMAT = '{0} - {1} - {2} - {3}';
    public static final String XERO_DEFAULT_ACCOUNT_CODE = '200';
    public static final String XERO_DEFAULT_ITEM_CODE = '200';
    public static final String XERO_SEND_INVOICE_ERROR = 'There was an error posting to Xero. Please check the related Log record.';
    public static final String XERO_SEND_INVOICES_BATCH_ALREADY_RUNNING_ERROR = 'The Send Invoices Batch job is already running. Please wait a few minutes before trying to resend invoices.';
    public static final String XERO_DATE_STRING_TIME = 'T00:00:00';
    public static final String XERO_TYPE_CONTACTS = 'Contacts';
    public static final String XERO_PHONE_TYPE_MOBILE = 'MOBILE';
    public static final String XERO_ADDRESS_TYPE_OTHER = 'POBOX';
    public static final String XERO_ADDRESS_TYPE_MAILING = 'STREET';

    public static final String GREATER_THAN_OR_EQUAL_TO = '<=';
    public static final String GREATER_THAN = '<';

    public static final String DATE_FORMAT_GMT = 'EEE, dd MMM yyyy HH:mm:ss Z';
    public static final String DATETIME_FORMAT_SOQL = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
    public static final String DATE_FORMAT_JSON = 'yyyy-MM-dd';
    public static final String CRON_EXPRESSION_MIDNIGHT = '0 59 23 * * ? *';
    public static final String XERO_DATE_REGEX = '[0-9]{4}\\-[0-9]{2}\\-[0-9]{2}';

    public static final Integer NAME_SIZE = 80;
    public static final Integer DEFAULT_MATCH_CONFIDENCE = 100;
    public static final Integer MAX_DUPLICATE_RECORDS = 50;
    public static final Integer BATCH_SIZE_1 = 1;
    public static final Integer VALID_NUMBER_FIELD_0 = 0;
    public static final Integer VALID_NUMBER_FIELD_1 = 1;
    public static final Integer VALID_NUMBER_FIELD_MINUS_1 = -1;
    public static final Integer VALID_NUMBER_FIELD_2 = 2;
    public static final Boolean BOOLEAN_TRUE = true;
    public static final Boolean BOOLEAN_FALSE = false;
    public static final String LAST_N_DAYS = 'LAST_N_DAYS:';
    public static final String APPLICATION_SETTING = 'Application_Setting';
    public static final String MASTER_RECORD_TYPE = 'Master';
    public static final String PARAM_FORMAT = '{0}={1}';
    public static final String DATE_AUS_FORMAT = 'dd/MM/yyyy';

    public static final String ERROR_BASE_CLASS_METHOD_MUST_BE_OVERRIDDEN = 'Error. Base class method must be overridden in extending domain class';
    public static final String EXTERNAL_ID_API_NAME = 'ESN_BR_External_Id__c';
    public static final Date CURRENT_FISCAL_QUARTER_END_DATE = [SELECT EndDate FROM Period WHERE Type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER].EndDate;
    public static final String EMAIL_TEMPLATE_LEAD_NOT_CONTACTED = 'ESN_ET_BR_Lead_Not_Contacted';
    public static final String INVOCABLE_PARAMETERS_ERROR = 'Please provide valid parameters';

    public static final String ACCOUNT_RECORD_TYPE_ORGANISATION_DEVELOPER_NAME = 'ESN_RT_BR_Organisation';

    public static final String CONTACT_CLINICIAN_DISCIPLINE_SPEECH_PATHOLOGY = 'Speech Pathology';
    public static final String CONTACT_CLINICIAN_DISCIPLINE_AHA = 'Allied Health Assistant';
    public static final String CONTACT_INTERNAL_BRANDING_AHA_SENIOR = 'Senior Allied Health Assistant';
    public static final String CONTACT_STATUS_CURRENT = 'Current';
    public static final String CONTACT_STATUS_WAITING = 'Waiting';
    public static final String CONTACT_ROLE_OTHER = 'Other';
    public static final String CONTACT_CASE_MANAGER_ROLE_SUPPORT_COORDINATOR = 'Support Coordinator';
    public static final String CONTACT_CASE_MANAGER_ROLE_CARE_MANAGER = 'Care Manager';
    public static final String CONTACT_INTERPRETER_YES_ENGLISH = 'Yes – for spoken language other than English';
    public static final String CONTACT_INTERPRETER_NO = 'No';
    public static final String CONTACT_ROLE_GP = 'General Practitioner';

    public static final String CONNECTION_STATUS_CURRENT = 'Current';

    public static final String CLINICAL_FILE_DISCIPLINE_EP = 'Exercise Physiology';
    public static final String CLINICAL_FILE_DISCIPLINE_OT = 'Occupational Therapy';
    public static final String CLINICAL_FILE_DISCIPLINE_PT = 'Physiotherapy';
    public static final String CLINICAL_FILE_DISCIPLINE_PBS = 'Positive Behaviour Support';
    public static final String CLINICAL_FILE_DISCIPLINE_SPEECH = 'Speech Pathology';
    public static final String CLINICAL_FILE_DISCIPLINE_PSYCH = 'Psychology';

    public static final String ADDRESS_COUNTRY_NEW_ZEALAND = 'New Zealand';
    public static final String ADDRESS_COUNTRY_AUSTRALIA = 'Australia';
    public static final String ADDRESS_COUNTRY_MEXICO = 'Mexico';
    public static final String REGION_SA = 'South Australia';
    public static final String REGION_VIC = 'Victoria';
    public static final String REGION_NSW = 'New South Wales';
    public static final String REGION_ACT = 'Australian Capital Territory';
    public static final String REGION_QLD = 'Queensland';
    public static final String REGION_NT = 'Northern Territory';
    public static final String REGION_WA = 'Western Australia';
    public static final String REGION_TAS = 'Tasmania';
    public static final String PRICEBOOK_STATE_SA = 'SA';
    public static final String PRICEBOOK_STATE_VIC = 'VIC';
    public static final String PRICEBOOK_STATE_NSW = 'NSW';
    public static final String PRICEBOOK_STATE_ACT = 'ACT';
    public static final String PRICEBOOK_STATE_QLD = 'QLD';
    public static final String PRICEBOOK_STATE_NT = 'NT';
    public static final String PRICEBOOK_STATE_WA = 'WA';
    public static final String PRICEBOOK_STATE_TAS = 'TAS';
    public static final String PRICEBOOK_STATE_REMOTE = 'REMOTE';
    public static final String OPPORTUNITY_REMOTE_REMOTE = 'REMOTE';
    public static final String PRICEBOOK_STATE_VERY_REMOTE = 'VERY_REMOTE';
    public static final String OPPORTUNITY_REMOTE_VERY_REMOTE = 'VERY_REMOTE';
    public static final String PRICEBOOK_STATE_ALL_STATES = 'ALL STATES';
    public static final String QUEUE_SA = 'ESN_Q_BR_SA_Queue';
    public static final String QUEUE_VIC = 'ESN_Q_BR_VIC_Admin';
    public static final String QUEUE_NSW = 'ESN_Q_BR_NSW_Admin';
    public static final String QUEUE_ACT = 'ESN_Q_BR_ACT_Queue';
    public static final String QUEUE_QLD = 'ESN_Q_BR_QLD_Admin';
    public static final String QUEUE_NT = 'ESN_Q_BR_NT_Queue';
    public static final String QUEUE_WA = 'ESN_Q_BR_WA_Admin';
    public static final String QUEUE_TAS = 'ESN_Q_BR_TAS_Queue';
    public static final String QUEUE_EP = 'ESN_Q_BR_EP_Report_Approval_Queue';
    public static final String QUEUE_OT = 'ESN_Q_BR_OT_Plan_Review_Report_Approval';
    public static final String QUEUE_PT = 'ESN_Q_BR_PT_Plan_Review_Report_Approval';
    public static final String QUEUE_PBS = 'ESN_Q_BR_PBS_Plan_Review_Report_Approval';
    public static final String QUEUE_SPEECH = 'ESN_Q_BR_Speech_Plan_Rvw_Rprt_Approval';
    public static final String QUEUE_PSYCH = 'ESN_Q_BR_Psych_Report_Approval_Queue';
    public static final String QUEUE_HSTP = 'ESN_Q_BR_HSTP_Queue';
    public static final String RELATIONSHIP_FATHER = 'Father';
    public static final String LANGUAGE_ENGLISH = 'English';
    public static final String GENDER_MALE = 'Male';
    public static final String DISABILITY_NEUROLOGICAL = 'Neurological';
    public static final String DISABILITY_ANXIETY = 'Anxiety';

    public static final String REFERRAL_FUNDING_SOURCE_NDIS = 'NDIS';
    public static final String REFERRAL_FUNDING_SOURCE_ECA = 'ECA';
    public static final String REFERRAL_FUNDING_SOURCE_NONE = 'None';
    public static final String REFERRAL_FUNDING_SOURCE_HSTP = 'HSTP';
    public static final String REFERRAL_FUNDING_SOURCE_PRIVATE = 'Private';
    public static final String REFERRAL_FUNDING_SOURCE_HCP = 'Home Care Package';
    public static final String REFERRAL_FUNDING_SOURCE_DSOA = 'DSOA';
    public static final String REFERRAL_PROCESSING_PRIORITY_HIGH = 'High';
    public static final String REFERRAL_SOURCE_SCREEN_FLOW = 'Screen Flow';
    public static final String REFERRAL_SOURCE_FORM = 'Formstack';
    public static final String REFERRAL_PREFERRED_TIMES_AM = 'AM';
    public static final String REFERRAL_DISCIPLINE_OT = 'Occupational Therapy';
    public static final String REFERRAL_PHYSIO_SERVICES_MOBILITY = 'Mobility';
    public static final String REFERRAL_SPEECH_PATH_SERVICES_SOCIAL_SKILLS = 'Social skills';
    public static final String REFERRAL_OT_SERVICE_HOME_MODS = 'Home Mods';
    public static final String REFERRAL_PBS_SERVICES_SKILL_DEVELOPMENT = 'Skill Development';
    public static final String REFERRAL_SERVICE_AGREEMENT_SIGNEE_PARTICIPANT = 'Participant';
    public static final String REFERRAL_SERVICE_AGREEMENT_SIGNEE_PLAN_NOMINEE = 'Plan Nominee';
    public static final String REFERRAL_HOW_PLAN_MANAGED_NDIA = 'NDIA Managed';
    public static final String REFERRAL_EXERCISE_PHYS_SERVICES_STRENGTH = 'Strength and Exercise Program';
    public static final String REFERRAL_TYPE_PERMANENT_HANDOVER = 'Permanent Handover';
    public static final String REFERRAL_TYPE_INTERNAL_REFERRAL = 'Internal Referral';
    public static final String REFERRAL_TYPE_EXTERNAL_REFERRAL = 'External Referral';
    public static final String REFERRAL_REFERRER_PARTICIPANT = 'Participant';
    public static final String REFERRAL_REFERRER_SUPPORT_COORDINATOR = 'Support Coordinator';
    public static final String REFERRAL_REFERRER_FAMILY = 'Family';
    public static final String REFERRAL_REFERRER_OTHER = 'Other';
    public static final String REFERRAL_REFERRER_CARE_MANAGER = 'Care Manager';
    public static final String REFERRAL_REFERRER_LAC = 'Local Area Coordinator';
    public static final String REFERRAL_RESIDENCE_TYPE_HOME = 'Home';
    public static final String REFERRAL_RECORD_TYPE_HSTP = 'ESN_RT_BR_HSTP';
    public static final String REFERRAL_RECORD_TYPE_NDIS = 'ESN_RT_BR_NDIS';
    public static final String REFERRAL_RECORD_TYPE_PRIVATE = 'ESN_RT_BR_Private';
    public static final String REFERRAL_PRIVATE_HEALTH_INSURER_BUPA = 'Bupa';
    public static final String REFERRAL_PRIVATE_HEALTH_INSURER_OTHER = 'Other';
    public static final String REFERRAL_ROLE_FAMILY = 'Family';
    public static final String REFERRAL_ROLE_OTHER = 'Other';

    public static final String OPPORTUNITY_STAGE_REFERRAL_RECEIVED = 'Open';
    public static final String OPPORTUNITY_STAGE_CONTACTED = 'Contacted';
    public static final String OPPORTUNITY_EXISTING_CLIENT_NEW = 'New';
    public static final String OPPORTUNITY_EXISTING_CLIENT_EXISTING = 'Existing';
    public static final String OPPORTUNITY_DISCIPLINE_PHYSIO = 'Physiotherapy';
    public static final String OPPORTUNITY_DISCIPLINE_PHYCOLOGY = 'Psychology';
    public static final String OPPORTUNITY_DISCIPLINE_EXERCISE_PHYSIO = 'Exercise Physiology';
    public static final String OPPORTUNITY_DISCIPLINE_AHA = 'Allied Health Assistants';
    public static final String OPPORTUNITY_DISCIPLINE_PBS = 'Positive Behaviour Support';
    public static final String OPPORTUNITY_DISCIPLINE_SPEECH = 'Speech Pathology';
    public static final String OPPORTUNITY_DISCIPLINE_OT = 'Occupational Therapy';

    public static final String SERVICE_ENROLLMENT_STATUS_ASSESSING_CAPACITY = 'Assessing Capacity';
    public static final String SERVICE_ENROLLMENT_STATUS_WAITLISTED = 'Waitlisted';

    public static final String OPPORTUNITY_RECORD_TYPE_SERVICE_AGREEMENT = 'Service_Agreement';
    public static final String OPPORTUNITY_RECORD_TYPE_HSTP = 'ESN_RT_BR_HSTP_Service_Agreement';

    public static final Map<String, RecordTypeInfo> MAP_REFERRAL_RECORD_TYPES = ESN_BR_Referral__c.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName();
    public static final Map<String, RecordTypeInfo> MAP_OPPORTUNITY_RECORD_TYPES = Opportunity.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName();
    public static final Map<String, RecordTypeInfo> MAP_ACCOUNT_RECORD_TYPES = Account.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName();

    public static final Map<SObjectField, SObjectField> REFERRAL_OPPORTUNITY_FIELD_MAPPING = new Map<SObjectField, SObjectField>
    {
            ESN_BR_Referral__c.ESN_BR_Acknowledgement__c => Opportunity.ESN_BR_Acknowledgement__c,
            ESN_BR_Referral__c.ESN_BR_Anticipated_Discharge_Date__c => Opportunity.ESN_BR_Anticipated_Discharge_Date__c,
            ESN_BR_Referral__c.ESN_BR_Date_of_Surgery__c => Opportunity.ESN_BR_Date_of_Surgery__c,
            ESN_BR_Referral__c.ESN_BR_Department__c => Opportunity.ESN_BR_Department__c,
            ESN_BR_Referral__c.ESN_BR_Detailed_Comments__c => Opportunity.ESN_BR_Detailed_Comments__c,
            ESN_BR_Referral__c.ESN_BR_Discipline__c => Opportunity.ESN_BR_Discipline__c,
            ESN_BR_Referral__c.ESN_BR_Doctors_Phone__c => Opportunity.ESN_BR_Doctors_Phone__c,
            ESN_BR_Referral__c.ESN_BR_Exercise_Physiology_Services__c => Opportunity.ESN_BR_Exercise_Physiology_Services__c,
            ESN_BR_Referral__c.ESN_BR_Funding_Source__c => Opportunity.ESN_BR_Funding_Source__c,
            ESN_BR_Referral__c.ESN_BR_Health_Fund_Expiry_Date__c => Opportunity.ESN_BR_Health_Fund_Expiry_Date__c,
            ESN_BR_Referral__c.ESN_BR_Health_Fund_Member_Number__c => Opportunity.ESN_BR_Health_Fund_Member_Number__c,
            ESN_BR_Referral__c.ESN_BR_NDIS_Plan_End_Date__c => Opportunity.ESN_BR_NDIS_Plan_End_Date__c,
            ESN_BR_Referral__c.ESN_BR_NDIS_Plan_Start_Date__c => Opportunity.ESN_BR_NDIS_Plan_Start_Date__c,
            ESN_BR_Referral__c.ESN_BR_Occupational_Therapy_Service__c => Opportunity.ESN_BR_Occupational_Therapy_Service__c,
            ESN_BR_Referral__c.ESN_BR_Participant_Merged_Region__c => Opportunity.ESN_BR_Region__c,
            ESN_BR_Referral__c.ESN_BR_PBS_Services__c => Opportunity.ESN_BR_PBS_Services__c,
            ESN_BR_Referral__c.ESN_BR_Physiotherapy_Services__c => Opportunity.ESN_BR_Physiotherapy_Services__c,
        //     ESN_BR_Referral__c.ESN_BR_Plan_Goals__c => Opportunity.ESN_BR_Plan_Goals__c,
            ESN_BR_Referral__c.Plan_Goals__c => Opportunity.Plan_Goals__c,
            ESN_BR_Referral__c.ESN_BR_Preferred_Weekday_App_Times__c => Opportunity.ESN_BR_Pref_Weekday_Appointment_Times__c,
            ESN_BR_Referral__c.ESN_BR_Referral_Source2__c => Opportunity.ESN_BR_Referral_Source__c,
            ESN_BR_Referral__c.ESN_BR_Referral_Type2__c => Opportunity.ESN_BR_Referral_Type2__c,
            ESN_BR_Referral__c.ESN_BR_Referrer__c => Opportunity.ESN_BR_Referrer__c,
            ESN_BR_Referral__c.ESN_BR_Speech_Pathology_Services__c => Opportunity.ESN_BR_Speech_Pathology_Services__c,
            ESN_BR_Referral__c.ESN_BR_Service_Agreement_Signee__c => Opportunity.ESN_BR_Service_Agreement_Signee__c,
            ESN_BR_Referral__c.ESN_BR_Treating_Surgeon_Doctor__c => Opportunity.ESN_BR_Treating_Surgeon_Doctor__c,
            ESN_BR_Referral__c.ESN_BR_Type_of_Surgery__c => Opportunity.ESN_BR_Type_of_Surgery__c,
            ESN_BR_Referral__c.Id => Opportunity.ESN_BR_Referral__c,
            //ESN_BR_Referral__c.ESN_BR_Date_Received__c => Opportunity.ESN_BR_Date_Received__c,
            ESN_BR_Referral__c.ESN_BR_Participant_Is_Primary_Contact__c => Opportunity.ESN_BR_Participant_Is_Primary_Contact__c,
            ESN_BR_Referral__c.ESN_BR_RAPT_Score__c => Opportunity.ESN_BR_RAPT_Score__c,
            ESN_BR_Referral__c.ESN_BR_Primary_Disabiliy__c => Opportunity.ESN_BR_Primary_Disability__c,
            ESN_BR_Referral__c.ESN_BR_Primary_Disability_Other__c => Opportunity.ESN_BR_Primary_Disability_Other__c
    };

    public static final Map<SObjectField, SObjectField> REFERRAL_OPPORTUNITY_LOOKUP_MAPPING = new Map<SObjectField, SObjectField>
    {
            ESN_BR_Referral__c.ESN_BR_Existing_Enquirer__c => Opportunity.ESN_BR_Referrer_Support_Coordinator__c,
            ESN_BR_Referral__c.ESN_BR_GP__c => Opportunity.ESN_BR_GP_Contact__c,
            ESN_BR_Referral__c.ESN_BR_Existing_Signee__c => Opportunity.ESN_BR_Signee__c,
            ESN_BR_Referral__c.ESN_BR_Hospital_Contact__c => Opportunity.ESN_BR_Referring_Hospital_Contact__c,
            ESN_BR_Referral__c.ESN_BR_Referrer_Organisation__c => Opportunity.ESN_BR_Referrer_Organisation__c,
            ESN_BR_Referral__c.ESN_BR_Hospital__c => Opportunity.ESN_BR_Hospital__c,
            ESN_BR_Referral__c.ESN_BR_Existing_Plan_Manager_Org__c => Opportunity.ESN_BR_Plan_Manager_Organisation__c
    };

    public static final Map<SObjectField, SObjectField> REFERRAL_LOOKUP_CHECKBOX_MAPPING = new Map<SObjectField, SObjectField>
    {
            ESN_BR_Referral__c.ESN_BR_Existing_Enquirer__c => ESN_BR_Referral__c.ESN_BR_Duplicate_Found_Enquirer__c,
            ESN_BR_Referral__c.ESN_BR_GP__c => ESN_BR_Referral__c.ESN_BR_Duplicate_Found_GP__c,
            ESN_BR_Referral__c.ESN_BR_Existing_Signee__c => ESN_BR_Referral__c.ESN_BR_Duplicate_Found_Signee__c,
            ESN_BR_Referral__c.ESN_BR_Hospital_Contact__c => ESN_BR_Referral__c.ESN_BR_Duplicate_Found_Hospital_Contact__c,
            ESN_BR_Referral__c.ESN_BR_Referrer_Organisation__c => ESN_BR_Referral__c.ESN_BR_Duplicate_Found_Referrer_Org__c,
            ESN_BR_Referral__c.ESN_BR_Hospital__c => ESN_BR_Referral__c.ESN_BR_Duplicate_Found_Hospital__c,
            ESN_BR_Referral__c.ESN_BR_Existing_Plan_Manager_Org__c => ESN_BR_Referral__c.ESN_BR_Duplicate_Found_Plan_Manager_Org__c
    };
	
    // The following mapping is used for CREATING an Enquirer whenever a Referral is being processed to an Opportunity
    public static final Map<SObjectField, SObjectField> REFERRAL_ENQUIRER_FIELD_MAPPING = new Map<SObjectField, SObjectField>
    {
            ESN_BR_Referral__c.ESN_BR_Enquirer_Email__c => Contact.Email,
            ESN_BR_Referral__c.ESN_BR_Enquirer_First_Name__c => Contact.FirstName,
            ESN_BR_Referral__c.ESN_BR_Enquirer_Last_Name__c => Contact.LastName,
            ESN_BR_Referral__c.ESN_BR_Enquirer_Phone__c => Contact.MobilePhone,
            ESN_BR_Referral__c.ESN_BR_Enquirer_Region__c => Contact.ESN_BR_Region__c,
            ESN_BR_Referral__c.Opt_out_of_Marketing__c => Contact.ESN_BR_Opt_out_of_Marketing__c,
            ESN_BR_Referral__c.Enquirer_Contact_Details__c => Contact.ESN_BR_Contact_Details__c
    };
        
    // The following mapping is used for UPDATING an existing Enquirer whenever a Referral is being processed to an Opportunity
    public static final Map<SObjectField, SObjectField> REFERRAL_ENQUIRER_FIELD_MAPPING_UPDATE = new Map<SObjectField, SObjectField>
    {
            ESN_BR_Referral__c.Opt_out_of_Marketing__c => Contact.ESN_BR_Opt_out_of_Marketing__c
    };

    public static final Map<SObjectField, SObjectField> REFERRAL_HOSPITAL_CONTACT_FIELD_MAPPING = new Map<SObjectField, SObjectField>
    {
            ESN_BR_Referral__c.ESN_BR_Hospital_Contact_Email__c=> Contact.Email,
            ESN_BR_Referral__c.ESN_BR_Hospital_Contact_First_Name__c => Contact.FirstName,
            ESN_BR_Referral__c.ESN_BR_Hospital_Contact_Last_Name__c => Contact.LastName,
            ESN_BR_Referral__c.ESN_BR_Hospital_Contact_Phone__c => Contact.MobilePhone,
            ESN_BR_Referral__c.Hospital_Contact_Details__c => Contact.ESN_BR_Contact_Details__c
    };

    public static final Map<SObjectField, SObjectField> REFERRAL_SIGNEE_CONTACT_FIELD_MAPPING = new Map<SObjectField, SObjectField>
    {
            ESN_BR_Referral__c.ESN_BR_Signee_Email__c => Contact.Email,
            ESN_BR_Referral__c.ESN_BR_Signee_First_Name__c => Contact.FirstName,
            ESN_BR_Referral__c.ESN_BR_Signee_Last_Name__c => Contact.LastName,
            ESN_BR_Referral__c.ESN_BR_Signee_Phone__c => Contact.MobilePhone,
            ESN_BR_Referral__c.Agreement_Signer_Contact_Details__c => Contact.ESN_BR_Contact_Details__c
    };

    public static final Map<SObjectField, SObjectField> REFERRAL_GP_CONTACT_FIELD_MAPPING = new Map<SObjectField, SObjectField>
    {
            ESN_BR_Referral__c.ESN_BR_GP_Email__c=> Contact.Email,
            ESN_BR_Referral__c.ESN_BR_GP_First_Name__c => Contact.FirstName,
            ESN_BR_Referral__c.ESN_BR_GP_Last_Name__c => Contact.LastName,
            ESN_BR_Referral__c.ESN_BR_GP_Phone__c => Contact.MobilePhone,
            ESN_BR_Referral__c.GP_Contact_Details__c => Contact.ESN_BR_Contact_Details__c
    };

    public static final Map<SObjectField, SObjectField> REFERRAL_PARTICIPANT_FIELD_MAPPING = new Map<SObjectField, SObjectField>
    {
            ESN_BR_Referral__c.ESN_BR_ADL_Mobility_Safety_Alerts__c => Contact.ESN_BR_ADL_Mobility_Safety_Alerts__c,
            ESN_BR_Referral__c.ESN_BR_Behavioural_Concerns__c => Contact.ESN_BR_Behavioural_Concerns__c,
            ESN_BR_Referral__c.ESN_BR_Participant_Region__c => Contact.ESN_BR_Region__c,
            ESN_BR_Referral__c.ESN_BR_Participant_Address__City__s => Contact.MailingCity,
            ESN_BR_Referral__c.ESN_BR_Participant_Address__CountryCode__s => Contact.MailingCountry,
            ESN_BR_Referral__c.ESN_BR_Participant_Address__PostalCode__s => Contact.MailingPostalCode,
            ESN_BR_Referral__c.ESN_BR_Participant_Address__StateCode__s => Contact.MailingState,
            ESN_BR_Referral__c.ESN_BR_Participant_Address__Street__s => Contact.MailingStreet,
            ESN_BR_Referral__c.ESN_BR_Participant_Date_of_Birth__c => Contact.Birthdate,
            ESN_BR_Referral__c.ESN_BR_Participant_Email__c => Contact.Email,
            ESN_BR_Referral__c.ESN_BR_Participant_First_Name__c => Contact.FirstName,
            ESN_BR_Referral__c.ESN_BR_Participant_Gender__c => Contact.maica__Gender__c,
            ESN_BR_Referral__c.ESN_BR_Participant_Is_Primary_Contact__c => Contact.ESN_BR_Participant_Is_Primary_Contact__c,
            ESN_BR_Referral__c.ESN_BR_Participant_Last_Name__c => Contact.LastName,
            ESN_BR_Referral__c.ESN_BR_Participant_Phone__c => Contact.MobilePhone,
            ESN_BR_Referral__c.ESN_BR_Patient_History__c => Contact.ESN_BR_Patient_History__c,
            ESN_BR_Referral__c.ESN_BR_Primary_concerns_or_condition__c => Contact.ESN_BR_Other_Health_Issues__c,
            ESN_BR_Referral__c.ESN_BR_Primary_Disability_Other__c => Contact.ESN_BR_Primary_Disability_Other__c,
            ESN_BR_Referral__c.ESN_BR_Primary_Disabiliy__c => Contact.ESN_BR_Primary_Disability__c,
            ESN_BR_Referral__c.ESN_BR_Primary_Language__c => Contact.maica__Primary_Language__c,
            ESN_BR_Referral__c.ESN_BR_Processing_Priority__c => Contact.ESN_BR_Priority__c,
            ESN_BR_Referral__c.ESN_BR_Residence_Type__c => Contact.ESN_BR_Residence_Type__c,
            ESN_BR_Referral__c.ESN_BR_Secondary_Disability__c => Contact.ESN_BR_Secondary_Disability__c,
            ESN_BR_Referral__c.Opt_out_of_Marketing__c => Contact.ESN_BR_Opt_out_of_Marketing__c,
            ESN_BR_Referral__c.Home_Care_Package_Level__c => Contact.Home_Care_Package_Level__c,
            ESN_BR_Referral__c.Participant_Contact_Details__c => Contact.ESN_BR_Contact_Details__c
    };

    public static final Map<SObjectField, SObjectField> REFERRAL_ORGANISATION_FIELD_MAPPING = new Map<SObjectField, SObjectField>
    {
            ESN_BR_Referral__c.ESN_BR_Referrer_Organisation_Name__c => Account.Name
    };

    public static final Map<SObjectField, SObjectField> REFERRAL_HOSPITAL_FIELD_MAPPING = new Map<SObjectField, SObjectField>
    {
            ESN_BR_Referral__c.ESN_BR_Hospital_Name__c => Account.Name
    };

    public static final Map<SObjectField, SObjectField> REFERRAL_PLAN_MANAGER_ORGANISATION_FIELD_MAPPING = new Map<SObjectField, SObjectField>
    {
            ESN_BR_Referral__c.ESN_BR_Plan_Manager_Organisation_Name__c => Account.Name,
            ESN_BR_Referral__c.ESN_BR_Plan_Manager_Phone__c => Account.Phone,
            ESN_BR_Referral__c.ESN_BR_Plan_Manager_Email__c => Account.ESN_BR_Email__c,
            ESN_BR_Referral__c.Plan_Manager_Contact_Details__c => Account.Description
    };

    public static final Map<String, String> MAP_REGION_QUEUE = new Map<String, String>
    {
            REGION_SA => QUEUE_SA,
            REGION_VIC => QUEUE_VIC,
            REGION_NSW => QUEUE_NSW,
            REGION_ACT => QUEUE_ACT,
            REGION_QLD => QUEUE_QLD,
            REGION_NT => QUEUE_NT,
            REGION_WA => QUEUE_WA,
            REGION_TAS => QUEUE_TAS
    };

    public static final Map<String, String> MAP_OPPORTUNITY_REGION_REMOTE_PRICEBOOK_STATE = new Map<String, String>
    {
            REGION_SA => PRICEBOOK_STATE_SA,
            REGION_VIC => PRICEBOOK_STATE_VIC,
            REGION_NSW => PRICEBOOK_STATE_NSW,
            REGION_ACT => PRICEBOOK_STATE_ACT,
            REGION_QLD => PRICEBOOK_STATE_QLD,
            REGION_NT => PRICEBOOK_STATE_NT,
            REGION_WA => PRICEBOOK_STATE_WA,
            REGION_TAS => PRICEBOOK_STATE_TAS,
            OPPORTUNITY_REMOTE_REMOTE => PRICEBOOK_STATE_REMOTE,
            PRICEBOOK_STATE_VERY_REMOTE => PRICEBOOK_STATE_VERY_REMOTE
    };

    public static final Map<String, String> MAP_DISCIPLINE_QUEUE = new Map<String, String>
    {
            CLINICAL_FILE_DISCIPLINE_EP => QUEUE_EP,
            CLINICAL_FILE_DISCIPLINE_OT => QUEUE_OT,
            CLINICAL_FILE_DISCIPLINE_PT => QUEUE_PT,
            CLINICAL_FILE_DISCIPLINE_PBS => QUEUE_PBS,
            CLINICAL_FILE_DISCIPLINE_SPEECH => QUEUE_SPEECH,
            CLINICAL_FILE_DISCIPLINE_PSYCH => QUEUE_PSYCH
    };

    public static final String ERROR_CLINICAL_FILE_NOT_FOUND = 'Clinical File Record Not Found';
    public static final Integer TEXT_AREA_MAX_LENGTH = 255;
    public static final String ID_PARAM = 'id';
    public static final String TEST_STRING = 'test';
    public static final String GENERATE_PDF_FILE_FORMAT = '{0}{1}.pdf';
    public static final String GENERATE_PDF_FILE_DATE_FORMAT = 'yyyyMMdd';
    public static final String RISK_STATUS_RULE_NAME_AMBER = 'amber';
    public static final String RISK_STATUS_RULE_NAME_RED = 'red';
    public static final String RISK_STATUS_RULE_NAME_GREEN = 'green';
    public static final String OPPORTUNITY_PROCESSING_PRIORITY_HIGH = 'High';
    public static final String PLAN_MANAGEMENT_TYPE_AGENCY = 'Agency Managed';
    public static final String OPPORTUNITY_NAME_HSTP = 'Referral - {0} - {1} - {2}';
    public static final String CONNECTION_TYPE_SUPPORT_COORDINATOR = 'Support Coordinator';
    public static final String CONNECTION_TYPE_CARE_MANAGER = 'Care Manager';
    public static final String CONNECTION_TYPE_LAC = 'LAC';
    
    /**
     * Version format used to append to the file name
     */
    public static final String VERSION_FORMAT = '{0} (Version: {1})';
    
    public static final String ID_IN_ID_SET = 'id in :idSet';
    public static final String SERVICE_PROGRAM_PURPOSE_CATEGORY_CORE = 'Core';
    public static final String PRICEBOOK_FUNDING_SOURCE_NDIS = 'NDIS';
    public static final String XERO_INVOICE_TRACKING_NAME_SITE = 'Site';
    public static final String XERO_INVOICE_TRACKING_NAME_STATE = 'State';
    public static final String XERO_SEND_INVOICE_COMPLETE_EMAIL_TEMPLATE = 'ESN_ET_BR_Send_Invoice_Complete';
    public static final String INVOICE_FUNDING_STRUCTURE_AGENCY = 'Agency Managed';

    /**
     * Fields that will be populated in addition to those that are defined within the getSobjectFieldList
     */
    public static List<String> CONTENT_VERSION_FIELDS_TO_SELECT = new List<String>
    {
        'LatestPublishedVersion.VersionDataUrl',
        'LatestPublishedVersion.VersionNumber'
    };

    public static final String CONTENT_FOLDER_SUB_SELECT_QUERY = ' IN (SELECT ID FROM ContentFolder WHERE Name = :category AND ParentContentFolder.Name = :discipline) ';

    public static final String CLINICAL_FILE_REVIEW_STATUS_DRAFT = 'Draft';
    public static final String CLINICAL_FILE_REVIEW_STATUS_COMPLETED = 'Completed';
    public static final String CLINICAL_FILE_REVIEW_STATUS_SENT_TO_STAKEHOLDERS = 'Sent to Stakeholders';

    public static final List<String> DEFAULT_CLINICAL_FILE_REVIEW_STATUSES = new List<String>{CLINICAL_FILE_REVIEW_STATUS_DRAFT, CLINICAL_FILE_REVIEW_STATUS_COMPLETED, CLINICAL_FILE_REVIEW_STATUS_SENT_TO_STAKEHOLDERS};

    public static final String NEW_LINE_SLASH_R_N = '\r\n';

    public static final String CONTENT_DOCUMENT_LINK_VIEW_SHARE_TYPE = 'V';

    // used for querying ui api for case notes
    public final static String GRAPH_QL_CRITERIA_FORMAT = '\'{\'{0} : \'{\' {1} : {2} \'}\' \'}\'';
    public final static String GRAPH_QL_AND_FORMAT = '\'{\' and : [{0}] \'}\'';
    public static final String GRAPH_QL_DATE_CRITERIA_FORMAT =  '\'{\'"value": "{0}"\'}\'';
    public static final String GRAPH_QL_EQUALS = 'eq';
    public static final String GRAPH_QL_LIKE = 'like';
    public static final String GRAPH_QL_GREATER_THAN_EQUAL_TO = 'gte';
    public static final String GRAPH_QL_LESS_THAN_EQUAL_TO = 'lte';
    public static final String DATE_TIME_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss.SSSZ';
    public static final String PARAM_RELATED_LIST_ID = 'relatedListId';
    public static final String PARAM_FIELDS = 'fields';
    public static final String PARAM_SORT_BY = 'sortBy';
    public static final String PARAM_WHERE = 'where';
    public static final String PARAM_PAGE_SIZE = 'pageSize';
    public static final String DOUBLE_QUOTE = '"';
    public static final String PERCENT_DOUBLE_QUOTE = '%"';
    public static final Integer HOUR_23 = 23;
    public static final Integer MINUTE_59 = 59;
    public static final Integer SECOND_59 = 59;

    // HTTP PARAMS
    public static final String HTTP_METHOD_POST = 'POST';
    public static final String HTTP_CONTENT_TYPE_HEADER = 'Content-Type';
    public static final String HTTP_AUTHORIZATION_HEADER = 'Authorization';
    public static final String HTTP_BEARER = 'Bearer ';
    public static final String HTTP_CT_APPLICATION_JSON = 'application/json';

    public static final String REGISTERED_PROVIDER = 'Registered Plan Manager Provider';
    public static List<String> CONTACT_ACCOUNT_FUNDING_MANAGER_FIELDS = new List<String>
    {
        'ESN_BR_Funding_Manager__r.maica__Provider_Email__c',
        'ESN_BR_Funding_Manager__r.Id'
    };

    public static final String CUSTOM_PERMISSION_BYPASS_TRIGGERS = 'ESN_CP_BR_Bypass_Triggers';
    public static final String SALESFORCE_PLATFORM_USER_WHERE_CLAUSE = ' Profile.UserLicense.Name = \'Salesforce Platform\'';
    public static final Integer DEFAULT_CREATE_OPPORTUNITY_BATCH_SIZE = 10;
    public static final Integer DEFAULT_RUN_OPPORTUNITY_BATCH_IN_X_MINUTES = 2;
}