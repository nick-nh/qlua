using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;

using MailKit;
using MailKit.Net.Imap;
using MailKit.Security;
using MimeKit;

namespace ImapIdleExample
{
    class Program
    {
        // Connection-related properties
        const SecureSocketOptions SslOptions = SecureSocketOptions.Auto;
 
        // Authentication-related properties
        static string Username, Password, Emails_Folder;
        static string Host = "";
        static int Port = 993;

        static string baseDirectory;

        public static void Main(string[] args)
        {

            baseDirectory = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
            Emails_Folder = baseDirectory;

            TextReader iniFile = null;
            string strLine = null;
            string[] keyPair = null;

            string CredentialsPathFile = baseDirectory + "\\ReciveEmail.ini";
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
                                if (keyPair[0].ToUpper() == "IMAPSERVER")
                                    Host = keyPair[1].Trim();
                                if (keyPair[0].ToUpper() == "SERVERPORT")
                                    Port = int.Parse(keyPair[1].Trim());
                                if (keyPair[0].ToUpper() == "LOGIN")
                                    Username = keyPair[1].Trim();
                                if (keyPair[0].ToUpper() == "PASSWORD")
                                    Password = keyPair[1].Trim();
                                if (keyPair[0].ToUpper() == "EMAILS_FOLDER")
                                    Emails_Folder = keyPair[1].Trim();
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
            else
                throw new FileNotFoundException("Unable to locate " + CredentialsPathFile);

            var err_log_path = Emails_Folder + "\\" + DateTime.Now.ToString("dd-MM-yyyy") + " err_log.txt";
            var log_path = Emails_Folder + "\\" + DateTime.Now.ToString("dd-MM-yyyy") + " log.txt";

            var sw = File.AppendText(log_path);

            if (System.IO.File.Exists(err_log_path))
                System.IO.File.Delete(err_log_path);

            var err_sw = new System.IO.StreamWriter(System.IO.File.Create(err_log_path));

            using (var client = new IdleClient(Host, Port, SslOptions, Username, Password, Emails_Folder, sw, err_sw))
            {
                Console.WriteLine("Hit any key to end the client.");

                var idleTask = client.RunAsync();

                Task.Run(() => {
                    Console.ReadKey(true);
                }).Wait();

                client.Exit();

                idleTask.GetAwaiter().GetResult();

                err_sw.Close();
                err_sw.Dispose();
                sw.Close();
                sw.Dispose();
            }
        }
    }

    class IdleClient : IDisposable
    {
        readonly string host, username, password;
        readonly SecureSocketOptions sslOptions;
        readonly int port;
        List<IMessageSummary> messages;
        CancellationTokenSource cancel;
        CancellationTokenSource done;
        bool messagesArrived;
        ImapClient client;
        readonly string emails_folder;
        StreamWriter sw;
        StreamWriter err_sw;

        public IdleClient(string host, int port, SecureSocketOptions sslOptions, string username, string password, string emails_folder, StreamWriter sw, StreamWriter err_sw)
        {
            //this.client         = new ImapClient(new ProtocolLogger(Console.OpenStandardError()));
            this.client         = new ImapClient(new ProtocolLogger("imap.log"));

            this.messages       = new List<IMessageSummary>();
            this.cancel         = new CancellationTokenSource();
            this.sslOptions     = sslOptions;
            this.username       = username;
            this.password       = password;
            this.host           = host;
            this.port           = port;
            this.emails_folder  = emails_folder;
            this.sw             = sw;
            this.err_sw         = err_sw;
        }

        async Task ReconnectAsync()
        {
            if (!client.IsConnected)
                await client.ConnectAsync(host, port, sslOptions, cancel.Token);

            if (!client.IsAuthenticated)
            {
                await client.AuthenticateAsync(username, password, cancel.Token);

                await client.Inbox.OpenAsync(FolderAccess.ReadWrite, cancel.Token);
            }
        }

