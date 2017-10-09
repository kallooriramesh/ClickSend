global with sharing class ClickSendSMS_Batch implements Database.Batchable<sObject>, Database.AllowsCallouts 
{   
  global string SMSTemplateBody;
  global String status;
  global String fromNumber;
  global List<Contact> contacts;
   global ClickSendSMS_Batch(string SMSBody)
    {
          SMSTemplateBody=SMSBody;
          Map<string,SMSSettings__c> mapCodes = SMSSettings__c.getAll(); 
        try{
          fromNumber=[Select From_Number__c FROM ClickSend_SMS_Settings__C LIMIT 1].From_Number__c;//String.valueof(mapCodes.get('ClickToSendSetting').From_Number__c); 
        }catch(Exception e){}
    }
    global Database.QueryLocator start(Database.BatchableContext BC)
    {  
    //  string conId='0032800000O8wYR';
        String strQuery;
        
        //if(Test.isRunningTest()!=TRUE)
        {
            strQuery='SELECT Id,AccountId, LastName, FirstName,  Name, OtherStreet, Email,Title,OwnerId , Phone, Fax, MobilePhone, HomePhone, ';
            strQuery=strQuery+' OtherPhone,ClickSend__Level__c,Languages__c,Is_SMS_Sent__c,Last_SMS_Sent_On__c,Send_SMS_To__c FROM Contact ';
            strQuery=strQuery+'where Is_SMS_Sent__c=false ';
        }
        
       
        return Database.getQueryLocator(strQuery);
    }
    global void execute(Database.BatchableContext BC,  List<Contact> contacts)
    {
        
        try
        { //Fetch Template body
        List<wrapperMsg> objwlist=new list<wrapperMsg>();
        Map<string,SMSSettings__c> mapCodes = SMSSettings__c.getAll();  
            fromNumber=[Select From_Number__c FROM ClickSend_SMS_Settings__C LIMIT 1].From_Number__c;
            list<Contact> lstUpdateAfterSMS=new list<Contact>();
            Integer consize=contacts.size();
            
            String JSONString;
            
            for(Integer i=0;i<contacts.size();i++)
            {
                string phone;
                  if(contacts[i].Phone!=null)
                {
                    phone=contacts[i].Phone;
                }
                else if(contacts[i].MobilePhone!=null)
                {
                    phone=contacts[i].MobilePhone;
                }
                else if(contacts[i].HomePhone!=null)
                {
                    phone=contacts[i].HomePhone;
                }else if(contacts[i].OtherPhone!=null)
                {
                    phone=contacts[i].OtherPhone;
                }
                                
                if(phone!=null && phone !='' )
                {
                    objwlist.add(new wrapperMsg(fromNumber,contacts[i].Phone,contacts[i].id,'Salesforce',SMSTemplateBody));                
                    Map<string,  List<wrapperMsg> > obj=new Map<string,  List<wrapperMsg> >();
                    obj.put('messages',objwlist);
                    
                    JSONString=SYSTEM.Json.serializePretty(obj).replace('from_1', 'from');
                    system.debug('jsonreq==>'+JSONString);
                }
                 
                   
        }
        
       
        
        //String JSONBody= JSON.serialize(ClickSendMessages);
        //JSONBody='{  "messages":'+JSONBody+'}';
        //System.debug('>>>>>>>>>>>>>>>>>>'+JSONBody);
        SendClickSendSMS  sms=new SendClickSendSMS();
        //sms.JSONBody=JSONBody;
        status=sms.SendBulkSMS(JSONString);
        
            if(contacts.size()>0)
            {
                for(integer i=0;i<contacts.size();i++)
                {
                    contacts.get(i).Is_SMS_Sent__c=true;
                    contacts.get(i).Last_SMS_Sent_On__c=system.Datetime.now();
                }
                update contacts;
            }
            
        }
        catch(Exception ex)
        {
            //Write Exception Log method
            system.debug('Exception'+ex.getMessage());
        }
    }
    global void finish(Database.BatchableContext BC)
    {  
        ClickSendSMS_ProcessedBatchUpdate processedBatch=new ClickSendSMS_ProcessedBatchUpdate();
        Database.executeBatch(processedBatch,200);
    } 
  
  global class wrapperMsg
    {
        string from_1 {get;set;}
        string to  {get;set;}
        id custom_string  {get;set;}
        string source  {get;set;}
        string body  {get;set;}
        global wrapperMsg(string from_v ,string to_v,id custom_string_v,string source_v,string body_v)
        {
            from_1 =from_v;
            to =to_v;
            custom_string =custom_string_v ;
            source =source_v;
            body =body_v;
        }
    }
}