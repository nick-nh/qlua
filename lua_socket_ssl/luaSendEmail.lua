local gSPath = getScriptPath()
package.cpath = gSPath .."\\clibs\\?.dll;"..gSPath.."\\clibs\\?\\?.dll;"..package.cpath
package.path  = gSPath .."\\?.lua;"..gSPath .."\\?\\?.lua;"..package.path

print(package.cpath)
print(package.path)

local socket = require("socket")
local smtp = require("socket.smtp")
local ssl = require("ssl")

local Settings = 
   {
      host = "smtp.yandex.ru",
      port = 465,
      from = "from@yandex.ru",
      to = "to@gmail.com",
      subject = "Qlua notification",
      cc = "",
      user = "user",
      password = "pass",
      rcpt = {
            "<to@gmail.com>"
            }
   }


function smtp_send(settings, msg)
   
   local function sslCreate()
       local conn =
       {
          sock = socket.tcp(),
          connect = function(self, host, port)
             local r, e = self.sock:connect(host, port)
             if not r then return r, e end
             self.sock = ssl.wrap(self.sock, {mode = 'client', protocol = 'tlsv1'})
             return self.sock:dohandshake()
          end
       }
    
       local fnIdx = function(t, key)
          return function(self, ...)
             return self.sock[key](self.sock, ...)
          end
       end
    
       return setmetatable(conn, {__index = fnIdx})
   end  
   
   local mesgt = 
   {
      headers = 
      {
         from     = settings.from,
         to       = settings.to,
         cc       = settings.cc,
         subject  = settings.subject or "Qlua Notification",
         ["content-type"] = 'text/plain; charset="windows-1251"'
      },
      body = msg
   }
 
   r, e = smtp.send
   {
        from        = settings.from,
        rcpt        = settings.rcpt, 
        source      = smtp.message(mesgt),
        server      = settings.host,
        port        = settings.port,
        user        = settings.user,
        password    = settings.password,
        create      = sslCreate
   }
   
   message('Send email res: '..tostring(r)..', error: '..tostring(e))

end

smtp_send(Settings, "TEST")