        async Task FetchMessageSummariesAsync(bool print)
        {
            IList<IMessageSummary> fetched;

            do
            {
                try
                {
                    // fetch summary information for messages that we don't already have
                    int startIndex = messages.Count;

                    fetched = client.Inbox.Fetch(startIndex, -1, MessageSummaryItems.Full | MessageSummaryItems.UniqueId | MessageSummaryItems.BodyStructure, cancel.Token);
                    break;
                }
                catch (ImapProtocolException)
                {
                    // protocol exceptions often result in the client getting disconnected
                    await ReconnectAsync();
                }
                catch (IOException)
                {
                    // I/O exceptions always result in the client getting disconnected
                    await ReconnectAsync();
                }
            } while (true);

            foreach (var message in fetched)
            {
                if (print)
                    Console.WriteLine("{0}: new message: {1}", client.Inbox, message.Envelope.Subject);
                messages.Add(message);
            }
            SaveMessageToFiles(fetched);
        }

        void SaveMessageToFiles(IList<IMessageSummary> fetched)
        {

            if (fetched.Count > 0)
            {

                try
                {
                    var trash_folder = client.GetFolder("Trash");
                    sw.WriteLine("----------------------------------------");
                    sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] Check email. New emails: {0}", fetched.Count);

                    foreach (var item in fetched)
                    {

                        // IMessageSummary.TextBody is a convenience property that finds the 'text/plain' body part for us
                        var bodyPart = (item.TextBody != null) ? item.TextBody : item.HtmlBody;
                        var file_ext = (item.TextBody != null) ? ".txt" : ".html";

                        // download the 'text/plain' body part
                        var body = (TextPart)client.Inbox.GetBodyPart(item.UniqueId, bodyPart);

                        // TextPart.Text is a convenience property that decodes the content and converts the result to
                        // a string for us
                        var text_annotation = "Sender: " + item.Envelope.Sender.ToString() + ", Date: " + item.Date.LocalDateTime.ToString("dd-MM-yyyy HH.mm.ss") + "\n";
                        var text = text_annotation + body.Text;

                        sw.WriteLine("Save email. Sender {0}, Reciever: {1}, My Email: {2}, Date: {3}, Subject: {4}", item.Envelope.Sender, item.Envelope.To, item.Envelope.To, item.Date.LocalDateTime.ToString("dd-MM-yyyy HH.mm.ss"), item.Envelope.Subject);

                        var email_path = "email_text" + item.UniqueId.Id + " " + item.Date.LocalDateTime.ToString("dd-MM-yyyy HH.mm.ss") + file_ext;
                        File.WriteAllText(Path.Combine(emails_folder, email_path), text);

                        // now iterate over all of the attachments and save them to disk
                        foreach (var attachment in item.Attachments)
                        {

                            // determine a directory to save stuff in
                            var directory = Path.Combine(emails_folder, item.UniqueId.ToString());

                            // create the directory
                            Directory.CreateDirectory(directory);

                            // download the attachment just like we did with the body
                            var entity = client.Inbox.GetBodyPart(item.UniqueId, attachment);

                            // attachments can be either message/rfc822 parts or regular MIME parts
                            if (entity is MessagePart)
                            {
                                var rfc822 = (MessagePart)entity;

                                var file_path = Path.Combine(directory, attachment.PartSpecifier + ".eml");

                                rfc822.Message.WriteTo(file_path);
                            }
                            else
                            {
                                var part = (MimePart)entity;

                                // note: it's possible for this to be null, but most will specify a filename
                                var fileName = part.FileName;

                                var file_path = Path.Combine(directory, fileName);

                                // decode and save the content to a file
                                using (var stream = File.Create(file_path))
                                    part.Content.DecodeTo(stream);
                            }
                        }

                        client.Inbox.MoveTo(item.UniqueId, trash_folder);

                    }
                    sw.Flush();
                }
                catch (Exception ex)
                {
                    err_sw.WriteLine("[" + DateTime.Now.ToString("dd-MM-yyyy HH.mm.ss") + "] BAD: Can't fetch email. " + ex.Message);
                    err_sw.Flush();
                    sw.Flush();
                }
            }
        }

