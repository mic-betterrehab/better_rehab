/**
 * Created by ersoz on 2020-04-21.
 */

public with sharing class ZiplineInboundUtil {

    private static final String OPT_OUT = 'stop';

    public static Boolean isRecognisable(String messageText) {

        if(String.isEmpty(messageText)) return false;

        messageText = messageText.deleteWhitespace();

        if (messageText.isNumeric()){

            Integer messageScore = Integer.valueOf(messageText);

            //Score must be between 1-10
            if (messageScore < 0 || messageScore > 10) return false;
        }
        else if(!isOptOut(messageText)){

            return false;
        }

        return true;
    }

    public static Boolean isOptOut(String messageText){

        if(messageText.isAlpha() && messageText.equalsIgnoreCase(OPT_OUT)) return true;

        return false;
    }
}