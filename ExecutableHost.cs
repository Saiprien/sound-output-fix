using System;
using System.IO;
using System.Linq;
using System.Threading;
using System.Windows.Forms;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Reflection;
[assembly: AssemblyTitle("Sound Output Fix")]
[assembly: AssemblyDescription("Windows audio output switcher for Spotify")]
[assembly: AssemblyVersion("1.2.0.0")]
internal static class ExecutableHost {
    [STAThread]
    private static int Main(string[] args) {
        bool smoke = args.Contains("--smoke-test");
        string root = AppDomain.CurrentDomain.BaseDirectory;
        try {
            string script = Path.Combine(root,"App.ps1");
            if(!File.Exists(script)) throw new FileNotFoundException("Keep SoundOutputFix.exe inside the complete application folder.",script);
            var session=InitialSessionState.CreateDefault();
            session.ExecutionPolicy=Microsoft.PowerShell.ExecutionPolicy.Bypass;
            using(var runspace=RunspaceFactory.CreateRunspace(session)) {
                runspace.ApartmentState=ApartmentState.STA;
                runspace.ThreadOptions=PSThreadOptions.UseCurrentThread;
                runspace.Open();
                using(var ps=PowerShell.Create()) {
                    ps.Runspace=runspace;
                    ps.AddCommand(script);
                    if(smoke) ps.AddParameter("SmokeTest",true);
                    if(args.Contains("--tray")) ps.AddParameter("StartInTray",true);
                    if(args.Contains("--startup")) ps.AddParameter("StartAtLogin",true);
                    var result=ps.Invoke();
                    // Handled errors (for example an absent optional registry value) also set HadErrors.
                    if(ps.InvocationStateInfo.State == PSInvocationState.Failed)
                        throw ps.InvocationStateInfo.Reason ?? new Exception("Application execution failed.");
                    if(smoke) File.WriteAllText(Path.Combine(root,"smoke-test.txt"),string.Join(Environment.NewLine,result.Select(r=>r.ToString()).ToArray()));
                }
            }
            return 0;
        } catch(Exception error) {
            File.WriteAllText(Path.Combine(root,"launch-error.txt"),error.ToString());
            if(!smoke) MessageBox.Show(error.Message,"Sound Output Fix",MessageBoxButtons.OK,MessageBoxIcon.Error);
            return 1;
        }
    }
}
