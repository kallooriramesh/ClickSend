global with sharing class ClickSendSMSSelected_Batch implements Database.Batchable<sObject>, Database.AllowsCallouts 
{   
    set<string> selectedContacts=new set<string>();
    global string SMSTemplateBody;
    global String status;
    global List<Contact> contacts;
    global ClickSendSMSSelected_Batch(list<string> ids,string strSMSBody)
    {
        selectedContacts.addAll(ids);
        SMSTemplateBody=strSMSBody;
    }
    global Database.QueryLocator start(Database.BatchableContext BC)
    {   
        String strQuery='SELECT Id,AccountId, LastName, FirstName,  Name, OtherStreet, Email,Title,OwnerId , Phone, Fax, MobilePhone, HomePhone, ';
        strQuery=strQuery+' OtherPhone,Level__c,Languages__c,Is_SMS_Sent__c,Last_SMS_Sent_On__c,Send_SMS_To__c FROM Contact ';
        strQuery=strQuery+'where  Id in : selectedContacts  ';
        return Database.getQueryLocator(strQuery);
    }
    global void execute(Database.BatchableContext BC,  List<Contact> contacts)
    {
        try
        { //Fetch Template body
            List<wrapperMsg> objwlist=new list<wrapperMsg>();

            String fromNumber;
            Map<string,SMSSettings__c> mapCodes = SMSSettings__c.getAll();  
            try{
                fromNumber=[Select From_Number__c from ClickSend_SMS_Settings__c LIMIT 1].From_Number__c;
            }catch(Exception e){}
            list<Contact> lstUpdateAfterSMS=new list<Contact>();
            Integer consize=contacts.size();
            Map<string,string> messages;string jsonreq='';
            
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
                
                jsonreq=SYSTEM.Json.serializePretty(obj).replace('from_1', 'from');

            }   
                
                
            }
            
          
            
            SendClickSendSMS  sms=new SendClickSendSMS();
            //sms.JSONBody=JSONBody;
            status=sms.SendBulkSMS(jsonreq);
            
        }
        catch(Exception ex)
        {
            //Write Exception Log method
        }
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
    global void finish(Database.BatchableContext BC)
    {  
        //Notify Admin once Job finished
        //Send Email
    } 
}