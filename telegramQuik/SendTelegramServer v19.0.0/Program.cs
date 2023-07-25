using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Pipes;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Telegram.Bot;
using Telegram.Bot.Args;
using Telegram.Bot.Exceptions;
using Telegram.Bot.Types;
using Telegram.Bot.Types.Enums;
using System.Net;
using System.Net.Mail;
using System.Text.RegularExpressions;
using System.Globalization;
using Telegram.Bot.Polling;

public delegate void OnReplyHandler();

public abstract class LogBase
{
    protected readonly object lockObj = new();
    protected readonly object _cleanLock = new();
    public abstract void Log(string message, bool to_con = false);
    public abstract void Close();
    public abstract void Clean();
}

public class FileLogger : LogBase
{
    private static string filePath = "";
    private static string dirPath = "";
    private static bool consoleLog = false;
    private static readonly int _threshold = 5;
    private static StreamWriter streamWriter;
    private static int count = 0;
    public FileLogger(bool toConsole)
    {
        dirPath = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + "\\logs";
        if (!System.IO.Directory.Exists(dirPath))
            System.IO.Directory.CreateDirectory(dirPath);

        filePath = dirPath + "\\" + DateTime.Now.ToString("dd-MM-yyyy") + " log.txt";
        consoleLog = toConsole;
        streamWriter ??= new StreamWriter(filePath);

        Clean();
        count += 1;
    }

    ~FileLogger()
    {
        count -= 1;
        if (count == 0)
            Close();
    }
    public override void Log(string message, bool to_con = false)
    {
        lock (lockObj)
        {
            if (streamWriter != null)
            {
                streamWriter.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] " + message);
                streamWriter.Flush();
                if (consoleLog | to_con)
                    Console.WriteLine(message);
            }
        }
    }
    public override void Close()
    {
        lock (lockObj)
        {
            if (streamWriter != null)
            {
                Console.WriteLine("FileLogger Close");
                streamWriter.Dispose();
            }
        }
    }
    public override void Clean()
    {
        lock (_cleanLock)
        {
            if (!Directory.Exists(dirPath))
                return;

            var now = DateTime.Now;
            var files = Directory.GetFiles(dirPath).Except(new string[] { filePath });

            foreach (var filepath in files)
            {
                var file = new FileInfo(filepath);
                var lifetime = now - file.CreationTime;

                if (lifetime.Days > _threshold)
                    file.Delete();
            }
        }
    }
}

public class ExitWait
{
    public static volatile bool exit = false;

    public void Start()
    {
        Task.Factory.StartNew(() =>
        {
            while (Console.ReadKey().Key != ConsoleKey.Q) ;
            exit = true;
        });
    }
}


public class Settings
{

    private static string SettingsPathFile = "";
    protected readonly object lockObj = new();

    public static string DefaultStartTele = "ON";
    public static string DefaultTPipeName = "telegram_pipe";
    public static string DefaultToken = "";
    public static string DefaultChatId = "";
    public static string DefaultEncoding = "windows-1251";

    public static string DefaultStartEmail = "OFF";
    public static string DefaultEPipeName = "email_pipe";
    public static string DefaultSender = "";
    public static string DefaultRecipient = "";
    public static string DefaultTo_copy = "";
    public static string DefaultEmail_subject = "Send Email Message";
    public static string DefaultSmtpServer = "";
    public static int DefaultServerPort = 587;
    public static string DefaultLogin = "";
    public static string DefaultPassword = "";

