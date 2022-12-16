/**
 * Created by Enrite Solutions on 24/07/2019.
 */

public with sharing class XeroCalloutResponseParser {

    public static List<XeroContact> parseContacts(String jsonBody) {

        // Re-serialize just the Contacts portion back to JSOn
        String jsonSerialized = generateJsonStringForParsing (jsonBody, 'Contacts');

        // And finally parse the now re-serialized contact list back into Contact objects
        return (List<XeroContact>) JSON.deserialize(jsonSerialized, List<XeroContact>.class);
    }

    public static List<XeroInvoice> parseInvoices(String jsonBody) {

        // Re-serialize just the Contacts portion back to JSOn
        String jsonSerialized = generateJsonStringForParsing (jsonBody, 'Invoices');

        // And finally parse the now re-serialized contact list back into Contact objects
        return (List<XeroInvoice>) JSON.deserialize(jsonSerialized, List<XeroInvoice>.class);
    }

    private static String generateJsonStringForParsing (String jsonBody, String objectName) {

        // Parse the JSON response
        Map<String, Object> jsonResponseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);

        // Re-serialize just the object portion back to JSON
        return JSON.serialize((List<Object>) jsonResponseMap.get(objectName));
    }
}