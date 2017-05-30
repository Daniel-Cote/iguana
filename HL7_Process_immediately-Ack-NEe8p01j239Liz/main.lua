-- This channel shows how one can make an HL7 listener interface which does not queue messages.
-- The message processing needs to happen inside the LLP Listener script before the ACKnowledgement message is sent.
function getApplicationConfig()
   local F = io.open("./configuration/test.xml","r")
  -- added comment
   local C = F:read("*a")
   F:close()
   local config = xml.parse{data=C}
   return config  
end

local function mapPID(PID, person)
   PID.PID[3][1] = person.id
   PID.PID[5][1][1][1]=person.name.family
   PID.PID[5][1][2]=person.name.given
end

local function createAck(msgInitial, personList) 
   local Ack = hl7.message{vmd='IPO.vmd',name='QPDK21'}
   
   Ack.MSH[3][1] = msgInitial.MSH[5][1]
   Ack.MSH[4][1] = msgInitial.MSH[6][1]
   Ack.MSH[5][1] = msgInitial.MSH[3][1]
   Ack.MSH[6][1] = msgInitial.MSH[4][1]
   Ack.MSH[10] = msgInitial.MSH[10]
   Ack.MSH[9][1] = 'ACK'
   Ack.MSH[11][1] = 'P'
   Ack.MSH[12][1] = '2.3'
   Ack.MSH[7][1] = os.date('%Y%m%d%H%M%S')
 
   local i=1
   for k,v in pairs(personList) do
      mapPID(Ack.person[i],v)
      i=i+1
   end
   
   trace(Ack)
   return Ack
end

local personIPO = require "personJson"

local function getRestCallParms(msg)
   local parms={}
   local restParms={}
   
   local p = msg.QPD[3]
   
    
  --
  -- parms extraction
  for i=1,#p do
      local v = p[i][2]   
      trace(v)    
      
      if not v:isNull() then
         trace(v)
         parms[i] = p[i]
         local parmName = p[i][1]:nodeValue()
         trace(parmName)
         trace(type(parmName))
         restParms[parmName]=p[i][2]
      end
   end
   
   trace(parms) 
   trace(restParms)  
   return restParms
end


function main(Data)
   -- TODO add message processing here
   -- all message processing needs to occur here
   
   local config = getApplicationConfig()
   
   local msg,typeMsg,processingErrors = hl7.parse{vmd='IPO.vmd',data=Data}
  
   
   trace(typeMsg)
   trace(processingErrors)
   
   trace(p)
   local restParms = getRestCallParms(msg)
   
  trace(_G)
      
   --
   -- at this point we should be able to conduct a REST call using provided parms
   --
   
   
   local UrlIPO = config["ipo.url"]:nodeText()
   local Patient1JsonString, JsonReadCode, JsonReadHeaders =  net.http.get{url=UrlIPO,parameters=restParms,live=false,debug=false}      
   trace(Patient1JsonString)
   trace(JsonReadCode)
   --
   
   local PatientJson = json.parse{data=personIPO.json}
   trace(PatientJson)

   ack.send(createAck(msg,Patient1Json))
end