    public void Read()
    {
        var baseDirectory = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
        SettingsPathFile = baseDirectory + "\\settings.ini";

        TextReader iniFile = null;
        string strLine;
        string[] keyPair;

        if (System.IO.File.Exists(SettingsPathFile))
        {
            try
            {
                iniFile = new StreamReader(SettingsPathFile);

                strLine = iniFile.ReadLine();

                while (strLine != null)
                {
                    strLine = strLine.Trim();

                    if (strLine != "")
                    {
                        keyPair = strLine.Split(new char[] { '=' }, 2);

                        if (keyPair.Length > 1)
                        {
                            if (keyPair[0].ToUpper().Trim() == "START_TELEGRAM")
                                DefaultStartTele = keyPair[1].Trim();
                            if (keyPair[0].ToUpper().Trim() == "TELEGRAM_PIPENAME")
                                DefaultTPipeName = keyPair[1].Trim();
                            if (keyPair[0].ToUpper().Trim() == "TOKEN")
                                DefaultToken = keyPair[1].Trim();
                            if (keyPair[0].ToUpper().Trim() == "CHAT_ID")
                                DefaultChatId = keyPair[1].Trim();
                            if (keyPair[0].ToUpper().Trim() == "USE_ENCODING")
                                DefaultEncoding = keyPair[1].Trim();
                            if (keyPair[0].ToUpper().Trim() == "START_EMAIL")
                                DefaultStartEmail = keyPair[1].Trim();
                            if (keyPair[0].ToUpper().Trim() == "EMAIL_PIPENAME")
                                DefaultEPipeName = keyPair[1].Trim();
                            if (keyPair[0].ToUpper().Trim() == "SENDER")
                                DefaultSender = keyPair[1].Trim();
                            if (keyPair[0].ToUpper().Trim() == "RECIPIENT")
                                DefaultRecipient = keyPair[1].Trim();
                            if (keyPair[0].ToUpper().Trim() == "COPY")
                                DefaultTo_copy = keyPair[1].Trim();
                            if (keyPair[0].ToUpper().Trim() == "EMAIL_SUBJECT")
                                DefaultEmail_subject = keyPair[1].Trim();
                            if (keyPair[0].ToUpper().Trim() == "SMTPSERVER")
                                DefaultSmtpServer = keyPair[1].Trim();
                            if (keyPair[0].ToUpper().Trim() == "SERVERPORT")
                                DefaultServerPort = int.Parse(keyPair[1].Trim());
                            if (keyPair[0].ToUpper().Trim() == "LOGIN")
                                DefaultLogin = keyPair[1].Trim();
                            if (keyPair[0].ToUpper().Trim() == "PASSWORD")
                                DefaultPassword = keyPair[1].Trim();
                        }

                    }

                    strLine = iniFile.ReadLine();
                }

            }
            catch (Exception ex)
            {
                throw ex;
            }
            finally
            {
                iniFile?.Close();
            }
        }

    }

    public void Update()
    {
        lock (lockObj)
        {
            var streamWriter = new StreamWriter(SettingsPathFile);

            streamWriter.Write("[TELEGRAM]\n");
            streamWriter.Write("START_TELEGRAM = " + DefaultStartTele + "\n");
            streamWriter.Write("TELEGRAM_PIPENAME = " + DefaultTPipeName + "\n");
            streamWriter.Write("TOKEN = " + DefaultToken + "\n");
            streamWriter.Write("CHAT_ID = " + DefaultChatId + "\n");
            streamWriter.Write("USE_ENCODING = " + DefaultEncoding + "\n");

            streamWriter.Write("\n[EMAIL]\n");
            streamWriter.Write("START_EMAIL = " + DefaultStartEmail + "\n");
            streamWriter.Write("EMAIL_PIPENAME = " + DefaultEPipeName + "\n");
            streamWriter.Write("SENDER = " + DefaultSender + "\n");
            streamWriter.Write("RECIPIENT = " + DefaultRecipient + "\n");
            streamWriter.Write("COPY = " + DefaultTo_copy + "\n");
            streamWriter.Write("EMAIL_SUBJECT = " + DefaultEmail_subject + "\n");
            streamWriter.Write("SMTPSERVER = " + DefaultSmtpServer + "\n");
            streamWriter.Write("SERVERPORT = " + DefaultServerPort + "\n");
            streamWriter.Write("LOGIN = " + DefaultLogin + "\n");
            streamWriter.Write("PASSWORD = " + DefaultPassword + "\n");
            streamWriter.Flush();
            streamWriter.Close();
        }
    }
}

namespace Program
{
    class Program
    {
        private static LogBase logger = null;

