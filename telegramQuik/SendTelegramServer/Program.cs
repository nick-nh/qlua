using System;
using System.IO;
using System.IO.Pipes;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Telegram.Bot;
using Telegram.Bot.Args;

namespace Program
{
    class Program
    {
        private static string DefaultPipeName   = "telegram_pipe";
        private static string DefaultToken      = "";
        private static string DefaultChatId     = "";
        private static StreamWriter sw;

        static void Main(string[] args)
        {
            var log_path = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + "\\" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + " log.txt";
            if (System.IO.File.Exists(log_path))
                System.IO.File.Delete(log_path);

            sw = new System.IO.StreamWriter(System.IO.File.Create(log_path));

            var baseDirectory = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
            string CredentialsPathFile = baseDirectory + "\\settings.ini";

            TextReader iniFile = null;
            string strLine;
            string[] keyPair;

            if (File.Exists(CredentialsPathFile))
            {
                try
                {
                    iniFile = new StreamReader(CredentialsPathFile);

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

            if (DefaultToken == "")
            {
                Console.WriteLine("Not set token.");
                sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] Not set token");
                sw.Flush();
                sw.Dispose();
                throw new Exception("Not set token");
            }

            new PipeTeleServer(DefaultPipeName, DefaultToken, DefaultChatId, sw);
        }
    }
}

public class PipeTeleServer
{
    private static int numThreads = 10;
    private static BotClient botClient;
    private static StreamWriter sw;
    private static string PipeName;
    static volatile bool exit = false;

    public PipeTeleServer(string pipe_name, string token, string chat_id, StreamWriter log_sw)
    {
        PipeName = pipe_name;

        Console.OutputEncoding = System.Text.Encoding.UTF8;

        sw = log_sw;

        botClient = new BotClient(token, chat_id, sw);

        int i;
        Thread[] servers = new Thread[numThreads];

        Console.WriteLine("Start Named pipe server stream {0}\n", PipeName);
        Console.WriteLine("Waiting for client connect...");
        Console.WriteLine("Press 'q' to exit");
        sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] Start Named pipe server stream {0}\n", PipeName);
        sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] Waiting for client connect...");
        sw.Flush();
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
                        //Console.WriteLine("Server thread[{0}] finished.", servers[j].ManagedThreadId);
                        sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] Server thread[{0}] finished.", servers[j].ManagedThreadId);
                        sw.Flush();
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
        Console.WriteLine("\nServer stops, exiting.");
        sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] Server stops, exiting.");
        sw.Flush();
        sw.Close();
        sw.Dispose();
    }

    private static void ServerThread(object data)
    {
        NamedPipeServerStream pipeServer =
            new NamedPipeServerStream(PipeName, PipeDirection.InOut, numThreads);

        int threadId = Thread.CurrentThread.ManagedThreadId;
        //Console.WriteLine("Start thread[{0}].", threadId);
        sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] Start thread[{0}].", threadId);
        sw.Flush();

        // Wait for a client to connect
        pipeServer.WaitForConnection();

        //Console.WriteLine("Client connected on thread[{0}].", threadId);
        sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] Client connected on thread[{0}].", threadId);
        sw.Flush();
        try
        {
            // Read the request from the client. Once the client has
            // written to the pipe its security token will be available.

            StreamString ss = new StreamString(pipeServer, sw);

            // Verify our identity to the connected client using a
            // string that the client anticipates.

            //ss.WriteString("I am the one true server!");
            string content = ss.ReadString();
            //Console.WriteLine("Get: {0}", content);
            //sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] Get: {0}", content);
            //sw.Flush();

            botClient.Send(content);

        }
        // Catch the IOException that is raised if the pipe is broken
        // or disconnected.
        catch (IOException e)
        {
            Console.WriteLine("ERROR: {0}", e.Message);
            sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] ERROR: {0}", e.Message);
            sw.Flush();
        }
        pipeServer.Close();
    }

}

public class BotClient
{ 
    readonly TelegramBotClient botClient;
    private string chat_id;
    private StreamWriter sw;

    public BotClient(string token, string chat_id, StreamWriter sw)
    {
        this.sw = sw;
        this.chat_id = chat_id;
        this.botClient = new TelegramBotClient(token);
        var me = botClient.GetMeAsync().Result;
        Console.WriteLine($"Hello, World! I am user {me.Id} and my name is {me.FirstName}.");
        sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] Hello, World! I am user {0} and my name is {1}.", me.Id, me.FirstName);
        if (chat_id == "")
        {
            Console.WriteLine("Chat ID not set yet");
            sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] Chat ID not set yet");
        }
        sw.Flush();

        botClient.OnMessage += Bot_OnMessage;
        botClient.StartReceiving();

    }

    ~BotClient()
    {
        botClient.StopReceiving();
    }

    async void Bot_OnMessage(object sender, MessageEventArgs e)
    {
        if (e.Message.Text != null)
        {
            Console.WriteLine($"Received a text message in chat {e.Message.Chat.Id}.");
            sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] Received a text message in chat {0}.", e.Message.Chat.Id);
            sw.Flush();
            this.chat_id = e.Message.Chat.Id.ToString();
            await botClient.SendTextMessageAsync(
              chatId: e.Message.Chat,
              text: "Ок " + e.Message.From + ". I`ll subscribe to this chat"
            );
        }
    }
    public void Send(string data)
    {
        try
        {
            var run_task = botClient.SendTextMessageAsync(this.chat_id, data);

            while (run_task.Status != TaskStatus.RanToCompletion)
            {
                //Console.WriteLine("Thread ID: {0}, Status: {1}", Thread.CurrentThread.ManagedThreadId, run_task.Status);
                this.sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] Thread ID: {0}, Status: {1}", Thread.CurrentThread.ManagedThreadId, run_task.Status);
                this.sw.Flush();
                if (run_task.Status == TaskStatus.Faulted)
                    break;

                Task.Delay(100).Wait();
            }
            //Console.WriteLine("Result: {0}", run_task.Result);
            this.sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] Result: {0}", run_task.Result);
            this.sw.Flush();
        }
        catch (AggregateException ex)
        {
            foreach (var e in ex.InnerExceptions)
            {
                Console.WriteLine(e.Message);
                this.sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] ERROR: {0}", e.Message);
                this.sw.Flush();
            }
        }
    }
}


// Defines the data protocol for reading and writing strings on our stream
public class StreamString
{
    private Stream ioStream;
    private StreamWriter sw;

    public StreamString(Stream ioStream, StreamWriter sw)
    {
        this.ioStream = ioStream;
        this.sw = sw;
    }

    public string ReadString()
    {
        int len = 0;

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
            Console.WriteLine("ERROR: {0}", e.Message);
            this.sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] ERROR: {0}", e.Message);
            this.sw.Flush();
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
