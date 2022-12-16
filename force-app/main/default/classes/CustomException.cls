public with sharing class CustomException extends Exception
{
    private static final String FIELD_CUSTOM_VALIDATION_EXCEPTION = 'FIELD_CUSTOM_VALIDATION_EXCEPTION, ';

    public static PageReference formatException(Exception e)
    {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CustomException.getExceptionMessage(e)));
        return null;
    }


    public static String getExceptionMessage(Exception e)
    {
        String msg = e.getMessage();
        if(msg.contains('insufficient access rights on object id'))
        {
            return 'You cannot edit this record.';
        }
        if(e instanceof DMLException)
        {
            String message = ((DMLException)e).getDmlMessage(0);
            if (String.isNotBlank(message) && message.contains(FIELD_CUSTOM_VALIDATION_EXCEPTION)) {
                Integer index = message.lastIndexOf(FIELD_CUSTOM_VALIDATION_EXCEPTION) + FIELD_CUSTOM_VALIDATION_EXCEPTION.length();
                Integer indexBrace = message.indexOf('[');
                if (index < indexBrace && message.length() > indexBrace) {
                    message = message.substring(index, indexBrace).removeEnd(': ');
                }
            }
            return message;
        }
        if(!(e instanceof CustomException))
        {
            msg = ' Line:' + e.getLineNumber().format() + ' ' +  msg;
        }
        return msg;
    }

    public static PageReference formatException(String message)
    {
        return formatException(ApexPages.Severity.ERROR, message);
    }

    public static PageReference formatException(ApexPages.Severity severity, String message)
    {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
        return null;
    }
}