        static void Main()
        {
            logger = new FileLogger(false);
            var settings = new Settings();
            settings.Read();

            if (Settings.DefaultToken == "")
            {

                logger.Log("ERROR: Token not set!", true);
                logger.Close();
                throw new Exception("ERROR: Token not set!");
            }

            var exit = new ExitWait();
            exit.Start();

            if (Settings.DefaultStartTele == "ON")
                new PipeTeleServer();
            if (Settings.DefaultStartEmail == "ON")
                new PipeEmailServer();
        }
    }
}

public class PipeTeleServer
{
    private static readonly int numThreads = 10;
    private static BotClient botClient;
    private static string PipeName;
    private static LogBase logger = null;
    static string DecodeEncodedNonAsciiCharacters2(string value)
    {
        return Regex.Replace(
        value,
        @"##(?<Value>[a-zA-Z0-9]*)",
        m =>
        {
            try
            {
                return char.ConvertFromUtf32((Int32.Parse(m.Groups["Value"].Value, NumberStyles.HexNumber)));
            }
            catch
            {
                logger.Log(string.Format("Wrong emoji utf string ##{0}", m.Groups["Value"].Value));
                return m.Groups["Value"].Value;
            }
        });
    }

    public PipeTeleServer()
    {

        Console.OutputEncoding = System.Text.Encoding.UTF8;

        PipeName = Settings.DefaultTPipeName;
        botClient = new BotClient(Settings.DefaultToken, Settings.DefaultChatId);
        logger = new FileLogger(false);

        int i;
        Thread[] servers = new Thread[numThreads];
        Thread[] out_servers = new Thread[numThreads];

        logger.Log(string.Format("\nStart Telegram Named pipe server stream {0}\n", PipeName), true);
        logger.Log("Waiting for client connect...", true);
        logger.Log("Press 'q' to exit", true);

        for (i = 0; i < numThreads; i++)
        {
            servers[i] = new Thread(ServerThread);
            servers[i].Start();
            out_servers[i] = new Thread(OutServerThread);
            out_servers[i].Start();
        }
        Thread.Sleep(250);

        Task.Factory.StartNew(() =>
        {
            while (!ExitWait.exit)
            {
                for (int j = 0; j < numThreads; j++)
                {
                    if (servers[j] != null)
                    {
                        if (servers[j].Join(250))
                        {
                            logger.Log(string.Format("Telegram Server thread[{0}] finished.", servers[j].ManagedThreadId));
                            servers[j].Abort();
                            servers[j] = null;
                        }
                    }
                    else
                    {
                        servers[j] = new Thread(ServerThread);
                        servers[j].Start();
                    }
                    if (out_servers[j] != null)
                    {
                        if (out_servers[j].Join(250))
                        {
                            logger.Log(string.Format("Telegram Server out_thread[{0}] finished.", out_servers[j].ManagedThreadId));
                            out_servers[j].Abort();
                            out_servers[j] = null;
                        }
                    }
                    else
                    {
                        out_servers[j] = new Thread(OutServerThread);
                        out_servers[j].Start();
                    }
                }
            }

            for (int j = 0; j < numThreads; j++)
            {
                if (servers[j] != null)
                {
                    servers[j].Abort();
                    servers[j] = null;
                }
                if (out_servers[j] != null)
                {
                    out_servers[j].Abort();
                    out_servers[j] = null;
                }
            }

            logger.Log(string.Format("\nTelegram Server {0} stops, exiting.", PipeName), true);
            logger.Close();
            Environment.Exit(0);
        });
    }