        async Task WaitForNewMessagesAsync()
        {
            do
            {
                try
                {
                    if (client.Capabilities.HasFlag(ImapCapabilities.Idle))
                    {
                        // Note: IMAP servers are only supposed to drop the connection after 30 minutes, so normally
                        // we'd IDLE for a max of, say, ~29 minutes... but GMail seems to drop idle connections after
                        // about 10 minutes, so we'll only idle for 9 minutes.
                        using (done = new CancellationTokenSource(new TimeSpan(0, 9, 0)))
                        {
                            using (var linked = CancellationTokenSource.CreateLinkedTokenSource(cancel.Token, done.Token))
                            {
                                await client.IdleAsync(linked.Token);

                                // throw OperationCanceledException if the cancel token has been canceled.
                                cancel.Token.ThrowIfCancellationRequested();
                            }
                        }
                    }
                    else
                    {
                        // Note: we don't want to spam the IMAP server with NOOP commands, so lets wait a minute
                        // between each NOOP command.
                        await Task.Delay(new TimeSpan(0, 1, 0), cancel.Token);
                        await client.NoOpAsync(cancel.Token);
                    }
                    break;
                }
                catch (ImapProtocolException)
                {
                    // protocol exceptions often result in the client getting disconnected
                    await ReconnectAsync();
                }
                catch (IOException)
                {
                    // I/O exceptions always result in the client getting disconnected
                    await ReconnectAsync();
                }
            } while (true);
        }

        async Task IdleAsync()
        {
            do
            {
                try
                {
                    await WaitForNewMessagesAsync();

                    if (messagesArrived)
                    {
                        await FetchMessageSummariesAsync(true);
                        messagesArrived = false;
                    }
                }
                catch (OperationCanceledException)
                {
                    break;
                }
            } while (!cancel.IsCancellationRequested);
        }

        public async Task RunAsync()
        {
            // connect to the IMAP server and get our initial list of messages
            try
            {
                await ReconnectAsync();
                await FetchMessageSummariesAsync(false);
                //SaveMessageToFiles();
            }
            catch (OperationCanceledException)
            {
                await client.DisconnectAsync(true);
                return;
            }

            // keep track of changes to the number of messages in the folder (this is how we'll tell if new messages have arrived).
            client.Inbox.CountChanged += OnCountChanged;

            // keep track of messages being expunged so that when the CountChanged event fires, we can tell if it's
            // because new messages have arrived vs messages being removed (or some combination of the two).
            client.Inbox.MessageExpunged += OnMessageExpunged;

            // keep track of flag changes
            client.Inbox.MessageFlagsChanged += OnMessageFlagsChanged;

            //SaveMessageToFiles();

            await IdleAsync();

            client.Inbox.MessageFlagsChanged -= OnMessageFlagsChanged;
            client.Inbox.MessageExpunged -= OnMessageExpunged;
            client.Inbox.CountChanged -= OnCountChanged;

            await client.DisconnectAsync(true);
        }

        // Note: the CountChanged event will fire when new messages arrive in the folder and/or when messages are expunged.
        void OnCountChanged(object sender, EventArgs e)
        {
            var folder = (ImapFolder)sender;

            // Note: because we are keeping track of the MessageExpunged event and updating our
            // 'messages' list, we know that if we get a CountChanged event and folder.Count is
            // larger than messages.Count, then it means that new messages have arrived.
            if (folder.Count > messages.Count)
            {
                int arrived = folder.Count - messages.Count;

                if (arrived > 1)
                    Console.WriteLine("\t{0} new messages have arrived.", arrived);
                else
                    Console.WriteLine("\t1 new message has arrived.");

                // Note: your first instict may be to fetch these new messages now, but you cannot do
                // that in this event handler (the ImapFolder is not re-entrant).
                //
                // Instead, cancel the `done` token and update our state so that we know new messages
                // have arrived. We'll fetch the summaries for these new messages later...
                messagesArrived = true;
                done?.Cancel();
            }
        }

        void OnMessageExpunged(object sender, MessageEventArgs e)
        {
            var folder = (ImapFolder)sender;

            if (e.Index < messages.Count)
            {
                var message = messages[e.Index];

                Console.WriteLine("{0}: message #{1} has been expunged: {2}", folder, e.Index, message.Envelope.Subject);

                // Note: If you are keeping a local cache of message information
                // (e.g. MessageSummary data) for the folder, then you'll need
                // to remove the message at e.Index.
                messages.RemoveAt(e.Index);
            }
            else
            {
                Console.WriteLine("{0}: message #{1} has been expunged.", folder, e.Index);
            }
        }

        void OnMessageFlagsChanged(object sender, MessageFlagsChangedEventArgs e)
        {
            var folder = (ImapFolder)sender;

            Console.WriteLine("{0}: flags have changed for message #{1} ({2}).", folder, e.Index, e.Flags);
        }

        public void Exit()
        {
            cancel.Cancel();
        }

        public void Dispose()
        {
            client.Dispose();
            cancel.Dispose();
            done?.Dispose();
        }
    }
}