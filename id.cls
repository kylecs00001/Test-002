public with sharing class IdHolidayCheckController {
     
    // This method checks the ID and creates / updates records on the SA_ID_Number__c Object
    @AuraEnabled
    public static Boolean isValidID(String idNumber) {
        
        Integer year = parseYear(idNumber);
        Integer month = parseMonth(idNumber);
        Integer day = parseDay(idNumber);
        Integer gender = parseGender(idNumber);
        Integer saCitizen = parseSACitizen(idNumber);
        Date formattedDate = parseFormattedDate(idNumber);
        Decimal iDNumberFormatted = parseIDNumber(idNumber);
        
        
        List<SA_ID_Number__c> saIDobj = [Select Id, ID_Number__c,Date_Of_Birth__c,Gender__c,SA_Citizen__c,Total__c  from SA_ID_Number__c where ID_Number__c  =: iDNumberFormatted limit 1 ];
        
        
        // Check if record already exist in SF
        if(saIDobj.size() > 0){
            
            if(saIDobj[0].Total__c == null){
                
                saIDobj[0].Total__c = 0;
                
            }
            
            saIDobj[0].Total__c++;
            
            update saIDobj;
            
        }else{
            
            SA_ID_Number__c newSAIdRecord = new SA_ID_Number__c();
            
            // Citizen Update
            if(saCitizen == 0){
                newSAIdRecord.SA_Citizen__c = true;
                
            }
            else if(saCitizen == 1){
                newSAIdRecord.SA_Citizen__c = false;
                
            }
            
            // Gender Check
            if(gender >= 0 && gender <= 4999){
                newSAIdRecord.Gender__c = 'Female';
                
            }
            else if(gender >= 5000 && gender <= 9999){
                newSAIdRecord.Gender__c = 'Male';
                
            }
            
            newSAIdRecord.ID_Number__c = iDNumberFormatted;
            newSAIdRecord.Date_Of_Birth__c = formattedDate;
            newSAIdRecord.Total__c = 1;
            
            insert newSAIdRecord;
            
        }
        
        return null;
    }
    
    
    // API callout to check if any holidays on ID date
    @AuraEnabled
    public static String makeApiCallout(String idNumber) {
        Integer year = parseYear(idNumber);
        Integer month = parseMonth(idNumber);
        Integer day = parseDay(idNumber);
        Integer gender = parseGender(idNumber);
        Integer saCitizen = parseSACitizen(idNumber);
        Date formattedDate = parseFormattedDate(idNumber);
        Decimal iDNumberFormatted = parseIDNumber(idNumber);
        
        String APIKey = getAPIKEY();
        String endpoint = buildApiEndpoint(APIKey, year, month, day);

                try{
        
        HttpResponse response = sendHttpRequest(endpoint);
        
        if (response.getStatusCode() == 200) {
            return parseApiResponse(response);
        } else {
            return null;
        }
    
       
    }
    catch(Exception e){
    System.debug('Error : ' + e);
	return null;
}
    }


    // Parse Year
    private static Integer parseYear(String idNumber) {
        Integer year = Integer.valueOf(idNumber.substring(0, 2));
        return (year >= 0 && year <= 24) ? year + 2000 : year + 1900;
    }
    
    // Parse Month
    private static Integer parseMonth(String idNumber) {
        return Integer.valueOf(idNumber.substring(2, 4));
    }
    // Parse Day
    private static Integer parseDay(String idNumber) {
        return Integer.valueOf(idNumber.substring(4, 6));
    }
    
    // Parse Gender
    private static Integer parseGender(String idNumber) {
        return Integer.valueOf(idNumber.substring(6, 10));
    }
    
    // Parse SACitizen
    private static Integer parseSACitizen(String idNumber) {
        return Integer.valueOf(idNumber.substring(10, 11));
    }
    
    // Formatted Date
    private static Date parseFormattedDate(String idNumber){
        Integer year = parseYear(idNumber);
        Integer month = parseMonth(idNumber);
        Integer day = parseDay(idNumber);
        return Date.newInstance(year, month, day);   
    }
    
    // Formatted ID
    private static Decimal parseIDNumber(String idNumber){
        String idString = idNumber;
        return Decimal.valueOf(idString);      
    }
    
    // Get API KEY
    public static String getAPIKEY(){
        List<CALENDARIFIC_API_KEY__mdt> CalendarFields = [ Select Label, CALENDARIFIC_SECRET_API_KEY__c	 FROM CALENDARIFIC_API_KEY__mdt];
        return CalendarFields[0].CALENDARIFIC_SECRET_API_KEY__c;
    }
    
    
    
    // Create Endpoint
    private static String buildApiEndpoint(String apiKey, Integer year, Integer month, Integer day) {
        return 'https://calendarific.com/api/v2/holidays?' +
            'api_key=' + apiKey +
            '&country=ZA' +
            '&year=' + year +
            '&day=' + day +
            '&month=' + month;
    }
    
    // Send API Request
    private static HttpResponse sendHttpRequest(String endpoint) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        return new Http().send(request);
    }
    
    // Parse API Response
    private static String parseApiResponse(HttpResponse response) {
        
        if (response.getStatusCode() == 200) {
            String responseBody = response.getBody();       
            
            JSONParser parser = JSON.createParser(responseBody);
            String holidayName;
            String holidayDescription;
            
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            if (jsonMap.containsKey('response')) {
                Map<String, Object> responseMap = (Map<String, Object>) jsonMap.get('response');
                
                if (responseMap.containsKey('holidays')) {
                    List<Object> holidaysList = (List<Object>) responseMap.get('holidays');
                    
                    
                    for (Object holidayObject : holidaysList) {
                        
                        Map<String, Object> holidayMap = (Map<String, Object>) holidayObject;
                        holidayName = (String) holidayMap.get('name');
                        holidayDescription = (String) holidayMap.get('description');
                        
                    }
                }
            }
            
            if(holidayName != null){
                return holidayName + ': ' + holidayDescription;
            }
            else{
                String noResult = 'No Holidays found on this day.';
                return noResult;
            }
            
            
        } else {
            return null;
        }
    }
    
    
}