    private static void ServerThread(object data)
    {
        NamedPipeServerStream pipeServer =
            new(PipeName, PipeDirection.In, numThreads);

        int threadId = Thread.CurrentThread.ManagedThreadId;
        logger.Log(string.Format("Start Telegram thread[{0}].", threadId));

        // Wait for a client to connect
        pipeServer.WaitForConnection();

        logger.Log(string.Format("Client connected on Telegram thread[{0}].", threadId));
        try
        {
            // Read the request from the client. Once the client has
            // written to the pipe its security token will be available.

            StreamString ss = new(pipeServer);

            // Verify our identity to the connected client using a
            // string that the client anticipates.

            string content = DecodeEncodedNonAsciiCharacters2(ss.ReadString());
            botClient.Send(content);

        }
        // Catch the IOException that is raised if the pipe is broken
        // or disconnected.
        catch (IOException e)
        {
            logger.Log(string.Format("Telegram ServerThread ERROR: {0}", e.Message), true);
        }
        pipeServer.Close();
    }

    private static void OutServerThread(object data)
    {
        NamedPipeServerStream pipeServer =
            new("out_" + PipeName, PipeDirection.Out, numThreads);

        int threadId = Thread.CurrentThread.ManagedThreadId;
        logger.Log(string.Format("Start Telegram out_thread[{0}].", threadId));

        // Wait for a client to connect
        pipeServer.WaitForConnection();

        logger.Log(string.Format("Client connected on Telegram out_thread[{0}].", threadId));
        try
        {

            StreamString ss = new(pipeServer);

            var msgs = botClient.GetIncomeMessages();
            msgs ??= "{[===[No new messages]===]}";

            logger.Log(string.Format("IncomeMessages {0}", msgs));

            ss.WriteString(msgs);
            BotClient.ClearIncomeMessages();

        }
        // Catch the IOException that is raised if the pipe is broken
        // or disconnected.
        catch (IOException e)
        {
            logger.Log(string.Format("Telegram OutServerThread ERROR: {0}", e.Message), true);
        }
        pipeServer.Close();
    }


}

public class PipeEmailServer
{
    private static readonly int numThreads = 10;
    private static string PipeName;
    private static LogBase logger = null;

    public PipeEmailServer()
    {

        Console.OutputEncoding = System.Text.Encoding.UTF8;

        PipeName = Settings.DefaultEPipeName;
        logger = new FileLogger(false);

        int i;
        Thread[] servers = new Thread[numThreads];

        logger.Log(string.Format("\nStart Email Named pipe server stream {0}\n", PipeName), true);
        logger.Log("Waiting for client connect...", true);
        logger.Log("Press 'q' to exit", true);

        for (i = 0; i < numThreads; i++)
        {
            servers[i] = new Thread(ServerThread);
            servers[i].Start();
        }
        Thread.Sleep(250);

        Task.Factory.StartNew(() =>
        {
            while (!ExitWait.exit)
            {
                for (int j = 0; j < numThreads; j++)
                {
                    if (servers[j] != null)
                    {
                        if (servers[j].Join(250))
                        {
                            logger.Log(string.Format("Email Server thread[{0}] finished.", servers[j].ManagedThreadId));
                            servers[j].Abort();
                            servers[j] = null;
                        }
                    }
                    else
                    {
                        servers[j] = new Thread(ServerThread);
                        servers[j].Start();
                    }
                }
            }

            for (int j = 0; j < numThreads; j++)
            {
                if (servers[j] != null)
                {
                    servers[j].Abort();
                    servers[j] = null;
                }
            }

            logger.Log(string.Format("\nEmail Server {0} stops, exiting.", PipeName), true);
        });
    }

