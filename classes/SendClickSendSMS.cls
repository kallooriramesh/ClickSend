public class SendClickSendSMS  
{
    
    public final String END_POINT_URL='https://rest.clicksend.com/v3/sms/send'; 
    public list<ClickSend_SMS_Settings__C>  settings;
    
    public String SendSMS(string toNumber, string message,Contact con) 
    {
        
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        String EndPointURL=END_POINT_URL;     
        String username=settings[0].Name; 
        String api_key=settings[0].ClickSend__ClickSend_API_Key__c;
        String fromNumber=settings[0].ClickSend__From_Number__c;
        req.setEndpoint(EndPointURL);
        system.debug('===='+message);
        //system.debug('===='+con.phone);
        
        Blob headerValue = Blob.valueOf(username+':'+api_key);
        String authorizationHeader = 'Basic '+EncodingUtil.base64Encode(headerValue);
        req.setHeader('Content-Type', 'application/json'); 
        req.setHeader('Authorization', authorizationHeader);
        
        List<wrapperMsg> objwlist=new list<wrapperMsg>();
        objwlist.add(new wrapperMsg(fromNumber,toNumber,con.id,'Salesforce',message));                
        Map<string,  List<wrapperMsg> > obj=new Map<string,  List<wrapperMsg> >();
        obj.put('messages',objwlist);
                
        String jsonRequestBody=Json.serializePretty(obj).replace('from_1', 'from');
        system.debug('jsonRequestBody==>'+jsonRequestBody);
        
       // String jsonRequestBody='{  "messages": [ { "body": "'+message+'","to":"'+toNumber+'","from":"'+fromNumber+'","source":"Salesforce","custom_string":"'+con.id+'"}]}';
      //jsonRequestBody= jsonRequestBody.replaceall('\\r\\n\\"','');
       //jsonRequestBody= jsonRequestBody.replace('\"','');
        System.debug(jsonRequestBody);
        req.setBody(jsonRequestBody);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody()); 
        
        if(res.getStatusCode()==200)
        {
            Task contactActivity=new Task();
            contactActivity.OwnerID=SYSTEM.UserInfo.getUserID();
            contactActivity.Status='Completed';
            contactActivity.Subject=message;
            //contactActivity.Description=message;
            contactActivity.WhoID=con.id;
            insert contactActivity;
        }
        return String.valueOf(res.getStatusCode());
    }
    
    
    public String SendBulkSMS(String JSONBody)
    {
        
        System.debug('JSONBody'+JSONBody);
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        
        settings=[Select ID,name,ClickSend_API_Key__c,From_Number__c from ClickSend_SMS_Settings__c LIMIT 1];        String EndPointURL=END_POINT_URL; 
        String username=settings[0].Name; 
        String api_key=settings[0].ClickSend__ClickSend_API_Key__c; 
        req.setEndpoint(EndPointURL);
        
        Blob headerValue = Blob.valueOf(username+':'+api_key);
        String authorizationHeader = 'Basic '+EncodingUtil.base64Encode(headerValue);
        req.setHeader('Content-Type', 'application/json'); 
        req.setHeader('Authorization', authorizationHeader);
        req.setBody(JSONBody);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody()); 
        
        JSONParser parser = JSON.createParser(res.getBody());
        List<ClickSendActivity> ActivityList=new List<ClickSendActivity>();
        String body;  
        String contactString;
        String contactID;
        String status;
        ClickSendActivity  act;
        String statusString;
        String bodyString;
        
        
        while (parser.nextToken() != null) 
        {
            act=new ClickSendActivity();
            String field=parser.getText();
                    
                    bodyString=parser.getText();
                    
                    if(bodyString=='body')
                    {
                        parser.nextToken();
                        body=parser.getText();
                        System.debug('SMS body'+body);
                    }
                    
                    contactString=parser.getText();
                    SYSTEM.DEBUG('contactString'+contactString);
                    if(contactString=='custom_string')
                    {
                        parser.nextToken();
                        contactID=parser.getText();
                        System.debug(contactID);
                    }
                    
                    statusString=parser.getText();
                    
                    SYSTEM.DEBUG('statusString'+statusString);
                    if(statusString=='status')
                    {
                        parser.nextToken();
                        status=parser.getText();
                        System.debug(status); 
                        
                    }
                    System.debug('status');
                    if(status=='SUCCESS')
                    {
                        act.smsBody=body;
                        act.contactID=contactID;
                        ActivityList.add(act);
                        status=null;
                    }   
              
        }
        List<Task> tasks=new List<Task>();
        System.debug('ActivityList.size()'+ActivityList.size());
        for(Integer i=0;i<ActivityList.size();i++)
        {
            Task contactActivity=new Task();
            contactActivity.OwnerID=SYSTEM.UserInfo.getUserID();
            contactActivity.Status='Completed';
            contactActivity.Subject=ActivityList[i].smsBody;
            //contactActivity.Description=message;
            contactActivity.WhoID=ActivityList[i].contactID;
            tasks.add(contactActivity);
        }
        System.debug('tasks'+tasks);
        insert tasks;
        
        return String.valueOf(res.getStatusCode());
    }
    
    public String validateDetails()
    {       
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        settings=[Select ID,name,ClickSend_API_Key__c,From_Number__c from ClickSend_SMS_Settings__c LIMIT 1];
        String username=settings[0].Name;                           
        String api_key=settings[0].ClickSend_API_Key__c; 
        req.setEndpoint('https://rest.clicksend.com/v3/account');
        
        Blob headerValue = Blob.valueOf(username+':'+api_key);
        String authorizationHeader = 'Basic '+EncodingUtil.base64Encode(headerValue);
        req.setHeader('Content-Type', 'application/json'); 
        req.setHeader('Authorization', authorizationHeader);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody()); 
        System.debug(res.getStatusCode()); 
        return String.valueOf(res.getStatusCode());         
    }
    
     public class wrapperMsg
    {
        string from_1 {get;set;}
        string to  {get;set;}
        id custom_string  {get;set;}
        string source  {get;set;}
        string body  {get;set;}
        public wrapperMsg(string from_v ,string to_v,id custom_string_v,string source_v,string body_v)
        {
            from_1 =from_v;
            to =to_v;
            custom_string =custom_string_v ;
            source =source_v;
            body =body_v;
        }
    }   
}