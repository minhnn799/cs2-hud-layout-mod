using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;
[assembly: System.Reflection.AssemblyVersion("1.4.0.0")]
[assembly: System.Reflection.AssemblyFileVersion("1.4.0.0")]
class Launcher {
 [STAThread] static void Main() {
  string dir=AppDomain.CurrentDomain.BaseDirectory;
  string script=Path.Combine(dir,"Loader.ps1");
  if(!File.Exists(script)){MessageBox.Show("Extract the whole ZIP before opening the launcher.");return;}
  var p=new ProcessStartInfo("powershell.exe","-NoProfile -STA -ExecutionPolicy Bypass -File \""+script+"\"");
  p.UseShellExecute=false;p.CreateNoWindow=true;p.WorkingDirectory=dir;
  try{using(var child=Process.Start(p)){child.WaitForExit();}}catch(Exception e){MessageBox.Show(e.Message);}
 }
}