    private static void ServerThread(object data)
    {
        NamedPipeServerStream pipeServer =
            new(PipeName, PipeDirection.InOut, numThreads);

        int threadId = Thread.CurrentThread.ManagedThreadId;
        logger.Log(string.Format("Start Email thread[{0}].", threadId));

        // Wait for a client to connect
        pipeServer.WaitForConnection();

        logger.Log(string.Format("Client connected on Email thread[{0}].", threadId));
        try
        {
            // Read the request from the client. Once the client has
            // written to the pipe its security token will be available.

            StreamString ss = new(pipeServer);

            // Verify our identity to the connected client using a
            // string that the client anticipates.

            string content = ss.ReadString();
            logger.Log(string.Format("Get Email message:\n{0}", content));

            var CountArray = content.Length;
            var Subject = Settings.DefaultEmail_subject;
            var Body = String.Join("\n", content);
            MailAddress From = new(Settings.DefaultSender);
            MailAddress To = new(Settings.DefaultRecipient);
            var msg = new MailMessage(From, To)
            {
                Body = Body,
                Subject = Subject
            };
            if (Settings.DefaultTo_copy != "")
            {
                string[] elements = Settings.DefaultTo_copy.Split(';');
                foreach (var element in elements)
                {
                    msg.CC.Add(new MailAddress(element.Trim()));
                }
            }
            var smtpClient = new SmtpClient(Settings.DefaultSmtpServer, Settings.DefaultServerPort)
            {
                Credentials = new NetworkCredential(Settings.DefaultLogin, Settings.DefaultPassword),
                EnableSsl = true
            };
            smtpClient.Send(msg);

        }
        // Catch the IOException that is raised if the pipe is broken
        // or disconnected.
        catch (IOException e)
        {
            logger.Log(string.Format("Email ServerThread ERROR: {0}", e.Message), true);
        }
        pipeServer.Close();
    }

}

public class BotClient
{
    private static TelegramBotClient telebotClient;
    private static CancellationTokenSource cts;
    private static List<string> chat_id;
    private static LogBase logger = null;
    private static Settings settings = null;
    private static readonly List<string> income_msgs = new();

    public BotClient(string token, string chatid)
    {

        logger = new FileLogger(false);
        settings = new Settings();

        chat_id = chatid.Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries).ToList();
        try
        {
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;

            telebotClient = new TelegramBotClient(token);
        }
        catch (System.ArgumentException e)
        {
            logger.Log(string.Format("TelegramBotClient ERROR: {0}", e.Message), true);
            logger.Close();
            throw new Exception("ERROR: Telegram Bot Client not init!");
        }
        catch (System.Net.WebException e)
        {
            logger.Log(string.Format("TelegramBotClient ERROR: {0}", e.Message), true);
            logger.Close();
            throw new Exception("ERROR: Telegram Bot Client not init!");
        }

        cts = new CancellationTokenSource();
        var receiverOptions = new ReceiverOptions
        {
            AllowedUpdates = { } // receive all update types
        };

        telebotClient.StartReceiving(
            HandleUpdateAsync,
            HandleErrorAsync,
            receiverOptions,
            cancellationToken: cts.Token);

        var me = telebotClient.GetMeAsync().Result;

        logger.Log(string.Format("Hello! I am user {0} and my name is {1}.", me.Id, me.Username), true);
        if (chatid == "")
        {
            logger.Log("Chat ID not set yet", true);
        }

