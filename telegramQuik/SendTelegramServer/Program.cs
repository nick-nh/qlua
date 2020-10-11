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

public abstract class LogBase
{
    protected readonly object lockObj = new object();
    protected readonly object _cleanLock = new object();
    public abstract void Log(string message, bool to_con = false);
    public abstract void Close();
    public abstract void Clean();
}

public class FileLogger : LogBase
{
    private static string filePath    = "";
    private static string dirPath     = "";
    private static bool consoleLog    = false;
    private static int _threshold     = 5;
    private static StreamWriter streamWriter;

    public FileLogger(bool toConsole)
    {
        dirPath = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + "\\logs";
        if (!System.IO.Directory.Exists(dirPath))
            System.IO.Directory.CreateDirectory(dirPath);

        filePath = dirPath + "\\" + DateTime.Now.ToString("dd-MM-yyyy") + " log.txt";
        consoleLog      = toConsole;
        if (streamWriter == null)
            streamWriter = new StreamWriter(filePath);
        
        Clean();
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
            var files = Directory.GetFiles(dirPath).Except(new string[] {filePath});

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

public class Settings
{

    private static string SettingsPathFile = "";
    protected readonly object lockObj = new object();

    public static string DefaultPipeName = "telegram_pipe";
    public static string DefaultToken = "";
    public static string DefaultChatId = "";

    public void Read()
    {
        var baseDirectory   = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
        SettingsPathFile    = baseDirectory + "\\settings.ini";

        TextReader iniFile = null;
        string strLine;
        string[] keyPair;

        if (File.Exists(SettingsPathFile))
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
                            if (keyPair[0].ToUpper().Trim() == "PIPENAME")
                                DefaultPipeName = keyPair[1].Trim();
                            if (keyPair[0].ToUpper().Trim() == "TOKEN")
                                DefaultToken = keyPair[1].Trim();
                            if (keyPair[0].ToUpper().Trim() == "CHAT_ID")
                                DefaultChatId = keyPair[1].Trim();
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
                if (iniFile != null)
                    iniFile.Close();
            }
        }

    }
    
    public void Update()
    {
        lock (lockObj)
        {
            var streamWriter = new StreamWriter(SettingsPathFile);
            streamWriter.Write("TOKEN = " + DefaultToken + "\n");
            streamWriter.Write("CHAT_ID = " + DefaultChatId + "\n");
            streamWriter.Write("PIPENAME = " + DefaultPipeName);
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

        static void Main(string[] args)
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

            new PipeTeleServer();
        }
    }
}

public class PipeTeleServer
{
    private static int numThreads = 10;
    private static BotClient botClient;
    private static string PipeName;
    private static LogBase logger = null;

    static volatile bool exit = false;

    public PipeTeleServer()
    {

        Console.OutputEncoding = System.Text.Encoding.UTF8;

        PipeName    = Settings.DefaultPipeName;
        botClient   = new BotClient(Settings.DefaultToken, Settings.DefaultChatId);
        logger      = new FileLogger(false);

        int i;
        Thread[] servers = new Thread[numThreads];

        logger.Log(string.Format("Start Named pipe server stream {0}\n", PipeName), true);
        logger.Log("Waiting for client connect...", true) ;
        logger.Log("Press 'q' to exit", true) ;

        for (i = 0; i < numThreads; i++)
        {
            servers[i] = new Thread(ServerThread);
            servers[i].Start();
        }
        Thread.Sleep(250);

        Task.Factory.StartNew(() =>
        {
            while (Console.ReadKey().Key != ConsoleKey.Q) ;
            exit = true;
        });

        while (!exit)
        {
            for (int j = 0; j < numThreads; j++)
            {
                if (servers[j] != null)
                {
                    if (servers[j].Join(250))
                    {
                        logger.Log(string.Format("Server thread[{0}] finished.", servers[j].ManagedThreadId));
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

        logger.Log("Server stops, exiting.", true);
        logger.Close();
    }

    private static void ServerThread(object data)
    {
        NamedPipeServerStream pipeServer =
            new NamedPipeServerStream(PipeName, PipeDirection.InOut, numThreads);

        int threadId = Thread.CurrentThread.ManagedThreadId;
        logger.Log(string.Format("Start thread[{0}].", threadId));

        // Wait for a client to connect
        pipeServer.WaitForConnection();

        logger.Log(string.Format("Client connected on thread[{0}].", threadId));
        try
        {
            // Read the request from the client. Once the client has
            // written to the pipe its security token will be available.

            StreamString ss = new StreamString(pipeServer);

            // Verify our identity to the connected client using a
            // string that the client anticipates.

            string content = ss.ReadString();

            botClient.Send(content);

        }
        // Catch the IOException that is raised if the pipe is broken
        // or disconnected.
        catch (IOException e)
        {
            logger.Log(string.Format("ERROR: {0}", e.Message), true);
        }
        pipeServer.Close();
    }

}

public class BotClient
{
    private static TelegramBotClient telebotClient;
    private static List<string> chat_id;
    private static LogBase logger = null;
    private static Settings settings = null;

    public BotClient(string token, string chatid)
    {

        chat_id    = chatid.Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries).ToList();
        telebotClient   = new TelegramBotClient(token);
        logger          = new FileLogger(false);
        settings        = new Settings();

        var me = telebotClient.GetMeAsync().Result;

        logger.Log(string.Format("Hello! I am user {0} and my name is {1}.", me.Id, me.FirstName), true);
        if (chatid == "")
        {
            logger.Log("Chat ID not set yet", true);
        }

        telebotClient.OnMessage += Bot_OnMessage;
        telebotClient.StartReceiving();

    }

    ~BotClient()
    {
        telebotClient.StopReceiving();
    }

    async void Bot_OnMessage(object sender, MessageEventArgs e)
    {
        if (e.Message.Text != null)
        {
            logger.Log(string.Format("Received a text message in chat {0}.", e.Message.Chat.Id), true);
            if (chat_id.FirstOrDefault(item => item == e.Message.Chat.Id.ToString()) == null)
            {
                chat_id.Add(e.Message.Chat.Id.ToString());
                Settings.DefaultChatId = String.Join(";", chat_id.ToArray());
                settings.Update();
            }

            await telebotClient.SendTextMessageAsync(
              chatId: e.Message.Chat,
              text: "Ок " + e.Message.From + ". I`ll subscribe to this chat"
            );
        }
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
                logger.Log(string.Format("Send Result: {0}", run_task.Result));
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
}


// Defines the data protocol for reading and writing strings on our stream
public class StreamString
{
    private Stream ioStream;
    private static LogBase logger = null;

    public StreamString(Stream ioStream)
    {
        this.ioStream = ioStream;
    }

    public string ReadString()
    {
        int len;

        try
        {
            len = ioStream.ReadByte() * 256;
            len += ioStream.ReadByte();
            byte[] inBuffer = new byte[len];
            ioStream.Read(inBuffer, 0, len);

            return Encoding.UTF8.GetString(inBuffer);
        }
        catch (IOException e)
        {
            logger.Log(string.Format("ReadPipe ERROR: {0}", e.Message), true);
        }
        return "";
    }

    public int WriteString(string outString)
    {
        byte[] outBuffer = Encoding.UTF8.GetBytes(outString);
        int len = outBuffer.Length;
        if (len > UInt16.MaxValue)
        {
            len = (int)UInt16.MaxValue;
        }
        ioStream.WriteByte((byte)(len / 256));
        ioStream.WriteByte((byte)(len & 255));
        ioStream.Write(outBuffer, 0, len);
        ioStream.Flush();

        return outBuffer.Length + 2;
    }
}
