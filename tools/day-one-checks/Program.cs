using System;
class Program
{
    static int Main()
    {
        try { Console.WriteLine(Sunflower.DayOneChecks.Run()); return 0; }
        catch(Exception e) { Console.Error.WriteLine(e); return 1; }
    }
}
