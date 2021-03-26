using System;
using System.Diagnostics;

namespace dotnet_wrapper
{
    class Program
    {
        static int Main(string[] args)
        {
            Console.WriteLine($"Hello World: {string.Join(", ", args)}");

            var pi = new ProcessStartInfo(args[0], string.Join(" ", args[1..]))
            {
                UseShellExecute = false,
                RedirectStandardOutput = false,
                RedirectStandardError = false
            };

            pi.Environment["CODEQL_TRACER_SKIP_MATCH"] = "1";

            using var p = Process.Start(pi);
            if (p is null)
            {
                return -1;
            }
            p.WaitForExit();
            return p.ExitCode;
        }
    }
}
