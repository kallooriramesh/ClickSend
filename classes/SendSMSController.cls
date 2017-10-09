public without sharing class SendSMSController {
    public Integer selectedContactsCount{get;set;}
    public SendSMSController(ApexPages.StandardSetController controller) {
         try{     
            template=new SMS_Template__c();       
            templates=[select ID,name,Template_Body__c from SMS_Template__c LIMIT 1000];
            wrapperList=new List<TemplateWrapper>();
            templates=[select ID,name,Template_Body__c from SMS_Template__c LIMIT 1000];
            clickSendSettings=[Select ID,name,ClickSend_API_Key__c,From_Number__c from ClickSend_SMS_Settings__c LIMIT 1];
            for(SMS_Template__c st:templates)
            {
                TemplateWrapper tw=new TemplateWrapper();
                tw.isChecked=false;
                tw.template=st;
                wrapperList.add(tw);
            }
            
        }Catch(Exception e1){}
        
    }
    
    
    public String smsStaus { get; set; }
    public string msg {get;set;}
    public SMS_Template__c template{get;set;}
    public List<SMS_Template__c> templates{get;set;}
    public List<TemplateWrapper> wrapperList{get;set;} 
    string ids; string types;string strSMSBody {get;set;}
    public Boolean isTemplateSeleted{get;set;}
    public List<ClickSend_SMS_Settings__c> clickSendSettings;
    private final contact con;
    
    public SendSMSController(ApexPages.StandardController controller) 
    {
        this.con = (contact)controller.getRecord();
    }
   
    public class TemplateWrapper{
        public Boolean isChecked{get;set;}
        public SMS_Template__c template{get;set;}
        
    }
    public PageReference Cancel() {
        return null;
    }
    
    public PageReference send() 
    {
        if(clickSendSettings.size()>0)
        {
            list<string> selectedIds=new list<string>();
            ClickSendSMSSelected_Batch objScheduleSMS ;
            try{
                String theId = ApexPages.currentPage().getParameters().get('id');
                if (theId != null) 
                {
                    String toNumber;
                    contact con=[select id, name, phone,MobilePhone,HomePhone,OtherPhone from contact  where id =:theId];
                    if(con.Phone!=null)
                    {
                        toNumber=con.Phone;
                    }
                    else if(con.MobilePhone!=null)
                    {
                        toNumber=con.MobilePhone;
                    }
                    else if(con.HomePhone!=null)
                    {
                        toNumber=con.HomePhone;
                    }
                    else
                    {
                        toNumber=con.OtherPhone; 
                    }
                    
                    
                    if(toNumber!=null && toNumber!='')
                    {
                        try
                        {   
                            SendClickSendSMS sms=new SendClickSendSMS();
                            sms.settings=clickSendSettings;
                            smsStaus=sms.validateDetails();   
                            if(smsStaus=='200')
                            {
                                sms.SendSMS(toNumber, template.Template_Body__c,con);
                            }
                        }
                        catch(Exception e){
                            smsStaus='other';
                        }
                    }else if(toNumber==null){
                        smsStaus='1001';
                    }
                    
                    else{smsStaus='1000';}
                    
                    return null;
                }
            }catch(Exception e){}
            if(types=='1')  // selected contacts
            {
                if(ids != null)
                {   
                    try
                    {        
                        SendClickSendSMS sms=new SendClickSendSMS();
                        sms.settings=clickSendSettings;
                        smsStaus=sms.validateDetails();                           
                        if(smsStaus=='200')
                        {
                            selectedIds= ids.split(',');
                            objScheduleSMS = new ClickSendSMSSelected_Batch(selectedIds,template.Template_Body__c);         
                            database.executebatch(objScheduleSMS,1000);
                        }
                        
                    }
                    catch(Exception e){
                        smsStaus='other';
                    }
                }
            }else if(types=='2')
            {
                try
                {
                    SendClickSendSMS sms=new SendClickSendSMS();
                    sms.settings=clickSendSettings;
                    smsStaus=sms.validateDetails();   
                    if(smsStaus=='200')
                    {
                        ClickSendSMS_Batch batch=new ClickSendSMS_Batch(template.Template_Body__c);
                        database.executebatch(batch,1000);
                    }
                    
                }
                catch(Exception e){
                    smsStaus='other';
                }
            }
        }else{smsStaus='1000';}
        return null;
        
    }
    
    
}