        foreach (var chat in chat_id)
            logger.Log(string.Format("Start Bot to Chats {0}", chat));


    }

    ~BotClient()
    {
        cts.Cancel();
    }

    async Task HandleUpdateAsync(ITelegramBotClient botClient, Update update, CancellationToken cancellationToken)
    {
        // Only process Message updates: https://core.telegram.org/bots/api#message
        if (update.Type != UpdateType.Message)
            return;
        // Only process text messages
        if (update.Message!.Type != MessageType.Text)
            return;

        var chatId = update.Message.Chat.Id;
        var messageText = update.Message.Text;

        if (messageText != null)
        {
            logger.Log(string.Format("Received a text message in chat {0}:\n", chatId), true);
            logger.Log(string.Format("{0}", messageText));
            if (chat_id.Count() == 0)
            //& (chat_id.FirstOrDefault(item => item == e.Message.Chat.Id.ToString()) == null)
            {
                chat_id.Add(chatId.ToString());
                Settings.DefaultChatId = String.Join(";", chat_id.ToArray());
                settings.Update();

                await telebotClient.SendTextMessageAsync(
                  chatId: chatId,
                  text: "Ок " + update.Message.From + ". I`ll subscribe to this chat",
                  cancellationToken: cancellationToken
                );
            }
            else
                income_msgs.Add(messageText.Trim());
        }

    }

    Task HandleErrorAsync(ITelegramBotClient botClient, Exception exception, CancellationToken cancellationToken)
    {
        var ErrorMessage = exception switch
        {
            ApiRequestException apiRequestException
                => $"Telegram API Error:\n[{apiRequestException.ErrorCode}]\n{apiRequestException.Message}",
            _ => exception.ToString()
        };

        Console.WriteLine(ErrorMessage);
        return Task.CompletedTask;
    }

    public void Send(string data)
    {
        try
        {
            foreach (var chat in chat_id)
            {
                var run_task = telebotClient.SendTextMessageAsync(chat, data);

                while (run_task.Status != TaskStatus.RanToCompletion)
                {
                    logger.Log(string.Format("Thread ID: {0}, Status: {1}", Thread.CurrentThread.ManagedThreadId, run_task.Status));
                    if (run_task.Status == TaskStatus.Faulted)
                        break;

                    Task.Delay(100).Wait();
                }
                logger.Log(string.Format("Send to {0} Result: {1}", chat, run_task.Result));
            }
        }
        catch (AggregateException ex)
        {
            foreach (var e in ex.InnerExceptions)
            {
                logger.Log(string.Format("Send ERROR: {0}", e.Message), true);
            }
        }
    }

    public string GetIncomeMessages()
    {
        if (income_msgs.Count() > 0)
        {
            var msgs = "{[===[" + String.Join("]===], [===[", income_msgs.ToArray()) + "]===]}";
            return msgs;
        }
        return null;
    }

    public static void ClearIncomeMessages()
    {
        income_msgs.Clear();
    }
}

// Defines the data protocol for reading and writing strings on our stream
public class StreamString
{
    private readonly Stream ioStream;
    private static LogBase logger = null;

    public StreamString(Stream ioStream)
    {
        this.ioStream = ioStream;
        logger = new FileLogger(false);
    }
    static string UTF8ToDefault(string sourceStr)
    {
        Encoding utf8 = Encoding.UTF8;
        Encoding def = Encoding.GetEncoding(Settings.DefaultEncoding);
        byte[] utf8Bytes = utf8.GetBytes(sourceStr);
        byte[] defBytes = Encoding.Convert(utf8, def, utf8Bytes);
        return def.GetString(defBytes);
    }
    static private string DefaultToUTF8(string sourceStr)
    {
        Encoding utf8 = Encoding.UTF8;
        Encoding def = Encoding.GetEncoding(Settings.DefaultEncoding);
        byte[] defBytes = def.GetBytes(sourceStr);
        byte[] utf8Bytes = Encoding.Convert(def, utf8, defBytes);
        return utf8.GetString(utf8Bytes); ;
    }

    public string ReadString()
    {

        try
        {
            string res = "";

            byte[] inBuffer = new byte[1024];
            int get = 0;
            do
            {
                get = ioStream.Read(inBuffer, 0, inBuffer.Length);
                res += Encoding.GetEncoding(Settings.DefaultEncoding).GetString(inBuffer).TrimEnd('\0');
                Array.Clear(inBuffer, 0, inBuffer.Length);
            } while (get >= inBuffer.Length);

            if (Settings.DefaultEncoding != "UTF-8")
                res = DefaultToUTF8(res);

            return res;
        }
        catch (IOException e)
        {
            logger.Log(string.Format("ReadPipe ERROR: {0}", e.ToString()), true);
        }
        return "";
    }

    public int WriteString(string outString)
    {
        try
        {
            string to_send = outString;
            if (Settings.DefaultEncoding != "UTF-8")
                to_send = UTF8ToDefault(outString);

            byte[] outBuffer = Encoding.GetEncoding(Settings.DefaultEncoding).GetBytes(to_send);
            int len = outBuffer.Length;
            if (len > UInt16.MaxValue)
            {
                len = (int)UInt16.MaxValue;
            }
            ioStream.Write(outBuffer, 0, len);
            ioStream.Flush();

            return outBuffer.Length + 2;
        }
        catch (IOException e)
        {
            logger.Log(string.Format("WriteString ERROR: {0}", e.ToString()), true);
        }
        return 0;
    }
}